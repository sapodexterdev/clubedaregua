import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const _pendingTokenKey =
      'clubedaregua.team_invitation.pending_token';
  final SupabaseRestService _rest;

  Future<void> capturePendingInvitation() async {
    if (!kIsWeb) return;
    final token = Uri.base.queryParameters['team_invite']?.trim();
    if (token == null || token.isEmpty) return;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_pendingTokenKey, token);
  }

  Future<String?> pendingToken() async {
    if (kIsWeb) {
      final urlToken = Uri.base.queryParameters['team_invite']?.trim();
      if (urlToken != null && urlToken.isNotEmpty) return urlToken;
    }

    final preferences = await SharedPreferences.getInstance();
    final storedToken = preferences.getString(_pendingTokenKey)?.trim();
    return storedToken == null || storedToken.isEmpty ? null : storedToken;
  }

  Future<AcceptedTeamInvitation?> acceptPendingInvitation() async {
    final token = await pendingToken();
    if (token == null || !_rest.isConfigured) return null;

    final auth = AuthService();
    final session = await auth.getValidSession();
    if (session == null) return null;

    final result = await _rest.postRpc(
      'accept_shop_invitation',
      data: {'p_token': token},
      accessToken: session.accessToken,
    );
    if (result is! Map) return null;

    final accepted = AcceptedTeamInvitation(
      barberShopId: result['barber_shop_id']?.toString() ?? '',
      role: result['role']?.toString() ?? '',
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pendingTokenKey);
    return accepted;
  }
}
