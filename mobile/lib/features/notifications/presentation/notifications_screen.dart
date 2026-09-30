import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/notifications_repository.dart';
import '../state/notifications_providers.dart';

IconData _iconFor(String type) => switch (type) {
  'appointment' => Icons.event_available_outlined,
  'prescription' => Icons.receipt_long_outlined,
  'payment' => Icons.payments_outlined,
  'review' => Icons.star_outline_rounded,
  'payout' => Icons.account_balance_wallet_outlined,
  _ => Icons.campaign_outlined,
};

String _when(DateTime t) {
  final now = DateTime.now();
  final diff = now.difference(t);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24 && t.day == now.day) {
    return DateFormat.jm().format(t);
  }
  if (diff.inDays < 7) return DateFormat('EEE h:mm a').format(t);
  return DateFormat('d MMM yyyy').format(t);
}

/// Everything that happened to the user's appointments, prescriptions,
/// payments and payouts, plus admin announcements.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AppNotification n,
  ) async {
    if (!n.isRead) {
      ref.read(notificationsRepositoryProvider).markRead(n.id).then((_) {
        ref.invalidate(notificationsProvider);
      }, onError: (_) {});
    }
    final link = n.link;
    if (link == null || !link.startsWith('/') || !context.mounted) return;
    // Bottom-nav tabs switch tabs; anything else opens on top.
    const tabs = {
      '/home',
      '/home/chats',
      '/home/appointments',
      '/home/profile',
      '/doctor-home',
      '/doctor-home/chats',
      '/doctor-home/appointments',
      '/doctor-home/earnings',
      '/doctor-home/profile',
    };
    tabs.contains(link) ? context.go(link) : context.push(link);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(notificationsProvider);
    final hasUnread = (inbox.value?.unread ?? 0) > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () async {
                await ref.read(notificationsRepositoryProvider).markAllRead();
                ref.invalidate(notificationsProvider);
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: inbox.when(
        loading: () => const SkeletonList(count: 6),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(notificationsProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (data) {
          if (data.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "You're all caught up",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Updates about your appointments and prescriptions '
                      'will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(notificationsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: data.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = data.items[i];
                return Material(
                  color: n.isRead
                      ? Colors.transparent
                      : seedTeal.withValues(alpha: 0.05),
                  child: InkWell(
                    onTap: () => _open(context, ref, n),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: seedTeal.withValues(alpha: 0.12),
                            child: Icon(
                              _iconFor(n.type),
                              color: seedTeal,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: TextStyle(
                                    fontWeight: n.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(n.message),
                                const SizedBox(height: 4),
                                Text(
                                  _when(n.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              margin: const EdgeInsets.only(top: 6, left: 8),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: seedTeal,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Bell with an unread count, for app bars and headers.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider);
    return IconButton(
      tooltip: unread > 0 ? '$unread unread notifications' : 'Notifications',
      onPressed: () => context.push('/notifications'),
      icon: Badge(
        isLabelVisible: unread > 0,
        backgroundColor: const Color(0xFFD32F2F),
        label: Text(unread > 9 ? '9+' : '$unread'),
        child: Icon(Icons.notifications_none_rounded, color: color),
      ),
    );
  }
}
