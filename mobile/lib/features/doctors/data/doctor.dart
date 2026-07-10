class Doctor {
  Doctor({
    required this.id,
    required this.name,
    this.image,
    this.specialization,
    this.department,
  });

  final String id;
  final String name;
  final String? image;
  final String? specialization;
  final String? department;

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: (json['_id'] ?? json['id']).toString(),
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      specialization: json['specialization'] as String?,
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
