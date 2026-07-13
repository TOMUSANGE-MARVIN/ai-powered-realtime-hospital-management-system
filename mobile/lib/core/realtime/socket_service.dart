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

  final _incomingCallController = StreamController<Map<String, dynamic>>.broadcast();
  final _callAnsweredController = StreamController<Map<String, dynamic>>.broadcast();
  final _callDeclinedController = StreamController<Map<String, dynamic>>.broadcast();
  final _callCancelledController = StreamController<Map<String, dynamic>>.broadcast();
  final _callEndedController = StreamController<Map<String, dynamic>>.broadcast();
  final _callBusyController = StreamController<Map<String, dynamic>>.broadcast();
  final _iceCandidateController = StreamController<Map<String, dynamic>>.broadcast();
  final _callStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController = StreamController<Map<String, dynamic>>.broadcast();

  /// Raw stream of `new_message` payloads for every conversation this user
  /// is part of; screens filter by sender/receiver id themselves.
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// Raw stream of `message_deleted` payloads (the message, now wiped).
  Stream<Map<String, dynamic>> get deletedMessages => _deletedController.stream;

  /// Raw stream of individual messages whose delivered/read tick just
  /// changed (server sends `messages_updated` as an array; this flattens
  /// it to one event per message so screens can `_replace()` each).
  Stream<Map<String, dynamic>> get messageStatusUpdates => _statusController.stream;

  /// Raw stream of `call:incoming` payloads (an offer from another user).
  Stream<Map<String, dynamic>> get incomingCalls => _incomingCallController.stream;

  /// Raw stream of `call:answered` payloads (the callee's answer SDP).
  Stream<Map<String, dynamic>> get callAnswered => _callAnsweredController.stream;

  /// Raw stream of `call:declined` payloads.
  Stream<Map<String, dynamic>> get callDeclined => _callDeclinedController.stream;

  /// Raw stream of `call:cancelled` payloads (caller gave up before answer).
  Stream<Map<String, dynamic>> get callCancelled => _callCancelledController.stream;

  /// Raw stream of `call:ended` payloads (hangup or peer-disconnected).
  Stream<Map<String, dynamic>> get callEnded => _callEndedController.stream;

  /// Raw stream of `call:busy` payloads (callee already on another call).
  Stream<Map<String, dynamic>> get callBusy => _callBusyController.stream;

  /// Raw stream of `call:ice-candidate` payloads from the other party.
  Stream<Map<String, dynamic>> get iceCandidates => _iceCandidateController.stream;

  /// Raw stream of `call:status` payloads — `{callId, calleeOnline}`, sent
  /// to the caller right after an invite is relayed.
  Stream<Map<String, dynamic>> get callStatus => _callStatusController.stream;

  /// Raw stream of `presence_changed` payloads — `{userId, online}`.
  Stream<Map<String, dynamic>> get presenceChanged => _presenceController.stream;

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

    _socket!.on('call:incoming', (data) {
      if (data is Map) _incomingCallController.add(Map<String, dynamic>.from(data));
    });
    _socket!.on('call:answered', (data) {
      if (data is Map) _callAnsweredController.add(Map<String, dynamic>.from(data));
    });
    _socket!.on('call:declined', (data) {
      if (data is Map) _callDeclinedController.add(Map<String, dynamic>.from(data));
    });
    _socket!.on('call:cancelled', (data) {
      if (data is Map) _callCancelledController.add(Map<String, dynamic>.from(data));
    });
    _socket!.on('call:ended', (data) {
      if (data is Map) _callEndedController.add(Map<String, dynamic>.from(data));
    });
    _socket!.on('call:busy', (data) {
      if (data is Map) _callBusyController.add(Map<String, dynamic>.from(data));
    });
    _socket!.on('call:ice-candidate', (data) {
      if (data is Map) _iceCandidateController.add(Map<String, dynamic>.from(data));
    });
    _socket!.on('call:status', (data) {
      if (data is Map) _callStatusController.add(Map<String, dynamic>.from(data));
    });
    _socket!.on('presence_changed', (data) {
      if (data is Map) _presenceController.add(Map<String, dynamic>.from(data));
    });
  }

  void emitCallInvite(Map<String, dynamic> data) => _socket?.emit('call:invite', data);
  void emitCallAnswer(Map<String, dynamic> data) => _socket?.emit('call:answer', data);
  void emitCallDecline(Map<String, dynamic> data) => _socket?.emit('call:decline', data);
  void emitCallCancel(Map<String, dynamic> data) => _socket?.emit('call:cancel', data);
  void emitCallHangup(Map<String, dynamic> data) => _socket?.emit('call:hangup', data);
  void emitIceCandidate(Map<String, dynamic> data) =>
      _socket?.emit('call:ice-candidate', data);

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
