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
    this.patientId,
    this.patientName,
    this.doctorId,
    this.fee,
    this.consultationType,
    this.isEmergency = false,
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
  final String? patientId;
  final String? patientName;
  final String? doctorId;
  final int? fee;
  final String? consultationType;
  final bool isEmergency;

  bool get isCancellable => status == 'requested' || status == 'scheduled' || status == 'confirmed';
  bool get isPending => status == 'requested';

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
      patientId: json['patientId'] as String?,
      patientName: json['patientName'] as String?,
      doctorId: json['doctorId'] as String?,
      fee: json['fee'] as int?,
      consultationType: json['consultationType'] as String?,
      isEmergency: json['isEmergency'] as bool? ?? false,
    );
  }
}
