import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../state/call_controller.dart';
import '../state/call_state.dart';
import 'in_call_screen.dart';
import 'incoming_call_screen.dart';
import 'minimized_call_card.dart';

/// Wraps the whole app so an incoming call rings over whatever route is
/// currently active (a route push would fight go_router's auth-driven
/// `redirect` and can't show up before the user has "accepted" anything, so
/// this one case renders in a [Stack] instead of being a real route).
///
/// The in-progress/outgoing call screen, by contrast, IS a real route
/// (pushed on [rootNavigatorKey] — see [_pushInCallScreen]): that's what
/// makes the system back button naturally pop just that screen instead of
/// leaking through to whatever route sits underneath a synthetic overlay.
/// Popping it is treated as "minimize" (shows [MinimizedCallCard]), not
/// hangup — matching WhatsApp's flow.
class CallOverlay extends ConsumerStatefulWidget {
  const CallOverlay({super.key, required this.child});

  final Widget? child;

  @override
  ConsumerState<CallOverlay> createState() => _CallOverlayState();
}

class _CallOverlayState extends ConsumerState<CallOverlay> with WidgetsBindingObserver {
  bool _minimized = false;
  bool _inCallRouteOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    // Swallow the system back button while an incoming call is ringing — it
    // must be Accept/Decline'd, matching real-phone UX. This hooks the raw
    // platform back-button channel directly (unlike PopScope, this doesn't
    // need a Navigator/ModalRoute ancestor), which is required here since
    // IncomingCallScreen is a synthetic overlay, not a real route.
    if (ref.read(callControllerProvider) is CallIncomingRinging) return true;
    return false;
  }

  bool _isActiveCallState(CallState state) =>
      state is CallOutgoingRinging || state is CallConnecting || state is CallInProgress;

  void _pushInCallScreen() {
    _inCallRouteOpen = true;
    rootNavigatorKey.currentState!
        .push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const InCallScreen()))
        .then((_) {
      _inCallRouteOpen = false;
      // Only re-show as minimized if the call is still actually active —
      // if it already ended (hangup/declined/etc. popped this route
      // programmatically below), there's nothing left to minimize back to.
      if (mounted && _isActiveCallState(ref.read(callControllerProvider))) {
        setState(() => _minimized = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CallState>(callControllerProvider, (previous, next) {
      if (next is CallIdle || next is CallIncomingRinging) {
        setState(() => _minimized = false);
        if (_inCallRouteOpen) {
          _inCallRouteOpen = false;
          rootNavigatorKey.currentState?.pop();
        }
      } else if (next is CallEnded) {
        if (_inCallRouteOpen) {
          _inCallRouteOpen = false;
          rootNavigatorKey.currentState?.pop();
        }
      } else if (_isActiveCallState(next) && !_inCallRouteOpen && !_minimized) {
        _pushInCallScreen();
      }
    });

    final callState = ref.watch(callControllerProvider);

    Widget? overlay;
    if (callState is CallIncomingRinging) {
      overlay = IncomingCallScreen(call: callState);
    } else if (_minimized && _isActiveCallState(callState)) {
      overlay = MinimizedCallCard(
        state: callState,
        onTap: () => setState(() {
          _minimized = false;
          _pushInCallScreen();
        }),
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
