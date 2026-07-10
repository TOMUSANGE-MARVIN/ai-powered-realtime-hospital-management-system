class Appointment {
  Appointment({
    required this.id,
    required this.doctorName,
    required this.date,
    required this.status,
    required this.isVirtual,
    this.time,
    this.reason,
    this.department,
    this.meetingId,
  });

  final String id;
  final String doctorName;
  final DateTime date;
  final String status;
  final bool isVirtual;
  final String? time;
  final String? reason;
  final String? department;
  final String? meetingId;

  bool get isCancellable => status == 'requested' || status == 'scheduled' || status == 'confirmed';

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: (json['_id'] ?? json['id']).toString(),
      doctorName: json['doctorName'] as String? ?? 'Unassigned',
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String? ?? 'requested',
      isVirtual: json['isVirtual'] as bool? ?? false,
      time: json['time'] as String?,
      reason: json['reason'] as String?,
      department: json['department'] as String?,
      meetingId: json['meetingId'] as String?,
    );
  }
}
