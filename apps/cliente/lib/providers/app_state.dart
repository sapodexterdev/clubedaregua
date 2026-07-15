import 'package:flutter/foundation.dart';

import '../models/appointment.dart';
import '../models/barber.dart';
import '../models/service_category.dart';
import '../models/service_item.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/barber_repository.dart';
import '../services/auth_service.dart';
import '../services/mock_data.dart';
import '../services/location_service.dart';

class AppState extends ChangeNotifier {
  static const discoveryRadiusKm = 10.0;

  final _barberRepository = BarberRepository();
  final _appointmentRepository = AppointmentRepository();
  final _locationService = const LocationService();

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
  String? discoveryLocation;
  String? currentUserName;
  bool discoveryOpenNowOnly = false;
  bool discoveryHighlyRatedOnly = false;
  bool isLocating = false;
  bool useCurrentLocation = false;
  String? locationError;
  double? _deviceLatitude;
  double? _deviceLongitude;
  bool isSignedIn = false;
  bool lastBookingRequestCreated = false;

  List<PublicBarbershop> get discoveredBarbershops {
    final query = _normalizedSearch(discoveryQuery);
    return publicBarbershops.where((shop) {
      if (useCurrentLocation &&
          (!shop.distanceKm.isFinite ||
              shop.distanceKm > discoveryRadiusKm)) {
        return false;
      }
      if (discoveryLocation?.isNotEmpty == true &&
          shop.identity.locationLabel != discoveryLocation) {
        return false;
      }
      if (discoveryOpenNowOnly && !shop.isOpen) return false;
      if (discoveryHighlyRatedOnly && shop.rating < 4.5) return false;
      if (query.isEmpty) return true;
      final searchableText = _normalizedSearch([
        shop.identity.name,
        shop.identity.address,
        shop.identity.city,
        shop.identity.state,
        shop.neighborhood,
        ...shop.services.map((item) => item.name),
      ].join(' '));
      return searchableText.contains(query);
    }).toList();
  }

  bool get hasDiscoveryQuery => discoveryQuery.trim().isNotEmpty;

  List<String> get availableDiscoveryLocations {
    final locations = publicBarbershops
        .map((shop) => shop.identity.locationLabel)
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return locations;
  }

  String get discoveryGreeting {
    final name = currentUserName?.trim();
    if (name == null || name.isEmpty) return 'Olá!';
    return 'Olá, ${name.split(RegExp(r'\s+')).first}!';
  }

  String get discoveryLocationLabel {
    if (isLocating) return 'Obtendo sua localização...';
    if (useCurrentLocation) return 'Perto de você · até 10 km';
    if (discoveryLocation == null) return 'Definir localização';
    if (discoveryLocation!.isEmpty) return 'Todas as localizações';
    return discoveryLocation!;
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
      userNameData: session?.user.name,
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
    required String? userNameData,
  }) {
    barbers = barbersData;
    categories = categoriesData;
    services = servicesData;
    appointments = appointmentsData;
    shopIdentity = shopIdentityData;
    isSignedIn = signedInData;
    currentUserName = userNameData;
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

  String _normalizedSearch(String value) {
    const accented = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const plain = 'aaaaaeeeeiiiiooooouuuuc';
    var normalized = value.trim().toLowerCase();
    for (var index = 0; index < accented.length; index++) {
      normalized = normalized.replaceAll(accented[index], plain[index]);
    }
    return normalized;
  }

  void selectDiscoveryLocation(String? value) {
    useCurrentLocation = false;
    locationError = null;
    discoveryLocation = value;
    notifyListeners();
  }

  Future<bool> locateDevice() async {
    if (isLocating) return false;
    isLocating = true;
    locationError = null;
    notifyListeners();

    try {
      final position = await _locationService.determinePosition();
      _deviceLatitude = position.latitude;
      _deviceLongitude = position.longitude;
      useCurrentLocation = true;
      discoveryLocation = null;
      publicBarbershops = _withRealDistances(publicBarbershops);
      return true;
    } catch (error) {
      useCurrentLocation = false;
      locationError = error is LocationException
          ? error.message
          : 'Não foi possível obter sua localização. Tente novamente.';
      return false;
    } finally {
      isLocating = false;
      notifyListeners();
    }
  }

  void setDiscoveryOpenNowOnly(bool value) {
    discoveryOpenNowOnly = value;
    notifyListeners();
  }

  void setDiscoveryHighlyRatedOnly(bool value) {
    discoveryHighlyRatedOnly = value;
    notifyListeners();
  }

  void clearDiscoveryFilters() {
    discoveryOpenNowOnly = false;
    discoveryHighlyRatedOnly = false;
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
          distanceKm: _distanceFromDevice(source[index]),
          nextSlot: _nextSlot(index),
          isOpen: DateTime.now().hour >= 8 && DateTime.now().hour < 20,
          neighborhood: source[index].address.isEmpty
              ? source[index].city
              : source[index].address.split(',').first,
        ),
    ];
  }

  double _distanceFromDevice(ShopIdentity shop) {
    final latitude = _deviceLatitude;
    final longitude = _deviceLongitude;
    if (latitude == null || longitude == null || !shop.hasCoordinates) {
      return double.infinity;
    }
    return _locationService.distanceKm(
      fromLatitude: latitude,
      fromLongitude: longitude,
      toLatitude: shop.latitude!,
      toLongitude: shop.longitude!,
    );
  }

  List<PublicBarbershop> _withRealDistances(List<PublicBarbershop> shops) {
    return [
      for (final shop in shops)
        PublicBarbershop(
          identity: shop.identity,
          barbers: shop.barbers,
          services: shop.services,
          rating: shop.rating,
          reviewCount: shop.reviewCount,
          distanceKm: _distanceFromDevice(shop.identity),
          nextSlot: shop.nextSlot,
          isOpen: shop.isOpen,
          neighborhood: shop.neighborhood,
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
