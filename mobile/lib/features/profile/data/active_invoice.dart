class ActiveInvoice {
  ActiveInvoice({required this.id, required this.totalAmount, required this.status});

  final String id;
  final int totalAmount;
  final String status;

  factory ActiveInvoice.fromJson(Map<String, dynamic> json) {
    return ActiveInvoice(
      id: (json['id'] ?? json['_id']).toString(),
      totalAmount: json['totalAmount'] as int? ?? 0,
      status: json['status'] as String? ?? 'draft',
    );
  }
}
