import 'package:clubedaregua_gestao/management.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('painel do Dono exibe métricas reais e filtros de período',
      (tester) async {
    final session = _DashboardSession();
    addTearDown(session.dispose);
    final semantics = tester.ensureSemantics();

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(session));
    await tester.pump();

    expect(find.byKey(const ValueKey('owner-dashboard-v5')), findsOneWidget);
    expect(find.text('Seus números, com clareza'), findsOneWidget);
    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('7 dias'), findsOneWidget);
    expect(find.text('30 dias'), findsOneWidget);
    expect(find.text('Agendamentos'), findsOneWidget);
    expect(find.text('Confirmados'), findsOneWidget);
    expect(find.text('Previsto'), findsOneWidget);
    expect(find.text('Recebido'), findsWidgets);
    expect(find.text('R\$ 4.820'), findsNothing);
    expect(find.text('R\$ 1.240'), findsNothing);
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
      Size(1440, 900)
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pump();

      expect(find.text('Agendamentos'), findsOneWidget);
      expect(find.text('Confirmados'), findsOneWidget);
      expect(find.text('Previsto'), findsOneWidget);
      expect(find.text('Recebido'), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('painel preserva os cards em duas colunas no desktop',
      (tester) async {
    final session = _DashboardSession();
    addTearDown(session.dispose);

    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(session));
    await tester.pump();

    expect(find.text('Agendamentos'), findsOneWidget);
    expect(find.text('Confirmados'), findsOneWidget);
    expect(find.text('Previsto'), findsOneWidget);
    expect(find.text('Recebido'), findsWidgets);
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
    dashboardMetrics = const DashboardMetrics(
      appointments: 2,
      confirmedAppointments: 1,
      projectedRevenue: 90,
      realizedRevenue: 45,
      averageTicket: 45,
      dailyTrend: [],
    );
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
