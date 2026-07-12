import 'doctor.dart';

class AiSpecialtyMatch {
  AiSpecialtyMatch({required this.specialty, required this.reason});

  final String specialty;
  final String reason;

  factory AiSpecialtyMatch.fromJson(Map<String, dynamic> json) {
    return AiSpecialtyMatch(
      specialty: json['specialty'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
  }
}

class AiSearchResult {
  AiSearchResult({required this.matches, required this.doctors});

  final List<AiSpecialtyMatch> matches;
  final List<Doctor> doctors;

  factory AiSearchResult.fromJson(Map<String, dynamic> json) {
    return AiSearchResult(
      matches: ((json['matches'] as List?) ?? [])
          .map((e) => AiSpecialtyMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      doctors: ((json['doctors'] as List?) ?? [])
          .map((e) => Doctor.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
