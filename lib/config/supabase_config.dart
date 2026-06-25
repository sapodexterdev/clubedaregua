import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static SupabaseClient get client => Supabase.instance.client;
  static bool isConfigured = false;

  static Future<void> initialize() async {
    const definedUrl = String.fromEnvironment('SUPABASE_URL');
    const definedAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    var url = definedUrl;
    var anonKey = definedAnonKey;

    if (url.isEmpty || anonKey.isEmpty) {
      try {
        await dotenv.load(fileName: '.env');
        url = dotenv.env['SUPABASE_URL'] ?? '';
        anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      } catch (_) {
        try {
          await dotenv.load(fileName: '.env.example');
          url = dotenv.env['SUPABASE_URL'] ?? '';
          anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
        } catch (_) {
          url = '';
          anonKey = '';
        }
      }
    }

    if (url.isEmpty ||
        anonKey.isEmpty ||
        url.contains('your-project') ||
        anonKey.contains('your-public')) {
      isConfigured = false;
      return;
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    isConfigured = true;
  }
}
