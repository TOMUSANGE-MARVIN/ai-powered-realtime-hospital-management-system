class Conversation {
  Conversation({
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImage,
    this.otherUserRole,
    required this.lastMessageText,
    this.lastMessageAttachmentType,
    required this.lastMessageAt,
    required this.lastMessageFromMe,
    required this.unreadCount,
  });

  final String otherUserId;
  final String otherUserName;
  final String? otherUserImage;
  final String? otherUserRole;
  final String lastMessageText;
  final String? lastMessageAttachmentType;
  final DateTime lastMessageAt;
  final bool lastMessageFromMe;
  final int unreadCount;

  /// A friendly one-line preview — falls back to an attachment label
  /// (matching WhatsApp-style previews) when there's no text.
  String get previewText {
    if (lastMessageText.isNotEmpty) return lastMessageText;
    switch (lastMessageAttachmentType) {
      case 'image':
        return '📷 Photo';
      case 'audio':
        return '🎤 Voice message';
      case 'file':
        return '📎 Document';
      default:
        return '';
    }
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      otherUserId: json['otherUserId'] as String,
      otherUserName: json['otherUserName'] as String? ?? 'Unknown',
      otherUserImage: json['otherUserImage'] as String?,
      otherUserRole: json['otherUserRole'] as String?,
      lastMessageText: json['lastMessageText'] as String? ?? '',
      lastMessageAttachmentType: json['lastMessageAttachmentType'] as String?,
      lastMessageAt:
          DateTime.tryParse(json['lastMessageAt'] as String? ?? '') ?? DateTime.now(),
      lastMessageFromMe: json['lastMessageFromMe'] as bool? ?? false,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}
