import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/chat_args.dart';
import '../data/conversation.dart';
import '../state/chat_providers.dart';

final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((ref) {
  return ref.watch(chatRepositoryProvider).listConversations();
});

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            tooltip: 'Calls',
            onPressed: () => context.push('/calls'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search chats',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) {
                final filtered = _query.isEmpty
                    ? conversations
                    : conversations
                        .where((c) => c.otherUserName.toLowerCase().contains(_query))
                        .toList();
                if (conversations.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No conversations yet.\nTap the chat button to start one.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (filtered.isEmpty) {
                  return const Center(child: Text('No chats match your search'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(conversationsProvider.future),
                  child: ListView(
                    children: [
                      if (_query.isEmpty) _QuickAccessRow(conversations: conversations),
                      ...filtered.map(
                        (c) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _ConversationTile(conversation: c),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/new-chat'),
        child: const Icon(Icons.chat),
      ),
    );
  }
}

/// Circular-avatar quick-access row for the most recently active
/// conversations, sitting above the full list — tap an avatar to jump
/// straight into that chat.
class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow({required this.conversations});

  final List<Conversation> conversations;

  @override
  Widget build(BuildContext context) {
    final recent = conversations.take(8).toList();
    if (recent.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: recent.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final c = recent[index];
          return GestureDetector(
            onTap: () => context.push(
              '/chat/${c.otherUserId}',
              extra: ChatArgs(name: c.otherUserName, image: c.otherUserImage),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundImage: c.otherUserImage != null ? NetworkImage(c.otherUserImage!) : null,
                      child: c.otherUserImage == null ? const Icon(Icons.person) : null,
                    ),
                    if (c.unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 56,
                  child: Text(
                    c.otherUserName.split(' ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final isToday = now.year == dateTime.year && now.month == dateTime.month && now.day == dateTime.day;
    if (isToday) return DateFormat('HH:mm').format(dateTime);
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        yesterday.year == dateTime.year && yesterday.month == dateTime.month && yesterday.day == dateTime.day;
    if (isYesterday) return 'Yesterday';
    return DateFormat('MMM d').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: () => context.push(
          '/chat/${conversation.otherUserId}',
          extra: ChatArgs(name: conversation.otherUserName, image: conversation.otherUserImage),
        ),
        leading: CircleAvatar(
          radius: 26,
          backgroundImage:
              conversation.otherUserImage != null ? NetworkImage(conversation.otherUserImage!) : null,
          child: conversation.otherUserImage == null ? const Icon(Icons.person) : null,
        ),
        title: Text(
          conversation.otherUserName,
          style: TextStyle(fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600),
        ),
        subtitle: Text(
          conversation.lastMessageFromMe
              ? 'You: ${conversation.previewText}'
              : conversation.previewText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
            color: hasUnread ? Theme.of(context).colorScheme.onSurface : Colors.grey.shade600,
          ),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(conversation.lastMessageAt),
              style: TextStyle(
                fontSize: 12,
                color: hasUnread
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade600,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (hasUnread) ...[
              const SizedBox(height: 4),
              CircleAvatar(
                radius: 10,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  '${conversation.unreadCount}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
