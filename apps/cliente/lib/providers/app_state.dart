import 'package:flutter/foundation.dart';

import '../models/appointment.dart';
import '../models/barber.dart';
import '../models/service_category.dart';
import '../models/service_item.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/barber_repository.dart';
import '../services/auth_service.dart';
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
  ShopIdentity? shopIdentity;
  List<PublicBarbershop> publicBarbershops = const [];
  PublicBarbershop? selectedBarbershop;
  String discoveryQuery = '';
  bool isSignedIn = false;
  bool lastBookingRequestCreated = false;

  List<PublicBarbershop> get discoveredBarbershops {
    final query = discoveryQuery.trim().toLowerCase();
    if (query.isEmpty) return publicBarbershops;

    return publicBarbershops.where((shop) {
      final serviceNames = shop.services.map((item) => item.name).join(' ');
      return shop.identity.name.toLowerCase().contains(query) ||
          serviceNames.toLowerCase().contains(query) ||
          shop.neighborhood.toLowerCase().contains(query) ||
          shop.identity.city.toLowerCase().contains(query);
    }).toList();
  }

  List<PublicBarbershop> get topRatedBarbershops {
    final items = List<PublicBarbershop>.of(discoveredBarbershops)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return items;
  }

  List<PublicBarbershop> get nearbyBarbershops {
    final items = List<PublicBarbershop>.of(discoveredBarbershops)
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return items;
  }

  List<PublicBarbershop> get popularBarbershops {
    final items = List<PublicBarbershop>.of(discoveredBarbershops)
      ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    return items;
  }

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
    final shopsFuture = _barberRepository.fetchShopIdentities();
    final sessionFuture = AuthService().restoreSession();

    final fetchedBarbers = await barbersFuture;
    final fetchedCategories = await categoriesFuture;
    final fetchedServices = await servicesFuture;
    final fetchedAppointments = await appointmentsFuture;
    final fetchedShopIdentities = await shopsFuture;
    final session = await sessionFuture;
    final fetchedShopIdentity = fetchedShopIdentities.isNotEmpty
        ? fetchedShopIdentities.first
        : await _barberRepository.fetchShopIdentity(
            barberShopId: fetchedBarbers.isEmpty
                ? null
                : fetchedBarbers.first.barberShopId,
          );

    _applyData(
      barbersData: fetchedBarbers,
      categoriesData: fetchedCategories,
      servicesData: fetchedServices,
      appointmentsData: fetchedAppointments,
      shopIdentityData: fetchedShopIdentity,
      shopIdentitiesData: fetchedShopIdentities,
      signedInData: session != null,
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
    required ShopIdentity? shopIdentityData,
    required List<ShopIdentity> shopIdentitiesData,
    required bool signedInData,
  }) {
    barbers = barbersData;
    categories = categoriesData;
    services = servicesData;
    appointments = appointmentsData;
    shopIdentity = shopIdentityData;
    isSignedIn = signedInData;
    publicBarbershops = _buildPublicBarbershops(
      shopIdentitiesData.isEmpty && shopIdentityData != null
          ? [shopIdentityData]
          : shopIdentitiesData,
      barbersData,
      servicesData,
    );
    selectedBarbershop = _preserveSelectedShop(selectedBarbershop);
    selectedBarber = _preserveSelectedBarber(selectedBarber);
    selectedService = _preserveSelectedService(selectedService);
    selectedCategoryId = _preserveSelectedCategory(selectedCategoryId);
    _ensureSelectedServiceMatchesBarber();
  }

  void updateDiscoveryQuery(String value) {
    discoveryQuery = value;
    notifyListeners();
  }

  void selectBarbershop(PublicBarbershop shop) {
    selectedBarbershop = shop;
    shopIdentity = shop.identity;
    final shopBarbers = barbers
        .where((barber) => barber.barberShopId == shop.identity.id)
        .toList();
    final shopServices = services
        .where((service) => service.barberShopId == shop.identity.id)
        .toList();
    selectedBarber = shopBarbers.isEmpty ? null : shopBarbers.first;
    selectedService = shopServices.isEmpty ? null : shopServices.first;
    selectedCategoryId = null;
    notifyListeners();
    refreshAvailableTimes();
  }

  void requireSignedIn() {
    isSignedIn = AuthService().isSignedIn;
    notifyListeners();
  }

  List<PublicBarbershop> _buildPublicBarbershops(
    List<ShopIdentity> identities,
    List<Barber> barbersData,
    List<ServiceItem> servicesData,
  ) {
    final source = identities.isEmpty
        ? [
            const ShopIdentity(
              id: MockData.demoShopId,
              name: 'Barbearia Elite',
              logoUrl: '',
              coverUrl: '',
              phone: '',
              whatsapp: '',
              email: '',
              instagram: '@barbeariaelite',
              address: 'Centro',
              city: 'Sao Paulo',
              state: 'SP',
              secondaryColor: '#F3B200',
              bookingIntervalMinutes: 30,
              bookingDaysAhead: 30,
              minNoticeMinutes: 60,
              maxDelayMinutes: 15,
              minCancelHours: 2,
            ),
          ]
        : identities;

    return [
      for (var index = 0; index < source.length; index++)
        PublicBarbershop(
          identity: source[index],
          barbers: barbersData
              .where((barber) => barber.barberShopId == source[index].id)
              .toList(),
          services: servicesData
              .where((service) => service.barberShopId == source[index].id)
              .toList(),
          rating: _shopRating(source[index], barbersData),
          reviewCount: 80 + (index * 37),
          distanceKm: 1.2 + (index * .8),
          nextSlot: _nextSlot(index),
          isOpen: DateTime.now().hour >= 8 && DateTime.now().hour < 20,
          neighborhood: source[index].address.isEmpty
              ? source[index].city
              : source[index].address.split(',').first,
        ),
    ];
  }

  PublicBarbershop? _preserveSelectedShop(PublicBarbershop? current) {
    if (publicBarbershops.isEmpty) return null;
    if (current == null) return publicBarbershops.first;
    for (final shop in publicBarbershops) {
      if (shop.identity.id == current.identity.id) return shop;
    }
    return publicBarbershops.first;
  }

  double _shopRating(ShopIdentity shop, List<Barber> barbersData) {
    final shopBarbers =
        barbersData.where((barber) => barber.barberShopId == shop.id).toList();
    if (shopBarbers.isEmpty) return 4.8;
    final total = shopBarbers.fold<double>(0, (sum, item) => sum + item.rating);
    final rating = total / shopBarbers.length;
    return double.parse(rating.toStringAsFixed(1));
  }

  String _nextSlot(int index) {
    const slots = ['Hoje 14:30', 'Hoje 16:00', 'Amanha 09:00', 'Amanha 11:30'];
    return slots[index % slots.length];
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
    if (!_selectedDateIsAllowed()) return false;
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
    availableTimes = _filterTimesBySettings(times);
    if (!availableTimes.contains(selectedTime)) {
      selectedTime = availableTimes.isEmpty ? '' : availableTimes.first;
    }
    notifyListeners();
  }

  bool _selectedDateIsAllowed() {
    final identity = shopIdentity;
    if (identity == null) return true;
    final today = DateTime.now();
    final selectedDay =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final maxDay = DateTime(today.year, today.month, today.day)
        .add(Duration(days: identity.bookingDaysAhead));
    return !selectedDay.isAfter(maxDay);
  }

  List<String> _filterTimesBySettings(List<String> times) {
    final identity = shopIdentity;
    if (identity == null) return times;

    final minDateTime =
        DateTime.now().add(Duration(minutes: identity.minNoticeMinutes));
    return times.where((time) {
      final parts = time.split(':');
      if (parts.length != 2) return false;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return false;
      final slot = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        hour,
        minute,
      );
      return !slot.isBefore(minDateTime);
    }).toList();
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
