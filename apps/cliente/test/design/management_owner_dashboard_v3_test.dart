import 'package:clubedaregua_gestao/management.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('painel do Dono não apresenta números demonstrativos',
      (tester) async {
    final session = _DashboardSession();
    addTearDown(session.dispose);
    final semantics = tester.ensureSemantics();

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(session));
    await tester.pump();

    expect(find.byKey(const ValueKey('owner-dashboard-v3')), findsOneWidget);
    expect(find.text('Seus números, com clareza'), findsOneWidget);
    expect(find.text('Dados em preparação'), findsOneWidget);
    expect(find.text('R\$ 4.820'), findsNothing);
    expect(find.text('46'), findsNothing);
    expect(find.text('R\$ 1.240'), findsNothing);
    expect(find.text('18 atendimentos nesta semana'), findsNothing);
    expect(find.text('34% dos agendamentos'), findsNothing);
    final statusSemantics = tester
        .getSemantics(find.byKey(const ValueKey('owner-dashboard-status')))
        .label;
    expect(
      'Status: dados em preparação'.allMatches(statusSemantics),
      hasLength(1),
    );
    expect(session.loadedDestinations, isEmpty);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('painel do Dono é responsivo com texto ampliado', (tester) async {
    final session = _DashboardSession();
    addTearDown(session.dispose);

    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(session, textScaler: const TextScaler.linear(2)),
    );
    await tester.pump();

    for (final size in const [
      Size(360, 640),
      Size(600, 800),
      Size(768, 900),
      Size(1024, 900),
      Size(1440, 900),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pump();

      expect(find.text('Faturamento'), findsOneWidget);
      expect(find.text('Agendamentos'), findsOneWidget);
      expect(find.text('Desempenho operacional'), findsOneWidget);
      final first = tester.getRect(
        find.byKey(
          const ValueKey('owner-dashboard-indicator-Faturamento'),
        ),
      );
      final second = tester.getRect(
        find.byKey(
          const ValueKey('owner-dashboard-indicator-Agendamentos'),
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
          tester
              .getSize(find.byKey(const ValueKey('owner-dashboard-intro')))
              .width,
          lessThanOrEqualTo(760),
        );
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('painel usa três colunas no desktop com escala padrão',
      (tester) async {
    final session = _DashboardSession();
    addTearDown(session.dispose);

    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(session));
    await tester.pump();

    final cards = [
      'Faturamento',
      'Agendamentos',
      'Desempenho operacional',
    ].map(
      (title) => tester.getRect(
        find.byKey(ValueKey('owner-dashboard-indicator-$title')),
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
      child: const ManagementHomeScreen(initialRole: ManagementRole.admin),
    ),
  );
}

class _DashboardSession extends ManagementSession {
  _DashboardSession() {
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
  Future<void> ensureDataForDestination(
    ManagementRole role,
    ManagementDestinationId destination, {
    bool force = false,
  }) async {
    loadedDestinations.add(destination);
  }
}
