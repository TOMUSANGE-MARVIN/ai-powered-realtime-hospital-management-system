import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'chat_message.dart';
import 'conversation.dart';

class ChatRepository {
  ChatRepository(this._dio);

  final Dio _dio;

  /// The chat inbox — one row per counterpart, most recent first.
  Future<List<Conversation>> listConversations() async {
    final response = await _dio.get('/api/messages/conversations');
    ApiException.checkStatus(response);
    final results = (response.data as Map)['res'] as List;
    return results
        .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> getConversation(String otherUserId) async {
    final response = await _dio.get('/api/messages/$otherUserId');
    ApiException.checkStatus(response);
    final results = (response.data as Map)['res'] as List;
    return results
        .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> send({
    required String receiverId,
    String text = '',
    String? attachmentUrl,
    String? attachmentType,
    String? attachmentName,
    String? replyToId,
  }) async {
    final response = await _dio.post(
      '/api/messages',
      data: {
        'receiverId': receiverId,
        'text': text,
        'attachmentUrl': ?attachmentUrl,
        'attachmentType': ?attachmentType,
        'attachmentName': ?attachmentName,
        'replyToId': ?replyToId,
      },
    );
    ApiException.checkStatus(response);
    return ChatMessage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ChatMessage> delete(String messageId) async {
    final response = await _dio.delete('/api/messages/$messageId');
    ApiException.checkStatus(response);
    return ChatMessage.fromJson(response.data as Map<String, dynamic>);
  }
}
