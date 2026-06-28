import '../models/appointment.dart';
import '../services/mock_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentRepository {
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<List<Appointment>> fetchAppointments() async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return MockData.appointments;

    try {
      final rows = await client
          .from('appointments')
          .select('id,starts_at,status,total_price,barbers(name),services(name)')
          .eq('client_id', userId)
          .order('starts_at', ascending: false);

      final appointments = rows
          .map<Appointment>(
            (row) => Appointment.fromMap(Map<String, dynamic>.from(row)),
          )
          .toList();
      return appointments.isEmpty ? MockData.appointments : appointments;
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
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    try {
      final timeParts = time.split(':');
      final startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      final endsAt = startsAt.add(const Duration(hours: 1));

      final barber = await client
          .from('barbers')
          .select('barber_shop_id')
          .eq('id', barberId)
          .single();

      await client.from('appointments').insert({
        'barber_shop_id': barber['barber_shop_id'],
        'client_id': userId,
        'barber_id': barberId,
        'service_id': serviceId,
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt.toIso8601String(),
        'status': 'pending',
        'total_price': total,
        'created_by': userId,
      });
    } catch (_) {
      return;
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    try {
      await client
          .from('appointments')
          .update({'status': 'cancelled'})
          .eq('id', appointmentId)
          .eq('client_id', userId);
    } catch (_) {
      return;
    }
  }
}
