class SupabaseConfig {
  static bool isConfigured = false;
  static String url = '';
  static String anonKey = '';

  static Future<void> initialize() {
    const definedUrl = String.fromEnvironment('SUPABASE_URL');
    const definedAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    url = definedUrl;
    anonKey = definedAnonKey;

    if (url.isEmpty ||
        anonKey.isEmpty ||
        url.contains('your-project') ||
        anonKey.contains('your-public')) {
      isConfigured = false;
      return Future.value();
    }

    isConfigured = true;
    return Future.value();
  }
}
