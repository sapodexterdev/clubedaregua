import '../services/auth_service.dart';
import '../services/supabase_rest_service.dart';

class FavoriteRepository {
  const FavoriteRepository({SupabaseRestService? rest})
      : _rest = rest ?? const SupabaseRestService();

  final SupabaseRestService _rest;

  Future<Set<String>> fetchFavoriteShopIds() async {
    if (!_rest.isConfigured) return <String>{};
    final session = await _authenticatedSession();
    if (session == null) return <String>{};
    final rows = await _rest.getRows(
      'client_favorites',
      select: 'barber_shop_id',
      filters: {'client_id': 'eq.${session.user.id}'},
      order: 'created_at.desc',
      accessToken: session.accessToken,
    );
    return rows
        .map((row) => row['barber_shop_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<bool> addFavorite(String shopId) async {
    final session = await _authenticatedSession();
    if (session == null || shopId.isEmpty) return false;
    return _rest.insertRow(
      'client_favorites',
      {
        'client_id': session.user.id,
        'barber_shop_id': shopId,
      },
      accessToken: session.accessToken,
    );
  }

  Future<bool> removeFavorite(String shopId) async {
    final session = await _authenticatedSession();
    if (session == null || shopId.isEmpty) return false;
    return _rest.deleteRows(
      'client_favorites',
      filters: {
        'client_id': 'eq.${session.user.id}',
        'barber_shop_id': 'eq.$shopId',
      },
      accessToken: session.accessToken,
    );
  }

  Future<AuthSession?> _authenticatedSession() async {
    final auth = AuthService();
    var session = auth.currentSession ?? await auth.restoreSession();
    if (session?.isExpired == true) session = await auth.refreshSession();
    return session;
  }
}
