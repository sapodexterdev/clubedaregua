import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';
import 'auth_callback_url.dart';

class AuthService {
  static const _sessionKey = 'clubedaregua.client.session';
  static AuthSession? _currentSession;

  AuthSession? get currentSession => _currentSession;
  AuthUser? get currentUser => _currentSession?.user;
  bool get isSignedIn => _currentSession?.accessToken.isNotEmpty == true;

  Future<AuthSession?> restoreSession() async {
    final callbackSession = await _consumeAuthCallback();
    if (callbackSession != null) return callbackSession;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final session = AuthSession.fromMap(decoded);
      _currentSession = session;

      if (session.isExpired && session.refreshToken.isNotEmpty) {
        return refreshSession();
      }

      return session;
    } catch (_) {
      await prefs.remove(_sessionKey);
      _currentSession = null;
      return null;
    }
  }

  Future<AuthSession> signIn(String email, String password) async {
    _ensureConfigured();

    final uri = Uri.parse(
      '${SupabaseConfig.url}/auth/v1/token',
    ).replace(queryParameters: {'grant_type': 'password'});

    final response = await http.post(
      uri,
      headers: _authHeaders,
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    if (!_isSuccess(response)) throw AuthException.fromResponse(response);

    final session = AuthSession.fromMap(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    await _saveSession(session);
    return session;
  }

  Future<AuthSession?> signUp(
    String email,
    String password,
    String name,
  ) async {
    _ensureConfigured();

    final response = await http.post(
      Uri.parse('${SupabaseConfig.url}/auth/v1/signup').replace(
        queryParameters: {'redirect_to': _publicAppRedirectUrl()},
      ),
      headers: _authHeaders,
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'data': {
          'name': name.trim(),
          'role': 'client',
        },
      }),
    );

    if (!_isSuccess(response)) throw AuthException.fromResponse(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['access_token'] == null) return null;

    final session = AuthSession.fromMap(data);
    await _saveSession(session);
    return session;
  }

  Future<AuthSession> refreshSession() async {
    final refreshToken = _currentSession?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const AuthException('Faça login novamente.');
    }

    final uri = Uri.parse(
      '${SupabaseConfig.url}/auth/v1/token',
    ).replace(queryParameters: {'grant_type': 'refresh_token'});

    final response = await http.post(
      uri,
      headers: _authHeaders,
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (!_isSuccess(response)) throw AuthException.fromResponse(response);

    final session = AuthSession.fromMap(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    await _saveSession(session);
    return session;
  }

  Future<void> recoverPassword(String email) async {
    _ensureConfigured();

    final response = await http.post(
      Uri.parse('${SupabaseConfig.url}/auth/v1/recover').replace(
        queryParameters: {'redirect_to': _publicAppRedirectUrl()},
      ),
      headers: _authHeaders,
      body: jsonEncode({'email': email.trim()}),
    );

    if (!_isSuccess(response)) throw AuthException.fromResponse(response);
  }

  Future<void> signOut() async {
    final session = _currentSession ?? await restoreSession();
    final token = session?.accessToken;
    if (SupabaseConfig.isConfigured && token != null && token.isNotEmpty) {
      await http.post(
        Uri.parse('${SupabaseConfig.url}/auth/v1/logout'),
        headers: {
          ..._authHeaders,
          'authorization': 'Bearer $token',
        },
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _currentSession = null;
  }

  Future<void> _saveSession(AuthSession session) async {
    _currentSession = session;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toMap()));
  }

  Future<AuthSession?> _consumeAuthCallback() async {
    final fragment = Uri.base.fragment;
    if (fragment.isEmpty) return null;

    final parameters = Uri.splitQueryString(fragment);
    final callbackError = parameters['error_description'];
    if (callbackError != null && callbackError.isNotEmpty) {
      clearAuthCallbackUrl();
      return null;
    }

    final accessToken = parameters['access_token'];
    final refreshToken = parameters['refresh_token'];
    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return null;
    }

    _ensureConfigured();
    final response = await http.get(
      Uri.parse('${SupabaseConfig.url}/auth/v1/user'),
      headers: {
        'apikey': SupabaseConfig.anonKey,
        'authorization': 'Bearer $accessToken',
      },
    );
    if (!_isSuccess(response)) throw AuthException.fromResponse(response);

    final session = AuthSession.fromMap({
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': int.tryParse(parameters['expires_in'] ?? '') ?? 3600,
      'user': jsonDecode(response.body),
    });
    await _saveSession(session);
    clearAuthCallbackUrl();
    return session;
  }

  String _publicAppRedirectUrl() {
    final current = Uri.base;
    if (current.scheme != 'http' && current.scheme != 'https') {
      return current.toString();
    }
    return Uri(
      scheme: current.scheme,
      host: current.host,
      port: current.hasPort ? current.port : null,
      path: '/',
      queryParameters: const {'email_confirmed': '1'},
    ).toString();
  }

  void _ensureConfigured() {
    if (!SupabaseConfig.isConfigured) {
      throw const AuthException('Configure o Supabase antes de entrar.');
    }
  }

  bool _isSuccess(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Map<String, String> get _authHeaders => {
        'apikey': SupabaseConfig.anonKey,
        'content-type': 'application/json',
      };
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final AuthUser user;

  bool get isExpired {
    return DateTime.now().isAfter(
      expiresAt.subtract(const Duration(minutes: 2)),
    );
  }

  factory AuthSession.fromMap(Map<String, dynamic> map) {
    final expiresIn = (map['expires_in'] as num?)?.toInt();
    final expiresAtSeconds = (map['expires_at'] as num?)?.toInt();
    final expiresAt = expiresAtSeconds == null
        ? DateTime.now().add(Duration(seconds: expiresIn ?? 3600))
        : DateTime.fromMillisecondsSinceEpoch(expiresAtSeconds * 1000);

    return AuthSession(
      accessToken: map['access_token']?.toString() ?? '',
      refreshToken: map['refresh_token']?.toString() ?? '',
      expiresAt: expiresAt,
      user: AuthUser.fromMap(
        Map<String, dynamic>.from(map['user'] as Map? ?? const {}),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.millisecondsSinceEpoch ~/ 1000,
      'user': user.toMap(),
    };
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
  });

  final String id;
  final String email;
  final String name;

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    final metadata = Map<String, dynamic>.from(
      map['user_metadata'] as Map? ?? const {},
    );

    return AuthUser(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      name: metadata['name']?.toString() ?? map['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'user_metadata': {'name': name},
    };
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  factory AuthException.fromResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = data['msg'] ?? data['message'] ?? data['error_description'];
      return AuthException(_friendlyMessage(raw?.toString()));
    } catch (_) {
      return const AuthException('Não foi possível concluir a autenticação.');
    }
  }

  static String _friendlyMessage(String? message) {
    final text = message?.toLowerCase() ?? '';
    if (text.contains('invalid login')) {
      return 'E-mail ou senha inválidos.';
    }
    if (text.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    if (text.contains('password')) {
      return 'Verifique a senha informada.';
    }
    if (text.contains('already registered') || text.contains('already exists')) {
      return 'Este e-mail já está cadastrado.';
    }
    return message ?? 'Não foi possível concluir a autenticação.';
  }

  @override
  String toString() => message;
}
