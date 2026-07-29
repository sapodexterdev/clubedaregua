import '../services/auth_service.dart';
import '../services/supabase_rest_service.dart';

class ClientProfile {
  const ClientProfile({
    required this.fullName,
    required this.email,
    required this.phone,
  });

  final String fullName;
  final String email;
  final String phone;
}

class ClientProfileRepository {
  const ClientProfileRepository({SupabaseRestService? rest})
      : _rest = rest ?? const SupabaseRestService();

  final SupabaseRestService _rest;

  Future<ClientProfile?> fetchProfile() async {
    final session = await _authenticatedSession();
    if (session == null) return null;
    final rows = await _rest.getRows(
      'profiles',
      select: 'full_name,phone',
      filters: {'user_id': 'eq.${session.user.id}'},
      limit: 1,
      accessToken: session.accessToken,
    );
    if (rows.isEmpty) {
      return ClientProfile(
        fullName: session.user.name,
        email: session.user.email,
        phone: '',
      );
    }
    final row = rows.first;
    return ClientProfile(
      fullName: row['full_name']?.toString() ?? session.user.name,
      email: session.user.email,
      phone: row['phone']?.toString() ?? '',
    );
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final session = await _authenticatedSession();
    if (session == null) return false;
    return _rest.updateRows(
      'profiles',
      data: {
        'full_name': fullName.trim(),
        'phone': phone.trim().isEmpty ? null : phone.trim(),
      },
      filters: {'user_id': 'eq.${session.user.id}'},
      accessToken: session.accessToken,
    );
  }

  Future<AuthSession?> _authenticatedSession() async {
    final auth = AuthService();
    return auth.getValidSession();
  }
}
