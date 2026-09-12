import 'package:clubedaregua_gestao/management.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Comissão não apresenta valores demonstrativos', (tester) async {
    final session = _CommissionSession();
    addTearDown(session.dispose);
    final semantics = tester.ensureSemantics();

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(session));
    await tester.pump();
    await tester.tap(find.text('Comissão'));
    await tester.pump();

    expect(find.byKey(const ValueKey('commission-page-v3')), findsOneWidget);
    expect(find.text('Sua comissão, sem estimativas'), findsOneWidget);
    expect(find.text('Dados de comissão em preparação'), findsOneWidget);
    for (final demonstrativeValue in [
      'R\$ 1.780',
      'R\$ 712',
      '31',
      'Ticket médio de R\$ 57',
      'Corte + barba',
      '14 atendimentos no período',
      'Comissão estimada (40%)',
      'R\$ 1.780,00',
      'R\$ 712,00',
      'R\$ 1.068,00',
    ]) {
      expect(find.text(demonstrativeValue), findsNothing);
    }
    final statusSemantics = tester
        .getSemantics(find.byKey(const ValueKey('commission-status')))
        .label;
    expect(
      'Status: dados de comissão em preparação'.allMatches(statusSemantics),
      hasLength(1),
    );
    expect(
      session.loadedDestinations,
      [ManagementDestinationId.commission],
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('Comissão preserva o destino e a geometria com texto ampliado',
      (tester) async {
    final session = _CommissionSession();
    addTearDown(session.dispose);

    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(session));
    await tester.pump();
    await tester.tap(find.text('Comissão'));
    await tester.pump();
    await tester.pumpWidget(
      _app(session, textScaler: const TextScaler.linear(2)),
    );
    await tester.pump();

    for (final size in const [
      Size(360, 640),
      Size(390, 844),
      Size(600, 800),
      Size(768, 900),
      Size(1024, 900),
      Size(1440, 900),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pump();

      expect(find.text('Comissão e faturamento'), findsOneWidget);
      final first = tester.getRect(
        find.byKey(
          const ValueKey('commission-indicator-Produção do período'),
        ),
      );
      final second = tester.getRect(
        find.byKey(
          const ValueKey('commission-indicator-Percentual aplicado'),
        ),
      );
      if (size.width >= 768) {
        expect(second.top, first.top);
      } else {
        expect(second.top, greaterThan(first.bottom));
      }
      if (size.width == 1440) {
        expect(first.width, lessThan(600));
        expect(
          tester.getSize(find.byKey(const ValueKey('commission-intro'))).width,
          lessThanOrEqualTo(760),
        );
      }
      expect(tester.takeException(), isNull);
    }
    expect(
      session.loadedDestinations,
      [ManagementDestinationId.commission],
    );
  });

  testWidgets('Comissão usa três colunas no desktop com escala padrão',
      (tester) async {
    final session = _CommissionSession();
    addTearDown(session.dispose);

    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(session));
    await tester.pump();
    await tester.tap(find.text('Comissão'));
    await tester.pump();

    final cards = [
      'Produção do período',
      'Percentual aplicado',
      'Repasse previsto',
    ].map(
      (title) => tester.getRect(
        find.byKey(ValueKey('commission-indicator-$title')),
      ),
    );
    final tops = cards.map((card) => card.top).toSet();

    expect(tops, hasLength(1));
    expect(cards.every((card) => card.width < 400), isTrue);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(
  ManagementSession session, {
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: ChangeNotifierProvider<ManagementSession>.value(
      value: session,
      child: const ManagementHomeScreen(initialRole: ManagementRole.barber),
    ),
  );
}

class _CommissionSession extends ManagementSession {
  _CommissionSession() {
    barberShopName = 'Sapao Barber';
    isRestoringSession = false;
  }

  final loadedDestinations = <ManagementDestinationId>[];

  @override
  bool get isSignedIn => true;

  @override
  bool get professionalAccessResolved => true;

  @override
  bool get canWorkAsBarber => true;

  @override
  bool get canManageShop => true;

  @override
  String get barberHeaderName => 'Barbeiro atual';

  @override
  Future<void> ensureDataForDestination(
    ManagementRole role,
    ManagementDestinationId destination, {
    bool force = false,
  }) async {
    loadedDestinations.add(destination);
  }
}
