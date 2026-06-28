import '../models/appointment.dart';
import '../services/mock_data.dart';
import '../services/supabase_rest_service.dart';

class AppointmentRepository {
  const AppointmentRepository({SupabaseRestService? rest})
      : _rest = rest ?? const SupabaseRestService();

  final SupabaseRestService _rest;

  Future<List<Appointment>> fetchAppointments() async {
    return MockData.appointments;
  }

  Future<bool> createAppointment({
    required String barberId,
    required String serviceId,
    required DateTime date,
    required String time,
    required double total,
    required String barberShopId,
    required String customerName,
    required String customerPhone,
  }) async {
    if (!_rest.isConfigured || barberShopId.isEmpty) return false;

    try {
      return await _rest.insertRow('booking_requests', {
        'barber_shop_id': barberShopId,
        'barber_id': barberId,
        'service_id': serviceId,
        'requested_date': _dateOnly(date),
        'requested_time': time,
        'customer_name': customerName.trim(),
        'customer_phone': customerPhone.trim(),
        'total_price': total,
        'notes': 'Solicitacao criada pelo PWA Cliente',
      });
    } catch (_) {
      return false;
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    return;
  }

  String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
