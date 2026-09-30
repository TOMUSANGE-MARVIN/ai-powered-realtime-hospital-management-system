import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';

/// One entry in the user's notification inbox (`/api/notifications`).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.link,
  });

  final String id;
  final String title;
  final String message;

  /// appointment | prescription | payment | review | payout | system | …
  final String type;
  final bool isRead;
  final DateTime createdAt;

  /// In-app route to open when tapped, e.g. "/home/appointments".
  final String? link;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    message: message,
    type: type,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    link: link,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'system',
      isRead: json['isRead'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      link: json['link'] as String?,
    );
  }
}

class NotificationsRepository {
  NotificationsRepository(this._dio);

  final Dio _dio;

  Future<({List<AppNotification> items, int unread})> list() async {
    try {
      final response = await _dio.get('/api/notifications');
      ApiException.checkStatus(response);
      final data = response.data as Map<String, dynamic>;
      return (
        items: [
          for (final n in data['notifications'] as List? ?? const [])
            AppNotification.fromJson(n as Map<String, dynamic>),
        ],
        unread: (data['unreadCount'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  Future<void> markRead(String id) async {
    final response = await _dio.post('/api/notifications/$id/read');
    ApiException.checkStatus(response);
  }

  Future<void> markAllRead() async {
    final response = await _dio.post('/api/notifications/read-all');
    ApiException.checkStatus(response);
  }
}
