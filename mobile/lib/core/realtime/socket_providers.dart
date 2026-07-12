import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/app_user.dart';
import '../../features/auth/state/auth_controller.dart';
import 'socket_service.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(service.disconnect);
  return service;
});

/// Connects/disconnects the shared socket as the session comes and goes.
/// Read once near the app root (see main.dart) so it stays alive for the
/// whole app lifetime rather than per-screen.
final socketLifecycleProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<AppUser?>>(authControllerProvider, (previous, next) {
    final service = ref.read(socketServiceProvider);
    final user = next.value;
    if (user != null) {
      service.connect(user.id);
    } else if (!next.isLoading) {
      service.disconnect();
    }
  }, fireImmediately: true);
});
