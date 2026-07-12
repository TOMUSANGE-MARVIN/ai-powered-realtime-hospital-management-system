class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.attachmentUrl,
    this.attachmentType,
    this.attachmentName,
    this.deletedAt,
    this.deliveredAt,
    this.readAt,
    this.replyToId,
    this.replyToText,
    this.replyToSenderId,
    this.replyToAttachmentType,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final String? attachmentUrl;
  final String? attachmentType;
  final String? attachmentName;
  final DateTime? deletedAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? replyToId;
  final String? replyToText;
  final String? replyToSenderId;
  final String? replyToAttachmentType;

  bool get isDeleted => deletedAt != null;
  bool get isImage => attachmentType == 'image';
  bool get isAudio => attachmentType == 'audio';
  bool get hasAttachment => attachmentUrl != null && !isDeleted;
  bool get isReply => replyToId != null;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? json['_id']).toString(),
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      attachmentUrl: json['attachmentUrl'] as String?,
      attachmentType: json['attachmentType'] as String?,
      attachmentName: json['attachmentName'] as String?,
      deletedAt:
          json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'] as String) : null,
      deliveredAt:
          json['deliveredAt'] != null ? DateTime.tryParse(json['deliveredAt'] as String) : null,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'] as String) : null,
      replyToId: json['replyToId'] as String?,
      replyToText: json['replyToText'] as String?,
      replyToSenderId: json['replyToSenderId'] as String?,
      replyToAttachmentType: json['replyToAttachmentType'] as String?,
    );
  }
}
