import '../models/notification_item.dart';
import '../services/auth_service.dart';
import '../services/supabase_rest_service.dart';

class NotificationRepository {
  const NotificationRepository({SupabaseRestService? rest})
      : _rest = rest ?? const SupabaseRestService();

  final SupabaseRestService _rest;

  Future<List<NotificationItem>> fetchNotifications() async {
    final session = await _authenticatedSession();
    if (session == null) return const [];
    final rows = await _rest.getRows(
      'notifications',
      select: 'id,title,message,is_read,created_at',
      filters: {'user_id': 'eq.${session.user.id}'},
      order: 'created_at.desc',
      limit: 100,
      accessToken: session.accessToken,
      preventCache: true,
    );
    return rows.map((row) {
      return NotificationItem(
        id: row['id']?.toString() ?? '',
        title: row['title']?.toString() ?? 'Atualização',
        message: row['message']?.toString() ?? '',
        isRead: row['is_read'] == true,
        createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '')
                ?.toLocal() ??
            DateTime.now(),
      );
    }).where((item) => item.id.isNotEmpty).toList();
  }

  Future<bool> markAsRead(String notificationId) async {
    final session = await _authenticatedSession();
    if (session == null || notificationId.isEmpty) return false;
    return _rest.updateRows(
      'notifications',
      data: const {'is_read': true},
      filters: {
        'id': 'eq.$notificationId',
        'user_id': 'eq.${session.user.id}',
      },
      accessToken: session.accessToken,
    );
  }

  Future<bool> markAllAsRead() async {
    final session = await _authenticatedSession();
    if (session == null) return false;
    return _rest.updateRows(
      'notifications',
      data: const {'is_read': true},
      filters: {
        'user_id': 'eq.${session.user.id}',
        'is_read': 'eq.false',
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
