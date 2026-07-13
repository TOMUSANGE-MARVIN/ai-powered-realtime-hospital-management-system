enum CallEndReason { hangup, declined, busy, noAnswer, cancelled, peerDisconnected, error }

sealed class CallState {
  const CallState();
}

class CallIdle extends CallState {
  const CallIdle();
}

class CallOutgoingRinging extends CallState {
  const CallOutgoingRinging({
    required this.callId,
    required this.peerId,
    required this.peerName,
    required this.isVideo,
    this.peerImage,
    this.calleeOnline,
  });

  final String callId;
  final String peerId;
  final String peerName;
  final bool isVideo;
  final String? peerImage;

  /// Null until the server's `call:status` reply arrives — used to show
  /// "Calling…" (offline/unknown) vs "Ringing…" (reaching a live device).
  final bool? calleeOnline;

  CallOutgoingRinging copyWith({bool? calleeOnline}) {
    return CallOutgoingRinging(
      callId: callId,
      peerId: peerId,
      peerName: peerName,
      isVideo: isVideo,
      peerImage: peerImage,
      calleeOnline: calleeOnline ?? this.calleeOnline,
    );
  }
}

class CallIncomingRinging extends CallState {
  const CallIncomingRinging({
    required this.callId,
    required this.peerId,
    required this.peerName,
    required this.isVideo,
    required this.offerSdp,
    this.peerImage,
  });

  final String callId;
  final String peerId;
  final String peerName;
  final bool isVideo;
  final Map<String, dynamic> offerSdp;
  final String? peerImage;
}

class CallConnecting extends CallState {
  const CallConnecting({
    required this.callId,
    required this.peerId,
    required this.peerName,
    required this.isVideo,
    this.peerImage,
  });

  final String callId;
  final String peerId;
  final String peerName;
  final bool isVideo;
  final String? peerImage;
}

class CallInProgress extends CallState {
  const CallInProgress({
    required this.callId,
    required this.peerId,
    required this.peerName,
    required this.isVideo,
    required this.connectedAt,
    this.peerImage,
    this.muted = false,
    this.speakerOn = false,
  });

  final String callId;
  final String peerId;
  final String peerName;
  final bool isVideo;
  final DateTime connectedAt;
  final String? peerImage;
  final bool muted;
  final bool speakerOn;

  CallInProgress copyWith({bool? muted, bool? speakerOn}) {
    return CallInProgress(
      callId: callId,
      peerId: peerId,
      peerName: peerName,
      isVideo: isVideo,
      connectedAt: connectedAt,
      peerImage: peerImage,
      muted: muted ?? this.muted,
      speakerOn: speakerOn ?? this.speakerOn,
    );
  }
}

class CallEnded extends CallState {
  const CallEnded({required this.reason, this.duration});

  final CallEndReason reason;
  final Duration? duration;
}
