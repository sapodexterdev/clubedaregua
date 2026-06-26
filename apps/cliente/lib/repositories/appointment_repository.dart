import '../models/appointment.dart';
import '../services/mock_data.dart';

class AppointmentRepository {
  Future<List<Appointment>> fetchAppointments() async {
    return MockData.appointments;
  }

  Future<void> createAppointment({
    required String barberId,
    required String serviceId,
    required DateTime date,
    required String time,
    required double total,
  }) async {
    return;
  }

  Future<void> cancelAppointment(String appointmentId) async {
    return;
  }
}
