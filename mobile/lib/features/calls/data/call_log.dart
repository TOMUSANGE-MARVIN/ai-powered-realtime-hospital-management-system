class CallLogEntry {
  CallLogEntry({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.isOutgoing,
    required this.otherUserId,
    required this.otherUserName,
  });

  final String id;
  final String type;
  final DateTime createdAt;
  final bool isOutgoing;
  final String otherUserId;
  final String otherUserName;

  bool get isVideo => type == 'video';

  factory CallLogEntry.fromJson(Map<String, dynamic> json) {
    return CallLogEntry(
      id: (json['id'] ?? json['_id']).toString(),
      type: json['type'] as String? ?? 'voice',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      isOutgoing: json['isOutgoing'] as bool? ?? false,
      otherUserId: json['otherUserId'] as String,
      otherUserName: json['otherUserName'] as String? ?? 'Unknown',
    );
  }
}
