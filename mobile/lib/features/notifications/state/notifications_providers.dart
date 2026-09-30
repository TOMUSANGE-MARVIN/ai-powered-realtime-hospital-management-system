import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../../../core/offline/offline_first.dart';
import '../../../core/realtime/socket_providers.dart';
import '../../appointments/state/appointment_providers.dart';
import '../../profile/state/profile_providers.dart';
import '../data/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(ref.watch(dioProvider));
});

/// The inbox, refreshed whenever the server pushes a new notification.
/// Most notifications are about appointments, so those lists refresh too.
final notificationsProvider =
    FutureProvider<({List<AppNotification> items, int unread})>((ref) {
      final sub = ref.watch(socketServiceProvider).notifications.listen((_) {
        ref.invalidateSelf();
        ref.invalidate(myAppointmentsProvider);
        ref.invalidate(allAssignedAppointmentsProvider);
        ref.invalidate(myPrescriptionsProvider);
      });
      ref.onDispose(sub.cancel);
      return offlineFirst(
        ref,
        () => ref.watch(notificationsRepositoryProvider).list(),
      );
    });

final unreadNotificationsProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).value?.unread ?? 0;
});
