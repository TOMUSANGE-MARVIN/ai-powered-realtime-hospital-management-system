class PatientPrescriptionItem {
  PatientPrescriptionItem({
    required this.medicationName,
    required this.dosage,
    required this.quantity,
    this.instructions,
  });

  final String medicationName;
  final String dosage;
  final int quantity;
  final String? instructions;

  factory PatientPrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PatientPrescriptionItem(
      medicationName: json['medicationName'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      instructions: json['instructions'] as String?,
    );
  }
}

class PatientPrescription {
  PatientPrescription({
    required this.id,
    required this.doctorName,
    required this.status,
    required this.createdAt,
    required this.items,
    this.notes,
    this.imageUrl,
    this.patientName,
    this.signatureUrl,
    this.licenseNo,
    this.dateIssued,
    this.dispensedAt,
    this.appointmentId,
    this.doctorSpecialization,
    this.doctorFacility,
    this.doctorFacilityAddress,
    this.doctorPhone,
  });

  final String id;
  final String doctorName;

  /// pending (not yet dispensed) | dispensed | cancelled
  final String status;
  final DateTime createdAt;
  final List<PatientPrescriptionItem> items;

  /// The doctor's diagnosis / notes.
  final String? notes;

  /// A photo of a paper prescription, when the doctor uploaded one.
  final String? imageUrl;
  final String? patientName;
  final String? signatureUrl;

  /// Licence number printed on the prescription — falls back to the
  /// doctor's verified licence when the prescription didn't record one.
  final String? licenseNo;

  /// The date printed on the prescription (yyyy-MM-dd), if set.
  final String? dateIssued;
  final DateTime? dispensedAt;
  final String? appointmentId;
  final String? doctorSpecialization;
  final String? doctorFacility;
  final String? doctorFacilityAddress;
  final String? doctorPhone;

  bool get isActive => status == 'pending';

  /// The date to show as "issued": the printed date, else when it was sent.
  DateTime get issuedOn => DateTime.tryParse(dateIssued ?? '') ?? createdAt;

  String get statusLabel => switch (status) {
    'pending' => 'Active',
    'dispensed' => 'Dispensed',
    'cancelled' => 'Cancelled',
    _ => status,
  };

  factory PatientPrescription.fromJson(Map<String, dynamic> json) {
    return PatientPrescription(
      id: (json['id'] ?? json['_id']).toString(),
      doctorName: json['doctorName'] as String? ?? 'Doctor',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      items: (json['items'] as List? ?? [])
          .map(
            (i) => PatientPrescriptionItem.fromJson(i as Map<String, dynamic>),
          )
          .toList(),
      notes: json['notes'] as String?,
      imageUrl: json['imageUrl'] as String?,
      patientName: json['patientName'] as String?,
      signatureUrl: json['signatureUrl'] as String?,
      licenseNo:
          json['licenseNo'] as String? ??
          (json['doctorDetails'] as Map?)?['licenseNumber'] as String?,
      dateIssued: json['dateIssued'] as String?,
      dispensedAt: DateTime.tryParse(
        json['dispensedAt'] as String? ?? '',
      )?.toLocal(),
      appointmentId: json['appointmentId'] as String?,
      doctorSpecialization:
          (json['doctorDetails'] as Map?)?['specialization'] as String?,
      doctorFacility:
          (json['doctorDetails'] as Map?)?['hospitalName'] as String?,
      doctorFacilityAddress:
          (json['doctorDetails'] as Map?)?['hospitalAddress'] as String?,
      doctorPhone: (json['doctorDetails'] as Map?)?['phoneNumber'] as String?,
    );
  }
}
