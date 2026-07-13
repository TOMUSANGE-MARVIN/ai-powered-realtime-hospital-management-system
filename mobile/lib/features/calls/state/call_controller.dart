import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:record/record.dart';

import '../../../core/realtime/socket_providers.dart';
import '../../auth/state/auth_controller.dart';
import '../data/webrtc_service.dart';
import 'call_providers.dart';
import 'call_state.dart';

const _ringTimeout = Duration(seconds: 45);

/// Owns the one active call's WebRTC peer connection + signaling, exposed
/// as a state machine screens react to (see [CallState]). Instantiated
/// once near the app root (see main.dart's CallOverlay) so it keeps
/// listening for incoming calls regardless of the current screen.
class CallController extends Notifier<CallState> {
  WebRtcService? _rtc;
  Timer? _ringTimer;
  Timer? _resetTimer;
  StreamSubscription? _incomingSub;
  StreamSubscription? _answeredSub;
  StreamSubscription? _declinedSub;
  StreamSubscription? _cancelledSub;
  StreamSubscription? _endedSub;
  StreamSubscription? _busySub;
  StreamSubscription? _iceSub;
  StreamSubscription? _callStatusSub;

  /// True when this device placed the call — only the caller logs the
  /// outcome via [recordCall], so one call produces exactly one log row.
  bool _wasCaller = false;
  DateTime? _connectedAt;

  final _ringbackPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  final _ringtonePlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);

  void _stopRingingSounds() {
    _ringbackPlayer.stop();
    _ringtonePlayer.stop();
  }

  @override
  CallState build() {
    final socket = ref.read(socketServiceProvider);

    _incomingSub = socket.incomingCalls.listen(_onIncomingCall);
    _answeredSub = socket.callAnswered.listen(_onCallAnswered);
    _declinedSub = socket.callDeclined.listen((_) => _onTerminal(CallEndReason.declined));
    _cancelledSub = socket.callCancelled.listen((_) => _onTerminal(CallEndReason.cancelled));
    _endedSub = socket.callEnded.listen(_onCallEnded);
    _busySub = socket.callBusy.listen((_) => _onTerminal(CallEndReason.busy));
    _iceSub = socket.iceCandidates.listen(_onRemoteIceCandidate);
    _callStatusSub = socket.callStatus.listen(_onCallStatus);

    ref.onDispose(() {
      _incomingSub?.cancel();
      _answeredSub?.cancel();
      _declinedSub?.cancel();
      _cancelledSub?.cancel();
      _endedSub?.cancel();
      _busySub?.cancel();
      _iceSub?.cancel();
      _callStatusSub?.cancel();
      _ringTimer?.cancel();
      _resetTimer?.cancel();
      _rtc?.dispose();
      _ringbackPlayer.dispose();
      _ringtonePlayer.dispose();
    });

    return const CallIdle();
  }

  String? get _peerId => switch (state) {
        CallOutgoingRinging(:final peerId) => peerId,
        CallIncomingRinging(:final peerId) => peerId,
        CallConnecting(:final peerId) => peerId,
        CallInProgress(:final peerId) => peerId,
        _ => null,
      };

  String? get _callId => switch (state) {
        CallOutgoingRinging(:final callId) => callId,
        CallIncomingRinging(:final callId) => callId,
        CallConnecting(:final callId) => callId,
        CallInProgress(:final callId) => callId,
        _ => null,
      };

  Future<bool> _checkMicPermission() => AudioRecorder().hasPermission();

  Future<void> startOutgoingCall(
    String peerId,
    String peerName, {
    bool isVideo = false,
    String? peerImage,
  }) async {
    if (state is! CallIdle) return;
    if (!await _checkMicPermission()) return;

    final me = ref.read(authControllerProvider).value;
    if (me == null) return;

    final callId = '${DateTime.now().microsecondsSinceEpoch}-${me.id}';
    _wasCaller = true;
    state = CallOutgoingRinging(
      callId: callId,
      peerId: peerId,
      peerName: peerName,
      isVideo: isVideo,
      peerImage: peerImage,
    );
    _ringbackPlayer.play(AssetSource('sounds/ringback.m4a'));

    final rtc = WebRtcService();
    rtc.onIceCandidate = (c) => _sendIceCandidate(callId, peerId, c);
    rtc.onConnectionState = _onPeerConnectionState;
    _rtc = rtc;

    final offer = await _rtc!.createOffer(video: isVideo);

    ref.read(socketServiceProvider).emitCallInvite({
      'callId': callId,
      'calleeId': peerId,
      'callerId': me.id,
      'callerName': me.name,
      'callerImage': me.image,
      'type': isVideo ? 'video' : 'voice',
      'sdp': offer.toMap(),
    });

    _ringTimer?.cancel();
    _ringTimer = Timer(_ringTimeout, () {
      if (state is CallOutgoingRinging) {
        ref.read(socketServiceProvider).emitCallCancel({'callId': callId});
        _finish(CallEndReason.noAnswer);
      }
    });
  }

  void _onIncomingCall(Map<String, dynamic> data) {
    if (state is! CallIdle) {
      // Already on a call — let the server-side busy-check handle it;
      // nothing to do here besides ignore this invite.
      return;
    }
    final sdp = data['sdp'] as Map;
    state = CallIncomingRinging(
      callId: data['callId'] as String,
      peerId: data['callerId'] as String,
      peerName: data['callerName'] as String? ?? 'Unknown',
      isVideo: data['type'] == 'video',
      offerSdp: Map<String, dynamic>.from(sdp),
      peerImage: data['callerImage'] as String?,
    );
    _ringtonePlayer.play(AssetSource('sounds/ringtone.m4a'));
  }

  Future<void> acceptIncomingCall() async {
    final current = state;
    if (current is! CallIncomingRinging) return;
    if (!await _checkMicPermission()) {
      declineIncomingCall();
      return;
    }

    _stopRingingSounds();
    _wasCaller = false;
    final callId = current.callId;
    final peerId = current.peerId;

    state = CallConnecting(
      callId: callId,
      peerId: peerId,
      peerName: current.peerName,
      isVideo: current.isVideo,
      peerImage: current.peerImage,
    );

    final rtc = WebRtcService();
    rtc.onIceCandidate = (c) => _sendIceCandidate(callId, peerId, c);
    rtc.onConnectionState = _onPeerConnectionState;
    _rtc = rtc;

    final answer = await _rtc!.createAnswer(
      video: current.isVideo,
      remoteOffer: RTCSessionDescription(
        current.offerSdp['sdp'] as String?,
        current.offerSdp['type'] as String?,
      ),
    );

    ref.read(socketServiceProvider).emitCallAnswer({
      'callId': callId,
      'sdp': answer.toMap(),
    });
  }

  void declineIncomingCall() {
    final current = state;
    if (current is! CallIncomingRinging) return;
    _stopRingingSounds();
    ref.read(socketServiceProvider).emitCallDecline({'callId': current.callId});
    _cleanupRtc();
    state = const CallIdle();
  }

  Future<void> _onCallAnswered(Map<String, dynamic> data) async {
    final current = state;
    if (current is! CallOutgoingRinging || data['callId'] != current.callId) return;
    _stopRingingSounds();
    _ringTimer?.cancel();

    state = CallConnecting(
      callId: current.callId,
      peerId: current.peerId,
      peerName: current.peerName,
      isVideo: current.isVideo,
      peerImage: current.peerImage,
    );

    final sdp = data['sdp'] as Map;
    await _rtc?.setRemoteAnswer(
      RTCSessionDescription(sdp['sdp'] as String?, sdp['type'] as String?),
    );
  }

  void _onPeerConnectionState(RTCPeerConnectionState connectionState) {
    if (connectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      final current = state;
      if (current is CallConnecting) {
        _connectedAt = DateTime.now();
        state = CallInProgress(
          callId: current.callId,
          peerId: current.peerId,
          peerName: current.peerName,
          isVideo: current.isVideo,
          connectedAt: _connectedAt!,
          peerImage: current.peerImage,
        );
      }
    } else if (connectionState == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
      _finish(CallEndReason.error);
    }
  }

  void _onCallEnded(Map<String, dynamic> data) {
    final callId = _callId;
    if (callId == null || data['callId'] != callId) return;
    final reason = data['reason'] == 'peer-disconnected'
        ? CallEndReason.peerDisconnected
        : CallEndReason.hangup;
    _finish(reason);
  }

  void _onTerminal(CallEndReason reason) {
    _finish(reason);
  }

  void _onCallStatus(Map<String, dynamic> data) {
    final current = state;
    if (current is! CallOutgoingRinging || data['callId'] != current.callId) return;
    state = current.copyWith(calleeOnline: data['calleeOnline'] as bool? ?? false);
  }

  void _sendIceCandidate(String callId, String targetUserId, RTCIceCandidate candidate) {
    ref.read(socketServiceProvider).emitIceCandidate({
      'callId': callId,
      'targetUserId': targetUserId,
      'candidate': candidate.toMap(),
    });
  }

  void _onRemoteIceCandidate(Map<String, dynamic> data) {
    if (data['callId'] != _callId) return;
    final c = data['candidate'] as Map;
    _rtc?.addRemoteIceCandidate(
      RTCIceCandidate(
        c['candidate'] as String?,
        c['sdpMid'] as String?,
        c['sdpMLineIndex'] as int?,
      ),
    );
  }

  void toggleMute() {
    final current = state;
    if (current is! CallInProgress) return;
    _rtc?.toggleMute();
    state = current.copyWith(muted: _rtc?.isMuted ?? current.muted);
  }

  Future<void> toggleSpeaker() async {
    final current = state;
    if (current is! CallInProgress) return;
    await _rtc?.toggleSpeaker();
    state = current.copyWith(speakerOn: _rtc?.isSpeakerOn ?? current.speakerOn);
  }

  Future<void> switchCamera() => _rtc?.switchCamera() ?? Future.value();

  RTCVideoRenderer? get localRenderer => _rtc?.localRenderer;
  RTCVideoRenderer? get remoteRenderer => _rtc?.remoteRenderer;

  void hangUp() {
    final callId = _callId;
    if (callId == null) {
      state = const CallIdle();
      return;
    }
    ref.read(socketServiceProvider).emitCallHangup({'callId': callId});
    _finish(CallEndReason.hangup);
  }

  void _finish(CallEndReason reason) {
    _stopRingingSounds();
    final wasInProgress = state is CallInProgress;
    final duration = wasInProgress ? DateTime.now().difference(_connectedAt!) : null;

    if (_wasCaller) {
      final callType = switch (state) {
        CallOutgoingRinging(:final isVideo) => isVideo,
        CallConnecting(:final isVideo) => isVideo,
        CallInProgress(:final isVideo) => isVideo,
        _ => false,
      };
      final status = switch (reason) {
        CallEndReason.hangup || CallEndReason.peerDisconnected =>
          wasInProgress ? 'answered' : 'cancelled',
        CallEndReason.declined => 'declined',
        CallEndReason.busy => 'busy',
        CallEndReason.noAnswer || CallEndReason.cancelled => 'missed',
        CallEndReason.error => 'missed',
      };
      final peerId = _peerId;
      if (peerId != null) {
        ref.read(callRepositoryProvider).recordCall(
              calleeId: peerId,
              type: callType ? 'video' : 'voice',
              status: status,
              durationSeconds: duration?.inSeconds,
            );
      }
    }

    _cleanupRtc();
    _ringTimer?.cancel();
    state = CallEnded(reason: reason, duration: duration);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (state is CallEnded) state = const CallIdle();
    });
  }

  void _cleanupRtc() {
    _rtc?.dispose();
    _rtc = null;
    _connectedAt = null;
  }
}

final callControllerProvider = NotifierProvider<CallController, CallState>(CallController.new);
