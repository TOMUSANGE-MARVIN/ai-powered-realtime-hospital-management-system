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
    this.phoneNumber,
    this.dateOfBirth,
    this.address,
    this.insuranceProvider,
    this.insuranceMemberNo,
    this.createdAt,
    this.qualifications,
    this.yearsOfExperience,
    this.treatments,
    this.availabilityDays,
    this.availabilityHours,
    this.availableToday = false,
    this.twoFactorEnabled = false,
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
  final bool twoFactorEnabled;
  final String? phoneNumber;
  final String? dateOfBirth;
  final String? address;
  final String? insuranceProvider;
  final String? insuranceMemberNo;
  final DateTime? createdAt;
  final String? qualifications;
  final int? yearsOfExperience;
  final String? treatments;
  final String? availabilityDays;
  final String? availabilityHours;
  final bool availableToday;

  bool get hasInsurance => insuranceProvider?.isNotEmpty == true;

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
      twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
      phoneNumber: json['phoneNumber'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      address: json['address'] as String?,
      insuranceProvider: json['insuranceProvider'] as String?,
      insuranceMemberNo: json['insuranceMemberNo'] as String?,
      qualifications: json['qualifications'] as String?,
      yearsOfExperience: (json['yearsOfExperience'] as num?)?.toInt(),
      treatments: json['treatments'] as String?,
      availabilityDays: json['availabilityDays'] as String?,
      availabilityHours: json['availabilityHours'] as String?,
      availableToday: json['availableToday'] as bool? ?? false,
      createdAt: DateTime.tryParse(
        json['createdAt'] as String? ?? '',
      )?.toLocal(),
    );
  }
}
