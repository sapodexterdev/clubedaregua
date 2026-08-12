import 'package:flutter/foundation.dart';

import '../models/appointment.dart';
import '../models/barber.dart';
import '../models/notification_item.dart';
import '../models/service_category.dart';
import '../models/service_item.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/barber_repository.dart';
import '../repositories/client_profile_repository.dart';
import '../repositories/favorite_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/team_invitation_repository.dart';
import '../repositories/user_access_repository.dart';
import '../services/auth_service.dart';
import '../services/mock_data.dart';
import '../services/location_service.dart';

class AppState extends ChangeNotifier {
  static const discoveryRadiusKm = 10.0;

  final _barberRepository = BarberRepository();
  final _appointmentRepository = AppointmentRepository();
  final _clientProfileRepository = const ClientProfileRepository();
  final _favoriteRepository = FavoriteRepository();
  final _notificationRepository = const NotificationRepository();
  final _teamInvitationRepository = const TeamInvitationRepository();
  final _userAccessRepository = const UserAccessRepository();
  final _locationService = const LocationService();

  bool isLoading = false;
  bool isLoadingAvailability = false;
  bool isLoadingAppointments = false;
  bool isLoadingFavorites = false;
  bool isLoadingClientProfile = false;
  bool isLoadingNotifications = false;
  String? discoveryLoadError;
  String? availabilityError;
  String? appointmentsLoadError;
  String? favoritesLoadError;
  String? clientProfileError;
  String? notificationsLoadError;
  String? teamInvitationMessage;
  String? teamInvitationError;
  String selectedTab = 'home';
  Barber? selectedBarber = MockData.barbers.first;
  ServiceItem? selectedService = MockData.services.first;
  String? selectedCategoryId = MockData.categories.first.id;
  DateTime selectedDate = DateTime.now();
  String selectedTime = '10:30';

  List<Barber> barbers = List.of(MockData.barbers);
  List<ServiceCategory> categories = List.of(MockData.categories);
  List<ServiceItem> services = List.of(MockData.services);
  List<Appointment> appointments = const [];
  List<NotificationItem> notifications = const [];
  List<String> availableTimes = List.of(MockData.times);
  ShopIdentity? shopIdentity;
  List<PublicBarbershop> publicBarbershops = const [];
  PublicBarbershop? selectedBarbershop;
  String discoveryQuery = '';
  String? discoveryCategoryId;
  String? discoveryLocation;
  String? currentUserName;
  String? currentUserEmail;
  String? currentUserPhone;
  bool discoveryOpenNowOnly = false;
  bool discoveryHighlyRatedOnly = false;
  bool isLocating = false;
  bool useCurrentLocation = false;
  String? locationError;
  double? _deviceLatitude;
  double? _deviceLongitude;
  int _availabilityRequestId = 0;
  final Set<String> _favoriteShopIds = <String>{};
  final Set<String> _favoriteUpdates = <String>{};
  bool isSignedIn = false;
  bool lastBookingRequestCreated = false;
  String? lastBookingErrorMessage;
  BookingReceipt? lastBookingReceipt;
  Set<String> professionalRoles = const <String>{};
  Set<String> professionalShopIds = const <String>{};

  bool get hasBarberAccess => professionalRoles.contains('barber');

  bool get hasOwnerAccess => professionalRoles.any(
        (role) => const {'owner', 'manager', 'admin'}.contains(role),
      );

  bool get hasProfessionalAccess => hasBarberAccess || hasOwnerAccess;

  int get unreadNotificationCount =>
      notifications.where((item) => !item.isRead).length;

  List<PublicBarbershop> get discoveredBarbershops {
    final query = _normalizedSearch(discoveryQuery);
    return publicBarbershops.where((shop) {
      if (useCurrentLocation &&
          (!shop.distanceKm.isFinite || shop.distanceKm > discoveryRadiusKm)) {
        return false;
      }
      if (discoveryLocation?.isNotEmpty == true &&
          shop.identity.locationLabel != discoveryLocation) {
        return false;
      }
      if (discoveryOpenNowOnly && !shop.isOpen) return false;
      if (discoveryHighlyRatedOnly && shop.rating < 4.5) return false;
      if (discoveryCategoryId != null &&
          !shop.services.any(
            (service) => service.categoryId == discoveryCategoryId,
          )) {
        return false;
      }
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

  List<PublicBarbershop> get favoriteBarbershops => publicBarbershops
      .where((shop) => _favoriteShopIds.contains(shop.identity.id))
      .toList();

  bool isFavorite(String shopId) => _favoriteShopIds.contains(shopId);

  bool isFavoriteUpdating(String shopId) => _favoriteUpdates.contains(shopId);

  List<ServiceCategory> get discoveryCategories {
    const order = ['corte', 'barba', 'combo', 'infantil', 'premium'];
    final items = List<ServiceCategory>.of(categories);
    items.sort((a, b) {
      final aIndex = order.indexOf(_normalizedSearch(a.name));
      final bIndex = order.indexOf(_normalizedSearch(b.name));
      return (aIndex < 0 ? order.length : aIndex)
          .compareTo(bIndex < 0 ? order.length : bIndex);
    });
    return items;
  }

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

  List<PublicBarbershop> get openBarbershops =>
      discoveredBarbershops.where((shop) => shop.isOpen).toList();

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
    final source = selectedBarbershop?.services ?? services;
    if (barber == null || barber.serviceIds.isEmpty) return source;
    return source
        .where((service) => barber.serviceIds.contains(service.id))
        .toList();
  }

  Future<void> loadInitialData() async {
    if (isLoading) return;

    isLoading = true;
    discoveryLoadError = null;
    appointmentsLoadError = null;
    favoritesLoadError = null;
    clientProfileError = null;
    notificationsLoadError = null;
    notifyListeners();

    await _teamInvitationRepository.capturePendingInvitation();

    final barbersFuture = _barberRepository.fetchBarbers();
    final categoriesFuture = _barberRepository.fetchCategories();
    final servicesFuture = _barberRepository.fetchServices();
    final appointmentsFuture = _appointmentRepository.fetchAppointments();
    final favoritesFuture = _favoriteRepository.fetchFavoriteShopIds();
    final shopsFuture = _barberRepository.fetchShopIdentities();
    final sessionFuture = AuthService().restoreSession();

    final fetchedBarbers = await barbersFuture;
    final fetchedCategories = await categoriesFuture;
    final fetchedServices = await servicesFuture;
    List<Appointment> fetchedAppointments;
    try {
      fetchedAppointments = await appointmentsFuture;
    } catch (_) {
      fetchedAppointments = const [];
      appointmentsLoadError = 'Não foi possível carregar sua agenda.';
    }
    List<ShopIdentity> fetchedShopIdentities;
    try {
      fetchedShopIdentities = await shopsFuture;
    } catch (_) {
      fetchedShopIdentities = const [];
      discoveryLoadError =
          'Não foi possível carregar as barbearias. Verifique sua conexão.';
    }
    Set<String> fetchedFavoriteIds;
    try {
      fetchedFavoriteIds = await favoritesFuture;
    } catch (_) {
      fetchedFavoriteIds = <String>{};
      favoritesLoadError = 'Não foi possível carregar seus favoritos.';
    }
    final session = await sessionFuture;
    ClientProfile? clientProfile;
    UserAccess userAccess = const UserAccess.client();
    if (session != null) {
      teamInvitationMessage = null;
      teamInvitationError = null;
      try {
        final invitation =
            await _teamInvitationRepository.acceptPendingInvitation();
        if (invitation != null) {
          teamInvitationMessage =
              'Convite aceito. Seu acesso profissional foi liberado.';
        }
      } catch (error) {
        teamInvitationError = _cleanTeamInvitationError(error);
      }
      try {
        clientProfile = await _clientProfileRepository.fetchProfile();
      } catch (_) {
        clientProfileError = 'Não foi possível carregar os dados da conta.';
      }
      try {
        notifications = await _notificationRepository.fetchNotifications();
      } catch (_) {
        notifications = const [];
        notificationsLoadError = 'Não foi possível carregar suas notificações.';
      }
      try {
        userAccess = await _userAccessRepository.fetchAccess();
      } catch (_) {
        userAccess = const UserAccess.client();
      }
    } else {
      notifications = const [];
    }
    final fetchedShopIdentity = fetchedShopIdentities.isNotEmpty
        ? fetchedShopIdentities.first
        : discoveryLoadError != null
            ? null
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
      userNameData: clientProfile?.fullName ?? session?.user.name,
    );
    currentUserEmail = clientProfile?.email ?? session?.user.email;
    currentUserPhone = clientProfile?.phone;
    professionalRoles = userAccess.professionalRoles;
    professionalShopIds = userAccess.shopIds;
    _favoriteShopIds
      ..clear()
      ..addAll(fetchedFavoriteIds);
    await refreshAvailableTimes();

    isLoading = false;
    notifyListeners();
  }

  String _cleanTeamInvitationError(Object error) {
    final message = error.toString();
    final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(message);
    return match?.group(1) ?? 'Não foi possível aceitar o convite.';
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

  void toggleDiscoveryCategory(String categoryId) {
    discoveryCategoryId = discoveryCategoryId == categoryId ? null : categoryId;
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
    discoveryQuery = '';
    discoveryOpenNowOnly = false;
    discoveryHighlyRatedOnly = false;
    discoveryCategoryId = null;
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
    final source = identities;

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
          reviewCount: 0,
          distanceKm: _distanceFromDevice(source[index]),
          nextSlot: source[index].currentHoursDetail,
          isOpen: source[index].isOpenNow,
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
    final shop = selectedBarbershop;
    if (barber == null || service == null || shop == null) return false;
    if (!_selectedDateIsAllowed()) return false;
    final requestedDate = selectedDate;
    final requestedTime = selectedTime;
    await refreshAvailableTimes(preserveSelectedTime: true);
    if (!availableTimes.contains(requestedTime)) return false;

    lastBookingErrorMessage = null;
    try {
      lastBookingRequestCreated =
          await _appointmentRepository.createAppointment(
        barberId: barber.id,
        serviceId: service.id,
        date: requestedDate,
        time: requestedTime,
        total: service.price,
        barberShopId: barber.barberShopId,
        customerName: customerName,
        customerPhone: customerPhone,
        paymentMethodLabel: paymentMethodLabel,
      );
    } catch (error) {
      lastBookingRequestCreated = false;
      final message = error.toString().toLowerCase();
      if (message.contains('cliente bloqueado para agendamentos')) {
        lastBookingErrorMessage =
            'Esta barbearia não está aceitando novos agendamentos para este contato.';
      }
    }

    if (lastBookingRequestCreated) {
      lastBookingReceipt = BookingReceipt(
        shopName: shop.identity.name,
        serviceName: service.name,
        barberName: barber.name,
        date: requestedDate,
        time: requestedTime,
        total: service.price,
      );
      try {
        appointments = await _appointmentRepository.fetchAppointments();
        appointmentsLoadError = null;
      } catch (_) {
        appointmentsLoadError = 'Não foi possível atualizar sua agenda.';
      }
    }
    notifyListeners();
    return lastBookingRequestCreated;
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      final cancelled =
          await _appointmentRepository.cancelAppointment(appointmentId);
      if (cancelled) await refreshAppointments();
      return cancelled;
    } catch (_) {
      return false;
    }
  }

  Future<void> refreshAppointments() async {
    if (isLoadingAppointments) return;
    isLoadingAppointments = true;
    appointmentsLoadError = null;
    notifyListeners();
    try {
      appointments = await _appointmentRepository.fetchAppointments();
    } catch (_) {
      appointmentsLoadError = 'Não foi possível carregar sua agenda.';
    } finally {
      isLoadingAppointments = false;
      notifyListeners();
    }
  }

  Future<void> refreshFavorites() async {
    if (isLoadingFavorites) return;
    isLoadingFavorites = true;
    favoritesLoadError = null;
    notifyListeners();
    try {
      final ids = await _favoriteRepository.fetchFavoriteShopIds();
      _favoriteShopIds
        ..clear()
        ..addAll(ids);
    } catch (_) {
      favoritesLoadError = 'Não foi possível carregar seus favoritos.';
    } finally {
      isLoadingFavorites = false;
      notifyListeners();
    }
  }

  Future<void> refreshClientProfile() async {
    if (!isSignedIn || isLoadingClientProfile) return;
    isLoadingClientProfile = true;
    clientProfileError = null;
    notifyListeners();
    try {
      final profile = await _clientProfileRepository.fetchProfile();
      if (profile != null) {
        currentUserName = profile.fullName;
        currentUserEmail = profile.email;
        currentUserPhone = profile.phone;
      }
    } catch (_) {
      clientProfileError = 'Não foi possível carregar os dados da conta.';
    } finally {
      isLoadingClientProfile = false;
      notifyListeners();
    }
  }

  Future<void> refreshNotifications() async {
    if (!isSignedIn || isLoadingNotifications) return;
    isLoadingNotifications = true;
    notificationsLoadError = null;
    notifyListeners();
    try {
      notifications = await _notificationRepository.fetchNotifications();
    } catch (_) {
      notificationsLoadError = 'Não foi possível carregar suas notificações.';
    } finally {
      isLoadingNotifications = false;
      notifyListeners();
    }
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    final index = notifications.indexWhere((item) => item.id == notificationId);
    if (index < 0 || notifications[index].isRead) return true;
    try {
      final updated = await _notificationRepository.markAsRead(notificationId);
      if (!updated) return false;
      final item = notifications[index];
      notifications = List.of(notifications)
        ..[index] = NotificationItem(
          id: item.id,
          title: item.title,
          message: item.message,
          isRead: true,
          createdAt: item.createdAt,
        );
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead() async {
    if (unreadNotificationCount == 0) return true;
    try {
      final updated = await _notificationRepository.markAllAsRead();
      if (!updated) return false;
      notifications = notifications
          .map(
            (item) => NotificationItem(
              id: item.id,
              title: item.title,
              message: item.message,
              isRead: true,
              createdAt: item.createdAt,
            ),
          )
          .toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateClientProfile({
    required String fullName,
    required String phone,
  }) async {
    if (!isSignedIn || isLoadingClientProfile) return false;
    isLoadingClientProfile = true;
    clientProfileError = null;
    notifyListeners();
    try {
      final updated = await _clientProfileRepository.updateProfile(
        fullName: fullName,
        phone: phone,
      );
      if (updated) {
        currentUserName = fullName.trim();
        currentUserPhone = phone.trim();
      }
      return updated;
    } catch (_) {
      clientProfileError = 'Não foi possível salvar seus dados.';
      return false;
    } finally {
      isLoadingClientProfile = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await AuthService().signOut();
    isSignedIn = false;
    currentUserName = null;
    currentUserEmail = null;
    currentUserPhone = null;
    professionalRoles = const <String>{};
    professionalShopIds = const <String>{};
    appointments = const [];
    notifications = const [];
    _favoriteShopIds.clear();
    notifyListeners();
  }

  Future<bool> toggleFavorite(PublicBarbershop shop) async {
    final shopId = shop.identity.id;
    if (!isSignedIn || shopId.isEmpty || _favoriteUpdates.contains(shopId)) {
      return false;
    }
    _favoriteUpdates.add(shopId);
    favoritesLoadError = null;
    notifyListeners();
    try {
      final removing = _favoriteShopIds.contains(shopId);
      final success = removing
          ? await _favoriteRepository.removeFavorite(shopId)
          : await _favoriteRepository.addFavorite(shopId);
      if (!success) return false;
      if (removing) {
        _favoriteShopIds.remove(shopId);
      } else {
        _favoriteShopIds.add(shopId);
      }
      return true;
    } catch (_) {
      favoritesLoadError = 'Não foi possível atualizar o favorito.';
      return false;
    } finally {
      _favoriteUpdates.remove(shopId);
      notifyListeners();
    }
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

  Future<void> refreshAvailableTimes(
      {bool preserveSelectedTime = false}) async {
    final requestId = ++_availabilityRequestId;
    final barber = selectedBarber;
    final service = selectedService;
    if (barber == null || service == null) {
      availableTimes = const [];
      availabilityError = null;
      notifyListeners();
      return;
    }

    isLoadingAvailability = true;
    availabilityError = null;
    availableTimes = const [];
    final previousSelectedTime = selectedTime;
    if (!preserveSelectedTime) selectedTime = '';
    notifyListeners();
    try {
      final times = await _appointmentRepository.fetchAvailableTimes(
        barberId: barber.id,
        barberShopId: barber.barberShopId,
        date: selectedDate,
        durationMinutes: service.durationMinutes,
      );
      if (requestId != _availabilityRequestId) return;
      availableTimes = _filterTimesBySettings(times);
      selectedTime = preserveSelectedTime
          ? previousSelectedTime
          : availableTimes.isEmpty
              ? ''
              : availableTimes.first;
    } catch (_) {
      if (requestId != _availabilityRequestId) return;
      availableTimes = const [];
      availabilityError = 'Não foi possível consultar os horários.';
    } finally {
      if (requestId == _availabilityRequestId) {
        isLoadingAvailability = false;
        notifyListeners();
      }
    }
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

class BookingReceipt {
  const BookingReceipt({
    required this.shopName,
    required this.serviceName,
    required this.barberName,
    required this.date,
    required this.time,
    required this.total,
  });

  final String shopName;
  final String serviceName;
  final String barberName;
  final DateTime date;
  final String time;
  final double total;
}
