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
  });

  final String id;
  final String doctorName;
  final String status;
  final DateTime createdAt;
  final List<PatientPrescriptionItem> items;
  final String? notes;
  final String? imageUrl;

  bool get isActive => status == 'pending';

  factory PatientPrescription.fromJson(Map<String, dynamic> json) {
    return PatientPrescription(
      id: (json['id'] ?? json['_id']).toString(),
      doctorName: json['doctorName'] as String? ?? 'Doctor',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] as String),
      items: (json['items'] as List? ?? [])
          .map((i) => PatientPrescriptionItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
