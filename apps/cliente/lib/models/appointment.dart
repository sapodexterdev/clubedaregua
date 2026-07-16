class Appointment {
  const Appointment({
    required this.id,
    this.shopName = '',
    required this.barberName,
    required this.serviceName,
    required this.dateLabel,
    required this.time,
    required this.status,
    required this.total,
  });

  final String id;
  final String shopName;
  final String barberName;
  final String serviceName;
  final String dateLabel;
  final String time;
  final String status;
  final double total;

  factory Appointment.fromMap(Map<String, dynamic> map) {
    final startsAt = map['starts_at']?.toString();
    final legacyDate = map['appointment_date']?.toString();
    final legacyTime = map['appointment_time']?.toString();

    return Appointment(
      id: map['id'].toString(),
      shopName: map['barber_shops']?['name']?.toString() ?? '',
      barberName: map['barbers']?['name'] ?? '',
      serviceName: map['services']?['name'] ?? '',
      dateLabel: map['requested_date']?.toString() ??
          legacyDate ??
          _dateFromTimestamp(startsAt),
      time: _timeFromValue(map['requested_time']?.toString()) ??
          legacyTime ??
          _timeFromTimestamp(startsAt),
      status: map['status'] ?? 'pending',
      total: (map['total_price'] ?? 0).toDouble(),
    );
  }

  static String _dateFromTimestamp(String? value) {
    if (value == null || value.length < 10) return '';
    return value.substring(0, 10);
  }

  static String _timeFromTimestamp(String? value) {
    if (value == null || value.length < 16) return '';
    return value.substring(11, 16);
  }

  static String? _timeFromValue(String? value) {
    if (value == null || value.length < 5) return null;
    return value.substring(0, 5);
  }
}
