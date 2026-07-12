import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../api/api_client.dart';

/// Thin wrapper around a single Socket.IO connection shared by the whole
/// app. Connects once per signed-in session (see [connect]) and joins a
/// per-user room so the backend's `io.to('user_<id>')` chat pushes reach
/// this device — see backend/src/lib/socket.ts's `join_user_room` handler.
class SocketService {
  socket_io.Socket? _socket;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _deletedController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();

  /// Raw stream of `new_message` payloads for every conversation this user
  /// is part of; screens filter by sender/receiver id themselves.
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// Raw stream of `message_deleted` payloads (the message, now wiped).
  Stream<Map<String, dynamic>> get deletedMessages => _deletedController.stream;

  /// Raw stream of individual messages whose delivered/read tick just
  /// changed (server sends `messages_updated` as an array; this flattens
  /// it to one event per message so screens can `_replace()` each).
  Stream<Map<String, dynamic>> get messageStatusUpdates => _statusController.stream;

  void connect(String userId) {
    if (_socket != null) return;

    _socket = socket_io.io(
      apiBaseUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setExtraHeaders(kIsWeb ? {} : {'Origin': 'askmusawo://mobile'})
          .build(),
    );

    _socket!.onConnect((_) => _socket!.emit('join_user_room', userId));
    _socket!.on('new_message', (data) {
      if (data is Map) {
        _messageController.add(Map<String, dynamic>.from(data));
      }
    });
    _socket!.on('message_deleted', (data) {
      if (data is Map) {
        _deletedController.add(Map<String, dynamic>.from(data));
      }
    });
    _socket!.on('messages_updated', (data) {
      if (data is List) {
        for (final item in data) {
          if (item is Map) _statusController.add(Map<String, dynamic>.from(item));
        }
      }
    });
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
