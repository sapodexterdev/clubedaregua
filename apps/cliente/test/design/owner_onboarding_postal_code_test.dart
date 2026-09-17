import 'dart:async';
import 'dart:convert';

import 'package:clubedaregua/providers/app_state.dart';
import 'package:clubedaregua/screens/owner_onboarding_screen.dart';
import 'package:clubedaregua/services/postal_code_service.dart';
import 'package:clubedaregua/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

Finder field(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label);

String value(WidgetTester tester, String label) =>
    tester.widget<TextField>(field(label)).controller!.text;

http.Response address(String street,
        {String city = 'Uberaba', String uf = 'MG'}) =>
    http.Response.bytes(
        utf8.encode(jsonEncode({
          'logradouro': street,
          'bairro': '',
          'localidade': city,
          'uf': uf,
        })),
        200);

Future<void> openAddress(WidgetTester tester, MockClient client) async {
  final service = PostalCodeService(client: client);
  addTearDown(client.close);
  await tester.pumpWidget(ChangeNotifierProvider(
    create: (_) => AppState(),
    child: MaterialApp(
        theme: AppTheme.light,
        home: OwnerOnboardingScreen(postalCodeService: service)),
  ));
  await tester.enterText(field('Nome da barbearia'), 'Barbearia teste');
  await tester.enterText(field('WhatsApp'), '34999999999');
  await tester.ensureVisible(find.text('CONTINUAR'));
  await tester.tap(find.text('CONTINUAR'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('city-wide CEP clears the previous street', (tester) async {
    await openAddress(
        tester,
        MockClient((request) async => request.url.path.contains('01001000')
            ? address('Rua Antiga', city: 'São Paulo', uf: 'SP')
            : address('')));
    await tester.enterText(field('CEP (opcional)'), '01001000');
    await tester.pumpAndSettle();
    expect(value(tester, 'Endereço completo'), 'Rua Antiga');
    await tester.enterText(field('CEP (opcional)'), '38000000');
    await tester.pumpAndSettle();
    expect(value(tester, 'Endereço completo'), isEmpty);
    expect(value(tester, 'Cidade'), 'Uberaba');
  });

  testWidgets('leaving the step invalidates pending lookup', (tester) async {
    final pending = Completer<http.Response>();
    await openAddress(tester, MockClient((_) => pending.future));
    await tester.enterText(field('CEP (opcional)'), '38000000');
    await tester.pump();
    await tester.ensureVisible(find.text('VOLTAR'));
    await tester.tap(find.text('VOLTAR'));
    await tester.pumpAndSettle();
    pending.complete(address('Rua Remota'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('CONTINUAR'));
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    expect(value(tester, 'Endereço completo'), isEmpty);
    expect(find.text('Buscando endereço…'), findsNothing);
  });

  testWidgets('fills address automatically and preserves manual completion',
      (tester) async {
    var requests = 0;
    await openAddress(tester, MockClient((_) async {
      requests++;
      return address('Rua das Flores');
    }));
    await tester.enterText(field('CEP (opcional)'), '38000-000');
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(value(tester, 'Endereço completo'), 'Rua das Flores');
    expect(value(tester, 'Cidade'), 'Uberaba');
    expect(value(tester, 'UF'), 'MG');
    await tester.enterText(field('Endereço completo'), 'Rua das Flores, 123');
    await tester.ensureVisible(find.text('CONTINUAR'));
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    expect(find.text('Tudo certo para começar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('old CEP response cannot overwrite the latest lookup',
      (tester) async {
    final first = Completer<http.Response>();
    await openAddress(
        tester,
        MockClient((request) => request.url.path.contains('01001000')
            ? first.future
            : Future.value(address('Rua Nova'))));
    await tester.enterText(field('CEP (opcional)'), '01001000');
    await tester.pump();
    await tester.enterText(field('CEP (opcional)'), '38000000');
    await tester.pumpAndSettle();
    first.complete(address('Rua Antiga'));
    await tester.pumpAndSettle();
    expect(value(tester, 'Endereço completo'), 'Rua Nova');
  });

  testWidgets('manual edits invalidate a pending lookup', (tester) async {
    final pending = Completer<http.Response>();
    await openAddress(tester, MockClient((_) => pending.future));
    await tester.enterText(field('CEP (opcional)'), '38000000');
    await tester.pump();
    await tester.enterText(field('Endereço completo'), 'Rua Manual, 10');
    pending.complete(address('Rua Remota'));
    await tester.pumpAndSettle();
    expect(value(tester, 'Endereço completo'), 'Rua Manual, 10');
  });

  testWidgets('failed lookup allows manual completion without CEP',
      (tester) async {
    await openAddress(
        tester, MockClient((_) async => http.Response('offline', 503)));
    await tester.enterText(field('CEP (opcional)'), '38000000');
    await tester.pumpAndSettle();
    expect(find.textContaining('Não foi possível buscar'), findsOneWidget);
    await tester.enterText(field('Endereço completo'), 'Rua Manual, 10');
    await tester.enterText(field('Cidade'), 'Uberaba');
    await tester.enterText(field('UF'), 'MG');
    await tester.ensureVisible(find.text('CONTINUAR'));
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    expect(find.text('Tudo certo para começar'), findsOneWidget);
  });

  testWidgets('disposing the screen ignores pending response', (tester) async {
    final pending = Completer<http.Response>();
    await openAddress(tester, MockClient((_) => pending.future));
    await tester.enterText(field('CEP (opcional)'), '38000000');
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    pending.complete(address('Rua Remota'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
