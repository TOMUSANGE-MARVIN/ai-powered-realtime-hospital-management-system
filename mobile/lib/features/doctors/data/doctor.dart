class Doctor {
  Doctor({
    required this.id,
    required this.name,
    this.image,
    this.specialization,
    this.department,
    this.bio,
    this.hospitalName,
    this.hospitalAddress,
    this.consultationFee,
    this.rating,
    this.reviewCount = 0,
  });

  final String id;
  final String name;
  final String? image;
  final String? specialization;
  final String? department;
  final String? bio;
  final String? hospitalName;
  final String? hospitalAddress;
  final int? consultationFee;
  final double? rating;
  final int reviewCount;

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: (json['_id'] ?? json['id']).toString(),
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      specialization: json['specialization'] as String?,
      department: json['department'] as String?,
      bio: json['bio'] as String?,
      hospitalName: json['hospitalName'] as String?,
      hospitalAddress: json['hospitalAddress'] as String?,
      consultationFee: (json['consultationFee'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class Category {
  Category({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorKey,
    this.department,
  });

  final String id;
  final String name;
  final String iconKey;
  final String colorKey;
  final String? department;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      iconKey: json['iconKey'] as String? ?? 'general',
      colorKey: json['colorKey'] as String? ?? 'lavender',
      department: json['department'] as String?,
    );
  }
}

class Specialty {
  Specialty({required this.name, required this.count});

  final String name;
  final int count;

  factory Specialty.fromJson(Map<String, dynamic> json) {
    return Specialty(
      name: json['specialization'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}
