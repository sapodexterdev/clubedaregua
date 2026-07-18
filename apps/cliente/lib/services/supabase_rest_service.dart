import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';

class SupabaseRestService {
  const SupabaseRestService();

  static const _requestTimeout = Duration(seconds: 8);

  bool get isConfigured => SupabaseConfig.isConfigured;

  Future<List<Map<String, dynamic>>> getRows(
    String table, {
    required String select,
    Map<String, String> filters = const {},
    String? order,
    int? limit,
    String? accessToken,
  }) async {
    if (!isConfigured) return const [];

    final query = <String, String>{
      'select': select,
      ...filters,
      if (order != null) 'order': order,
      if (limit != null) 'limit': limit.toString(),
    };

    final uri = Uri.parse('${SupabaseConfig.url}/rest/v1/$table').replace(
      queryParameters: query,
    );

    final response = await http
        .get(
          uri,
          headers: {
            'apikey': SupabaseConfig.anonKey,
            'authorization':
                'Bearer ${accessToken ?? SupabaseConfig.anonKey}',
          },
        )
        .timeout(_requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Supabase REST ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<bool> insertRow(
    String table,
    Map<String, dynamic> data, {
    String? accessToken,
  }) async {
    if (!isConfigured) return false;

    final uri = Uri.parse('${SupabaseConfig.url}/rest/v1/$table');

    final response = await http
        .post(
          uri,
          headers: {
            'apikey': SupabaseConfig.anonKey,
            'authorization':
                'Bearer ${accessToken ?? SupabaseConfig.anonKey}',
            'content-type': 'application/json',
            'prefer': 'return=representation',
          },
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Supabase REST ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    return decoded is List && decoded.isNotEmpty;
  }

  Future<bool> updateRows(
    String table, {
    required Map<String, dynamic> data,
    required Map<String, String> filters,
    String? accessToken,
  }) async {
    if (!isConfigured) return false;

    final uri = Uri.parse('${SupabaseConfig.url}/rest/v1/$table').replace(
      queryParameters: filters,
    );
    final response = await http
        .patch(
          uri,
          headers: {
            'apikey': SupabaseConfig.anonKey,
            'authorization':
                'Bearer ${accessToken ?? SupabaseConfig.anonKey}',
            'content-type': 'application/json',
            'prefer': 'return=representation',
          },
          body: jsonEncode(data),
        )
        .timeout(_requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Supabase REST ${response.statusCode}: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    return decoded is List && decoded.isNotEmpty;
  }

  Future<bool> deleteRows(
    String table, {
    required Map<String, String> filters,
    String? accessToken,
  }) async {
    if (!isConfigured) return false;

    final uri = Uri.parse('${SupabaseConfig.url}/rest/v1/$table').replace(
      queryParameters: filters,
    );
    final response = await http
        .delete(
          uri,
          headers: {
            'apikey': SupabaseConfig.anonKey,
            'authorization':
                'Bearer ${accessToken ?? SupabaseConfig.anonKey}',
            'prefer': 'return=representation',
          },
        )
        .timeout(_requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Supabase REST ${response.statusCode}: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    return decoded is List && decoded.isNotEmpty;
  }

  Future<bool> exists(
    String table, {
    Map<String, String> filters = const {},
  }) async {
    if (!isConfigured) return false;

    final rows = await getRows(
      table,
      select: 'id',
      filters: filters,
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
