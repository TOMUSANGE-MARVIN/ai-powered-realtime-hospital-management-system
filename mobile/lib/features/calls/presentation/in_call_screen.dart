import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../state/call_controller.dart';
import '../state/call_state.dart';
import 'duration_ticker.dart';

/// Shown for [CallOutgoingRinging], [CallConnecting], and [CallInProgress]
/// — an outgoing call in flight, being connected, or already live. Pressing
/// back minimizes to [MinimizedCallCard] via [onMinimize] instead of doing
/// nothing / leaking through to the route underneath.
class InCallScreen extends ConsumerWidget {
  const InCallScreen({
    super.key,
    required this.state,
    required this.onMinimize,
  });

  final CallState state;
  final VoidCallback onMinimize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(callControllerProvider.notifier);

    final (peerName, peerImage, isVideo, statusText) = switch (state) {
      CallOutgoingRinging(
        :final peerName,
        :final peerImage,
        :final isVideo,
        :final calleeOnline,
      ) =>
        (
          peerName,
          peerImage,
          isVideo,
          calleeOnline == true ? 'Ringing…' : 'Calling…',
        ),
      CallConnecting(:final peerName, :final peerImage, :final isVideo) => (
        peerName,
        peerImage,
        isVideo,
        'Connecting…',
      ),
      CallInProgress(:final peerName, :final peerImage, :final isVideo) => (
        peerName,
        peerImage,
        isVideo,
        null,
      ),
      _ => ('', null, false, ''),
    };

    final inProgress = state is CallInProgress;
    final muted = inProgress ? (state as CallInProgress).muted : false;
    final speakerOn = inProgress ? (state as CallInProgress).speakerOn : false;

    final localRenderer = controller.localRenderer;
    final remoteRenderer = controller.remoteRenderer;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onMinimize();
      },
      child: Material(
        color: Colors.black87,
        child: SafeArea(
          child: Stack(
            children: [
              if (isVideo && remoteRenderer != null)
                Positioned.fill(
                  child: RTCVideoView(
                    remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              if (isVideo && localRenderer != null)
                Positioned(
                  top: 24,
                  right: 16,
                  child: SizedBox(
                    width: 100,
                    height: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: RTCVideoView(
                        localRenderer,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Column(
                  children: [
                    if (!isVideo || remoteRenderer == null) ...[
                      const Spacer(),
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.white24,
                        backgroundImage: peerImage != null
                            ? NetworkImage(peerImage)
                            : null,
                        child: peerImage == null
                            ? Text(
                                peerName.isNotEmpty
                                    ? peerName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 20),
                    ] else
                      const Spacer(),
                    Text(
                      peerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (state is CallInProgress)
                      DurationTicker(
                        connectedAt: (state as CallInProgress).connectedAt,
                      )
                    else
                      Text(
                        statusText ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _RoundButton(
                          icon: muted ? Icons.mic_off : Icons.mic,
                          active: muted,
                          onTap: controller.toggleMute,
                        ),
                        _RoundButton(
                          icon: Icons.call_end,
                          color: Colors.red,
                          onTap: controller.hangUp,
                        ),
                        if (isVideo)
                          _RoundButton(
                            icon: Icons.cameraswitch,
                            onTap: controller.switchCamera,
                          )
                        else
                          _RoundButton(
                            icon: speakerOn ? Icons.volume_up : Icons.hearing,
                            active: speakerOn,
                            onTap: controller.toggleSpeaker,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.color,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? (active ? Colors.white : Colors.white24),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(
            icon,
            color: color != null
                ? Colors.white
                : (active ? Colors.black87 : Colors.white),
            size: 24,
          ),
        ),
      ),
    );
  }
}
