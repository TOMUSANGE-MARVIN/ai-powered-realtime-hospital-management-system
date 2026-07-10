class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.image,
    this.specialization,
    this.department,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String? image;
  final String? specialization;
  final String? department;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] ?? json['_id']).toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'patient',
      image: json['image'] as String?,
      specialization: json['specialization'] as String?,
      department: json['department'] as String?,
    );
  }
}
