import 'dart:async';
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

  test('a refresh completed after logout cannot restore the old session',
      () async {
    final expiredSession = AuthSession(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      user: const AuthUser(
        id: 'user-a',
        email: 'a@example.com',
        name: 'User A',
      ),
    );
    SharedPreferences.setMockInitialValues({
      'clubedaregua.client.session': jsonEncode(expiredSession.toMap()),
    });
    final refreshStarted = Completer<void>();
    final refreshResponse = Completer<http.Response>();
    final client = MockClient((request) async {
      if (request.url.path == '/auth/v1/logout') {
        return http.Response('{}', 200);
      }
      if (!refreshStarted.isCompleted) refreshStarted.complete();
      return refreshResponse.future;
    });
    final auth = AuthService(
      client: client,
      supabaseUrl: 'https://project.supabase.co',
      anonKey: 'test-anon-key',
    );

    final validation = auth.getValidSession();
    await refreshStarted.future;
    await auth.signOut();
    refreshResponse.complete(http.Response(
      jsonEncode(_sessionResponse('user-a', 'late-access', 'late-refresh')),
      200,
    ));

    expect(await validation, isNull);
    expect(auth.currentSession, isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('clubedaregua.client.session'), isNull);
  });

  test('a refresh from user A cannot overwrite a login from user B', () async {
    final expiredSession = AuthSession(
      accessToken: 'a-access',
      refreshToken: 'a-refresh',
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      user: const AuthUser(
        id: 'user-a',
        email: 'a@example.com',
        name: 'User A',
      ),
    );
    SharedPreferences.setMockInitialValues({
      'clubedaregua.client.session': jsonEncode(expiredSession.toMap()),
    });
    final refreshStarted = Completer<void>();
    final refreshResponse = Completer<http.Response>();
    final client = MockClient((request) async {
      final grant = request.url.queryParameters['grant_type'];
      if (grant == 'refresh_token') {
        if (!refreshStarted.isCompleted) refreshStarted.complete();
        return refreshResponse.future;
      }
      if (grant == 'password') {
        return http.Response(
          jsonEncode(_sessionResponse('user-b', 'b-access', 'b-refresh')),
          200,
        );
      }
      return http.Response('{}', 404);
    });
    final auth = AuthService(
      client: client,
      supabaseUrl: 'https://project.supabase.co',
      anonKey: 'test-anon-key',
    );

    final oldValidation = auth.getValidSession();
    await refreshStarted.future;
    final userB = await auth.signIn('b@example.com', 'password');
    refreshResponse.complete(http.Response(
      jsonEncode(_sessionResponse('user-a', 'late-a', 'late-a-refresh')),
      200,
    ));

    expect(await oldValidation, isNull);
    expect(userB.user.id, 'user-b');
    expect(auth.currentSession?.user.id, 'user-b');
    final preferences = await SharedPreferences.getInstance();
    final persisted = jsonDecode(
      preferences.getString('clubedaregua.client.session')!,
    ) as Map<String, dynamic>;
    expect((persisted['user'] as Map<String, dynamic>)['id'], 'user-b');
  });

  test('getValidSession cannot restore a session while logout is pending',
      () async {
    final activeSession = AuthSession(
      accessToken: 'a-access',
      refreshToken: 'a-refresh',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      user: const AuthUser(
        id: 'user-a',
        email: 'a@example.com',
        name: 'User A',
      ),
    );
    SharedPreferences.setMockInitialValues({
      'clubedaregua.client.session': jsonEncode(activeSession.toMap()),
    });
    final logoutStarted = Completer<void>();
    final logoutResponse = Completer<http.Response>();
    final client = MockClient((request) async {
      if (!logoutStarted.isCompleted) logoutStarted.complete();
      return logoutResponse.future;
    });
    final auth = AuthService(
      client: client,
      supabaseUrl: 'https://project.supabase.co',
      anonKey: 'test-anon-key',
    );
    await auth.restoreSession();

    final logout = auth.signOut();
    await logoutStarted.future;
    var validationCompleted = false;
    final validation = auth.getValidSession().then((session) {
      validationCompleted = true;
      return session;
    });
    await Future<void>.delayed(Duration.zero);
    expect(validationCompleted, isFalse);

    logoutResponse.complete(http.Response('{}', 200));
    await logout;
    expect(await validation, isNull);
  });

  test('a second user can sign out while the previous logout is pending',
      () async {
    final activeSession = AuthSession(
      accessToken: 'a-access',
      refreshToken: 'a-refresh',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      user: const AuthUser(
        id: 'user-a',
        email: 'a@example.com',
        name: 'User A',
      ),
    );
    SharedPreferences.setMockInitialValues({
      'clubedaregua.client.session': jsonEncode(activeSession.toMap()),
    });
    final firstLogoutStarted = Completer<void>();
    final firstLogoutResponse = Completer<http.Response>();
    final client = MockClient((request) async {
      if (request.url.path == '/auth/v1/logout' &&
          request.headers['authorization'] == 'Bearer a-access') {
        if (!firstLogoutStarted.isCompleted) firstLogoutStarted.complete();
        return firstLogoutResponse.future;
      }
      if (request.url.queryParameters['grant_type'] == 'password') {
        return http.Response(
          jsonEncode(_sessionResponse('user-b', 'b-access', 'b-refresh')),
          200,
        );
      }
      if (request.url.path == '/auth/v1/logout' &&
          request.headers['authorization'] == 'Bearer b-access') {
        return http.Response('{}', 200);
      }
      return http.Response('{}', 404);
    });
    final auth = AuthService(
      client: client,
      supabaseUrl: 'https://project.supabase.co',
      anonKey: 'test-anon-key',
    );
    await auth.restoreSession();

    final firstLogout = auth.signOut();
    await firstLogoutStarted.future;
    await auth.signIn('b@example.com', 'password');
    await auth.signOut();

    expect(auth.currentSession, isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('clubedaregua.client.session'), isNull);

    firstLogoutResponse.complete(http.Response('{}', 200));
    await firstLogout;
    expect(auth.currentSession, isNull);
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

Map<String, dynamic> _sessionResponse(
  String userId,
  String accessToken,
  String refreshToken,
) =>
    {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': 3600,
      'user': {
        'id': userId,
        'email': '$userId@example.com',
        'user_metadata': {'name': userId},
      },
    };
