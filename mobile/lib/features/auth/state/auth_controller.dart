import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
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

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _clearOfflineData();
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signUp(name: name, email: email, password: password),
    );
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
