import 'package:flutter/foundation.dart';

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
  Barber? selectedBarber = MockData.barbers.first;
  ServiceItem? selectedService = MockData.services.first;
  String? selectedCategoryId = MockData.categories.first.id;
  DateTime selectedDate = DateTime.now();
  String selectedTime = '10:30';

  List<Barber> barbers = List.of(MockData.barbers);
  List<ServiceCategory> categories = List.of(MockData.categories);
  List<ServiceItem> services = List.of(MockData.services);
  List<Appointment> appointments = List.of(MockData.appointments);
  bool lastBookingRequestCreated = false;

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
    if (isLoading) return;

    isLoading = true;
    notifyListeners();

    final barbersFuture = _barberRepository.fetchBarbers();
    final categoriesFuture = _barberRepository.fetchCategories();
    final servicesFuture = _barberRepository.fetchServices();
    final appointmentsFuture = _appointmentRepository.fetchAppointments();

    final fetchedBarbers = await barbersFuture;
    final fetchedCategories = await categoriesFuture;
    final fetchedServices = await servicesFuture;
    final fetchedAppointments = await appointmentsFuture;

    _applyData(
      barbersData: fetchedBarbers,
      categoriesData: fetchedCategories,
      servicesData: fetchedServices,
      appointmentsData: fetchedAppointments,
    );

    isLoading = false;
    notifyListeners();
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
    selectedBarber = _preserveSelectedBarber(selectedBarber);
    selectedService = _preserveSelectedService(selectedService);
    selectedCategoryId = _preserveSelectedCategory(selectedCategoryId);
  }

  Barber? _preserveSelectedBarber(Barber? current) {
    if (barbers.isEmpty) return null;
    if (current == null) return barbers.first;

    for (final barber in barbers) {
      if (barber.id == current.id) return barber;
    }

    return barbers.first;
  }

  ServiceItem? _preserveSelectedService(ServiceItem? current) {
    if (services.isEmpty) return null;
    if (current == null) return services.first;

    for (final service in services) {
      if (service.id == current.id) return service;
    }

    return services.first;
  }

  String? _preserveSelectedCategory(String? current) {
    if (categories.isEmpty) return null;
    if (current == null) return categories.first.id;

    for (final category in categories) {
      if (category.id == current) return category.id;
    }

    return categories.first.id;
  }

  Future<bool> createSelectedAppointment({
    required String customerName,
    required String customerPhone,
    required String paymentMethodLabel,
  }) async {
    final barber = selectedBarber;
    final service = selectedService;
    if (barber == null || service == null) return false;

    lastBookingRequestCreated = await _appointmentRepository.createAppointment(
      barberId: barber.id,
      serviceId: service.id,
      date: selectedDate,
      time: selectedTime,
      total: service.price,
      barberShopId: barber.barberShopId,
      customerName: customerName,
      customerPhone: customerPhone,
      paymentMethodLabel: paymentMethodLabel,
    );

    appointments = await _appointmentRepository.fetchAppointments();
    notifyListeners();
    return lastBookingRequestCreated;
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
