import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';

class SupabaseRestService {
  const SupabaseRestService();

  bool get isConfigured => SupabaseConfig.isConfigured;

  Future<List<Map<String, dynamic>>> getRows(
    String table, {
    required String select,
    Map<String, String> filters = const {},
    String? order,
    int? limit,
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

    final response = await http.get(
      uri,
      headers: {
        'apikey': SupabaseConfig.anonKey,
        'authorization': 'Bearer ${SupabaseConfig.anonKey}',
      },
    );

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
    Map<String, dynamic> data,
  ) async {
    if (!isConfigured) return false;

    final uri = Uri.parse('${SupabaseConfig.url}/rest/v1/$table');

    final response = await http.post(
      uri,
      headers: {
        'apikey': SupabaseConfig.anonKey,
        'authorization': 'Bearer ${SupabaseConfig.anonKey}',
        'content-type': 'application/json',
        'prefer': 'return=minimal',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Supabase REST ${response.statusCode}: ${response.body}');
    }

    return true;
  }
}
