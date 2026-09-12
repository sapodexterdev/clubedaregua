import 'package:clubedaregua_gestao/management.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Agenda do Barbeiro suporta texto ampliado e seleção de data',
      (tester) async {
    final session = _AgendaSession();
    addTearDown(session.dispose);
    final semantics = tester.ensureSemantics();

    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        session,
        role: ManagementRole.barber,
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pump();

    expect(find.text('Agendamentos no dia'), findsOneWidget);
    expect(find.text('Confirmados no dia'), findsOneWidget);
    final appointments = tester.getRect(
      find.byKey(const ValueKey('agenda-metric-appointments')),
    );
    final confirmed = tester.getRect(
      find.byKey(const ValueKey('agenda-metric-confirmed')),
    );
    expect(confirmed.top, greaterThan(appointments.bottom));
    expect(find.text('Agenda vazia'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final today = session.selectedScheduleDate;
    final todayFinder = find.byKey(
      ValueKey('schedule-day-${_dateKey(today)}'),
    );
    await tester.ensureVisible(todayFinder);
    await tester.pump();
    final todaySemantics = tester.getSemantics(todayFinder).getSemanticsData();
    expect(todaySemantics.label, contains(_fullDateLabel(today)));
    expect(todaySemantics.label, isNot(contains('selecionado')));
    expect(todaySemantics.hasFlag(SemanticsFlag.isSelected), isTrue);

    final tomorrow = today.add(const Duration(days: 1));
    final tomorrowFinder = find.byKey(
      ValueKey('schedule-day-${_dateKey(tomorrow)}'),
    );
    await tester.ensureVisible(tomorrowFinder);
    await tester.pump();
    final tomorrowSemantics = tester.getSemantics(tomorrowFinder).label;
    expect(tomorrowSemantics, contains(_fullDateLabel(tomorrow)));
    await tester.tap(tomorrowFinder);
    await tester.pump();

    expect(session.dateSelections, [tomorrow]);
    expect(
      tester
          .getSemantics(tomorrowFinder)
          .getSemanticsData()
          .hasFlag(SemanticsFlag.isSelected),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('Agenda separa loading inicial do estado vazio', (tester) async {
    final session = _AgendaSession()..isScheduleLoading = true;
    addTearDown(session.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(session, role: ManagementRole.barber));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('agenda-initial-loading')),
      findsOneWidget,
    );
    expect(find.text('Agenda vazia'), findsNothing);
    expect(
      find.byKey(const ValueKey('agenda-metric-appointments')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Agenda preserva layout entre breakpoints com texto ampliado',
      (tester) async {
    final session = _AgendaSession();
    addTearDown(session.dispose);

    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        session,
        role: ManagementRole.barber,
        textScaler: const TextScaler.linear(2),
      ),
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

      final appointments = tester.getRect(
        find.byKey(const ValueKey('agenda-metric-appointments')),
      );
      final confirmed = tester.getRect(
        find.byKey(const ValueKey('agenda-metric-confirmed')),
      );
      if (size.width >= 768) {
        expect(confirmed.top, appointments.top);
      } else {
        expect(confirmed.top, greaterThan(appointments.bottom));
      }
      expect(find.text('Agenda do barbeiro'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Agenda do Dono mantém nomes longos e detalhes roláveis',
      (tester) async {
    final session = _AgendaSession(populated: true);
    addTearDown(session.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(session, role: ManagementRole.admin));
    await tester.pump();
    await tester.tap(find.text('Agenda'));
    await tester.pump();
    await tester.pump();
    await tester.pumpWidget(
      _app(
        session,
        role: ManagementRole.admin,
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pump();

    expect(find.text('Todos os barbeiros'), findsOneWidget);
    expect(find.text(_AgendaSession.longClient), findsOneWidget);
    expect(find.text(_AgendaSession.longService), findsOneWidget);
    expect(find.text(_AgendaSession.longBarber), findsWidgets);
    expect(find.text(_AgendaSession.longStatus.toUpperCase()), findsOneWidget);
    expect(session.adminViewChanges, 1);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text(_AgendaSession.longClient));
    await tester.tap(find.text(_AgendaSession.longClient));
    await tester.pumpAndSettle();

    expect(find.text('DETALHES DO ATENDIMENTO'), findsOneWidget);
    expect(find.text(_AgendaSession.longNotes), findsOneWidget);
    final detailsScrollable = find.descendant(
      of: find.byKey(const ValueKey('agenda-details-scroll')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('CONCLUIR ATENDIMENTO'),
      120,
      scrollable: detailsScrollable,
    );
    await tester.pump();
    expect(find.text('CONCLUIR ATENDIMENTO').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Agenda preenchida preserva o card amplo no desktop',
      (tester) async {
    final session = _AgendaSession(populated: true);
    addTearDown(session.dispose);

    await tester.binding.setSurfaceSize(const Size(1024, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(session, role: ManagementRole.admin));
    await tester.pump();
    await tester.tap(find.text('Agenda'));
    await tester.pump();
    await tester.pump();

    expect(find.text(_AgendaSession.longClient), findsOneWidget);
    expect(find.text(_AgendaSession.longService), findsOneWidget);
    expect(find.text(_AgendaSession.longBarber), findsWidgets);
    expect(find.text(_AgendaSession.longStatus.toUpperCase()), findsOneWidget);
    expect(session.adminViewChanges, 1);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(_AgendaSession.longClient));
    await tester.pumpAndSettle();

    expect(find.text('DETALHES DO ATENDIMENTO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Agenda oculta erro técnico e mantém retry', (tester) async {
    final session = _AgendaSession()
      ..scheduleError = 'PostgrestException: relation schedules failed';
    addTearDown(session.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(session, role: ManagementRole.barber));
    await tester.pump();

    expect(
      find.text('Tente novamente em instantes.'),
      findsOneWidget,
    );
    expect(find.textContaining('PostgrestException'), findsNothing);
    await tester.tap(find.text('TENTAR NOVAMENTE'));
    await tester.pump();

    expect(session.refreshCalls, 1);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(
  ManagementSession session, {
  required ManagementRole role,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: ChangeNotifierProvider<ManagementSession>.value(
      value: session,
      child: ManagementHomeScreen(initialRole: role),
    ),
  );
}

class _AgendaSession extends ManagementSession {
  _AgendaSession({bool populated = false}) {
    barberShopName = 'Sapao Barber';
    isRestoringSession = false;
    selectedScheduleDate = _dayFromNow(0);
    if (populated) {
      teamBarbers = const [
        TeamBarber(
          id: 'barber-1',
          barberShopId: 'shop-1',
          userId: 'user-1',
          name: longBarber,
          bio: '',
          photoUrl: '',
          startingPrice: 50,
          commissionPercent: 40,
          isActive: true,
        ),
      ];
      scheduleEntries = const [
        ScheduleEntry(
          id: 'entry-1',
          appointmentId: 'appointment-1',
          time: '09:30',
          client: longClient,
          service: longService,
          barber: longBarber,
          status: longStatus,
          notes: longNotes,
        ),
      ];
    }
  }

  static const longClient =
      'Cliente com nome completo muito extenso para teste';
  static const longService =
      'Corte, barba e tratamento capilar completo com finalização';
  static const longBarber =
      'Profissional com nome muito extenso da unidade principal';
  static const longStatus = 'Confirmado';
  static const longNotes =
      'Cliente solicitou atendimento com atenção especial e deixou uma observação longa para validar a rolagem segura dos detalhes no iPhone.';

  final dateSelections = <DateTime>[];
  final loadedDestinations = <ManagementDestinationId>[];
  var refreshCalls = 0;
  var adminViewChanges = 0;

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
  Future<void> setScheduleAdminView(bool value) async {
    if (scheduleAdminView == value) return;
    scheduleAdminView = value;
    adminViewChanges++;
    notifyListeners();
  }

  @override
  Future<void> selectScheduleDate(DateTime date) async {
    selectedScheduleDate = DateTime(date.year, date.month, date.day);
    dateSelections.add(selectedScheduleDate);
    notifyListeners();
  }

  @override
  Future<void> fetchScheduleEntries() async {
    refreshCalls++;
  }
}

DateTime _dayFromNow(int offset) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + offset);
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _fullDateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
