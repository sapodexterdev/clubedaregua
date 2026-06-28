import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Object? get currentUser => _client?.auth.currentUser;

  Future<void> signIn(String email, String password) async {
    final client = _client;
    if (client == null) return;

    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUp(String email, String password, String name) async {
    final client = _client;
    if (client == null) return;

    await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'name': name.trim(), 'role': 'client'},
    );
  }

  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;

    await client.auth.signOut();
  }
}
