import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../../legal/data/legal_repository.dart';
import '../data/app_user.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

/// Holds the current session's user, or null when signed out.
///
/// Built once at startup (checks for an existing session cookie) and then
/// updated directly by sign in / sign up / sign out, so the router can react
/// to auth changes without re-hitting the network.
class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() {
    return ref.read(authRepositoryProvider).getSession();
  }

  /// Saved offline data belongs to one account — drop it whenever the
  /// signed-in user changes so nobody sees someone else's records.
  Future<void> _clearOfflineData() => ref.read(offlineCacheProvider).clear();

  Future<void> signIn({required String email, required String password}) async {
    await _clearOfflineData();
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password),
    );
  }

  /// Finishes a sign-in that stopped at the 2FA challenge. Throws on a wrong
  /// code and leaves the user signed out so they can try again.
  Future<void> verifySecondFactor(
    String code, {
    bool isBackupCode = false,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .verifySecondFactor(code, isBackupCode: isBackupCode);
    state = AsyncData(user);
  }

  /// Re-reads the session user, e.g. after turning 2FA on or off.
  Future<void> refreshUser() async {
    final user = await ref.read(authRepositoryProvider).getSession();
    if (user != null) state = AsyncData(user);
  }

  /// [acceptedLegalVersion] is the Terms + Privacy version the person
  /// ticked on the Register screen; it's recorded straight after the
  /// account is created, before the app moves on, so a new user is never
  /// asked to accept twice.
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String acceptedLegalVersion,
  }) async {
    await _clearOfflineData();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signUp(
        name: name,
        email: email,
        password: password,
      );
      try {
        await ref.read(legalRepositoryProvider).accept(acceptedLegalVersion);
        return await repo.getSession() ?? user;
      } catch (_) {
        // The account exists either way; the app will ask for acceptance
        // on the next screen instead.
        return user;
      }
    });
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    await _clearOfflineData();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);
