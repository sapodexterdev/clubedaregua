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
  List<String> availableTimes = List.of(MockData.times);
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

  List<ServiceItem> get servicesForSelectedBarber {
    final barber = selectedBarber;
    if (barber == null || barber.serviceIds.isEmpty) return services;
    return services
        .where((service) => barber.serviceIds.contains(service.id))
        .toList();
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
    await refreshAvailableTimes();

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
    _ensureSelectedServiceMatchesBarber();
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
    final availableServices = servicesForSelectedBarber;
    if (availableServices.isEmpty) return null;
    if (current == null) return availableServices.first;

    for (final service in availableServices) {
      if (service.id == current.id) return service;
    }

    return availableServices.first;
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
    await refreshAvailableTimes();
    if (!availableTimes.contains(selectedTime)) return false;

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
    _ensureSelectedServiceMatchesBarber();
    notifyListeners();
    refreshAvailableTimes();
  }

  void selectService(ServiceItem service) {
    selectedService = service;
    notifyListeners();
    refreshAvailableTimes();
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
    refreshAvailableTimes();
  }

  void selectTime(String time) {
    selectedTime = time;
    notifyListeners();
  }

  Future<void> refreshAvailableTimes() async {
    final barber = selectedBarber;
    final service = selectedService;
    if (barber == null || service == null) {
      availableTimes = const [];
      notifyListeners();
      return;
    }

    final times = await _appointmentRepository.fetchAvailableTimes(
      barberId: barber.id,
      barberShopId: barber.barberShopId,
      date: selectedDate,
      durationMinutes: service.durationMinutes,
    );
    availableTimes = times;
    if (!availableTimes.contains(selectedTime)) {
      selectedTime = availableTimes.isEmpty ? '' : availableTimes.first;
    }
    notifyListeners();
  }

  void _ensureSelectedServiceMatchesBarber() {
    final availableServices = servicesForSelectedBarber;
    if (availableServices.isEmpty) {
      selectedService = null;
      return;
    }

    final current = selectedService;
    if (current == null ||
        !availableServices.any((service) => service.id == current.id)) {
      selectedService = availableServices.first;
    }
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
