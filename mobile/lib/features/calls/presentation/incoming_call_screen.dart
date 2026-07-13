import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/call_controller.dart';
import '../state/call_state.dart';

class IncomingCallScreen extends ConsumerWidget {
  const IncomingCallScreen({super.key, required this.call});

  final CallIncomingRinging call;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(callControllerProvider.notifier);

    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 56,
                backgroundColor: Colors.white24,
                backgroundImage: call.peerImage != null
                    ? NetworkImage(call.peerImage!)
                    : null,
                child: call.peerImage == null
                    ? Text(
                        call.peerName.isNotEmpty
                            ? call.peerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                call.peerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                call.isVideo ? 'Incoming video call…' : 'Incoming voice call…',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallActionButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    label: 'Decline',
                    onTap: controller.declineIncomingCall,
                  ),
                  _CallActionButton(
                    icon: call.isVideo ? Icons.videocam : Icons.call,
                    color: Colors.green,
                    label: 'Accept',
                    onTap: controller.acceptIncomingCall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}
