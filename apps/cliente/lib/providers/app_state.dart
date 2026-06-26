import 'package:flutter/foundation.dart';

import '../models/appointment.dart';
import '../models/barber.dart';
import '../models/service_category.dart';
import '../models/service_item.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/barber_repository.dart';

class AppState extends ChangeNotifier {
  final _barberRepository = BarberRepository();
  final _appointmentRepository = AppointmentRepository();

  bool isLoading = false;
  String selectedTab = 'home';
  Barber? selectedBarber;
  ServiceItem? selectedService;
  DateTime selectedDate = DateTime.now();
  String selectedTime = '10:30';

  List<Barber> barbers = [];
  List<ServiceCategory> categories = [];
  List<ServiceItem> services = [];
  List<Appointment> appointments = [];

  Future<void> loadInitialData() async {
    isLoading = true;
    notifyListeners();

    final results = await Future.wait([
      _barberRepository.fetchBarbers(),
      _barberRepository.fetchCategories(),
      _barberRepository.fetchServices(),
      _appointmentRepository.fetchAppointments(),
    ]);

    barbers = results[0] as List<Barber>;
    categories = results[1] as List<ServiceCategory>;
    services = results[2] as List<ServiceItem>;
    appointments = results[3] as List<Appointment>;
    selectedBarber = barbers.isEmpty ? null : barbers.first;
    selectedService = services.isEmpty ? null : services.first;

    isLoading = false;
    notifyListeners();
  }

  void selectBarber(Barber barber) {
    selectedBarber = barber;
    notifyListeners();
  }

  void selectService(ServiceItem service) {
    selectedService = service;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void selectTime(String time) {
    selectedTime = time;
    notifyListeners();
  }
}
