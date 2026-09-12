import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clubedaregua_gestao/management.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ManagementSession customer isolation', () {
    test('Barber uses only the scoped customer RPCs', () async {
      final requests = <http.Request>[];
      final session = _sessionWith((request) async {
        requests.add(request);
        return _responseFor(request);
      });
      addTearDown(session.dispose);

      await session.restoreUnifiedSession(
        initialRole: ManagementRole.barber,
      );
      requests.clear();

      // P0 contract: this intentionally depends on the role-scoped
      // implementation in ManagementSession and fails against the legacy
      // unit-wide REST loading used for barbers.
      await session.ensureDataForDestination(
        ManagementRole.barber,
        ManagementDestinationId.clients,
      );

      final customerRpc = requests.singleWhere(
        (request) => _endpoint(request.url) == 'list_barber_customers',
      );
      final appointmentsRpc = requests.singleWhere(
        (request) =>
            _endpoint(request.url) == 'list_barber_customer_appointments',
      );
      for (final request in [customerRpc, appointmentsRpc]) {
        expect(request.method, 'POST');
        expect(
          jsonDecode(request.body),
          containsPair('p_barber_shop_id', 'shop-1'),
        );
        expect(
          jsonDecode(request.body),
          containsPair('p_barber_id', 'barber-1'),
        );
      }
      expect(
        requests.map((request) => _endpoint(request.url)),
        isNot(contains('management_clients')),
      );
      expect(
        requests.map((request) => _endpoint(request.url)),
        isNot(contains('management_client_appointments')),
      );
      expect(session.customers.map((customer) => customer.name), [
        'Cliente do barbeiro',
      ]);
      expect(
        session.customerAppointments.map((appointment) => appointment.barber),
        ['Barbeiro atual'],
      );
    });

    test('Owner keeps the current unit-wide REST sources', () async {
      final requests = <http.Request>[];
      final session = _sessionWith((request) async {
        requests.add(request);
        return _responseFor(request);
      });
      addTearDown(session.dispose);

      await session.restoreUnifiedSession(initialRole: ManagementRole.admin);
      requests.clear();

      await session.ensureDataForDestination(
        ManagementRole.admin,
        ManagementDestinationId.clients,
      );

      final endpoints = requests.map((request) => _endpoint(request.url));
      expect(
        endpoints,
        containsAll([
          'management_clients',
          'management_client_appointments',
          'booking_requests',
          'client_booking_blocks',
        ]),
      );
      expect(endpoints, isNot(contains('list_barber_customers')));
      expect(
        endpoints,
        isNot(contains('list_barber_customer_appointments')),
      );
      for (final endpoint in [
        'management_clients',
        'management_client_appointments',
        'booking_requests',
        'client_booking_blocks',
      ]) {
        final request = requests.singleWhere(
          (request) => _endpoint(request.url) == endpoint,
        );
        expect(request.method, 'GET');
        expect(request.url.queryParameters['barber_shop_id'], 'eq.shop-1');
      }
      expect(session.customers.map((customer) => customer.name), [
        'Cliente da unidade',
      ]);
    });

    test('switching Owner and Barber reloads their isolated customer caches',
        () async {
      final requests = <http.Request>[];
      final session = _sessionWith((request) async {
        requests.add(request);
        return _responseFor(request);
      });
      addTearDown(session.dispose);

      await session.restoreUnifiedSession(initialRole: ManagementRole.admin);
      requests.clear();

      await session.ensureDataForDestination(
        ManagementRole.admin,
        ManagementDestinationId.clients,
      );
      expect(session.customers.single.name, 'Cliente da unidade');

      await session.activateRole(
        ManagementRole.barber,
        destination: ManagementDestinationId.clients,
      );
      expect(session.activeRole, ManagementRole.barber);
      expect(session.customers.single.name, 'Cliente do barbeiro');

      await session.activateRole(
        ManagementRole.admin,
        destination: ManagementDestinationId.clients,
      );
      expect(session.activeRole, ManagementRole.admin);
      expect(session.customers.single.name, 'Cliente da unidade');

      expect(
        requests
            .where((request) => _endpoint(request.url) == 'management_clients'),
        hasLength(2),
      );
      expect(
        requests.where(
          (request) => _endpoint(request.url) == 'list_barber_customers',
        ),
        hasLength(1),
      );
    });

    test('a late Owner response cannot overwrite the active Barber scope',
        () async {
      final ownerResponse = Completer<http.Response>();
      final ownerRequestStarted = Completer<void>();
      final endpoints = <String>[];
      var ownerCustomerRequests = 0;
      final session = _sessionWith((request) async {
        endpoints.add(_endpoint(request.url));
        if (_endpoint(request.url) == 'management_clients') {
          ownerCustomerRequests++;
          if (ownerCustomerRequests == 1) {
            ownerRequestStarted.complete();
            return ownerResponse.future;
          }
        }
        return _responseFor(request);
      });
      addTearDown(session.dispose);

      await session.restoreUnifiedSession(initialRole: ManagementRole.admin);

      // P0 race contract: role changes must invalidate the publication token
      // of an already-running customer request, not only its loaded flag.
      final ownerLoad = session.ensureDataForDestination(
        ManagementRole.admin,
        ManagementDestinationId.clients,
      );
      await ownerRequestStarted.future;

      final barberLoad = session.activateRole(
        ManagementRole.barber,
        destination: ManagementDestinationId.clients,
      );
      await barberLoad;
      expect(session.activeRole, ManagementRole.barber);
      expect(session.customers.single.name, 'Cliente do barbeiro');

      ownerResponse.complete(
        http.Response(jsonEncode([_ownerCustomerRow()]), 200),
      );
      await ownerLoad;

      expect(session.activeRole, ManagementRole.barber);
      expect(session.customers.map((customer) => customer.name), [
        'Cliente do barbeiro',
      ]);
      expect(session.customersError, isNull);
      expect(session.isCustomersLoading, isFalse);
      expect(
        endpoints
            .where((endpoint) => endpoint == 'management_client_appointments'),
        isEmpty,
        reason: 'A carga antiga deve parar antes das demais fontes do Dono.',
      );
    });

    test('dual-role account cannot mutate customers while in Barber mode',
        () async {
      final requests = <http.Request>[];
      final session = _sessionWith((request) async {
        requests.add(request);
        return _responseFor(request);
      });
      addTearDown(session.dispose);

      await session.restoreUnifiedSession(
        initialRole: ManagementRole.barber,
      );
      requests.clear();
      final customer = ManagedCustomer.fromMap(
        _ownerCustomerRow(),
        appointmentCount: 1,
        favoriteBarber: 'Barbeiro atual',
      );

      await expectLater(
        session.updateCustomer(
          customer,
          name: 'Nome alterado',
          phone: '34999990003',
          notes: 'Não deve persistir',
        ),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        session.setCustomerBookingBlock(customer, blocked: true),
        throwsA(isA<StateError>()),
      );

      expect(requests, isEmpty);
    });

    test('Manager cannot configure customer booking blocks', () async {
      final requests = <http.Request>[];
      final session = ManagementSession(
        authService: _ManagerService(),
        httpClient: MockClient((request) async {
          requests.add(request);
          return _managerResponseFor(request);
        }),
      );
      addTearDown(session.dispose);

      await session.restoreUnifiedSession(
        initialRole: ManagementRole.admin,
      );
      requests.clear();
      final customer = ManagedCustomer.fromMap(
        _ownerCustomerRow(),
        appointmentCount: 1,
        favoriteBarber: 'Barbeiro atual',
      );

      await expectLater(
        session.setCustomerBookingBlock(customer, blocked: true),
        throwsA(isA<StateError>()),
      );

      expect(requests, isEmpty);
    });

    test('customer scope migration keeps the server-side guardrails', () {
      final sql = File(
        '../../supabase/issue_025_barber_customer_scope.sql',
      ).readAsStringSync();

      expect(sql, contains('list_barber_customers'));
      expect(sql, contains('list_barber_customer_appointments'));
      expect(sql, contains('barber.user_id = auth.uid()'));
      expect(
        sql,
        contains("appointment.status = 'completed'::public.appointment_status"),
      );
      expect(sql, contains('security definer'));
      expect(sql, contains('security_barrier = true'));
      expect(sql, contains('validate_client_booking_block_scope'));
      expect(
        sql,
        contains('relationship.barber_shop_id = new.barber_shop_id'),
      );
      expect(sql, contains('relationship.client_id = new.client_id'));
      expect(sql, contains('profile.user_id = new.client_id'));
      expect(
        sql,
        contains(
            '(new.client_id is null or request.client_id = new.client_id)'),
      );
      expect(
        sql,
        contains('Telefone do cliente invalido para esta barbearia.'),
      );
      expect(sql,
          contains('drop policy if exists client_relationships_manage_staff'));
      expect(
        sql,
        isNot(contains('create policy client_relationships_manage_staff')),
      );
    });
  });
}

ManagementSession _sessionWith(
  Future<http.Response> Function(http.Request request) handler,
) {
  return ManagementSession(
    authService: _AuthenticatedService(),
    httpClient: MockClient(handler),
  );
}

class _AuthenticatedService extends AuthService {
  @override
  Future<AuthSession?> getValidSession() async {
    return AuthSession(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      user: const AuthUser(
        id: 'user-1',
        email: 'professional@example.com',
        name: 'Professional',
      ),
    );
  }
}

class _ManagerService extends AuthService {
  @override
  Future<AuthSession?> getValidSession() async {
    return AuthSession(
      accessToken: 'manager-access-token',
      refreshToken: 'manager-refresh-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      user: const AuthUser(
        id: 'manager-1',
        email: 'manager@example.com',
        name: 'Manager',
      ),
    );
  }
}

http.Response _responseFor(http.Request request) {
  final endpoint = _endpoint(request.url);
  final select = request.url.queryParameters['select'] ?? '';
  final body = request.body.isEmpty
      ? const <String, dynamic>{}
      : jsonDecode(request.body) as Map<String, dynamic>;

  final rows = switch (endpoint) {
    'users' => const <Map<String, dynamic>>[],
    'shop_members' when select == 'barber_shop_id,barber_shops(name)' => [
        {
          'barber_shop_id': 'shop-1',
          'barber_shops': {'name': 'Sapao Barber'},
        },
      ],
    'shop_members' => [
        {'role': 'owner'},
      ],
    'barber_shops' when select == 'owner_id' => [
        {'owner_id': 'user-1'},
      ],
    'barbers' when select == 'id' => [
        {'id': 'barber-1'},
      ],
    'barbers' => [_barberRow()],
    'management_clients' => [_ownerCustomerRow()],
    'management_client_appointments' => [_ownerAppointmentRow()],
    'client_booking_blocks' => const <Map<String, dynamic>>[],
    'list_barber_customers' => _scopedRpcRows(
        body,
        [_barberCustomerRow()],
      ),
    'list_barber_customer_appointments' => _scopedRpcRows(
        body,
        [_barberAppointmentRow()],
      ),
    _ => const <Map<String, dynamic>>[],
  };
  return http.Response(jsonEncode(rows), 200);
}

http.Response _managerResponseFor(http.Request request) {
  final endpoint = _endpoint(request.url);
  final select = request.url.queryParameters['select'] ?? '';
  if (endpoint == 'shop_members' &&
      select != 'barber_shop_id,barber_shops(name)') {
    return http.Response(
        jsonEncode(const [
          {'role': 'manager'}
        ]),
        200);
  }
  if (endpoint == 'barber_shops' && select == 'owner_id') {
    return http.Response(
        jsonEncode(const [
          {'owner_id': 'owner-1'}
        ]),
        200);
  }
  return _responseFor(request);
}

List<Map<String, dynamic>> _scopedRpcRows(
  Map<String, dynamic> body,
  List<Map<String, dynamic>> rows,
) {
  if (body['p_barber_shop_id'] != 'shop-1' ||
      body['p_barber_id'] != 'barber-1') {
    return const [];
  }
  return rows;
}

Map<String, dynamic> _barberRow() => {
      'id': 'barber-1',
      'barber_shop_id': 'shop-1',
      'user_id': 'user-1',
      'name': 'Barbeiro atual',
      'bio': '',
      'photo_url': '',
      'starting_price': 50,
      'commission_percent': 40,
      'is_active': true,
    };

Map<String, dynamic> _ownerCustomerRow() => {
      'relationship_id': 'relationship-owner',
      'barber_shop_id': 'shop-1',
      'client_id': 'client-owner',
      'first_seen_at': '2026-08-01T10:00:00Z',
      'last_appointment_at': '2026-09-01T10:00:00Z',
      'notes': '',
      'is_blocked': false,
      'email': 'unit@example.com',
      'user_is_active': true,
      'full_name': 'Cliente da unidade',
      'phone': '34999990001',
      'avatar_url': '',
      'profile_created_at': '2026-07-01T10:00:00Z',
    };

Map<String, dynamic> _barberCustomerRow() => {
      'relationship_id': 'relationship-barber',
      'barber_shop_id': 'shop-1',
      'client_id': 'client-barber',
      'first_seen_at': '2026-08-02T10:00:00Z',
      'last_appointment_at': '2026-09-02T10:00:00Z',
      'notes': '',
      'is_blocked': false,
      'email': 'barber@example.com',
      'user_is_active': true,
      'full_name': 'Cliente do barbeiro',
      'phone': '34999990002',
      'avatar_url': '',
      'profile_created_at': '2026-07-02T10:00:00Z',
    };

Map<String, dynamic> _ownerAppointmentRow() => {
      'id': 'appointment-owner',
      'client_id': 'client-owner',
      'starts_at': '2026-09-01T10:00:00Z',
      'status': 'completed',
      'notes': '',
      'service_name': 'Corte',
      'barber_name': 'Outro barbeiro',
    };

Map<String, dynamic> _barberAppointmentRow() => {
      'id': 'appointment-barber',
      'client_id': 'client-barber',
      'starts_at': '2026-09-02T10:00:00Z',
      'status': 'completed',
      'notes': '',
      'service_name': 'Barba',
      'barber_name': 'Barbeiro atual',
    };

String _endpoint(Uri uri) {
  final segments = uri.pathSegments;
  return segments.isEmpty ? '' : segments.last;
}
