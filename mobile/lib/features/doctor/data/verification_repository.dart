import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/providers.dart';

/// A doctor's licence submission and where it stands.
class DoctorVerification {
  const DoctorVerification({
    this.status,
    this.licenseNumber,
    this.licenseDocumentUrl,
    this.hospitalName,
    this.hospitalAddress,
    this.specialization,
    this.yearsOfExperience,
    this.submittedAt,
    this.note,
  });

  /// `pending`, `approved`, `rejected`, or null before the first submission.
  final String? status;
  final String? licenseNumber;
  final String? licenseDocumentUrl;
  final String? hospitalName;
  final String? hospitalAddress;
  final String? specialization;
  final int? yearsOfExperience;
  final DateTime? submittedAt;

  /// The admin's reason when rejected.
  final String? note;

  bool get isSubmitted => submittedAt != null;

  factory DoctorVerification.fromJson(Map<String, dynamic> json) =>
      DoctorVerification(
        status: json['doctorVerificationStatus'] as String?,
        licenseNumber: json['licenseNumber'] as String?,
        licenseDocumentUrl: json['licenseDocumentUrl'] as String?,
        hospitalName: json['hospitalName'] as String?,
        hospitalAddress: json['hospitalAddress'] as String?,
        specialization: json['specialization'] as String?,
        yearsOfExperience: json['yearsOfExperience'] as int?,
        submittedAt: DateTime.tryParse(
          json['verificationSubmittedAt'] as String? ?? '',
        )?.toLocal(),
        note: json['verificationNote'] as String?,
      );
}

class VerificationRepository {
  VerificationRepository(this._dio);

  final Dio _dio;

  Future<DoctorVerification> getMine() => _call(
    () => _dio.get(
      '/api/doctors/me/verification',
      // Status must be live — a cached "pending" would hide an approval.
      options: Options(extra: {'offline': false}),
    ),
  );

  /// Turns a new account into a doctor awaiting verification.
  Future<DoctorVerification> apply({required String specialization}) => _call(
    () => _dio.post(
      '/api/doctors/apply',
      data: {'specialization': specialization},
    ),
  );

  Future<DoctorVerification> submit({
    required String licenseNumber,
    required String licenseDocumentUrl,
    required String hospitalName,
    String? hospitalAddress,
    String? specialization,
    int? yearsOfExperience,
  }) => _call(
    () => _dio.put(
      '/api/doctors/me/verification',
      data: {
        'licenseNumber': licenseNumber,
        'licenseDocumentUrl': licenseDocumentUrl,
        'hospitalName': hospitalName,
        'hospitalAddress': ?hospitalAddress,
        'specialization': ?specialization,
        'yearsOfExperience': ?yearsOfExperience,
      },
    ),
  );

  Future<DoctorVerification> _call(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      ApiException.checkStatus(response);
      return DoctorVerification.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }
}

final verificationRepositoryProvider = Provider<VerificationRepository>(
  (ref) => VerificationRepository(ref.watch(dioProvider)),
);

final myVerificationProvider = FutureProvider.autoDispose<DoctorVerification>(
  (ref) => ref.watch(verificationRepositoryProvider).getMine(),
);

/// Set on the Register screen when someone signs up as a doctor, so the
/// router sends the new account to the verification screen instead of the
/// patient home.
final doctorSignupIntentProvider = NotifierProvider<_Intent, bool>(_Intent.new);

class _Intent extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}
