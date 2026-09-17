import 'dart:async';
import 'dart:convert';

import 'package:clubedaregua/services/postal_code_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('looks up formatted CEP over HTTPS without session headers', () async {
    final service = PostalCodeService(client: MockClient((request) async {
      expect(request.url.toString(), 'https://viacep.com.br/ws/01001000/json/');
      expect(request.headers.containsKey('authorization'), isFalse);
      expect(request.headers.containsKey('apikey'), isFalse);
      return http.Response.bytes(
          utf8.encode(jsonEncode({
            'logradouro': 'Praça da Sé',
            'bairro': 'Sé',
            'localidade': 'São Paulo',
            'uf': 'SP',
          })),
          200);
    }));
    final address = await service.lookup('01001-000');
    expect(address!.formattedAddress, 'Praça da Sé - Sé');
    expect(address.city, 'São Paulo');
    expect(address.state, 'SP');
  });

  test('incomplete CEP never makes a request', () async {
    final service = PostalCodeService(client: MockClient((_) async {
      fail('Invalid CEP must not make a request');
    }));
    await expectLater(service.lookup('123'), throwsArgumentError);
  });

  for (final error in [true, 'true']) {
    test('handles not found: $error (${error.runtimeType})', () async {
      final service = PostalCodeService(
          client: MockClient(
              (_) async => http.Response(jsonEncode({'erro': error}), 200)));
      expect(await service.lookup('99999999'), isNull);
    });
  }

  test('city-wide CEP accepts empty street and neighborhood', () async {
    final service = PostalCodeService(
        client: MockClient((_) async =>
            http.Response('{"localidade":"Uberaba","uf":"MG"}', 200)));
    final address = await service.lookup('38000000');
    expect(address!.formattedAddress, isEmpty);
    expect(address.city, 'Uberaba');
  });

  test('unavailable and malformed responses fail instead of filling fields',
      () async {
    for (final response in [
      http.Response('unavailable', 503),
      http.Response('not json', 200),
      http.Response('{}', 200)
    ]) {
      final service =
          PostalCodeService(client: MockClient((_) async => response));
      await expectLater(service.lookup('01001000'), throwsA(isA<Exception>()));
    }
  });

  test('lookup has a bounded timeout', () async {
    final service = PostalCodeService(
      client: MockClient((_) => Completer<http.Response>().future),
      timeout: const Duration(milliseconds: 10),
    );
    await expectLater(
        service.lookup('01001000'), throwsA(isA<TimeoutException>()));
  });
}
