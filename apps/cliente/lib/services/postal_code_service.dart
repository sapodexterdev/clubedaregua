import 'dart:convert';

import 'package:http/http.dart' as http;

class PostalAddress {
  const PostalAddress({
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  final String street;
  final String neighborhood;
  final String city;
  final String state;

  String get formattedAddress =>
      [street, neighborhood].where((part) => part.isNotEmpty).join(' - ');
}

/// Uses a separate public HTTP client; never sends the application's session.
class PostalCodeService {
  PostalCodeService({
    http.Client? client,
    this.timeout = const Duration(seconds: 8),
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;

  Future<PostalAddress?> lookup(String postalCode) async {
    final digits = postalCode.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) {
      throw ArgumentError.value(postalCode, 'postalCode', 'Use 8 digits');
    }
    final response = await _client
        .get(Uri.https('viacep.com.br', '/ws/$digits/json/'))
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('Postal code lookup unavailable');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid postal address');
    }
    if (decoded['erro'] == true || decoded['erro'] == 'true') return null;
    String field(String key) => (decoded[key] as String? ?? '').trim();
    final address = PostalAddress(
      street: field('logradouro'),
      neighborhood: field('bairro'),
      city: field('localidade'),
      state: field('uf'),
    );
    if (address.city.isEmpty || address.state.length != 2) {
      throw const FormatException('Incomplete postal address');
    }
    return address;
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
