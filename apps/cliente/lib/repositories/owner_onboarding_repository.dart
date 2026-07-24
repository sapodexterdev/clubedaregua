import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';
import '../services/auth_service.dart';

class OwnerOnboardingResult {
  const OwnerOnboardingResult({
    required this.barberShopId,
    required this.slug,
    required this.trialEndsAt,
    required this.servesAsBarber,
  });

  final String barberShopId;
  final String slug;
  final DateTime? trialEndsAt;
  final bool servesAsBarber;

  factory OwnerOnboardingResult.fromMap(Map<String, dynamic> map) {
    return OwnerOnboardingResult(
      barberShopId: map['barber_shop_id']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      trialEndsAt: DateTime.tryParse(
        map['trial_ends_at']?.toString() ?? '',
      ),
      servesAsBarber: map['serves_as_barber'] == true,
    );
  }
}

class OwnerOnboardingRepository {
  const OwnerOnboardingRepository();

  Future<OwnerOnboardingResult> createBarbershop({
    required String name,
    required String phone,
    required String whatsapp,
    required String address,
    required String city,
    required String state,
    required String ownerName,
    required bool servesAsBarber,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      throw StateError('O serviço ainda não está configurado.');
    }

    final auth = AuthService();
    var session = auth.currentSession ?? await auth.restoreSession();
    if (session == null) {
      throw StateError('Faça login novamente para continuar.');
    }
    if (session.isExpired) session = await auth.refreshSession();

    final response = await http
        .post(
          Uri.parse(
            '${SupabaseConfig.url}/rest/v1/rpc/create_owner_barbershop',
          ),
          headers: {
            'apikey': SupabaseConfig.anonKey,
            'authorization': 'Bearer ${session.accessToken}',
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'p_name': name.trim(),
            'p_phone': phone.trim(),
            'p_whatsapp': whatsapp.trim(),
            'p_address': address.trim(),
            'p_city': city.trim(),
            'p_state': state.trim(),
            'p_owner_name': ownerName.trim(),
            'p_serves_as_barber': servesAsBarber,
            'p_plan_slug': 'pro',
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_errorMessage(response.body));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw StateError('Não foi possível concluir o cadastro da barbearia.');
    }

    final result = OwnerOnboardingResult.fromMap(
      Map<String, dynamic>.from(decoded),
    );
    if (result.barberShopId.isEmpty) {
      throw StateError('A barbearia foi criada sem identificação válida.');
    }
    return result;
  }

  String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return 'Não foi possível cadastrar a barbearia. Tente novamente.';
  }
}
