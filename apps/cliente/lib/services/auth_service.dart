import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class AuthService {
  User? get currentUser {
    if (!SupabaseConfig.isConfigured) return null;
    return SupabaseConfig.client.auth.currentUser;
  }

  Future<void> signIn(String email, String password) async {
    if (!SupabaseConfig.isConfigured) return;

    await SupabaseConfig.client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUp(String email, String password, String name) async {
    if (!SupabaseConfig.isConfigured) return;

    await SupabaseConfig.client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'name': name.trim(), 'role': 'client'},
    );
  }

  Future<void> signOut() async {
    if (!SupabaseConfig.isConfigured) return;

    await SupabaseConfig.client.auth.signOut();
  }
}
