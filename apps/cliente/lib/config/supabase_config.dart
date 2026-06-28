class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      url.startsWith('https://') && anonKey.trim().isNotEmpty;

  static bool get canInitializeAuthSdk =>
      isConfigured && anonKey.trim().startsWith('eyJ');
}
