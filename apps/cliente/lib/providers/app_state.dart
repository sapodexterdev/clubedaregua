import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import '../models/appointment.dart';
import '../models/barber.dart';
import '../models/service_category.dart';
import '../models/service_item.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/barber_repository.dart';
import '../services/mock_data.dart';

class AppState extends ChangeNotifier {
  final _barberRepository = BarberRepository();
  final _appointmentRepository = AppointmentRepository();

  bool isLoading = false;
  String selectedTab = 'home';
  Barber? selectedBarber;
  ServiceItem? selectedService;
  String? selectedCategoryId;
  DateTime selectedDate = DateTime.now();
  String selectedTime = '10:30';

  List<Barber> barbers = [];
  List<ServiceCategory> categories = [];
  List<ServiceItem> services = [];
  List<Appointment> appointments = [];

  List<Barber> get filteredBarbers {
    final categoryId = selectedCategoryId;
    if (categoryId == null) return barbers;

    return barbers
        .where((barber) => barber.categoryIds.contains(categoryId))
        .toList();
  }

  String get selectedCategoryTitle {
    final categoryId = selectedCategoryId;
    if (categoryId == null) return 'Profissionais em destaque';

    ServiceCategory? category;
    for (final item in categories) {
      if (item.id == categoryId) {
        category = item;
        break;
      }
    }

    final label = _categoryDisplayName(category?.name ?? 'Serviços');
    return '$label em destaque';
  }

  Future<void> loadInitialData() async {
    isLoading = true;
    notifyListeners();

    _applyData(
      barbersData: MockData.barbers,
      categoriesData: MockData.categories,
      servicesData: MockData.services,
      appointmentsData: MockData.appointments,
    );

    isLoading = false;
    notifyListeners();

    await refreshFromSupabase();
  }

  Future<void> refreshFromSupabase() async {
    try {
      await SupabaseConfig.initialize();
      if (!SupabaseConfig.isConfigured) return;

      final results = await Future.wait([
        _barberRepository.fetchBarbers(),
        _barberRepository.fetchCategories(),
        _barberRepository.fetchServices(),
        _appointmentRepository.fetchAppointments(),
      ]);

      _applyData(
        barbersData: results[0] as List<Barber>,
        categoriesData: results[1] as List<ServiceCategory>,
        servicesData: results[2] as List<ServiceItem>,
        appointmentsData: results[3] as List<Appointment>,
      );
      notifyListeners();
    } catch (_) {
      SupabaseConfig.isConfigured = false;
    }
  }

  void _applyData({
    required List<Barber> barbersData,
    required List<ServiceCategory> categoriesData,
    required List<ServiceItem> servicesData,
    required List<Appointment> appointmentsData,
  }) {
    barbers = barbersData;
    categories = categoriesData;
    services = servicesData;
    appointments = appointmentsData;
    selectedBarber = barbers.isEmpty ? null : barbers.first;
    selectedService = services.isEmpty ? null : services.first;
    selectedCategoryId ??= categories.isEmpty ? null : categories.first.id;
  }

  Future<void> createSelectedAppointment() async {
    final barber = selectedBarber;
    final service = selectedService;
    if (barber == null || service == null) return;

    await _appointmentRepository.createAppointment(
      barberId: barber.id,
      serviceId: service.id,
      date: selectedDate,
      time: selectedTime,
      total: service.price,
    );

    appointments = await _appointmentRepository.fetchAppointments();
    notifyListeners();
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await _appointmentRepository.cancelAppointment(appointmentId);
    appointments = await _appointmentRepository.fetchAppointments();
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

  void selectCategory(String categoryId) {
    selectedCategoryId = categoryId;
    notifyListeners();
  }

  void clearCategory() {
    selectedCategoryId = null;
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

  String _categoryDisplayName(String name) {
    return switch (name.toLowerCase()) {
      'cabelo' => 'Cortes',
      'barba' => 'Barbas',
      'combo' => 'Combos',
      'sobrancelha' => 'Sobrancelhas',
      _ => name,
    };
  }
}
