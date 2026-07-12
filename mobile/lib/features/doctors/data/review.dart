class Review {
  Review({
    required this.id,
    required this.patientName,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.doctorReply,
    this.doctorRepliedAt,
  });

  final String id;
  final String patientName;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? doctorReply;
  final DateTime? doctorRepliedAt;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: (json['id'] ?? json['_id']).toString(),
      patientName: json['patientName'] as String? ?? 'Patient',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      doctorReply: json['doctorReply'] as String?,
      doctorRepliedAt: json['doctorRepliedAt'] != null
          ? DateTime.tryParse(json['doctorRepliedAt'] as String)
          : null,
    );
  }
}

/// A doctor's reviews together with the aggregate shown in the header.
class DoctorReviews {
  DoctorReviews({
    required this.reviews,
    this.averageRating,
    required this.totalReviews,
  });

  final List<Review> reviews;
  final double? averageRating;
  final int totalReviews;

  factory DoctorReviews.fromJson(Map<String, dynamic> json) {
    return DoctorReviews(
      reviews: ((json['res'] as List?) ?? [])
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
    );
  }
}
