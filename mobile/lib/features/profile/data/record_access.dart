import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/providers.dart';
import '../../../core/offline/offline_first.dart';

/// One time someone other than the patient opened their records (E23.3).
class RecordAccess {
  const RecordAccess({
    required this.viewerName,
    required this.viewerRole,
    required this.resource,
    required this.at,
  });

  final String viewerName;
  final String viewerRole;

  /// full_history | lab_results | prescriptions | profile
  final String resource;
  final DateTime at;

  String get resourceLabel => switch (resource) {
    'full_history' => 'Full medical history',
    'lab_results' => 'Lab results',
    'prescriptions' => 'Prescriptions',
    'profile' => 'Profile and health details',
    _ => 'Records',
  };

  String get roleLabel => switch (viewerRole) {
    'doctor' => 'Doctor',
    'nurse' => 'Nurse',
    'pharmacist' => 'Pharmacist',
    'lab_tech' => 'Lab technician',
    'admin' || 'superadmin' => 'Ask Musawo staff',
    _ => viewerRole,
  };

  factory RecordAccess.fromJson(Map<String, dynamic> json) => RecordAccess(
    viewerName: json['viewerName'] as String? ?? 'Unknown',
    viewerRole: json['viewerRole'] as String? ?? '',
    resource: json['resource'] as String? ?? '',
    at:
        DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
  );
}

final myRecordAccessProvider = FutureProvider.autoDispose<List<RecordAccess>>(
  (ref) => offlineFirst(ref, () async {
    try {
      final response = await ref
          .watch(dioProvider)
          .get('/api/record-access/mine');
      ApiException.checkStatus(response);
      return [
        for (final e in response.data as List)
          RecordAccess.fromJson(e as Map<String, dynamic>),
      ];
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }),
);
