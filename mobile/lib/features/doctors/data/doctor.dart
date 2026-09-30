/// Whole days a doctor isn't taking bookings (inclusive).
class TimeOffRange {
  const TimeOffRange({
    required this.id,
    required this.start,
    required this.end,
    this.reason,
  });

  final String id;

  /// Calendar days (UTC midnight from the server; compare by date only).
  final DateTime start;
  final DateTime end;
  final String? reason;

  bool covers(DateTime day) {
    final d = DateTime.utc(day.year, day.month, day.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  factory TimeOffRange.fromJson(Map<String, dynamic> json) {
    DateTime day(String v) {
      final d = DateTime.parse(v).toUtc();
      return DateTime.utc(d.year, d.month, d.day);
    }

    return TimeOffRange(
      id: json['id'] as String,
      start: day(json['startDate'] as String),
      end: day(json['endDate'] as String),
      reason: json['reason'] as String?,
    );
  }
}

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
    this.yearsOfExperience,
    this.qualifications,
    this.boardCertified = false,
    this.treatments = const [],
    this.availabilityDays,
    this.availabilityHours,
    this.availableToday = false,
    this.timeOff = const [],
    this.patientCount,
    this.gender,
  });

  /// Profile gender (Male / Female / Other), picks the default portrait.
  final String? gender;

  /// Upcoming time off (only included on the doctor detail endpoint).
  final List<TimeOffRange> timeOff;

  /// Distinct patients seen (doctor detail endpoint only).
  final int? patientCount;

  bool isAwayOn(DateTime day) => timeOff.any((t) => t.covers(day));

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
  final int? yearsOfExperience;
  final String? qualifications;
  final bool boardCertified;
  final List<String> treatments;
  final String? availabilityDays;
  final String? availabilityHours;
  final bool availableToday;

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
      yearsOfExperience: (json['yearsOfExperience'] as num?)?.toInt(),
      qualifications: json['qualifications'] as String?,
      boardCertified: json['boardCertified'] as bool? ?? false,
      treatments:
          (json['treatments'] as String?)
              ?.split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList() ??
          const [],
      availabilityDays: json['availabilityDays'] as String?,
      availabilityHours: json['availabilityHours'] as String?,
      availableToday: json['availableToday'] as bool? ?? false,
      patientCount: (json['patientCount'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      timeOff: [
        for (final t in json['timeOff'] as List? ?? const [])
          TimeOffRange.fromJson(t as Map<String, dynamic>),
      ],
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
