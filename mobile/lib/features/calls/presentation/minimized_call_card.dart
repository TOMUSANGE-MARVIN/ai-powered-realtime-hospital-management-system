import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/call_controller.dart';
import '../state/call_state.dart';
import 'duration_ticker.dart';

/// A small persistent pill shown when an in-flight/in-progress call has
/// been minimized (back button while [InCallScreen] was full-screen) —
/// tapping it restores the full-screen call UI. The call itself (audio,
/// signaling) is unaffected by minimizing; this is a pure display concern.
/// Its own hangup button ends the call directly, without restoring first.
class MinimizedCallCard extends ConsumerWidget {
  const MinimizedCallCard({
    super.key,
    required this.state,
    required this.onTap,
  });

  final CallState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (peerName, isVideo, statusText, connectedAt) = switch (state) {
      CallOutgoingRinging(
        :final peerName,
        :final isVideo,
        :final calleeOnline,
      ) =>
        (
          peerName,
          isVideo,
          calleeOnline == true ? 'Ringing…' : 'Calling…',
          null,
        ),
      CallConnecting(:final peerName, :final isVideo) => (
        peerName,
        isVideo,
        'Connecting…',
        null,
      ),
      CallInProgress(:final peerName, :final isVideo, :final connectedAt) => (
        peerName,
        isVideo,
        null,
        connectedAt,
      ),
      _ => ('', false, '', null),
    };

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.black87,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVideo ? Icons.videocam : Icons.call,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      peerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (connectedAt != null)
                      DurationTicker(
                        connectedAt: connectedAt,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      )
                    else
                      Text(
                        statusText ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Material(
                      color: Colors.red,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () =>
                            ref.read(callControllerProvider.notifier).hangUp(),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
