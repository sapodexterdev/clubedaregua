import 'dart:async';

import 'package:clubedaregua/models/appointment.dart';
import 'package:clubedaregua/models/barber.dart';
import 'package:clubedaregua/models/notification_item.dart';
import 'package:clubedaregua/models/service_item.dart';
import 'package:clubedaregua/providers/app_state.dart';
import 'package:clubedaregua/repositories/appointment_repository.dart';
import 'package:clubedaregua/repositories/barber_repository.dart';
import 'package:clubedaregua/repositories/client_profile_repository.dart';
import 'package:clubedaregua/repositories/favorite_repository.dart';
import 'package:clubedaregua/repositories/notification_repository.dart';
import 'package:clubedaregua/repositories/team_invitation_repository.dart';
import 'package:clubedaregua/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('a request from user A cannot populate the state of user B', () async {
    final auth = _MutableAuthService()..session = _sessionFor('user-a');
    final repository = _PendingAppointmentRepository();
    final state = AppState(
      authService: auth,
      appointmentRepository: repository,
    );
    addTearDown(state.dispose);
    state.requireSignedIn();

    final oldRefresh = state.refreshAppointments();
    await repository.requestStarted.future;

    await state.signOut();
    auth.session = _sessionFor('user-b');
    state.requireSignedIn();
    repository.response.complete(const [
      Appointment(
        id: 'appointment-user-a',
        barberName: 'Barbeiro A',
        serviceName: 'Corte A',
        dateLabel: '2026-08-23',
        time: '10:00',
        status: 'accepted',
        total: 50,
      ),
    ]);
    await oldRefresh;

    expect(state.isSignedIn, isTrue);
    expect(state.appointments, isEmpty);
    expect(state.isLoadingAppointments, isFalse);
  });

  test('old private responses are discarded after an account change', () async {
    final auth = _MutableAuthService()..session = _sessionFor('user-a');
    final favorites = _PendingFavoriteRepository();
    final profiles = _PendingProfileRepository();
    final notifications = _PendingNotificationRepository();
    final state = AppState(
      authService: auth,
      favoriteRepository: favorites,
      clientProfileRepository: profiles,
      notificationRepository: notifications,
    );
    addTearDown(state.dispose);
    state.requireSignedIn();

    final oldRequests = [
      state.refreshFavorites(),
      state.refreshClientProfile(),
      state.refreshNotifications(),
    ];
    await Future.wait([
      favorites.requestStarted.future,
      profiles.requestStarted.future,
      notifications.requestStarted.future,
    ]);

    await state.signOut();
    auth.session = _sessionFor('user-b');
    state.requireSignedIn();
    favorites.response.complete({'shop-user-a'});
    profiles.response.complete(const ClientProfile(
      fullName: 'User A',
      email: 'a@example.com',
      phone: '11999999999',
    ));
    notifications.response.complete([
      NotificationItem(
        id: 'notification-user-a',
        title: 'Conta A',
        message: 'Não pode aparecer para B',
        isRead: false,
        createdAt: DateTime(2026, 8, 23),
      ),
    ]);
    await Future.wait(oldRequests);

    expect(state.isSignedIn, isTrue);
    expect(state.isFavorite('shop-user-a'), isFalse);
    expect(state.currentUserName, isNull);
    expect(state.notifications, isEmpty);
    expect(state.isLoadingFavorites, isFalse);
    expect(state.isLoadingClientProfile, isFalse);
    expect(state.isLoadingNotifications, isFalse);
  });

  test('bootstrap notifications from user A cannot reach user B', () async {
    final auth = _MutableAuthService()..session = _sessionFor('user-a');
    final notifications = _PendingNotificationRepository();
    final state = AppState(
      authService: auth,
      notificationRepository: notifications,
    );
    addTearDown(state.dispose);

    final oldBootstrap = state.loadInitialData();
    await notifications.requestStarted.future;

    await state.signOut();
    auth.session = _sessionFor('user-b');
    state.requireSignedIn();
    notifications.response.complete([
      NotificationItem(
        id: 'bootstrap-user-a',
        title: 'Conta A',
        message: 'Resposta antiga',
        isRead: false,
        createdAt: DateTime(2026, 8, 23),
      ),
    ]);
    await oldBootstrap;

    expect(state.isSignedIn, isTrue);
    expect(state.notifications, isEmpty);
  });

  test('login restarts a pending anonymous bootstrap for the new account',
      () async {
    final auth = _MutableAuthService();
    final invitations = _PendingFirstInvitationRepository();
    final state = AppState(
      authService: auth,
      teamInvitationRepository: invitations,
    );
    addTearDown(state.dispose);

    final anonymousBootstrap = state.loadInitialData();
    await invitations.firstRequestStarted.future;

    auth.session = _sessionFor('user-b');
    final signedInBootstrap = state.loadInitialData();
    await signedInBootstrap;
    invitations.firstResponse.complete();
    await anonymousBootstrap;

    expect(state.isLoading, isFalse);
    expect(state.isSignedIn, isTrue);
    expect(state.currentUserName, 'user-b');
  });

  test('guest can create an appointment without an account scope', () async {
    final repository = _SuccessfulBookingRepository();
    final state = AppState(
      authService: _MutableAuthService(),
      appointmentRepository: repository,
    );
    addTearDown(state.dispose);
    state
      ..selectedBarbershop = _testShop
      ..selectedBarber = _testBarber
      ..selectedService = _testService
      ..selectedDate = DateTime.now().add(const Duration(days: 1))
      ..selectedTime = '10:30'
      ..availableTimes = const ['10:30'];

    final created = await state.createSelectedAppointment(
      customerName: 'Cliente Visitante',
      customerPhone: '(34)99999-9999',
      paymentMethodLabel: 'Pix',
    );

    expect(created, isTrue);
    expect(repository.createCalls, 1);
    expect(repository.fetchAppointmentsCalls, 0);
    expect(state.lastBookingRequestCreated, isTrue);
    expect(state.lastBookingReceipt?.time, '10:30');
  });
}

class _PendingFirstInvitationRepository extends TeamInvitationRepository {
  final firstRequestStarted = Completer<void>();
  final firstResponse = Completer<void>();
  var requests = 0;

  @override
  Future<void> capturePendingInvitation() async {
    requests++;
    if (requests != 1) return;
    firstRequestStarted.complete();
    await firstResponse.future;
  }

  @override
  Future<AcceptedTeamInvitation?> acceptPendingInvitation() async => null;
}

class _PendingAppointmentRepository extends AppointmentRepository {
  final requestStarted = Completer<void>();
  final response = Completer<List<Appointment>>();

  @override
  Future<List<Appointment>> fetchAppointments() {
    if (!requestStarted.isCompleted) requestStarted.complete();
    return response.future;
  }
}

class _SuccessfulBookingRepository extends AppointmentRepository {
  var createCalls = 0;
  var fetchAppointmentsCalls = 0;

  @override
  Future<List<String>> fetchAvailableTimes({
    required String barberId,
    required String barberShopId,
    required DateTime date,
    required int durationMinutes,
  }) async {
    return const ['10:30'];
  }

  @override
  Future<bool> createAppointment({
    required String barberId,
    required String serviceId,
    required DateTime date,
    required String time,
    required double total,
    required String barberShopId,
    required String customerName,
    required String customerPhone,
    required String paymentMethodLabel,
  }) async {
    createCalls++;
    return true;
  }

  @override
  Future<List<Appointment>> fetchAppointments() async {
    fetchAppointmentsCalls++;
    return const [];
  }
}

class _PendingFavoriteRepository extends FavoriteRepository {
  final requestStarted = Completer<void>();
  final response = Completer<Set<String>>();

  @override
  Future<Set<String>> fetchFavoriteShopIds() {
    if (!requestStarted.isCompleted) requestStarted.complete();
    return response.future;
  }
}

class _PendingProfileRepository extends ClientProfileRepository {
  final requestStarted = Completer<void>();
  final response = Completer<ClientProfile?>();

  @override
  Future<ClientProfile?> fetchProfile() {
    if (!requestStarted.isCompleted) requestStarted.complete();
    return response.future;
  }
}

class _PendingNotificationRepository extends NotificationRepository {
  final requestStarted = Completer<void>();
  final response = Completer<List<NotificationItem>>();

  @override
  Future<List<NotificationItem>> fetchNotifications() {
    if (!requestStarted.isCompleted) requestStarted.complete();
    return response.future;
  }
}

class _MutableAuthService extends AuthService {
  AuthSession? session;

  @override
  AuthSession? get currentSession => session;

  @override
  AuthUser? get currentUser => session?.user;

  @override
  bool get isSignedIn => session != null;

  @override
  Future<AuthSession?> restoreSession() async => session;

  @override
  Future<void> signOut() async {
    session = null;
  }
}

AuthSession _sessionFor(String userId) => AuthSession(
      accessToken: '$userId-access',
      refreshToken: '$userId-refresh',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      user: AuthUser(
        id: userId,
        email: '$userId@example.com',
        name: userId,
      ),
    );

const _testBarber = Barber(
  id: 'barber-1',
  name: 'Barbeiro Teste',
  barberShopId: 'shop-1',
  shopName: 'Barbearia Teste',
  imageUrl: '',
  rating: 5,
  startingPrice: 50,
  bio: '',
  serviceIds: ['service-1'],
);

const _testService = ServiceItem(
  id: 'service-1',
  name: 'Corte',
  durationMinutes: 30,
  price: 50,
  barberShopId: 'shop-1',
);

const _testShop = PublicBarbershop(
  identity: ShopIdentity(
    id: 'shop-1',
    name: 'Barbearia Teste',
    logoUrl: '',
    coverUrl: '',
    phone: '',
    whatsapp: '',
    email: '',
    instagram: '',
    address: '',
    city: 'Uberlândia',
    state: 'MG',
    secondaryColor: '',
    bookingIntervalMinutes: 30,
    bookingDaysAhead: 30,
    minNoticeMinutes: 0,
    maxDelayMinutes: 10,
    minCancelHours: 2,
  ),
  barbers: [_testBarber],
  services: [_testService],
  rating: 5,
  reviewCount: 0,
  distanceKm: 1,
  nextSlot: '10:30',
  isOpen: true,
  neighborhood: 'Centro',
);
