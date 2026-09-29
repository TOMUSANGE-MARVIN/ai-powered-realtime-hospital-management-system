import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/chat_args.dart';
import '../data/conversation.dart';
import '../state/chat_providers.dart';

const _favoritesPrefKey = 'chat_favorite_ids';

const _accent = seedTeal;
const _fieldBg = Color(0xFFF1F3F8);
const _chipBg = Color(0xFFEDEFF5);
const _onlineGreen = Color(0xFF3BB273);
const _offlineGrey = Color(0xFFB6BAC6);

final conversationsProvider = FutureProvider<List<Conversation>>((ref) {
  return ref.watch(chatRepositoryProvider).listConversations();
});

enum _ChatFilter { all, unread, favorites }

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _ChatFilter _filter = _ChatFilter.all;
  Set<String> _favoriteIds = {};
  bool _favoritesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _favoriteIds = (prefs.getStringList(_favoritesPrefKey) ?? []).toSet();
      _favoritesLoaded = true;
    });
  }

  Future<void> _toggleFavorite(String otherUserId) async {
    setState(() {
      if (!_favoriteIds.add(otherUserId)) _favoriteIds.remove(otherUserId);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesPrefKey, _favoriteIds.toList());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chats',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: Color(0xFF12172B),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Color(0xFF12172B)),
            tooltip: 'Calls',
            onPressed: () => context.push('/calls'),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF12172B)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search chats',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                suffixIcon: Icon(Icons.tune, color: Colors.grey.shade600),
                filled: true,
                fillColor: _fieldBg,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(kCardRadius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  icon: Icons.chat_bubble,
                  selected: _filter == _ChatFilter.all,
                  onTap: () => setState(() => _filter = _ChatFilter.all),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: 'Unread',
                  icon: Icons.circle_outlined,
                  selected: _filter == _ChatFilter.unread,
                  onTap: () => setState(() => _filter = _ChatFilter.unread),
                  showDot: true,
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: 'Favorites',
                  icon: Icons.star,
                  selected: _filter == _ChatFilter.favorites,
                  onTap: () => setState(() => _filter = _ChatFilter.favorites),
                ),
              ],
            ),
          ),
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) {
                if (!_favoritesLoaded) {
                  return const SkeletonList();
                }
                var filtered = conversations;
                if (_query.isNotEmpty) {
                  filtered = filtered
                      .where(
                        (c) => c.otherUserName.toLowerCase().contains(_query),
                      )
                      .toList();
                }
                switch (_filter) {
                  case _ChatFilter.unread:
                    filtered = filtered
                        .where((c) => c.unreadCount > 0)
                        .toList();
                    break;
                  case _ChatFilter.favorites:
                    filtered = filtered
                        .where((c) => _favoriteIds.contains(c.otherUserId))
                        .toList();
                    break;
                  case _ChatFilter.all:
                    break;
                }
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
                  return Center(
                    child: Text(
                      _filter == _ChatFilter.favorites
                          ? 'No favorites yet.\nTap the star on a chat to add one.'
                          : 'No chats match your search',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(conversationsProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.only(top: 8),
                    children: [
                      if (_query.isEmpty && _filter == _ChatFilter.all)
                        _RecentContactsRow(conversations: conversations),
                      ...filtered.map(
                        (c) => _ConversationTile(
                          conversation: c,
                          isFavorite: _favoriteIds.contains(c.otherUserId),
                          onToggleFavorite: () =>
                              _toggleFavorite(c.otherUserId),
                        ),
                      ),
                      const SizedBox(height: 88),
                    ],
                  ),
                );
              },
              loading: () => const SkeletonList(),
              error: (error, _) => Center(child: Text(error.toString())),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accent,
        onPressed: () => context.push('/new-chat'),
        child: const Icon(Icons.add_comment_rounded, color: Colors.white),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.showDot = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kCardRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _accent.withValues(alpha: 0.12) : _chipBg,
          borderRadius: BorderRadius.circular(kCardRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? _accent : const Color(0xFF3B4254),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? _accent : const Color(0xFF3B4254),
              ),
            ),
            if (showDot) ...[
              const SizedBox(width: 6),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentContactsRow extends StatelessWidget {
  const _RecentContactsRow({required this.conversations});

  final List<Conversation> conversations;

  @override
  Widget build(BuildContext context) {
    final recent = conversations.take(6).toList();
    if (recent.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent contacts',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF12172B),
                ),
              ),
              Row(
                children: [
                  Text(
                    'See all',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recent.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              if (index == recent.length) {
                return GestureDetector(
                  onTap: () => context.push('/new-chat'),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: _accent, size: 26),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final c = recent[index];
              return GestureDetector(
                onTap: () => context.push(
                  '/chat/${c.otherUserId}',
                  extra: ChatArgs(
                    name: c.otherUserName,
                    image: c.otherUserImage,
                  ),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFE3F2F1),
                          backgroundImage: c.otherUserImage != null
                              ? NetworkImage(c.otherUserImage!)
                              : null,
                          child: c.otherUserImage == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: c.otherUserOnline
                                  ? _onlineGreen
                                  : _offlineGrey,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 64,
                      child: Text(
                        c.otherUserName.startsWith('Dr.') ||
                                c.otherUserName.startsWith('Dr ')
                            ? c.otherUserName.replaceFirst(
                                RegExp(r'^Dr\.?\s*'),
                                'Dr. ',
                              )
                            : c.otherUserName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF3B4254),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final Conversation conversation;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final isToday =
        now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;
    if (isToday) return DateFormat('HH:mm').format(dateTime);
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        yesterday.year == dateTime.year &&
        yesterday.month == dateTime.month &&
        yesterday.day == dateTime.day;
    if (isYesterday) return 'Yesterday';
    return DateFormat('MMM d').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;
    return InkWell(
      onTap: () => context.push(
        '/chat/${conversation.otherUserId}',
        extra: ChatArgs(
          name: conversation.otherUserName,
          image: conversation.otherUserImage,
        ),
      ),
      onLongPress: onToggleFavorite,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasUnread ? _accent.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(kCardRadius),
          border: hasUnread ? null : Border.all(color: const Color(0xFFF0F1F5)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFE3F2F1),
                  backgroundImage: conversation.otherUserImage != null
                      ? NetworkImage(conversation.otherUserImage!)
                      : null,
                  child: conversation.otherUserImage == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: conversation.otherUserOnline
                          ? _onlineGreen
                          : _offlineGrey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.otherUserName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                      color: Color(0xFF12172B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conversation.lastMessageFromMe
                        ? 'You: ${conversation.previewText}'
                        : conversation.previewText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: hasUnread
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: hasUnread
                          ? const Color(0xFF2F3648)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatTime(conversation.lastMessageAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: hasUnread ? _accent : Colors.grey.shade600,
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 6),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(kCardRadius),
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isFavorite)
                  const Icon(Icons.star, size: 16, color: Color(0xFFF5A623)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
