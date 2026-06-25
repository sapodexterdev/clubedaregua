class Appointment {
  const Appointment({
    required this.id,
    required this.barberName,
    required this.serviceName,
    required this.dateLabel,
    required this.time,
    required this.status,
    required this.total,
  });

  final String id;
  final String barberName;
  final String serviceName;
  final String dateLabel;
  final String time;
  final String status;
  final double total;

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'].toString(),
      barberName: map['barbers']?['name'] ?? '',
      serviceName: map['services']?['name'] ?? '',
      dateLabel: map['appointment_date'] ?? '',
      time: map['appointment_time'] ?? '',
      status: map['status'] ?? 'pending',
      total: (map['total_price'] ?? 0).toDouble(),
    );
  }
}
