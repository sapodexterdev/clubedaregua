import '../config/supabase_config.dart';
import '../models/appointment.dart';
import '../services/mock_data.dart';

class AppointmentRepository {
  Future<List<Appointment>> fetchAppointments() async {
    if (!SupabaseConfig.isConfigured) return MockData.appointments;
    try {
      final data = await SupabaseConfig.client
          .from('appointments')
          .select('*, barbers(name), services(name)')
          .order('appointment_date', ascending: false);
      return data.map<Appointment>((row) => Appointment.fromMap(row)).toList();
    } catch (_) {
      return MockData.appointments;
    }
  }

  Future<void> createAppointment({
    required String barberId,
    required String serviceId,
    required DateTime date,
    required String time,
    required double total,
  }) async {
    if (!SupabaseConfig.isConfigured) return;
    await SupabaseConfig.client.from('appointments').insert({
      'barber_id': barberId,
      'service_id': serviceId,
      'appointment_date': date.toIso8601String().substring(0, 10),
      'appointment_time': time,
      'total_price': total,
      'status': 'pending',
    });
  }

  Future<void> cancelAppointment(String appointmentId) async {
    if (!SupabaseConfig.isConfigured) return;
    await SupabaseConfig.client
        .from('appointments')
        .update({'status': 'cancelled'}).eq('id', appointmentId);
  }
}
