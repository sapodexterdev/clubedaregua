import '../config/supabase_config.dart';
import '../models/appointment.dart';
import '../services/mock_data.dart';

class AppointmentRepository {
  Future<List<Appointment>> fetchAppointments() async {
    if (!SupabaseConfig.isConfigured) return MockData.appointments;

    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return MockData.appointments;

    try {
      final rows = await SupabaseConfig.client
          .from('appointments')
          .select('id, starts_at, status, total_price, barbers(name), services(name)')
          .eq('client_id', user.id)
          .order('starts_at', ascending: false);

      return rows
          .map((row) => Appointment.fromMap(Map<String, dynamic>.from(row)))
          .toList();
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

    final client = SupabaseConfig.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final barber = await client
        .from('barbers')
        .select('barber_shop_id')
        .eq('id', barberId)
        .single();
    final service = await client
        .from('services')
        .select('duration_minutes')
        .eq('id', serviceId)
        .single();

    final parts = time.split(':');
    final startsAt = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    final durationMinutes = service['duration_minutes'] as int? ?? 30;
    final endsAt = startsAt.add(Duration(minutes: durationMinutes));

    final appointment = await client
        .from('appointments')
        .insert({
          'barber_shop_id': barber['barber_shop_id'],
          'client_id': user.id,
          'barber_id': barberId,
          'service_id': serviceId,
          'starts_at': startsAt.toIso8601String(),
          'ends_at': endsAt.toIso8601String(),
          'status': 'pending',
          'total_price': total,
          'created_by': user.id,
        })
        .select('id, barber_shop_id')
        .single();

    await client.from('payments').insert({
      'barber_shop_id': appointment['barber_shop_id'],
      'appointment_id': appointment['id'],
      'method': 'pix',
      'status': 'pending',
      'amount': total,
    });
  }

  Future<void> cancelAppointment(String appointmentId) async {
    if (!SupabaseConfig.isConfigured) return;

    await SupabaseConfig.client
        .from('appointments')
        .update({'status': 'cancelled'})
        .eq('id', appointmentId);
  }
}
