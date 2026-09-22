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
    expect(find.text('Cancelados'), findsOneWidget);
    expect(find.text('Atendidos'), findsOneWidget);
    expect(find.text('Clientes novos'), findsOneWidget);
    expect(find.text('Confirmados'), findsNothing);
    expect(find.text('Previsto'), findsOneWidget);
    expect(find.text('Recebido'), findsWidgets);
    expect(find.text('R\$ 4.820'), findsNothing);
    expect(find.text('R\$ 1.240'), findsNothing);
    expect(
      tester
          .getTopLeft(find.byKey(
            const ValueKey('owner-dashboard-card-Atendidos'),
          ))
          .dy,
      lessThan(tester
          .getTopLeft(find.byKey(
            const ValueKey('owner-dashboard-card-Cancelados'),
          ))
          .dy),
    );
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
      expect(find.text('Cancelados'), findsOneWidget);
      expect(find.text('Atendidos'), findsOneWidget);
      expect(find.text('Clientes novos'), findsOneWidget);
      expect(find.text('Confirmados'), findsNothing);
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
    expect(find.text('Cancelados'), findsOneWidget);
    expect(find.text('Atendidos'), findsOneWidget);
    expect(find.text('Clientes novos'), findsOneWidget);
    expect(find.text('Confirmados'), findsNothing);
    expect(find.text('Previsto'), findsOneWidget);
    expect(find.text('Recebido'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card de cancelados abre a lista do período do painel',
      (tester) async {
    final session = _DashboardSession();
    addTearDown(session.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(session));
    await tester.pump();

    final cancelledCard =
        find.byKey(const ValueKey('owner-dashboard-card-Cancelados'));
    await tester.ensureVisible(cancelledCard);
    await tester.tap(cancelledCard);
    await tester.pumpAndSettle();

    expect(find.text('Agendamentos cancelados'), findsOneWidget);
    expect(find.text('Cliente de teste'), findsOneWidget);
    expect(find.text('Motivo: conflito de horário'), findsOneWidget);
    expect(
        find.text('Considera a data marcada do agendamento.'), findsOneWidget);
    expect(session.dashboardDetailQueries, ['cancelled:7']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card sem registros não oferece navegação para detalhes',
      (tester) async {
    final session = _DashboardSession()
      ..dashboardMetrics = const DashboardMetrics(
        appointments: 0,
        cancelledAppointments: 0,
        completedAppointments: 0,
        newCustomers: 0,
        projectedRevenue: 0,
        realizedRevenue: 0,
        averageTicket: 0,
        dailyTrend: [],
      );
    addTearDown(session.dispose);
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    await tester.pumpWidget(_app(session));
    await tester.pump();

    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('owner-dashboard-card-Cancelados')),
          )
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
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
      cancelledAppointments: 1,
      completedAppointments: 1,
      newCustomers: 1,
      projectedRevenue: 90,
      realizedRevenue: 45,
      averageTicket: 45,
      dailyTrend: [],
    );
  }

  final loadedDestinations = <ManagementDestinationId>[];
  final dashboardDetailQueries = <String>[];

  @override
  bool get isSignedIn => true;

  @override
  bool get professionalAccessResolved => true;

  @override
  bool get canWorkAsBarber => true;

  @override
  bool get canManageShop => true;

  @override
  Future<List<DashboardDetailEntry>> fetchDashboardDetails({
    required String kind,
    required int days,
  }) async {
    dashboardDetailQueries.add('$kind:$days');
    return const [
      DashboardDetailEntry(
        id: 'appointment-1',
        occurredAt: DateTime(2026, 9, 18, 15),
        customerName: 'Cliente de teste',
        serviceName: 'Corte clássico',
        barberName: 'Rafael Luz',
        status: 'cancelled',
        cancellationReason: 'conflito de horário',
      ),
    ];
  }

  @override
  Future<void> ensureDataForDestination(
    ManagementRole role,
    ManagementDestinationId destination, {
    bool force = false,
  }) async {
    loadedDestinations.add(destination);
  }
}
