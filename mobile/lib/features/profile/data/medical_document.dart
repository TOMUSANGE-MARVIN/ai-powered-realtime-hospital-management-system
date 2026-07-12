class MedicalDocument {
  MedicalDocument({
    required this.id,
    required this.title,
    required this.url,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String url;
  final DateTime createdAt;

  factory MedicalDocument.fromJson(Map<String, dynamic> json) {
    return MedicalDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
