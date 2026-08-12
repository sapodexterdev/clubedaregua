part of 'management.dart';

class ManagementSession extends ChangeNotifier {
  ManagementSession({AuthService? authService, http.Client? httpClient})
      : _authService = authService ?? AuthService(),
        _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  final AuthService _authService;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  var _disposed = false;
  var _refreshGeneration = 0;
  var _activeRole = ManagementRole.barber;
  var _barberRequestsLoaded = false;
  var _ownerRequestsLoaded = false;
  var _teamLoaded = false;
  var _availabilityLoaded = false;
  var _scheduleLoaded = false;
  var _servicesLoaded = false;
  var _customersLoaded = false;
  var _settingsLoaded = false;
  String? _accessToken;
  String? _userId;
  String? _barberShopId;
  bool _isPlatformAdmin = false;
  bool _isShopOwner = false;
  bool _isLinkedBarber = false;
  String? _membershipRole;
  String? barberShopName;
  String? email;
  bool isLoading = false;
  bool isRestoringSession = true;
  String? errorMessage;
  bool isBookingRequestsLoading = false;
  String? bookingRequestsError;
  String? bookingRequestActionError;
  List<BookingRequest> bookingRequests = [];
  List<TeamBarber> teamBarbers = [];
  List<ScheduleEntry> scheduleEntries = [];
  List<ManagedService> services = [];
  List<ServiceCategory> serviceCategories = [];
  List<ManagedCustomer> customers = [];
  List<CustomerAppointment> customerAppointments = [];
  ShopConfiguration? shopConfiguration;
  bool isScheduleLoading = false;
  bool isAvailabilityLoading = false;
  bool isAvailabilitySaving = false;
  bool isServicesLoading = false;
  bool isCustomersLoading = false;
  bool isSettingsLoading = false;
  String? scheduleError;
  String? availabilityError;
  String? servicesError;
  String? customersError;
  String? settingsError;
  DateTime selectedScheduleDate = DateTime.now();
  String? selectedScheduleBarberId;
  bool scheduleAdminView = false;
  List<BarberAvailabilityDay> weeklyAvailability =
      BarberAvailabilityDay.defaults();
  ServiceStatusFilter serviceStatusFilter = ServiceStatusFilter.all;
  CustomerStatusFilter customerStatusFilter = CustomerStatusFilter.all;
  String? selectedServiceCategoryId;
  String serviceSearchQuery = '';
  String customerSearchQuery = '';

  bool get isSignedIn => _accessToken != null;
  bool get professionalAccessResolved =>
      !isSignedIn || _professionalAccessResolved;
  bool get canWorkAsBarber => _isLinkedBarber || _membershipRole == 'barber';
  bool get canManageShop =>
      _isPlatformAdmin ||
      _isShopOwner ||
      _membershipRole == 'owner' ||
      _membershipRole == 'manager';
  bool get canManageCustomerBlocks =>
      _isPlatformAdmin || _isShopOwner || _membershipRole == 'owner';
  bool get hasProfessionalAccess => canWorkAsBarber || canManageShop;

  bool _professionalAccessResolved = false;

  Future<void> restoreUnifiedSession({
    ManagementRole initialRole = ManagementRole.barber,
  }) async {
    _activeRole = initialRole;
    try {
      final session = await _authService.getValidSession();
      if (session == null) {
        _clearSessionInMemory();
        return;
      }
      _applyAuthSession(session);
      _professionalAccessResolved = false;
      await _loadRestoredManagementData();
    } catch (error) {
      _clearSessionInMemory();
      errorMessage = 'Sua conta não possui acesso profissional ativo.';
    } finally {
      isRestoringSession = false;
      notifyListeners();
    }
  }

  Future<void> _loadRestoredManagementData() async {
    final token = _accessToken;
    if (token == null || token.isEmpty) return;

    try {
      await _resolvePlatformAdmin(token).timeout(const Duration(seconds: 8));
      if (_disposed) return;
      await _ensureBarberShopId(token).timeout(const Duration(seconds: 8));
      if (_disposed) return;
      await _resolveShopCapabilities(token).timeout(const Duration(seconds: 8));
      if (_disposed) return;
      _activeRole = _effectiveRole(_activeRole);
      await refreshManagementData();
    } catch (error) {
      errorMessage = _cleanErrorMessage(error);
    } finally {
      _professionalAccessResolved = true;
      notifyListeners();
    }
  }

  TeamBarber? get currentBarber {
    final userId = _userId;
    if (userId != null && userId.isNotEmpty) {
      for (final barber in teamBarbers) {
        if (barber.userId == userId && barber.isActive) return barber;
      }
    }

    return null;
  }

  List<BookingRequest> get currentBarberBookingRequests {
    final barberId = currentBarber?.id;
    if (barberId == null || barberId.isEmpty) return const [];
    return bookingRequests
        .where((request) => request.barberId == barberId)
        .toList();
  }

  String get barberHeaderName =>
      currentBarber?.name ?? barberShopName ?? 'Agenda do barbeiro';

  TeamBarber? get selectedScheduleBarber {
    final id = selectedScheduleBarberId;
    if (id == null || id.isEmpty) return null;
    for (final barber in teamBarbers) {
      if (barber.id == id) return barber;
    }
    return null;
  }

  List<ManagedService> get filteredServices {
    final query = serviceSearchQuery.trim().toLowerCase();
    return services.where((service) {
      final matchesStatus = switch (serviceStatusFilter) {
        ServiceStatusFilter.all => true,
        ServiceStatusFilter.active => service.isActive,
        ServiceStatusFilter.inactive => !service.isActive,
      };
      final matchesCategory = selectedServiceCategoryId == null ||
          selectedServiceCategoryId == service.categoryId;
      final matchesSearch =
          query.isEmpty || service.name.toLowerCase().contains(query);
      return matchesStatus && matchesCategory && matchesSearch;
    }).toList()
      ..sort((a, b) {
        final status = b.isActive.toString().compareTo(a.isActive.toString());
        if (status != 0) return status;
        return a.name.compareTo(b.name);
      });
  }

  List<ManagedCustomer> get filteredCustomers {
    final query = customerSearchQuery.trim().toLowerCase();
    return customers.where((customer) {
      final matchesStatus = switch (customerStatusFilter) {
        CustomerStatusFilter.all => true,
        CustomerStatusFilter.active => customer.isActive,
        CustomerStatusFilter.inactive => !customer.isActive,
        CustomerStatusFilter.recent => customer.isRecent,
      };
      final matchesSearch = query.isEmpty ||
          customer.name.toLowerCase().contains(query) ||
          customer.phone.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> signIn(String emailValue, String password) async {
    if (!SupabaseConfig.isConfigured) {
      errorMessage = 'Configure SUPABASE_URL e SUPABASE_ANON_KEY.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final session = await _authService.signIn(emailValue, password);
      _applyAuthSession(session);
      await _resolvePlatformAdmin(_accessToken!);
      await _ensureBarberShopId(_accessToken!);
      await _resolveShopCapabilities(_accessToken!);
      if (!hasProfessionalAccess) {
        throw StateError('Sua conta não possui acesso profissional ativo.');
      }
      _professionalAccessResolved = true;
      _activeRole = _effectiveRole(_activeRole);
      await refreshManagementData();
    } catch (error) {
      _accessToken = null;
      errorMessage = _cleanErrorMessage(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshManagementData() async {
    final generation = ++_refreshGeneration;
    await fetchTeamBarbers();
    if (!_isRefreshActive(generation)) return;
    await fetchBookingRequests(
      adminView: _activeRole == ManagementRole.admin,
    );
  }

  Future<void> activateRole(ManagementRole role) async {
    _activeRole = _effectiveRole(role);
    await ensureDataForTab(_activeRole, 0);
  }

  Future<void> ensureDataForTab(
    ManagementRole role,
    int tabIndex, {
    bool force = false,
  }) async {
    _activeRole = _effectiveRole(role);
    if (_disposed) return;

    if (_activeRole == ManagementRole.barber) {
      switch (tabIndex) {
        case 0:
          if (force || !_barberRequestsLoaded) {
            await fetchBookingRequests(adminView: false);
          }
        case 1:
          if (force || !_scheduleLoaded) await fetchScheduleEntries();
        case 2:
          if (force || !_availabilityLoaded) {
            await fetchWeeklyAvailability();
          }
        case 3:
          if (force || !_customersLoaded) await fetchCustomers();
        default:
          return;
      }
      return;
    }

    switch (tabIndex) {
      case 0:
        if (force || !_ownerRequestsLoaded) {
          await fetchBookingRequests(adminView: true);
        }
      case 2:
        if (force || !_scheduleLoaded) await fetchScheduleEntries();
      case 3:
        if (force || !_servicesLoaded) await fetchServiceCatalog();
      case 4:
        if (force || !_teamLoaded) await fetchTeamBarbers();
      case 5:
        if (force || !_customersLoaded) await fetchCustomers();
      case 7:
        if (force || !_settingsLoaded) await fetchShopConfiguration();
      default:
        return;
    }
  }

  ManagementRole _effectiveRole(ManagementRole requested) {
    if (requested == ManagementRole.admin && canManageShop) {
      return ManagementRole.admin;
    }
    if (requested == ManagementRole.barber && canWorkAsBarber) {
      return ManagementRole.barber;
    }
    return canManageShop ? ManagementRole.admin : ManagementRole.barber;
  }

  bool _isRefreshActive(int generation) =>
      !_disposed && generation == _refreshGeneration;

  Future<void> fetchBookingRequests({bool? adminView}) async {
    final token = _accessToken;
    if (token == null) return;
    final loadAdminView = adminView ?? _activeRole == ManagementRole.admin;

    isBookingRequestsLoading = true;
    bookingRequestsError = null;
    notifyListeners();

    try {
      final shopId = await _ensureBarberShopId(token);
      final query = <String, String>{
        'select':
            'id,barber_id,customer_name,customer_phone,requested_date,requested_time,status,total_price,notes,updated_at,barbers(name),services(name)',
        'barber_shop_id': 'eq.$shopId',
        'order': 'created_at.desc',
        'limit': loadAdminView ? '200' : '50',
      };
      if (!loadAdminView) {
        final barberId = currentBarber?.id;
        if (barberId == null || barberId.isEmpty) {
          bookingRequests = [];
          _barberRequestsLoaded = true;
          _ownerRequestsLoaded = false;
          return;
        }
        query['barber_id'] = 'eq.$barberId';
      }
      final rows = await _getRestRows(
        token,
        'booking_requests',
        query: query,
      );
      if (_disposed) return;
      bookingRequests = rows.map((row) => BookingRequest.fromMap(row)).toList();
      if (loadAdminView) {
        _ownerRequestsLoaded = true;
        _barberRequestsLoaded = true;
      } else {
        _barberRequestsLoaded = true;
        _ownerRequestsLoaded = false;
      }
      bookingRequestsError = null;
    } catch (error) {
      bookingRequestsError = _cleanErrorMessage(error);
    } finally {
      isBookingRequestsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTeamBarbers() async {
    final token = _accessToken;
    if (token == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final shopId = await _ensureBarberShopId(token);
      final rows = await _getRestRows(
        token,
        'barbers',
        query: {
          'select':
              'id,barber_shop_id,user_id,name,bio,photo_url,starting_price,commission_percent,is_active',
          'barber_shop_id': 'eq.$shopId',
          'order': 'name.asc',
        },
      );
      teamBarbers = rows.map(TeamBarber.fromMap).toList();
      _teamLoaded = true;
      errorMessage = null;
    } catch (error) {
      errorMessage = _cleanErrorMessage(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWeeklyAvailability() async {
    final token = _accessToken;
    final barber = currentBarber;
    if (token == null || barber == null) {
      weeklyAvailability = BarberAvailabilityDay.defaults();
      return;
    }

    isAvailabilityLoading = true;
    availabilityError = null;
    notifyListeners();

    try {
      final rows = await _getRestRows(
        token,
        'schedules',
        query: {
          'select': 'weekday,start_time,end_time,slot_minutes,is_active',
          'barber_id': 'eq.${barber.id}',
          'order': 'weekday.asc,start_time.asc',
        },
      );
      final byWeekday = <int, Map<String, dynamic>>{};
      for (final row in rows) {
        final weekday = (row['weekday'] as num?)?.toInt();
        if (weekday != null) byWeekday.putIfAbsent(weekday, () => row);
      }
      weeklyAvailability = [
        for (final fallback in BarberAvailabilityDay.defaults())
          if (byWeekday[fallback.weekday] case final row?)
            BarberAvailabilityDay(
              weekday: fallback.weekday,
              label: fallback.label,
              isActive: row['is_active'] != false,
              startTime: _managementTime(row['start_time'], fallback.startTime),
              endTime: _managementTime(row['end_time'], fallback.endTime),
              slotMinutes: (row['slot_minutes'] as num?)?.toInt() ??
                  fallback.slotMinutes,
            )
          else
            fallback.copyWith(isActive: false),
      ];
      _availabilityLoaded = true;
    } catch (error) {
      availabilityError = _cleanErrorMessage(error);
    } finally {
      isAvailabilityLoading = false;
      notifyListeners();
    }
  }

  void updateAvailabilityDay(BarberAvailabilityDay updated) {
    weeklyAvailability = [
      for (final day in weeklyAvailability)
        if (day.weekday == updated.weekday) updated else day,
    ];
    availabilityError = null;
    notifyListeners();
  }

  Future<void> saveWeeklyAvailability() async {
    final token = _accessToken;
    final barber = currentBarber;
    if (token == null || barber == null) {
      throw StateError('Não foi possível identificar o barbeiro.');
    }
    for (final day in weeklyAvailability.where((day) => day.isActive)) {
      if (_minutesFromTime(day.endTime) <= _minutesFromTime(day.startTime)) {
        throw StateError(
          'Em ${day.label}, o horário final deve ser depois do inicial.',
        );
      }
    }

    isAvailabilitySaving = true;
    availabilityError = null;
    notifyListeners();
    try {
      await _postRpc(
        token,
        'replace_barber_weekly_schedule',
        data: {
          'p_barber_id': barber.id,
          'p_days': [
            for (final day in weeklyAvailability)
              {
                'weekday': day.weekday,
                'is_active': day.isActive,
                'start_time': day.startTime,
                'end_time': day.endTime,
                'slot_minutes': day.slotMinutes,
              },
          ],
        },
      );
      await fetchWeeklyAvailability();
    } catch (error) {
      availabilityError = _cleanErrorMessage(error);
      rethrow;
    } finally {
      isAvailabilitySaving = false;
      notifyListeners();
    }
  }

  Future<void> setScheduleAdminView(bool value) async {
    if (scheduleAdminView == value) return;
    scheduleAdminView = value;
    if (!value) selectedScheduleBarberId = null;
    notifyListeners();
    await fetchScheduleEntries();
  }

  Future<void> selectScheduleDate(DateTime date) async {
    selectedScheduleDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
    await fetchScheduleEntries();
  }

  Future<void> selectScheduleBarber(String? barberId) async {
    selectedScheduleBarberId = barberId;
    notifyListeners();
    await fetchScheduleEntries();
  }

  Future<void> fetchScheduleEntries() async {
    final token = _accessToken;
    if (token == null) return;

    isScheduleLoading = true;
    scheduleError = null;
    notifyListeners();

    try {
      final shopId = await _ensureBarberShopId(token);
      final barberId = scheduleAdminView
          ? selectedScheduleBarberId
          : currentBarber?.id ?? selectedScheduleBarberId;
      final date = _dateOnly(selectedScheduleDate);
      final start = DateTime(
        selectedScheduleDate.year,
        selectedScheduleDate.month,
        selectedScheduleDate.day,
      );
      final end = start.add(const Duration(days: 1));

      final requestQuery = <String, String>{
        'select':
            'id,customer_name,requested_date,requested_time,status,notes,barbers(name),services(name)',
        'barber_shop_id': 'eq.$shopId',
        'requested_date': 'eq.$date',
        'status': 'eq.converted',
        'appointment_id': 'is.null',
        'order': 'requested_time.asc',
      };
      if (barberId != null && barberId.isNotEmpty) {
        requestQuery['barber_id'] = 'eq.$barberId';
      }

      final appointmentQuery = <String, String>{
        'select': 'id,starts_at,status,notes,barbers(name),services(name)',
        'barber_shop_id': 'eq.$shopId',
        'starts_at': 'gte.${start.toIso8601String()}',
        'ends_at': 'lt.${end.toIso8601String()}',
        'order': 'starts_at.asc',
      };
      if (barberId != null && barberId.isNotEmpty) {
        appointmentQuery['barber_id'] = 'eq.$barberId';
      }

      final requests = await _getRestRows(
        token,
        'booking_requests',
        query: requestQuery,
      );
      final appointments = await _getRestRows(
        token,
        'appointments',
        query: appointmentQuery,
      );

      scheduleEntries = [
        ...requests.map(ScheduleEntry.fromBookingRequest),
        ...appointments.map(ScheduleEntry.fromAppointment),
      ]..sort((a, b) => a.time.compareTo(b.time));
      _scheduleLoaded = true;
      scheduleError = null;
    } catch (error) {
      scheduleError = _cleanErrorMessage(error);
    } finally {
      isScheduleLoading = false;
      notifyListeners();
    }
  }

  void setServiceStatusFilter(ServiceStatusFilter filter) {
    serviceStatusFilter = filter;
    notifyListeners();
  }

  void setServiceCategoryFilter(String? categoryId) {
    selectedServiceCategoryId = categoryId;
    notifyListeners();
  }

  void setServiceSearchQuery(String value) {
    serviceSearchQuery = value;
    notifyListeners();
  }

  void setCustomerStatusFilter(CustomerStatusFilter filter) {
    customerStatusFilter = filter;
    notifyListeners();
  }

  void setCustomerSearchQuery(String value) {
    customerSearchQuery = value;
    notifyListeners();
  }

  List<CustomerAppointment> appointmentsForCustomer(String clientId) {
    return customerAppointments
        .where((appointment) => appointment.clientId == clientId)
        .toList()
      ..sort((a, b) {
        final aDate = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
  }

  Future<void> fetchCustomers() async {
    final token = _accessToken;
    if (token == null) return;

    isCustomersLoading = true;
    customersError = null;
    notifyListeners();

    try {
      final shopId = await _ensureBarberShopId(token);
      final rows = await _getRestRows(
        token,
        'management_clients',
        query: {
          'select':
              'relationship_id,barber_shop_id,client_id,first_seen_at,last_appointment_at,notes,is_blocked,email,user_is_active,full_name,phone,avatar_url,profile_created_at',
          'barber_shop_id': 'eq.$shopId',
          'order': 'full_name.asc',
          'limit': '500',
        },
      );
      final appointmentRows = await _getRestRows(
        token,
        'management_client_appointments',
        query: {
          'select':
              'id,client_id,starts_at,status,notes,service_name,barber_name',
          'barber_shop_id': 'eq.$shopId',
          'order': 'starts_at.desc',
          'limit': '500',
        },
      );
      final bookingRows = await _getRestRows(
        token,
        'booking_requests',
        query: {
          'select':
              'id,customer_name,customer_phone,requested_date,requested_time,status,notes,created_at,barbers(name),services(name)',
          'barber_shop_id': 'eq.$shopId',
          'order': 'created_at.desc',
          'limit': '500',
        },
      );
      final blockRows = canManageCustomerBlocks
          ? await _getRestRows(
              token,
              'client_booking_blocks',
              query: {
                'select': 'client_id,customer_phone_digits,barber_id',
                'barber_shop_id': 'eq.$shopId',
              },
            )
          : const <Map<String, dynamic>>[];
      if (_disposed) return;
      customerAppointments = [
        ...appointmentRows.map(CustomerAppointment.fromMap),
        ...bookingRows.map(CustomerAppointment.fromBookingRequest),
      ];

      final appointmentCounts = <String, int>{};
      final barberCounts = <String, Map<String, int>>{};
      final lastAppointments = <String, DateTime>{};
      for (final appointment in customerAppointments) {
        appointmentCounts[appointment.clientId] =
            (appointmentCounts[appointment.clientId] ?? 0) + 1;
        final byBarber =
            barberCounts.putIfAbsent(appointment.clientId, () => {});
        byBarber[appointment.barber] = (byBarber[appointment.barber] ?? 0) + 1;
        final date = appointment.date;
        if (date != null) {
          final current = lastAppointments[appointment.clientId];
          if (current == null || date.isAfter(current)) {
            lastAppointments[appointment.clientId] = date;
          }
        }
      }

      final relationshipCustomers = rows
          .map((row) {
            final clientId = row['client_id']?.toString() ?? '';
            final favoriteBarber = _favoriteBarber(barberCounts[clientId]);
            return ManagedCustomer.fromMap(
              row,
              appointmentCount: appointmentCounts[clientId] ?? 0,
              favoriteBarber: favoriteBarber,
              computedLastAppointmentAt: lastAppointments[clientId],
            );
          })
          .where((customer) => customer.clientId.isNotEmpty)
          .toList();

      final relationshipPhones = relationshipCustomers
          .map((customer) => ManagedCustomer._digitsOnly(customer.phone))
          .where((phone) => phone.isNotEmpty)
          .toSet();
      final bookingCustomersByPhone = <String, ManagedCustomer>{};
      for (final row in bookingRows) {
        final phone = ManagedCustomer._digitsOnly(
          row['customer_phone']?.toString() ?? '',
        );
        if (phone.isEmpty || relationshipPhones.contains(phone)) continue;
        final clientId = 'booking:$phone';
        final existing = bookingCustomersByPhone[phone];
        final favoriteBarber = _favoriteBarber(barberCounts[clientId]);
        final next = ManagedCustomer.fromBookingRequest(
          row,
          appointmentCount: appointmentCounts[clientId] ?? 0,
          favoriteBarber: favoriteBarber,
          computedLastAppointmentAt: lastAppointments[clientId],
        );
        if (existing == null ||
            (next.lastAppointmentAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .isAfter(existing.lastAppointmentAt ??
                    DateTime.fromMillisecondsSinceEpoch(0))) {
          bookingCustomersByPhone[phone] = next;
        }
      }

      final loadedCustomers = [
        ...relationshipCustomers,
        ...bookingCustomersByPhone.values,
      ];
      customers = canManageCustomerBlocks
          ? [
              for (final customer in loadedCustomers)
                _customerWithBookingBlocks(customer, blockRows),
            ]
          : loadedCustomers;
      _customersLoaded = true;
      customersError = null;
    } catch (error) {
      customersError = _cleanErrorMessage(error);
    } finally {
      isCustomersLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCustomer(
    ManagedCustomer customer, {
    required String name,
    required String phone,
    required String notes,
  }) async {
    final token = _accessToken;
    if (token == null) return;

    isCustomersLoading = true;
    customersError = null;
    notifyListeners();

    try {
      await _patchRestRows(
        token,
        'profiles',
        query: {'user_id': 'eq.${customer.clientId}'},
        data: {
          'full_name': name.trim(),
          'phone': phone.trim().isEmpty ? null : phone.trim(),
        },
      );
      await _patchRestRows(
        token,
        'client_shop_relationships',
        query: {'id': 'eq.${customer.relationshipId}'},
        data: {
          'notes': notes.trim().isEmpty ? null : notes.trim(),
        },
      );

      customers = [
        for (final item in customers)
          if (item.clientId == customer.clientId)
            item.copyWith(
              name: name.trim(),
              phone: phone.trim(),
              notes: notes.trim(),
            )
          else
            item,
      ];
      customersError = null;
    } catch (error) {
      customersError = _cleanErrorMessage(error);
      rethrow;
    } finally {
      isCustomersLoading = false;
      notifyListeners();
    }
  }

  ManagedCustomer _customerWithBookingBlocks(
    ManagedCustomer customer,
    List<Map<String, dynamic>> blockRows,
  ) {
    final phoneDigits = ManagedCustomer._digitsOnly(customer.phone);
    final matching = blockRows.where((row) {
      final clientId = row['client_id']?.toString() ?? '';
      final blockedPhone = row['customer_phone_digits']?.toString() ?? '';
      return (clientId.isNotEmpty && clientId == customer.clientId) ||
          (phoneDigits.isNotEmpty && blockedPhone == phoneDigits);
    });
    final barberIds = matching
        .map((row) => row['barber_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    return customer.copyWith(
      isBlocked: matching.any((row) => row['barber_id'] == null),
      blockedBarberIds: barberIds,
    );
  }

  Future<void> setCustomerBookingBlock(
    ManagedCustomer customer, {
    required bool blocked,
    Set<String> barberIds = const {},
  }) async {
    final token = _accessToken;
    if (token == null) {
      throw StateError('Sua sessão expirou. Entre novamente.');
    }
    if (!canManageCustomerBlocks) {
      throw StateError('Somente o dono pode bloquear agendamentos.');
    }

    final shopId = await _ensureBarberShopId(token);
    await _postRpc(
      token,
      'set_client_booking_blocks',
      data: {
        'p_barber_shop_id': shopId,
        'p_client_id':
            customer.clientId.startsWith('booking:') ? null : customer.clientId,
        'p_customer_phone': customer.phone,
        'p_barber_ids': blocked ? barberIds.toList() : <String>[],
        'p_blocked': blocked,
      },
    );

    customers = [
      for (final item in customers)
        if (item.clientId == customer.clientId)
          item.copyWith(
            isBlocked: blocked && barberIds.isEmpty,
            blockedBarberIds: blocked ? barberIds : <String>{},
          )
        else
          item,
    ];
    notifyListeners();
  }

  String _favoriteBarber(Map<String, int>? counts) {
    if (counts == null || counts.isEmpty) return 'Não definido';
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  Future<void> fetchShopConfiguration() async {
    final token = _accessToken;
    if (token == null) return;

    isSettingsLoading = true;
    settingsError = null;
    notifyListeners();

    try {
      final shopId = await _ensureBarberShopId(token);
      final shops = await _getRestRows(
        token,
        'barber_shops',
        query: {
          'select':
              'id,name,document,phone,whatsapp,address,city,state,logo_url,cover_url,opening_time,closing_time',
          'id': 'eq.$shopId',
          'limit': '1',
        },
      );
      if (shops.isEmpty) {
        throw StateError('Barbearia não encontrada.');
      }

      final settingsRows = await _getRestRows(
        token,
        'shop_settings',
        query: {
          'select': 'id,booking_interval_minutes,min_cancel_hours,settings',
          'barber_shop_id': 'eq.$shopId',
          'limit': '1',
        },
      );

      shopConfiguration = ShopConfiguration.fromRows(
        shop: shops.first,
        settings: settingsRows.isEmpty ? null : settingsRows.first,
      );
      barberShopName = shopConfiguration?.name;
      _settingsLoaded = true;
      settingsError = null;
    } catch (error) {
      settingsError = _cleanErrorMessage(error);
    } finally {
      isSettingsLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveShopConfiguration(
    ShopConfiguration config, {
    bool applyHoursToTeam = false,
  }) async {
    final token = _accessToken;
    if (token == null) return;

    isSettingsLoading = true;
    settingsError = null;
    notifyListeners();

    try {
      await _patchRestRows(
        token,
        'barber_shops',
        query: {'id': 'eq.${config.shopId}'},
        data: {
          'name': config.name.trim(),
          'document':
              config.document.trim().isEmpty ? null : config.document.trim(),
          'phone': config.phone.trim().isEmpty ? null : config.phone.trim(),
          'whatsapp':
              config.whatsapp.trim().isEmpty ? null : config.whatsapp.trim(),
          'address':
              config.address.trim().isEmpty ? null : config.address.trim(),
          'city': config.city.trim().isEmpty ? null : config.city.trim(),
          'state': config.state.trim().isEmpty ? null : config.state.trim(),
          'logo_url':
              config.logoUrl.trim().isEmpty ? null : config.logoUrl.trim(),
          'cover_url':
              config.coverUrl.trim().isEmpty ? null : config.coverUrl.trim(),
          'opening_time': _firstOpenTime(config.days),
          'closing_time': _lastCloseTime(config.days),
        },
      );

      final settingsData = {
        'barber_shop_id': config.shopId,
        'booking_interval_minutes': config.bookingIntervalMinutes,
        'min_cancel_hours': config.minCancelHours,
        'settings': config.settingsJson(),
      };
      if (config.settingsId.isEmpty) {
        await _postRestRows(token, 'shop_settings', data: settingsData);
      } else {
        await _patchRestRows(
          token,
          'shop_settings',
          query: {'id': 'eq.${config.settingsId}'},
          data: settingsData,
        );
      }

      if (applyHoursToTeam) {
        final activeBarbers =
            teamBarbers.where((barber) => barber.isActive).toList();
        for (final barber in activeBarbers) {
          await _postRpc(
            token,
            'replace_barber_weekly_schedule',
            data: {
              'p_barber_id': barber.id,
              'p_days': [
                for (final day in config.days)
                  {
                    'weekday': _weekdayForBusinessDay(day.key),
                    'is_active': day.isOpen,
                    'start_time': day.openTime,
                    'end_time': day.closeTime,
                    'slot_minutes': config.bookingIntervalMinutes,
                  },
              ],
            },
          );
        }
        await fetchWeeklyAvailability();
      }

      shopConfiguration = config;
      barberShopName = config.name;
      settingsError = null;
    } catch (error) {
      settingsError = _cleanErrorMessage(error);
      rethrow;
    } finally {
      isSettingsLoading = false;
      notifyListeners();
    }
  }

  Future<String> uploadShopMedia(LogoFile file,
      {required String folder}) async {
    final token = _accessToken;
    if (token == null) {
      throw StateError(
        'Sua sessão expirou. Entre novamente para enviar a imagem.',
      );
    }

    final shopId = await _ensureBarberShopId(token);
    final safeFolder = folder
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    final safeName = file.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    final objectPath =
        '$shopId/$safeFolder/${DateTime.now().millisecondsSinceEpoch}-$safeName';
    final uri = Uri.parse(
      '${SupabaseConfig.url}/storage/v1/object/shop-media/$objectPath',
    );

    final response = await http
        .post(
          uri,
          headers: {
            'apikey': SupabaseConfig.anonKey,
            'authorization': 'Bearer $token',
            'content-type': file.contentType,
            'x-upsert': 'true',
          },
          body: file.bytes,
        )
        .timeout(
          const Duration(seconds: 90),
          onTimeout: () => throw StateError(
            'O envio demorou mais que o esperado. Verifique sua conexão e tente novamente.',
          ),
        );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Supabase Storage ${response.statusCode}: ${response.body}');
    }

    return '${SupabaseConfig.url}/storage/v1/object/public/shop-media/$objectPath';
  }

  Future<void> saveShopMediaUrl({
    String? logoUrl,
    String? coverUrl,
  }) async {
    final token = _accessToken;
    if (token == null) {
      throw StateError(
        'Sua sessão expirou. Entre novamente para salvar a imagem.',
      );
    }

    final shopId = await _ensureBarberShopId(token);
    final data = <String, dynamic>{};
    if (logoUrl != null) data['logo_url'] = logoUrl.trim();
    if (coverUrl != null) data['cover_url'] = coverUrl.trim();
    if (data.isEmpty) return;

    await _patchRestRows(
      token,
      'barber_shops',
      query: {'id': 'eq.$shopId'},
      data: data,
    );
  }

  String? _firstOpenTime(List<ShopBusinessDay> days) {
    for (final day in days) {
      if (day.isOpen) return day.openTime;
    }
    return null;
  }

  String? _lastCloseTime(List<ShopBusinessDay> days) {
    for (final day in days.reversed) {
      if (day.isOpen) return day.closeTime;
    }
    return null;
  }

  int _weekdayForBusinessDay(String key) {
    return switch (key) {
      'monday' => 1,
      'tuesday' => 2,
      'wednesday' => 3,
      'thursday' => 4,
      'friday' => 5,
      'saturday' => 6,
      'sunday' => 0,
      _ => throw StateError('Dia de funcionamento inválido: $key'),
    };
  }

  Future<void> fetchServiceCatalog() async {
    final token = _accessToken;
    if (token == null) return;

    isServicesLoading = true;
    servicesError = null;
    notifyListeners();

    try {
      final shopId = await _ensureBarberShopId(token);
      final categories = await _getRestRows(
        token,
        'service_categories',
        query: {
          'select': 'id,name,is_active,sort_order',
          'barber_shop_id': 'eq.$shopId',
          'order': 'sort_order.asc,name.asc',
        },
      );
      serviceCategories = categories
          .map(ServiceCategory.fromMap)
          .where((category) => category.id.isNotEmpty)
          .toList();

      final appointmentRows = await _getRestRows(
        token,
        'appointments',
        query: {
          'select': 'service_id',
          'barber_shop_id': 'eq.$shopId',
          'limit': '500',
        },
      );
      final bookingRequestRows = await _getRestRows(
        token,
        'booking_requests',
        query: {
          'select': 'service_id',
          'barber_shop_id': 'eq.$shopId',
          'limit': '500',
        },
      );
      if (_disposed) return;
      final serviceUsageCounts = <String, int>{};
      for (final row in [...appointmentRows, ...bookingRequestRows]) {
        final id = row['service_id']?.toString();
        if (id == null || id.isEmpty) continue;
        serviceUsageCounts[id] = (serviceUsageCounts[id] ?? 0) + 1;
      }

      final rows = await _getRestRows(
        token,
        'services',
        query: {
          'select':
              'id,category_id,name,description,duration_minutes,price,image_url,is_active,service_categories(name)',
          'barber_shop_id': 'eq.$shopId',
          'order': 'name.asc',
        },
      );
      services = rows
          .map(
            (row) => ManagedService.fromMap(
              row,
              appointmentCount: serviceUsageCounts[row['id']?.toString()] ?? 0,
            ),
          )
          .where((service) => service.id.isNotEmpty)
          .toList();
      _servicesLoaded = true;
      servicesError = null;
    } catch (error) {
      servicesError = _cleanErrorMessage(error);
    } finally {
      isServicesLoading = false;
      notifyListeners();
    }
  }

  Future<void> createService({
    required String name,
    required String description,
    required String? categoryId,
    required double price,
    required int durationMinutes,
    required String imageUrl,
    required bool isActive,
  }) async {
    final token = _accessToken;
    if (token == null) return;

    isServicesLoading = true;
    servicesError = null;
    notifyListeners();

    try {
      final shopId = await _ensureBarberShopId(token);
      final createdRows = await _postRestRows(
        token,
        'services',
        data: {
          'barber_shop_id': shopId,
          'category_id':
              categoryId == null || categoryId.isEmpty ? null : categoryId,
          'name': name.trim(),
          'description': description.trim().isEmpty ? null : description.trim(),
          'duration_minutes': durationMinutes,
          'price': price,
          'image_url': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
          'is_active': isActive,
        },
      );
      final serviceId =
          createdRows.isEmpty ? null : createdRows.first['id']?.toString();
      if (serviceId != null && serviceId.isNotEmpty) {
        for (final barber in teamBarbers.where((item) => item.isActive)) {
          await _postRestRows(
            token,
            'barber_services',
            data: {
              'barber_shop_id': shopId,
              'barber_id': barber.id,
              'service_id': serviceId,
              'is_active': isActive,
            },
          );
        }
      }

      await fetchServiceCatalog();
    } catch (error) {
      servicesError = _cleanErrorMessage(error);
      rethrow;
    } finally {
      isServicesLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateService(
    ManagedService service, {
    required String name,
    required String description,
    required String? categoryId,
    required double price,
    required int durationMinutes,
    required String imageUrl,
    required bool isActive,
  }) async {
    final token = _accessToken;
    if (token == null) return;

    isServicesLoading = true;
    servicesError = null;
    notifyListeners();

    try {
      await _patchRestRows(
        token,
        'services',
        query: {'id': 'eq.${service.id}'},
        data: {
          'category_id':
              categoryId == null || categoryId.isEmpty ? null : categoryId,
          'name': name.trim(),
          'description': description.trim().isEmpty ? null : description.trim(),
          'duration_minutes': durationMinutes,
          'price': price,
          'image_url': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
          'is_active': isActive,
        },
      );

      await fetchServiceCatalog();
    } catch (error) {
      servicesError = _cleanErrorMessage(error);
      rethrow;
    } finally {
      isServicesLoading = false;
      notifyListeners();
    }
  }

  Future<void> deactivateService(ManagedService service) async {
    await updateService(
      service,
      name: service.name,
      description: service.description,
      categoryId: service.categoryId,
      price: service.price,
      durationMinutes: service.durationMinutes,
      imageUrl: service.imageUrl,
      isActive: false,
    );
  }

  Future<void> deleteOrDeactivateService(ManagedService service) async {
    if (service.appointmentCount > 0) {
      await deactivateService(service);
      return;
    }

    final token = _accessToken;
    if (token == null) return;

    isServicesLoading = true;
    servicesError = null;
    notifyListeners();

    try {
      await _deleteRestRows(
        token,
        'services',
        query: {'id': 'eq.${service.id}'},
      );
      services = [
        for (final item in services)
          if (item.id != service.id) item,
      ];
      await fetchServiceCatalog();
    } catch (error) {
      servicesError = _cleanErrorMessage(error);
      rethrow;
    } finally {
      isServicesLoading = false;
      notifyListeners();
    }
  }

  Future<TeamInvitationLink> createTeamBarber({
    required String email,
    required String name,
    required String bio,
    required String photoUrl,
    required double startingPrice,
    required double commissionPercent,
  }) async {
    final token = _accessToken;
    if (token == null) {
      throw StateError('Sua sessão expirou. Entre novamente.');
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final shopId = await _ensureBarberShopId(token);
      final result = await _postRpc(
        token,
        'create_shop_invitation',
        data: {
          'p_barber_shop_id': shopId,
          'p_email': email.trim().toLowerCase(),
          'p_name': name.trim(),
          'p_role': 'barber',
          'p_bio': bio.trim().isEmpty ? null : bio.trim(),
          'p_photo_url': photoUrl.trim().isEmpty ? null : photoUrl.trim(),
          'p_starting_price': startingPrice,
          'p_commission_percent': commissionPercent,
        },
      );

      if (result is! Map) {
        throw StateError('O servidor não retornou o convite criado.');
      }
      final invitation = Map<String, dynamic>.from(result);
      final barberId = invitation['barber_id']?.toString() ?? '';
      final rawInviteToken = invitation['token']?.toString() ?? '';
      if (barberId.isEmpty || rawInviteToken.isEmpty) {
        throw StateError('O convite foi criado sem os dados necessários.');
      }

      final invitedEmail =
          invitation['email']?.toString() ?? email.trim().toLowerCase();
      final inviteUri = Uri.base.replace(
        path: '/',
        queryParameters: {
          'team_invite': rawInviteToken,
          'invite_email': invitedEmail,
        },
        fragment: '',
      );
      String? setupWarning;

      try {
        final rows = await _getRestRows(
          token,
          'barbers',
          query: {
            'select':
                'id,barber_shop_id,user_id,name,bio,photo_url,starting_price,commission_percent,is_active',
            'id': 'eq.$barberId',
            'limit': '1',
          },
        );
        final created = rows.isEmpty ? null : TeamBarber.fromMap(rows.first);
        if (created != null) {
          teamBarbers = [
            for (final item in teamBarbers)
              if (item.id != created.id) item,
            created,
          ]..sort((a, b) => a.name.compareTo(b.name));

          await _postRpc(
            token,
            'replace_barber_weekly_schedule',
            data: {
              'p_barber_id': created.id,
              'p_days': [
                for (final day in BarberAvailabilityDay.defaults())
                  {
                    'weekday': day.weekday,
                    'is_active': day.isActive,
                    'start_time': day.startTime,
                    'end_time': day.endTime,
                    'slot_minutes': day.slotMinutes,
                  },
              ],
            },
          );
          for (final service in services.where((item) => item.isActive)) {
            await _postRestRows(
              token,
              'barber_services',
              data: {
                'barber_shop_id': shopId,
                'barber_id': created.id,
                'service_id': service.id,
                'is_active': true,
              },
            );
          }
        } else {
          setupWarning =
              'O convite foi criado, mas atualize a equipe para conferir o profissional.';
        }
      } catch (error) {
        setupWarning =
            'O convite foi criado. Revise os serviços e horários do profissional antes de liberar a agenda.';
        await fetchTeamBarbers();
      }

      errorMessage = null;
      return TeamInvitationLink(
        email: invitedEmail,
        url: inviteUri.toString(),
        setupWarning: setupWarning,
      );
    } catch (error) {
      errorMessage = _cleanErrorMessage(error);
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTeamBarber(
    TeamBarber barber, {
    required String name,
    required String bio,
    required String photoUrl,
    required double startingPrice,
    required double commissionPercent,
    required bool isActive,
  }) async {
    final token = _accessToken;
    if (token == null) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final rows = await _patchRestRows(
        token,
        'barbers',
        query: {'id': 'eq.${barber.id}'},
        data: {
          'name': name.trim(),
          'bio': bio.trim().isEmpty ? null : bio.trim(),
          'photo_url': photoUrl.trim().isEmpty ? null : photoUrl.trim(),
          'starting_price': startingPrice,
          'commission_percent': commissionPercent,
          'is_active': isActive,
        },
      );

      final updated = rows.isEmpty ? null : TeamBarber.fromMap(rows.first);
      if (updated != null) {
        teamBarbers = [
          for (final item in teamBarbers)
            if (item.id == updated.id) updated else item,
        ]..sort((a, b) => a.name.compareTo(b.name));
      } else {
        await fetchTeamBarbers();
      }
    } catch (error) {
      errorMessage = _cleanErrorMessage(error);
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deactivateTeamBarber(TeamBarber barber) async {
    await updateTeamBarber(
      barber,
      name: barber.name,
      bio: barber.bio,
      photoUrl: barber.photoUrl,
      startingPrice: barber.startingPrice,
      commissionPercent: barber.commissionPercent,
      isActive: false,
    );
  }

  Future<void> updateBookingRequestStatus(
    String id,
    String status, {
    String? reason,
  }) async {
    final token = _accessToken;
    if (token == null) return;

    isBookingRequestsLoading = true;
    bookingRequestActionError = null;
    notifyListeners();

    try {
      if (status == 'converted') {
        await _postRpc(
          token,
          'accept_booking_request',
          data: {'p_request_id': id},
        );
        await fetchBookingRequests();
        await fetchScheduleEntries();
        return;
      }
      final current = _bookingRequestById(id);
      final updatedAt = DateTime.now().toUtc().toIso8601String();
      final nextNotes = _notesWithReason(current?.notes ?? '', reason);
      final rows = await _patchRestRows(
        token,
        'booking_requests',
        query: {'id': 'eq.$id'},
        data: {
          'status': status,
          'updated_at': updatedAt,
          if (reason != null && reason.trim().isNotEmpty) 'notes': nextNotes,
        },
      );

      final updated = rows.isEmpty ? null : BookingRequest.fromMap(rows.first);
      bookingRequests = [
        for (final request in bookingRequests)
          if (request.id == id)
            updated ??
                request.copyWith(
                  status: status,
                  notes: nextNotes,
                  updatedAt: updatedAt,
                )
          else
            request,
      ];
      bookingRequestActionError = null;
      await fetchScheduleEntries();
    } catch (error) {
      final cleanMessage = _cleanErrorMessage(error);
      bookingRequestActionError = cleanMessage;
      throw StateError(cleanMessage);
    } finally {
      isBookingRequestsLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeAppointment(String appointmentId) async {
    final token = _accessToken;
    if (token == null || appointmentId.isEmpty) return;
    isScheduleLoading = true;
    scheduleError = null;
    notifyListeners();
    try {
      await _postRpc(
        token,
        'complete_appointment',
        data: {'p_appointment_id': appointmentId},
      );
      await fetchScheduleEntries();
    } catch (error) {
      scheduleError = _cleanErrorMessage(error);
      rethrow;
    } finally {
      isScheduleLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _clearSessionInMemory();
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _refreshGeneration++;
    if (_ownsHttpClient) _httpClient.close();
    super.dispose();
  }

  void _clearSessionInMemory() {
    _accessToken = null;
    _userId = null;
    _barberShopId = null;
    _isPlatformAdmin = false;
    _isShopOwner = false;
    _isLinkedBarber = false;
    _membershipRole = null;
    _professionalAccessResolved = false;
    barberShopName = null;
    email = null;
    bookingRequests = [];
    bookingRequestsError = null;
    isBookingRequestsLoading = false;
    scheduleEntries = [];
    scheduleError = null;
    isScheduleLoading = false;
    weeklyAvailability = BarberAvailabilityDay.defaults();
    availabilityError = null;
    isAvailabilityLoading = false;
    isAvailabilitySaving = false;
    selectedScheduleBarberId = null;
    scheduleAdminView = false;
    services = [];
    serviceCategories = [];
    servicesError = null;
    isServicesLoading = false;
    serviceStatusFilter = ServiceStatusFilter.all;
    selectedServiceCategoryId = null;
    serviceSearchQuery = '';
    customers = [];
    customerAppointments = [];
    customersError = null;
    isCustomersLoading = false;
    customerStatusFilter = CustomerStatusFilter.all;
    customerSearchQuery = '';
    shopConfiguration = null;
    settingsError = null;
    isSettingsLoading = false;
    teamBarbers = [];
    _barberRequestsLoaded = false;
    _ownerRequestsLoaded = false;
    _teamLoaded = false;
    _availabilityLoaded = false;
    _scheduleLoaded = false;
    _servicesLoaded = false;
    _customersLoaded = false;
    _settingsLoaded = false;
    errorMessage = null;
  }

  void _applyAuthSession(AuthSession session) {
    _accessToken = session.accessToken;
    _userId = session.user.id;
    email = session.user.email;
  }

  BookingRequest? _bookingRequestById(String id) {
    for (final request in bookingRequests) {
      if (request.id == id) return request;
    }
    return null;
  }

  Future<String> _ensureBarberShopId(String token) async {
    if (_barberShopId != null) return _barberShopId!;
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      throw StateError('Usuário sem identificação válida.');
    }

    final memberships = await _getRestRows(
      token,
      'shop_members',
      query: {
        'select': 'barber_shop_id,barber_shops(name)',
        'user_id': 'eq.$userId',
        'is_active': 'eq.true',
        'order': 'created_at.asc',
        'limit': '1',
      },
    );

    if (memberships.isNotEmpty) {
      final membership = memberships.first;
      _barberShopId = membership['barber_shop_id']?.toString();
      final shop = membership['barber_shops'];
      if (shop is Map) barberShopName = shop['name']?.toString();
      if (_barberShopId != null && _barberShopId!.isNotEmpty) {
        return _barberShopId!;
      }
    }

    final linkedBarbers = await _getRestRows(
      token,
      'barbers',
      query: {
        'select': 'barber_shop_id,barber_shops(name)',
        'user_id': 'eq.$userId',
        'is_active': 'eq.true',
        'limit': '1',
      },
    );

    if (linkedBarbers.isNotEmpty) {
      final barber = linkedBarbers.first;
      _barberShopId = barber['barber_shop_id']?.toString();
      final shop = barber['barber_shops'];
      if (shop is Map) barberShopName = shop['name']?.toString();
      if (_barberShopId != null && _barberShopId!.isNotEmpty) {
        return _barberShopId!;
      }
    }

    final shops = await _getRestRows(
      token,
      'barber_shops',
      query: {
        'select': 'id,name',
        if (!_isPlatformAdmin) 'owner_id': 'eq.$userId',
        'order': 'name.asc',
        'limit': '1',
      },
    );

    if (shops.isEmpty) {
      throw StateError('Nenhuma barbearia disponível para este usuário.');
    }

    final shop = shops.first;
    _barberShopId = shop['id']?.toString();
    barberShopName = shop['name']?.toString();
    if (_barberShopId == null || _barberShopId!.isEmpty) {
      throw StateError('Barbearia sem identificador válido.');
    }

    return _barberShopId!;
  }

  Future<void> _resolveShopCapabilities(String token) async {
    final userId = _userId;
    final shopId = _barberShopId;
    if (userId == null || userId.isEmpty || shopId == null || shopId.isEmpty) {
      return;
    }

    final memberships = await _getRestRows(
      token,
      'shop_members',
      query: {
        'select': 'role',
        'barber_shop_id': 'eq.$shopId',
        'user_id': 'eq.$userId',
        'is_active': 'eq.true',
        'limit': '1',
      },
    );
    _membershipRole =
        memberships.isEmpty ? null : memberships.first['role']?.toString();

    final shops = await _getRestRows(
      token,
      'barber_shops',
      query: {
        'select': 'owner_id',
        'id': 'eq.$shopId',
        'limit': '1',
      },
    );
    _isShopOwner =
        shops.isNotEmpty && shops.first['owner_id']?.toString() == userId;

    final barbers = await _getRestRows(
      token,
      'barbers',
      query: {
        'select': 'id',
        'barber_shop_id': 'eq.$shopId',
        'user_id': 'eq.$userId',
        'is_active': 'eq.true',
        'limit': '1',
      },
    );
    _isLinkedBarber = barbers.isNotEmpty;
  }

  Future<void> _resolvePlatformAdmin(String token) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    final rows = await _getRestRows(
      token,
      'users',
      query: {
        'select': 'role',
        'id': 'eq.$userId',
        'limit': '1',
      },
    );
    _isPlatformAdmin =
        rows.isNotEmpty && rows.first['role']?.toString() == 'admin';
  }

  Future<List<Map<String, dynamic>>> _getRestRows(
    String token,
    String table, {
    required Map<String, String> query,
  }) async {
    final uri = Uri.parse('${SupabaseConfig.url}/rest/v1/$table')
        .replace(queryParameters: query);

    final response = await _requestWithRefresh(
      token,
      (accessToken) => _httpClient.get(uri, headers: _restHeaders(accessToken)),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Supabase REST ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _postRestRows(
    String token,
    String table, {
    required Map<String, dynamic> data,
  }) async {
    final uri = Uri.parse('${SupabaseConfig.url}/rest/v1/$table');

    final response = await _requestWithRefresh(
      token,
      (accessToken) => _httpClient.post(
        uri,
        headers: _restHeaders(accessToken, preferRepresentation: true),
        body: jsonEncode(data),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Supabase REST ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _patchRestRows(
    String token,
    String table, {
    required Map<String, String> query,
    required Map<String, dynamic> data,
  }) async {
    final uri = Uri.parse('${SupabaseConfig.url}/rest/v1/$table')
        .replace(queryParameters: query);

    final response = await _requestWithRefresh(
      token,
      (accessToken) => _httpClient.patch(
        uri,
        headers: _restHeaders(accessToken, preferRepresentation: true),
        body: jsonEncode(data),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Supabase REST ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<dynamic> _postRpc(
    String token,
    String functionName, {
    required Map<String, dynamic> data,
  }) async {
    final uri = Uri.parse(
      '${SupabaseConfig.url}/rest/v1/rpc/$functionName',
    );
    final response = await _requestWithRefresh(
      token,
      (accessToken) => _httpClient.post(
        uri,
        headers: _restHeaders(accessToken),
        body: jsonEncode(data),
      ),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Supabase RPC ${response.statusCode}: ${response.body}',
      );
    }
    if (response.body.trim().isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<void> _deleteRestRows(
    String token,
    String table, {
    required Map<String, String> query,
  }) async {
    final uri = Uri.parse('${SupabaseConfig.url}/rest/v1/$table')
        .replace(queryParameters: query);

    final response = await _requestWithRefresh(
      token,
      (accessToken) =>
          _httpClient.delete(uri, headers: _restHeaders(accessToken)),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Supabase REST ${response.statusCode}: ${response.body}');
    }
  }

  Future<http.Response> _requestWithRefresh(
    String token,
    Future<http.Response> Function(String accessToken) request,
  ) async {
    var response = await request(token);
    if (response.statusCode != 401) return response;
    final refreshedToken = await _refreshAccessToken();
    if (refreshedToken == null || refreshedToken.isEmpty) return response;
    response = await request(refreshedToken);
    return response;
  }

  Future<String?> _refreshAccessToken() async {
    try {
      final session = await _authService.refreshSession();
      _applyAuthSession(session);
      return session.accessToken;
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _restHeaders(
    String token, {
    bool preferRepresentation = false,
  }) {
    return {
      'apikey': SupabaseConfig.anonKey,
      'authorization': 'Bearer $token',
      'content-type': 'application/json',
      if (preferRepresentation) 'prefer': 'return=representation',
    };
  }

  String _cleanErrorMessage(Object error) {
    final message = error
        .toString()
        .replaceFirst(RegExp(r'^\s*Bad state:\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^\s*Exception:\s*', caseSensitive: false), '');

    if (message.contains('Failed to fetch') ||
        message.contains('XMLHttpRequest') ||
        message.contains('SocketException') ||
        message.contains('ClientException')) {
      return 'Sem internet ou Supabase indisponível. Verifique sua conexão.';
    }

    if (message.contains('management_clients') ||
        message.contains('management_client_appointments') ||
        message.contains('PGRST205')) {
      return 'Execute o script supabase/issue_006_customer_management.sql no Supabase e atualize a tela. Ele cria as views necessarias para listar clientes.';
    }

    if ((message.contains('409') || message.contains('23505')) &&
        (message.contains('appointments_barber_id_starts_at_key') ||
            message.contains('duplicate key value'))) {
      return 'Este horário já possui um atendimento na agenda. Recuse ou cancele esta solicitação e oriente o cliente a escolher outro horário.';
    }

    if (message.toLowerCase().contains('horario escolhido ja esta ocupado') ||
        message.toLowerCase().contains('horário escolhido já está ocupado')) {
      return 'Este horário já possui um atendimento na agenda. Recuse ou cancele esta solicitação e oriente o cliente a escolher outro horário.';
    }

    return switch (message) {
      'Login invalido ou usuario sem acesso.' =>
        'Login inválido ou usuário sem acesso.',
      'Login inválido ou usuário sem acesso.' =>
        'Login inválido ou usuário sem acesso.',
      'Nao foi possivel carregar pedidos.' =>
        'Não foi possível carregar os pedidos.',
      'Não foi possível carregar os pedidos.' =>
        'Não foi possível carregar os pedidos.',
      'Nao foi possivel atualizar o pedido.' =>
        'Não foi possível atualizar o pedido.',
      'Não foi possível atualizar o pedido.' =>
        'Não foi possível atualizar o pedido.',
      _ => message,
    };
  }

  String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _notesWithReason(String notes, String? reason) {
    final cleanReason = reason?.trim();
    if (cleanReason == null || cleanReason.isEmpty) return notes;

    final reasonLine = 'Motivo: $cleanReason';
    if (notes.trim().isEmpty) return reasonLine;
    if (notes.contains(reasonLine)) return notes;
    return '${notes.trim()}\n$reasonLine';
  }
}
