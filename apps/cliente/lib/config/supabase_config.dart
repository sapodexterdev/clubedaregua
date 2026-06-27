import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static bool isConfigured = false;
  static String url = '';
  static String anonKey = '';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    const definedUrl = String.fromEnvironment('SUPABASE_URL');
    const definedAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    url = definedUrl;
    anonKey = definedAnonKey;

    if (url.isEmpty ||
        anonKey.isEmpty ||
        url.contains('your-project') ||
        anonKey.contains('your-public')) {
      isConfigured = false;
      return;
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
    isConfigured = true;
  }
}
