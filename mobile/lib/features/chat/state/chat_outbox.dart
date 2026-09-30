import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/providers.dart';
import '../../../core/offline/offline_interceptor.dart';
import '../../auth/state/auth_controller.dart';
import '../data/chat_message.dart';
import 'chat_providers.dart';

const _prefsKey = 'chat_outbox_v1';

/// A text message written but not yet accepted by the server.
class PendingMessage {
  const PendingMessage({
    required this.localId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.replyToId,
    this.replyToText,
    this.replyToSenderId,
  });

  final String localId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final String? replyToId;
  final String? replyToText;
  final String? replyToSenderId;

  /// How it's drawn in the thread until it's sent — a normal bubble with a
  /// clock instead of ticks.
  ChatMessage toChatMessage() => ChatMessage(
    id: localId,
    senderId: senderId,
    receiverId: receiverId,
    text: text,
    createdAt: createdAt,
    replyToId: replyToId,
    replyToText: replyToText,
    replyToSenderId: replyToSenderId,
    pending: true,
  );

  Map<String, Object?> toJson() => {
    'localId': localId,
    'senderId': senderId,
    'receiverId': receiverId,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'replyToId': replyToId,
    'replyToText': replyToText,
    'replyToSenderId': replyToSenderId,
  };

  static PendingMessage fromJson(Map<String, dynamic> json) => PendingMessage(
    localId: json['localId'] as String,
    senderId: json['senderId'] as String,
    receiverId: json['receiverId'] as String,
    text: json['text'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    replyToId: json['replyToId'] as String?,
    replyToText: json['replyToText'] as String?,
    replyToSenderId: json['replyToSenderId'] as String?,
  );
}

/// Outcome of trying to send one queued message.
sealed class OutboxEvent {
  const OutboxEvent(this.localId);
  final String localId;
}

class OutboxSent extends OutboxEvent {
  const OutboxSent(super.localId, this.message);
  final ChatMessage message;
}

class OutboxRejected extends OutboxEvent {
  const OutboxRejected(super.localId, this.text);
  final String text;
}

/// Every chat text message goes through here: it shows in the thread
/// straight away (with a clock), is saved to disk, and is sent in order —
/// immediately when online, or as soon as the connection comes back
/// (even after an app restart). Attachments and voice notes still need a
/// connection, since the file has to be uploaded first.
class ChatOutbox extends Notifier<List<PendingMessage>> {
  final _events = StreamController<OutboxEvent>.broadcast();
  bool _flushing = false;

  /// Sent / rejected notifications, so an open thread can swap the pending
  /// bubble for the real message.
  Stream<OutboxEvent> get events => _events.stream;

  @override
  List<PendingMessage> build() {
    final reconnectSub = ref
        .watch(networkStatusProvider)
        .onReconnect
        .listen((_) => flush());
    ref.onDispose(reconnectSub.cancel);
    // Queued messages wait for the session to be known before sending.
    ref.listen(authControllerProvider, (_, next) {
      if (next.value != null) flush();
    });
    _load();
    return const [];
  }

  String? get _myId => ref.read(authControllerProvider).value?.id;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final saved = [
        for (final m in jsonDecode(raw) as List)
          PendingMessage.fromJson(m as Map<String, dynamic>),
      ];
      final ids = {for (final m in state) m.localId};
      state = [...saved.where((m) => !ids.contains(m.localId)), ...state];
      unawaited(flush());
    } catch (_) {
      // Corrupt entry — start with an empty outbox.
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode([for (final m in state) m.toJson()]),
      );
    } catch (_) {}
  }

  /// Queues [text] for [receiverId] and starts sending it.
  void send({
    required String receiverId,
    required String text,
    ChatMessage? replyTo,
  }) {
    final myId = _myId;
    if (myId == null) return;
    final now = DateTime.now();
    state = [
      ...state,
      PendingMessage(
        localId: 'local-${now.microsecondsSinceEpoch}',
        senderId: myId,
        receiverId: receiverId,
        text: text,
        createdAt: now,
        replyToId: replyTo?.id,
        replyToText: replyTo?.text,
        replyToSenderId: replyTo?.senderId,
      ),
    ];
    _save();
    unawaited(flush());
  }

  /// Sends queued messages oldest first, stopping at the first one that
  /// can't reach the server (the rest wait for the next reconnect).
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      while (true) {
        final myId = _myId;
        if (myId == null) return;
        // Messages written under another account never go out as this one.
        if (state.any((m) => m.senderId != myId)) {
          state = state.where((m) => m.senderId == myId).toList();
          await _save();
        }
        if (state.isEmpty) return;
        final next = state.first;
        try {
          final sent = await ref
              .read(chatRepositoryProvider)
              .send(
                receiverId: next.receiverId,
                text: next.text,
                replyToId: next.replyToId,
              );
          _remove(next.localId);
          _events.add(OutboxSent(next.localId, sent));
          ref.invalidate(conversationsProvider);
        } catch (error) {
          // No connection, the server is briefly down (5xx) or rate limiting (429) — keep it
          // queued for the next reconnect / send.
          if (isUnreachableError(error) || _isServerError(error)) return;
          // The server refused it (e.g. the conversation is no longer
          // allowed) — retrying won't help, so give the text back.
          _remove(next.localId);
          _events.add(OutboxRejected(next.localId, next.text));
        }
      }
    } finally {
      _flushing = false;
    }
  }

  /// Worth retrying later: the server is briefly down (5xx) or asked us to
  /// slow down (429).
  static bool _isServerError(Object error) {
    final status = switch (error) {
      DioException(:final response) => response?.statusCode ?? 0,
      ApiException(:final statusCode) => statusCode ?? 0,
      _ => 0,
    };
    return status >= 500 || status == 429;
  }

  void _remove(String localId) {
    state = state.where((m) => m.localId != localId).toList();
    _save();
  }
}

final chatOutboxProvider = NotifierProvider<ChatOutbox, List<PendingMessage>>(
  ChatOutbox.new,
);
