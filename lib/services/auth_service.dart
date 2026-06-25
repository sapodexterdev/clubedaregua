import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class AuthService {
  User? get currentUser =>
      SupabaseConfig.isConfigured ? SupabaseConfig.client.auth.currentUser : null;

  Future<AuthResponse> signIn(String email, String password) {
    if (!SupabaseConfig.isConfigured) {
      throw StateError('Supabase nao configurado.');
    }
    return SupabaseConfig.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password, String name) {
    if (!SupabaseConfig.isConfigured) {
      throw StateError('Supabase nao configurado.');
    }
    return SupabaseConfig.client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'role': 'client'},
    );
  }

  Future<void> signOut() async {
    if (!SupabaseConfig.isConfigured) return;
    await SupabaseConfig.client.auth.signOut();
  }
}
