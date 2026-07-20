import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _hasSeenWelcomePrefKey = 'has_seen_welcome';

/// Tracks whether the user has been shown the first-launch welcome carousel,
/// persisted so it only ever appears once per install.
class OnboardingController extends Notifier<bool> {
  @override
  bool build() {
    _load();
    // Assume "seen" until proven otherwise, so the router doesn't briefly
    // flash the welcome screen for returning users while prefs load.
    return true;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_hasSeenWelcomePrefKey) ?? false;
  }

  Future<void> markSeen() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenWelcomePrefKey, true);
  }
}

final onboardingControllerProvider = NotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);
