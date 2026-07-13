import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Thin wrapper around a single flutter_webrtc peer connection for one
/// call — voice-only or voice+video. Signaling (offer/answer/ICE) is
/// carried over the app's existing Socket.IO connection by [CallController];
/// this class only owns the local media + the peer connection itself.
///
/// ICE candidates generated before the remote description is set (which
/// happens on the callee's side only after the user taps Accept) can't be
/// applied yet — they're buffered here and flushed once
/// [setRemoteDescription] has run, since Socket.IO doesn't queue emits for
/// listeners that haven't attached yet.
class WebRtcService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _remoteDescriptionSet = false;
  final _pendingRemoteCandidates = <RTCIceCandidate>[];

  RTCVideoRenderer? localRenderer;
  RTCVideoRenderer? remoteRenderer;

  void Function(RTCIceCandidate candidate)? onIceCandidate;
  void Function(MediaStream stream)? onRemoteStream;
  void Function(RTCPeerConnectionState state)? onConnectionState;

  bool _muted = false;
  bool _speakerOn = false;
  bool _videoEnabled = false;
  bool get isVideoEnabled => _videoEnabled;

  static const _config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
  };

  Future<void> _ensurePeerConnection() async {
    if (_peerConnection != null) return;
    final pc = await createPeerConnection(_config);
    pc.onIceCandidate = (candidate) => onIceCandidate?.call(candidate);
    pc.onConnectionState = (state) => onConnectionState?.call(state);
    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        if (remoteRenderer != null) remoteRenderer!.srcObject = _remoteStream;
        onRemoteStream?.call(_remoteStream!);
      }
    };
    _peerConnection = pc;
  }

  Future<void> _ensureLocalMedia(bool video) async {
    if (_localStream != null) return;
    _videoEnabled = video;
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video ? {'facingMode': 'user'} : false,
    });
    _localStream = stream;
    for (final track in stream.getTracks()) {
      await _peerConnection!.addTrack(track, stream);
    }
    if (video) {
      localRenderer = RTCVideoRenderer();
      await localRenderer!.initialize();
      localRenderer!.srcObject = stream;
    }
  }

  Future<void> _ensureRemoteRenderer(bool video) async {
    if (!video || remoteRenderer != null) return;
    remoteRenderer = RTCVideoRenderer();
    await remoteRenderer!.initialize();
  }

  /// Caller side: build the peer connection, grab local media, and return
  /// an SDP offer to send via `call:invite`.
  Future<RTCSessionDescription> createOffer({required bool video}) async {
    await _ensurePeerConnection();
    await _ensureRemoteRenderer(video);
    await _ensureLocalMedia(video);
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  /// Callee side: build the peer connection, grab local media, apply the
  /// caller's offer, and return an SDP answer to send via `call:answer`.
  Future<RTCSessionDescription> createAnswer({
    required bool video,
    required RTCSessionDescription remoteOffer,
  }) async {
    await _ensurePeerConnection();
    await _ensureRemoteRenderer(video);
    await _ensureLocalMedia(video);
    await _peerConnection!.setRemoteDescription(remoteOffer);
    _remoteDescriptionSet = true;
    await _flushPendingCandidates();
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  /// Caller side: apply the callee's answer once `call:answered` arrives.
  Future<void> setRemoteAnswer(RTCSessionDescription answer) async {
    if (_peerConnection == null) return;
    await _peerConnection!.setRemoteDescription(answer);
    _remoteDescriptionSet = true;
    await _flushPendingCandidates();
  }

  Future<void> addRemoteIceCandidate(RTCIceCandidate candidate) async {
    if (!_remoteDescriptionSet || _peerConnection == null) {
      _pendingRemoteCandidates.add(candidate);
      return;
    }
    await _peerConnection!.addCandidate(candidate);
  }

  Future<void> _flushPendingCandidates() async {
    for (final candidate in _pendingRemoteCandidates) {
      await _peerConnection?.addCandidate(candidate);
    }
    _pendingRemoteCandidates.clear();
  }

  void toggleMute() {
    _muted = !_muted;
    for (final track in _localStream?.getAudioTracks() ?? []) {
      track.enabled = !_muted;
    }
  }

  bool get isMuted => _muted;

  Future<void> toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    await Helper.setSpeakerphoneOn(_speakerOn);
  }

  bool get isSpeakerOn => _speakerOn;

  Future<void> switchCamera() async {
    final videoTracks = _localStream?.getVideoTracks() ?? [];
    if (videoTracks.isNotEmpty) await Helper.switchCamera(videoTracks.first);
  }

  Future<void> dispose() async {
    for (final track in _localStream?.getTracks() ?? []) {
      await track.stop();
    }
    await _localStream?.dispose();
    await _peerConnection?.close();
    await _peerConnection?.dispose();
    await localRenderer?.dispose();
    await remoteRenderer?.dispose();
    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
    _remoteDescriptionSet = false;
    _pendingRemoteCandidates.clear();
  }
}
