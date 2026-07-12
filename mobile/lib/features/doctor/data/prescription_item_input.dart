class PrescriptionItemInput {
  PrescriptionItemInput({
    required this.medicationName,
    required this.dosage,
    required this.quantity,
    this.instructions,
  });

  final String medicationName;
  final String dosage;
  final int quantity;
  final String? instructions;

  Map<String, dynamic> toJson() => {
        'medicationName': medicationName,
        'dosage': dosage,
        'quantity': quantity,
        if (instructions != null) 'instructions': instructions,
      };
}
