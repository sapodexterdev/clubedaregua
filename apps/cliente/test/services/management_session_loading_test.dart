import 'dart:async';
import 'dart:convert';

import 'package:clubedaregua_gestao/management.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('barber startup loads only the professional landing data', () async {
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      return http.Response(jsonEncode(_responseFor(request.url)), 200);
    });
    final session = ManagementSession(
      authService: _AuthenticatedService(),
      httpClient: client,
    );
    addTearDown(session.dispose);

    await session.restoreUnifiedSession(
      initialRole: ManagementRole.barber,
    );

    final loadedTables = requests.map(_tableName).toList();
    expect(loadedTables, contains('booking_requests'));
    expect(loadedTables, isNot(contains('management_clients')));
    expect(loadedTables, isNot(contains('management_client_appointments')));
    expect(loadedTables, isNot(contains('appointments')));
    expect(loadedTables, isNot(contains('service_categories')));
    expect(loadedTables, isNot(contains('services')));
    expect(loadedTables, isNot(contains('shop_settings')));

    final barberRequests = requests.singleWhere(
      (uri) =>
          _tableName(uri) == 'booking_requests' &&
          uri.queryParameters['select']?.startsWith('id,barber_id') == true,
    );
    expect(barberRequests.queryParameters['barber_id'], 'eq.barber-1');
    expect(barberRequests.queryParameters['limit'], '50');
  });

  test('owner data is loaded lazily by the selected tab', () async {
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      return http.Response(jsonEncode(_responseFor(request.url)), 200);
    });
    final session = ManagementSession(
      authService: _AuthenticatedService(),
      httpClient: client,
    );
    addTearDown(session.dispose);

    await session.restoreUnifiedSession(
      initialRole: ManagementRole.barber,
    );
    requests.clear();

    await session.activateRole(ManagementRole.admin);

    expect(
      requests.map(_tableName),
      everyElement(equals('booking_requests')),
    );
    final ownerRequests = requests.single;
    expect(ownerRequests.queryParameters.containsKey('barber_id'), isFalse);
    expect(ownerRequests.queryParameters['limit'], '200');

    requests.clear();
    await session.ensureDataForTab(ManagementRole.admin, 3);

    expect(
      requests.map(_tableName),
      containsAll([
        'service_categories',
        'appointments',
        'booking_requests',
        'services',
      ]),
    );
    expect(requests.map(_tableName), isNot(contains('management_clients')));
    expect(
      requests
          .where((uri) => _tableName(uri) == 'appointments')
          .single
          .queryParameters['limit'],
      '500',
    );
  });

  test('disposing the session stops the remaining startup requests', () async {
    final firstResponse = Completer<http.Response>();
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      return firstResponse.future;
    });
    final session = ManagementSession(
      authService: _AuthenticatedService(),
      httpClient: client,
    );

    final restore = session.restoreUnifiedSession();
    await Future<void>.delayed(Duration.zero);
    session.dispose();
    firstResponse.complete(http.Response('[]', 200));
    await restore;

    expect(requestCount, 1);
  });
}

class _AuthenticatedService extends AuthService {
  @override
  Future<AuthSession?> getValidSession() async => AuthSession(
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

String _tableName(Uri uri) {
  final segments = uri.pathSegments;
  return segments.isEmpty ? '' : segments.last;
}

List<Map<String, dynamic>> _responseFor(Uri uri) {
  final table = _tableName(uri);
  final select = uri.queryParameters['select'] ?? '';
  return switch (table) {
    'users' => const [],
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
    'barbers' => [
        {
          'id': 'barber-1',
          'barber_shop_id': 'shop-1',
          'user_id': 'user-1',
          'name': 'Barbeiro atual',
          'bio': '',
          'photo_url': '',
          'starting_price': 50,
          'commission_percent': 40,
          'is_active': true,
        },
      ],
    'booking_requests' when select.startsWith('id,barber_id') => [
        {
          'id': 'request-1',
          'barber_id': 'barber-1',
          'customer_name': 'Cliente',
          'customer_phone': '',
          'requested_date': '2026-07-31',
          'requested_time': '09:00',
          'status': 'new',
          'total_price': 50,
          'notes': '',
          'updated_at': '2026-07-31T09:00:00Z',
          'barbers': {'name': 'Barbeiro atual'},
          'services': {'name': 'Corte'},
        },
      ],
    _ => const [],
  };
}

