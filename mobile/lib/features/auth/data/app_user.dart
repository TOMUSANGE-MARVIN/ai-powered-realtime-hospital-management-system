class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.image,
    this.specialization,
    this.department,
    this.gender,
    this.bloodgroup,
    this.maritalStatus,
    this.age,
    this.bio,
    this.hospitalName,
    this.hospitalAddress,
    this.consultationFee,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String? image;
  final String? specialization;
  final String? department;
  final String? gender;
  final String? bloodgroup;
  final String? maritalStatus;
  final String? age;
  final String? bio;
  final String? hospitalName;
  final String? hospitalAddress;
  final int? consultationFee;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] ?? json['_id']).toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'patient',
      image: json['image'] as String?,
      specialization: json['specialization'] as String?,
      department: json['department'] as String?,
      gender: json['gender'] as String?,
      bloodgroup: json['bloodgroup'] as String?,
      maritalStatus: json['maritalStatus'] as String?,
      age: json['age'] as String?,
      bio: json['bio'] as String?,
      hospitalName: json['hospitalName'] as String?,
      hospitalAddress: json['hospitalAddress'] as String?,
      consultationFee: json['consultationFee'] as int?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      emergencyContactRelation: json['emergencyContactRelation'] as String?,
    );
  }
}
