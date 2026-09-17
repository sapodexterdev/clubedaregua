import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_config.dart';
import 'auth_callback_url.dart';

class AuthService {
  AuthService({
    http.Client? client,
    String? supabaseUrl,
    String? anonKey,
  })  : _client = client,
        _supabaseUrl = supabaseUrl ?? SupabaseConfig.url,
        _anonKey = anonKey ?? SupabaseConfig.anonKey;

  static const _sessionKey = 'clubedaregua.client.session';
  static const _passwordRecoveryKey =
      'clubedaregua.auth.password_recovery_pending';
  static AuthSession? _currentSession;
  static Future<AuthSession?>? _restoreInProgress;
  static int? _restoreInProgressGeneration;
  static Future<AuthSession?>? _validationInProgress;
  static int? _validationInProgressGeneration;
  static Future<AuthSession>? _refreshInProgress;
  static int? _refreshInProgressGeneration;
  static Future<void>? _signOutInProgress;
  static int? _signOutInProgressGeneration;
  static int _sessionMutationGeneration = 0;

  final http.Client? _client;
  final String _supabaseUrl;
  final String _anonKey;

  AuthSession? get currentSession => _currentSession;
  AuthUser? get currentUser => _currentSession?.user;
  bool get isSignedIn => _currentSession?.accessToken.isNotEmpty == true;

  Future<AuthSession?> getValidSession() async {
    final signOut = _signOutInProgress;
    if (signOut != null &&
        _signOutInProgressGeneration == _sessionMutationGeneration) {
      await signOut;
      return null;
    }
    final session = _currentSession;
    if (session == null) return restoreSession();
    if (!session.isExpired) return session;

    final currentValidation = _validationInProgress;
    if (currentValidation != null &&
        _validationInProgressGeneration == _sessionMutationGeneration) {
      return currentValidation;
    }

    final validation = _refreshSessionSafely();
    _validationInProgress = validation;
    _validationInProgressGeneration = _sessionMutationGeneration;
    try {
      return await validation;
    } finally {
      if (identical(_validationInProgress, validation)) {
        _validationInProgress = null;
        _validationInProgressGeneration = null;
      }
    }
  }

  Future<AuthSession?> _refreshSessionSafely() async {
    try {
      return await refreshSession();
    } catch (_) {
      return null;
    }
  }

  Future<AuthSession?> restoreSession() async {
    final signOut = _signOutInProgress;
    if (signOut != null &&
        _signOutInProgressGeneration == _sessionMutationGeneration) {
      await signOut;
      return null;
    }
    final currentRestore = _restoreInProgress;
    if (currentRestore != null &&
        _restoreInProgressGeneration == _sessionMutationGeneration) {
      return currentRestore;
    }

    final generation = _sessionMutationGeneration;
    final restore = _restoreSessionSafely(generation);
    _restoreInProgress = restore;
    _restoreInProgressGeneration = generation;
    try {
      return await restore;
    } finally {
      if (identical(_restoreInProgress, restore)) {
        _restoreInProgress = null;
        _restoreInProgressGeneration = null;
      }
    }
  }

  Future<AuthSession?> _restoreSessionSafely(int generation) async {
    try {
      final callbackSession = await _consumeAuthCallback(generation);
      _ensureCurrentGeneration(generation);
      if (callbackSession != null) return callbackSession;
    } catch (_) {
      clearAuthCallbackUrl();
      await _clearLocalSession(expectedGeneration: generation);
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!_isCurrentGeneration(generation)) return null;
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final session = AuthSession.fromMap(decoded);
      _ensureCurrentGeneration(generation);
      _currentSession = session;

      if (session.isExpired && session.refreshToken.isNotEmpty) {
        try {
          return await refreshSession();
        } catch (_) {
          await _clearLocalSession(expectedGeneration: generation);
          return null;
        }
      }

      _ensureCurrentGeneration(generation);
      return session;
    } catch (_) {
      await _clearLocalSession(expectedGeneration: generation);
      return null;
    }
  }

  Future<AuthSession> signIn(String email, String password) async {
    _ensureConfigured();
    final generation = ++_sessionMutationGeneration;

    final uri = Uri.parse(
      '$_supabaseUrl/auth/v1/token',
    ).replace(queryParameters: {'grant_type': 'password'});

    final response = await _post(
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
    await _saveSession(session, generation: generation);
    return session;
  }

  Future<AuthSession?> signUp(
    String email,
    String password,
    String name,
  ) async {
    _ensureConfigured();
    final generation = ++_sessionMutationGeneration;

    final response = await _post(
      Uri.parse('$_supabaseUrl/auth/v1/signup').replace(
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
    await _saveSession(session, generation: generation);
    return session;
  }

  Future<AuthSession> refreshSession() async {
    final currentRefresh = _refreshInProgress;
    if (currentRefresh != null &&
        _refreshInProgressGeneration == _sessionMutationGeneration) {
      return currentRefresh;
    }

    final generation = _sessionMutationGeneration;
    final refresh = _performRefreshSession(generation);
    _refreshInProgress = refresh;
    _refreshInProgressGeneration = generation;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshInProgress, refresh)) {
        _refreshInProgress = null;
        _refreshInProgressGeneration = null;
      }
    }
  }

  Future<AuthSession> _performRefreshSession(int generation) async {
    final refreshToken = _currentSession?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const AuthException('Faça login novamente.');
    }

    final uri = Uri.parse(
      '$_supabaseUrl/auth/v1/token',
    ).replace(queryParameters: {'grant_type': 'refresh_token'});

    final response = await _post(
      uri,
      headers: _authHeaders,
      body: jsonEncode({'refresh_token': refreshToken}),
    ).timeout(const Duration(seconds: 12));
    _ensureCurrentGeneration(generation);

    if (!_isSuccess(response)) {
      if (response.statusCode == 400 || response.statusCode == 401) {
        await _clearLocalSession(expectedGeneration: generation);
      }
      throw AuthException.fromResponse(response);
    }

    final session = AuthSession.fromMap(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    await _saveSession(session, generation: generation);
    return session;
  }

  Future<void> recoverPassword(String email) async {
    _ensureConfigured();

    final response = await _post(
      Uri.parse('$_supabaseUrl/auth/v1/recover').replace(
        queryParameters: {'redirect_to': _publicAppRedirectUrl()},
      ),
      headers: _authHeaders,
      body: jsonEncode({'email': email.trim()}),
    );

    if (!_isSuccess(response)) throw AuthException.fromResponse(response);
  }

  Future<bool> hasPendingPasswordRecovery() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_passwordRecoveryKey) ?? false;
  }

  Future<void> updatePassword(String password) async {
    _ensureConfigured();
    final session = await getValidSession();
    if (session == null) {
      throw const AuthException(
        'O link expirou. Solicite uma nova recuperação de senha.',
      );
    }

    final response = await _patch(
      Uri.parse('$_supabaseUrl/auth/v1/user'),
      headers: {
        ..._authHeaders,
        'authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({'password': password}),
    );
    if (!_isSuccess(response)) throw AuthException.fromResponse(response);

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_passwordRecoveryKey);
  }

  Future<void> signOut() async {
    final currentSignOut = _signOutInProgress;
    if (currentSignOut != null &&
        _signOutInProgressGeneration == _sessionMutationGeneration) {
      return currentSignOut;
    }

    final generation = ++_sessionMutationGeneration;
    final session = _currentSession;
    _currentSession = null;
    final signOut = _performSignOut(generation, session);
    _signOutInProgress = signOut;
    _signOutInProgressGeneration = generation;
    try {
      await signOut;
    } finally {
      if (identical(_signOutInProgress, signOut)) {
        _signOutInProgress = null;
        _signOutInProgressGeneration = null;
      }
    }
  }

  Future<void> _performSignOut(
    int generation,
    AuthSession? session,
  ) async {
    final token = session?.accessToken;
    try {
      if (_isConfigured && token != null && token.isNotEmpty) {
        await _post(
          Uri.parse('$_supabaseUrl/auth/v1/logout'),
          headers: {
            ..._authHeaders,
            'authorization': 'Bearer $token',
          },
        );
      }
    } catch (_) {
      // O logout local não pode depender da disponibilidade da rede.
    } finally {
      await _clearLocalSession(expectedGeneration: generation);
    }
  }

  Future<void> _saveSession(
    AuthSession session, {
    required int generation,
  }) async {
    _ensureCurrentGeneration(generation);
    final prefs = await SharedPreferences.getInstance();
    final encodedSession = jsonEncode(session.toMap());
    _ensureCurrentGeneration(generation);
    await prefs.setString(_sessionKey, encodedSession);
    if (!_isCurrentGeneration(generation)) {
      if (prefs.getString(_sessionKey) == encodedSession) {
        await prefs.remove(_sessionKey);
      }
      throw const AuthException('A sessão foi substituída. Entre novamente.');
    }
    _currentSession = session;
  }

  Future<void> _clearLocalSession({int? expectedGeneration}) async {
    if (expectedGeneration != null &&
        !_isCurrentGeneration(expectedGeneration)) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (expectedGeneration != null &&
        !_isCurrentGeneration(expectedGeneration)) {
      return;
    }
    await prefs.remove(_sessionKey);
    await prefs.remove(_passwordRecoveryKey);
    if (expectedGeneration == null ||
        _isCurrentGeneration(expectedGeneration)) {
      _currentSession = null;
    }
  }

  Future<AuthSession?> _consumeAuthCallback(int generation) async {
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
    final response = await _get(
      Uri.parse('$_supabaseUrl/auth/v1/user'),
      headers: {
        'apikey': _anonKey,
        'authorization': 'Bearer $accessToken',
      },
    );
    _ensureCurrentGeneration(generation);
    if (!_isSuccess(response)) throw AuthException.fromResponse(response);

    final session = AuthSession.fromMap({
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': int.tryParse(parameters['expires_in'] ?? '') ?? 3600,
      'user': jsonDecode(response.body),
    });
    await _saveSession(session, generation: generation);
    if (parameters['type'] == 'recovery') {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_passwordRecoveryKey, true);
    }
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
    if (!_isConfigured) {
      throw const AuthException('Configure o Supabase antes de entrar.');
    }
  }

  bool get _isConfigured =>
      _supabaseUrl.startsWith('https://') &&
      !_supabaseUrl.contains('seu-projeto') &&
      _anonKey.trim().isNotEmpty &&
      _anonKey.trim() != 'SUA_ANON_KEY';

  bool _isSuccess(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Map<String, String> get _authHeaders => {
        'apikey': _anonKey,
        'content-type': 'application/json',
      };

  Future<http.Response> _post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    final client = _client;
    return client == null
        ? http.post(uri, headers: headers, body: body)
        : client.post(uri, headers: headers, body: body);
  }

  Future<http.Response> _get(
    Uri uri, {
    Map<String, String>? headers,
  }) {
    final client = _client;
    return client == null
        ? http.get(uri, headers: headers)
        : client.get(uri, headers: headers);
  }

  Future<http.Response> _patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    final client = _client;
    return client == null
        ? http.patch(uri, headers: headers, body: body)
        : client.patch(uri, headers: headers, body: body);
  }

  static void resetInMemoryForTesting() {
    _currentSession = null;
    _restoreInProgress = null;
    _restoreInProgressGeneration = null;
    _validationInProgress = null;
    _validationInProgressGeneration = null;
    _refreshInProgress = null;
    _refreshInProgressGeneration = null;
    _signOutInProgress = null;
    _signOutInProgressGeneration = null;
    _sessionMutationGeneration = 0;
  }

  static bool _isCurrentGeneration(int generation) =>
      generation == _sessionMutationGeneration;

  static void _ensureCurrentGeneration(int generation) {
    if (!_isCurrentGeneration(generation)) {
      throw const AuthException('A sessão foi substituída. Entre novamente.');
    }
  }
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
    if (text.contains('already registered') ||
        text.contains('already exists')) {
      return 'Este e-mail já está cadastrado.';
    }
    return message ?? 'Não foi possível concluir a autenticação.';
  }

  @override
  String toString() => message;
}
