import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../../../core/realtime/socket_providers.dart';
import '../data/conversation.dart';
import '../data/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(dioProvider));
});

/// The user's conversations, refreshed whenever a message arrives or is read
/// so unread counts (list and tab badge) stay current.
final conversationsProvider = FutureProvider<List<Conversation>>((ref) {
  final socket = ref.watch(socketServiceProvider);
  final subs = [
    socket.messages.listen((_) => ref.invalidateSelf()),
    socket.messageStatusUpdates.listen((_) => ref.invalidateSelf()),
  ];
  ref.onDispose(() {
    for (final s in subs) {
      s.cancel();
    }
  });
  return ref.watch(chatRepositoryProvider).listConversations();
});

/// Total unread messages, for the Messages tab badge.
final unreadMessagesProvider = Provider<int>((ref) {
  final conversations = ref.watch(conversationsProvider).value ?? const [];
  return conversations.fold(0, (sum, c) => sum + c.unreadCount);
});
