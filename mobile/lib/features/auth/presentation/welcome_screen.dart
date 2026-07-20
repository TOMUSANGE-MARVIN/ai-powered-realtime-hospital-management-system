import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../state/onboarding_controller.dart';

/// Illustrations shown in the welcome carousel, in swipe order. Add more
/// entries here as additional SVGs are supplied — the dots and swipe
/// behavior already scale to however many are listed.
const _welcomeIllustrations = <String>[
  'assets/images/illustrations/welcome-screen-illustration.svg',
  'assets/images/illustrations/welcome-screen-illustration-2.svg',
  'assets/images/illustrations/welcome-screen-illustration-3.svg',
];

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  late final _pageController = PageController()..addListener(_onScroll);
  int _page = 0;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _startAutoAdvance();
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_pageController.hasClients) return;
      final nextPage = (_page + 1) % _welcomeIllustrations.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onScroll() {
    // Drives the illustration scale/fade and dot morph continuously as the
    // user drags, rather than snapping only once a page fully settles.
    setState(() {});
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _continueTo(String location) {
    ref.read(onboardingControllerProvider.notifier).markSeen();
    context.go(location);
  }

  double get _currentPagePosition {
    if (!_pageController.hasClients || !_pageController.position.haveDimensions) {
      return _page.toDouble();
    }
    return _pageController.page ?? _page.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final pagePosition = _currentPagePosition;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _welcomeIllustrations.length,
                onPageChanged: (index) {
                  setState(() => _page = index);
                  // A manual swipe counts as a fresh 2s window before the
                  // next auto-advance, so it doesn't fight the user's own
                  // gesture by jumping again right away.
                  _startAutoAdvance();
                },
                itemBuilder: (context, index) {
                  // Distance from this page to the current scroll position:
                  // 0 when centered, ±1 when a full page away. Powers a
                  // subtle native-feeling scale + fade as pages slide past.
                  final delta = (pagePosition - index).clamp(-1.0, 1.0);
                  final scale = 1 - (delta.abs() * 0.15);
                  final opacity = 1 - (delta.abs() * 0.4);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Center(
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: scale,
                          // A fixed width AND height box (not just width) so
                          // every illustration is fit into an identical
                          // footprint — otherwise SVGs with different aspect
                          // ratios end up visually different sizes even with
                          // the same nominal width.
                          child: SizedBox(
                            width: 360,
                            height: 360,
                            child: SvgPicture.asset(
                              _welcomeIllustrations[index],
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _DotIndicator(count: _welcomeIllustrations.length, pagePosition: pagePosition),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  children: const [
                    TextSpan(text: 'Welcome to ', style: TextStyle(color: Color(0xFF8BC34A))),
                    TextSpan(text: 'Ask Musawo', style: TextStyle(color: Color(0xFF29B6D8))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Connecting Patients\nWith Trusted Doctors',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _continueTo('/register'),
                  child: const Text('Create Account'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already Have An Account? '),
                GestureDetector(
                  onTap: () => _continueTo('/login'),
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.pagePosition});

  final int count;
  /// Continuous scroll position from the [PageController], e.g. 1.35 while
  /// dragging from page 1 to 2. Lets each dot morph its width/opacity in
  /// lockstep with the swipe instead of snapping only on page settle.
  final double pagePosition;

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        // 1 when this dot is fully active, 0 when a full page away.
        final closeness = (1 - (pagePosition - index).abs()).clamp(0.0, 1.0);
        final width = 8 + (12 * closeness);
        final color = Color.lerp(
          activeColor.withValues(alpha: 0.25),
          activeColor,
          closeness,
        );
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: width,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
