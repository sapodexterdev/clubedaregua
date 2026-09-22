import 'package:clubedaregua_gestao/management.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Comissão apresenta os dados reais recebidos da sessão',
      (tester) async {
    final session = _CommissionSession(
      metrics: const CommissionMetrics(
        completedAppointments: 4,
        production: 500,
        commissionPercent: 40,
        commission: 200,
      ),
    );
    addTearDown(session.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(session));
    await tester.pump();
    await tester.tap(find.text('Comissão'));
    await tester.pump();

    expect(find.text('Sua comissão, com clareza'), findsOneWidget);
    expect(find.text('R\$ 500,00'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('R\$ 200,00'), findsOneWidget);
    expect(find.text('4 atendimentos concluídos'), findsOneWidget);
    expect(find.textContaining('pagamentos e repasses não são controlados'),
        findsOneWidget);
    expect(session.loadedDestinations, [ManagementDestinationId.commission]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Comissão oferece períodos e informa quando não há atendimentos',
      (tester) async {
    final session = _CommissionSession(
      metrics: const CommissionMetrics(
        completedAppointments: 0,
        production: 0,
        commissionPercent: 35,
        commission: 0,
      ),
    );
    addTearDown(session.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(session));
    await tester.pump();
    await tester.tap(find.text('Comissão'));
    await tester.pump();

    expect(find.text('Nenhum atendimento concluído'), findsOneWidget);
    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('7 dias'), findsOneWidget);
    expect(find.text('30 dias'), findsOneWidget);
    await tester.tap(find.text('30 dias'));
    await tester.pump();
    expect(session.requestedDays, [30]);
    expect(session.commissionDays, 30);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Comissão mostra loading e permite repetir após erro',
      (tester) async {
    final session = _CommissionSession(
      metrics: const CommissionMetrics(
        completedAppointments: 2,
        production: 100,
        commissionPercent: 35,
        commission: 35,
      ),
      error: 'Falha temporária.',
    );
    addTearDown(session.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    session.commissionMetrics = null;
    session.isCommissionLoading = true;
    await tester.pumpWidget(_app(session));
    await tester.pump();
    await tester.tap(find.text('Comissão'));
    await tester.pump();
    expect(find.text('Carregando sua comissão'), findsOneWidget);

    session.isCommissionLoading = false;
    session.commissionError = 'Falha temporária.';
    session.notifyListeners();
    await tester.pump();
    expect(find.text('Não foi possível carregar a comissão'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    expect(session.commissionError, isNull);
    expect(find.text('R\$ 35,00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Comissão preserva o layout em telas pequenas e desktop',
      (tester) async {
    final session = _CommissionSession(
      metrics: const CommissionMetrics(
        completedAppointments: 1,
        production: 90,
        commissionPercent: 40,
        commission: 36,
      ),
    );
    addTearDown(session.dispose);

    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(session));
    await tester.pump();
    await tester.tap(find.text('Comissão'));
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
      expect(tester.takeException(), isNull);
    }

    await tester.binding.setSurfaceSize(const Size(1440, 900));
    final cards = [
      'Produção do período',
      'Percentual aplicado',
      'Comissão calculada',
    ].map((title) => tester.getRect(
          find.byKey(ValueKey('commission-indicator-$title')),
        ));
    expect(cards.map((card) => card.top).toSet(), hasLength(1));
    expect(cards.every((card) => card.width < 400), isTrue);
  });

  testWidgets('Comissão mantém leitura com texto ampliado no mobile',
      (tester) async {
    final session = _CommissionSession(
      metrics: const CommissionMetrics(
        completedAppointments: 1,
        production: 90,
        commissionPercent: 40,
        commission: 36,
      ),
    );
    addTearDown(session.dispose);

    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(session, textScaler: const TextScaler.linear(2)),
    );
    await tester.pump();
    await tester.tap(find.text('Comissão'));
    await tester.pump();

    expect(find.text('Sua comissão, com clareza'), findsOneWidget);
    expect(find.text('Produção do período'), findsOneWidget);
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
  _CommissionSession({required this.metrics, String? error}) {
    barberShopName = 'Sapao Barber';
    isRestoringSession = false;
    commissionMetrics = metrics;
    commissionError = error;
  }

  final CommissionMetrics? metrics;
  final loadedDestinations = <ManagementDestinationId>[];
  final requestedDays = <int>[];

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

  @override
  Future<void> fetchCommissionMetrics({int? days}) async {
    if (days != null) requestedDays.add(days);
    commissionDays = days ?? commissionDays;
    commissionMetrics = metrics;
    commissionError = null;
    isCommissionLoading = false;
    notifyListeners();
  }
}
