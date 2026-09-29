import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../profile/data/medical_document.dart';

/// A doctor's view of one patient: profile facts, the documents the patient
/// uploaded, and past visits with this doctor
/// (`GET /api/medical-documents/patient/:id`).
class PatientHistory {
  const PatientHistory({
    required this.patientId,
    required this.name,
    required this.documents,
    required this.visits,
    this.image,
    this.age,
    this.gender,
    this.bloodGroup,
    this.medicalHistory,
  });

  final String patientId;
  final String name;
  final String? image;
  final String? age;
  final String? gender;
  final String? bloodGroup;
  final String? medicalHistory;
  final List<MedicalDocument> documents;
  final List<PatientVisit> visits;

  factory PatientHistory.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'] as Map<String, dynamic>;
    return PatientHistory(
      patientId: patient['id'] as String,
      name: patient['name'] as String? ?? 'Patient',
      image: patient['image'] as String?,
      age: patient['age'] as String?,
      gender: patient['gender'] as String?,
      bloodGroup: patient['bloodgroup'] as String?,
      medicalHistory: patient['medicalHistory'] as String?,
      documents: [
        for (final d in json['documents'] as List? ?? const [])
          MedicalDocument.fromJson(d as Map<String, dynamic>),
      ],
      visits: [
        for (final v in json['appointments'] as List? ?? const [])
          PatientVisit.fromJson(v as Map<String, dynamic>),
      ],
    );
  }
}

class PatientVisit {
  const PatientVisit({
    required this.id,
    required this.date,
    required this.status,
    this.time,
    this.consultationType,
    this.reason,
    this.notes,
  });

  final String id;
  final DateTime date;
  final String? time;
  final String status;
  final String? consultationType;
  final String? reason;
  final String? notes;

  factory PatientVisit.fromJson(Map<String, dynamic> json) {
    return PatientVisit(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String).toLocal(),
      time: json['time'] as String?,
      status: json['status'] as String? ?? '',
      consultationType: json['consultationType'] as String?,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class PatientHistoryRepository {
  PatientHistoryRepository(this._dio);

  final Dio _dio;

  Future<PatientHistory> getHistory(String patientId) async {
    try {
      final response = await _dio.get(
        '/api/medical-documents/patient/$patientId',
      );
      ApiException.checkStatus(response);
      return PatientHistory.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }
}
