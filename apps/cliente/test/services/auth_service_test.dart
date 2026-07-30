import 'dart:convert';

import 'package:clubedaregua/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(AuthService.resetInMemoryForTesting);

  test('serializes concurrent refreshes and persists the rotated token',
      () async {
    final expiredSession = AuthSession(
      accessToken: 'expired-access',
      refreshToken: 'initial-refresh',
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      user: const AuthUser(
        id: 'user-1',
        email: 'user@example.com',
        name: 'User',
      ),
    );
    SharedPreferences.setMockInitialValues({
      'clubedaregua.client.session': jsonEncode(expiredSession.toMap()),
    });

    var refreshRequests = 0;
    final client = MockClient((request) async {
      expect(request.url.path, '/auth/v1/token');
      expect(request.url.queryParameters['grant_type'], 'refresh_token');
      expect(jsonDecode(request.body), {
        'refresh_token': 'initial-refresh',
      });
      refreshRequests++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return http.Response(
        jsonEncode({
          'access_token': 'renewed-access',
          'refresh_token': 'rotated-refresh',
          'expires_in': 3600,
          'user': {
            'id': 'user-1',
            'email': 'user@example.com',
            'user_metadata': {'name': 'User'},
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final auth = AuthService(
      client: client,
      supabaseUrl: 'https://project.supabase.co',
      anonKey: 'test-anon-key',
    );

    final sessions = await Future.wait([
      auth.getValidSession(),
      auth.getValidSession(),
      auth.getValidSession(),
    ]);

    expect(refreshRequests, 1);
    expect(
      sessions.map((session) => session?.accessToken),
      everyElement('renewed-access'),
    );
    expect(
      sessions.map((session) => session?.refreshToken),
      everyElement('rotated-refresh'),
    );

    final preferences = await SharedPreferences.getInstance();
    final persisted = jsonDecode(
      preferences.getString('clubedaregua.client.session')!,
    ) as Map<String, dynamic>;
    expect(persisted['access_token'], 'renewed-access');
    expect(persisted['refresh_token'], 'rotated-refresh');
  });

  test('shares a forced refresh after concurrent 401 responses', () async {
    final activeSession = AuthSession(
      accessToken: 'current-access',
      refreshToken: 'current-refresh',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      user: const AuthUser(
        id: 'user-1',
        email: 'user@example.com',
        name: 'User',
      ),
    );
    SharedPreferences.setMockInitialValues({
      'clubedaregua.client.session': jsonEncode(activeSession.toMap()),
    });

    var refreshRequests = 0;
    final client = MockClient((request) async {
      refreshRequests++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return http.Response(
        jsonEncode({
          'access_token': 'forced-access',
          'refresh_token': 'forced-refresh',
          'expires_in': 3600,
          'user': {
            'id': 'user-1',
            'email': 'user@example.com',
            'user_metadata': {'name': 'User'},
          },
        }),
        200,
      );
    });
    final auth = AuthService(
      client: client,
      supabaseUrl: 'https://project.supabase.co',
      anonKey: 'test-anon-key',
    );
    await auth.restoreSession();

    final sessions = await Future.wait([
      auth.refreshSession(),
      auth.refreshSession(),
      auth.refreshSession(),
    ]);

    expect(refreshRequests, 1);
    expect(
      sessions.map((session) => session.accessToken),
      everyElement('forced-access'),
    );
    expect(
      sessions.map((session) => session.refreshToken),
      everyElement('forced-refresh'),
    );
  });

  test('updates the password with the shared session', () async {
    final activeSession = AuthSession(
      accessToken: 'recovery-access',
      refreshToken: 'recovery-refresh',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      user: const AuthUser(
        id: 'user-1',
        email: 'user@example.com',
        name: 'User',
      ),
    );
    SharedPreferences.setMockInitialValues({
      'clubedaregua.client.session': jsonEncode(activeSession.toMap()),
      'clubedaregua.auth.password_recovery_pending': true,
    });

    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/auth/v1/user');
      expect(request.headers['authorization'], 'Bearer recovery-access');
      expect(jsonDecode(request.body), {'password': 'new-password'});
      return http.Response('{}', 200);
    });
    final auth = AuthService(
      client: client,
      supabaseUrl: 'https://project.supabase.co',
      anonKey: 'test-anon-key',
    );
    await auth.restoreSession();

    await auth.updatePassword('new-password');

    expect(await auth.hasPendingPasswordRecovery(), isFalse);
  });
}
