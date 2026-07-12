import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../chat/data/chat_args.dart';
import '../data/call_log.dart';
import '../state/call_providers.dart';

class CallsScreen extends ConsumerWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callsAsync = ref.watch(myCallsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calls')),
      body: callsAsync.when(
        data: (calls) {
          if (calls.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No call history yet.\nStart a call from any chat.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myCallsProvider.future),
            child: ListView.separated(
              itemCount: calls.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => _CallTile(call: calls[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}

class _CallTile extends StatelessWidget {
  const _CallTile({required this.call});

  final CallLogEntry call;

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final isToday = now.year == dateTime.year && now.month == dateTime.month && now.day == dateTime.day;
    if (isToday) return DateFormat('HH:mm').format(dateTime);
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        yesterday.year == dateTime.year && yesterday.month == dateTime.month && yesterday.day == dateTime.day;
    if (isYesterday) return 'Yesterday, ${DateFormat('HH:mm').format(dateTime)}';
    return DateFormat('MMM d, HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final directionColor = Theme.of(context).colorScheme.primary;
    return ListTile(
      onTap: () => context.push(
        '/chat/${call.otherUserId}',
        extra: ChatArgs(name: call.otherUserName),
      ),
      leading: CircleAvatar(child: Icon(call.isVideo ? Icons.videocam : Icons.call)),
      title: Text(call.otherUserName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Row(
        children: [
          Icon(
            call.isOutgoing ? Icons.call_made : Icons.call_received,
            size: 15,
            color: directionColor,
          ),
          const SizedBox(width: 4),
          Text(call.isOutgoing ? 'Outgoing' : 'Incoming'),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_formatTime(call.createdAt), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Icon(
            call.isVideo ? Icons.videocam_outlined : Icons.call_outlined,
            size: 18,
            color: Colors.grey.shade600,
          ),
        ],
      ),
    );
  }
}
