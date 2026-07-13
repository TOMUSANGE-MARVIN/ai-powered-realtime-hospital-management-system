import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/call_controller.dart';
import '../state/call_state.dart';
import 'in_call_screen.dart';
import 'incoming_call_screen.dart';
import 'minimized_call_card.dart';

/// Wraps the whole app so an incoming/ongoing call shows full-screen over
/// whatever route is currently active — a route push would fight
/// go_router's auth-driven `redirect`, so this renders in a [Stack] instead.
///
/// Holds its own `_minimized` flag: minimizing is a pure display concern,
/// not part of the call's actual state machine (the call itself keeps
/// running either way), so it doesn't belong on [CallState].
class CallOverlay extends ConsumerStatefulWidget {
  const CallOverlay({super.key, required this.child});

  final Widget? child;

  @override
  ConsumerState<CallOverlay> createState() => _CallOverlayState();
}

class _CallOverlayState extends ConsumerState<CallOverlay> {
  bool _minimized = false;

  @override
  Widget build(BuildContext context) {
    // A fresh incoming call always takes over full-screen (even over a
    // stale minimized flag left from a previous call), and the flag resets
    // once the call is fully over so the next call starts full-screen too.
    ref.listen<CallState>(callControllerProvider, (previous, next) {
      if (next is CallIdle || next is CallIncomingRinging) {
        setState(() => _minimized = false);
      }
    });

    final callState = ref.watch(callControllerProvider);

    Widget? overlay;
    if (callState is CallIncomingRinging) {
      overlay = IncomingCallScreen(call: callState);
    } else if (callState is CallOutgoingRinging ||
        callState is CallConnecting ||
        callState is CallInProgress) {
      overlay = _minimized
          ? MinimizedCallCard(
              state: callState,
              onTap: () => setState(() => _minimized = false),
            )
          : InCallScreen(
              state: callState,
              onMinimize: () => setState(() => _minimized = true),
            );
    }

    return Stack(
      children: [
        ?widget.child,
        ?overlay,
      ],
    );
  }
}
