import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/supabase_rest_service.dart';

class AcceptedTeamInvitation {
  const AcceptedTeamInvitation({
    required this.barberShopId,
    required this.role,
  });

  final String barberShopId;
  final String role;
}

class TeamInvitationRepository {
  const TeamInvitationRepository({SupabaseRestService? rest})
      : _rest = rest ?? const SupabaseRestService();

  final SupabaseRestService _rest;

  String? pendingToken() {
    if (!kIsWeb) return null;
    final token = Uri.base.queryParameters['team_invite']?.trim();
    return token == null || token.isEmpty ? null : token;
  }

  Future<AcceptedTeamInvitation?> acceptPendingInvitation() async {
    final token = pendingToken();
    if (token == null || !_rest.isConfigured) return null;

    final auth = AuthService();
    var session = auth.currentSession ?? await auth.restoreSession();
    if (session == null) return null;
    if (session.isExpired) session = await auth.refreshSession();

    final result = await _rest.postRpc(
      'accept_shop_invitation',
      data: {'p_token': token},
      accessToken: session.accessToken,
    );
    if (result is! Map) return null;

    return AcceptedTeamInvitation(
      barberShopId: result['barber_shop_id']?.toString() ?? '',
      role: result['role']?.toString() ?? '',
    );
  }
}
