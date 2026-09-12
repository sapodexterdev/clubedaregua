import 'package:clubedaregua_gestao/management.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Dono mobile usa quatro destinos e Mais', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = _ProfessionalSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(_app(session, ManagementRole.admin));
    await tester.pump();
    expect(tester.takeException(), isNull);

    for (final label in ['Painel', 'Agenda', 'Clientes', 'Caixa', 'Mais']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Serviços'), findsNothing);
    expect(find.byType(SegmentedButton<ManagementRole>), findsNothing);

    await tester.tap(find.text('Mais'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final label in ['Pedidos', 'Serviços', 'Equipe', 'Configurações']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Serviços'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Cadastro de serviços'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      4,
    );
    expect(
      session.loadedDestinations,
      contains(ManagementDestinationId.services),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Painel da barbearia'), findsOneWidget);
  });

  testWidgets('Barbeiro mobile mantém cinco destinos e Agenda como fallback',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = _ProfessionalSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(_app(session, ManagementRole.barber));
    await tester.pump();

    for (final label in [
      'Agenda',
      'Horários',
      'Clientes',
      'Comissão',
      'Pedidos',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Agenda do barbeiro'), findsOneWidget);
  });

  testWidgets('tablet usa rail com todos os destinos do Dono', (tester) async {
    await tester.binding.setSurfaceSize(const Size(768, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = _ProfessionalSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(_app(session, ManagementRole.admin));
    await tester.pump();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).destinations,
      hasLength(8),
    );
  });

  testWidgets('rota de Dono não libera destinos para conta somente Barbeiro',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = _ProfessionalSession(ownerAccess: false);
    addTearDown(session.dispose);

    await tester.pumpWidget(_app(session, ManagementRole.admin));
    await tester.pump();

    expect(find.text('Agenda do barbeiro'), findsOneWidget);
    expect(find.text('Caixa'), findsNothing);
    expect(find.text('Serviços'), findsNothing);
    expect(find.text('Equipe'), findsNothing);
    expect(find.text('Configurações'), findsNothing);
  });

  testWidgets('rota de Barbeiro usa Painel para conta somente Dono',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = _ProfessionalSession(barberAccess: false);
    addTearDown(session.dispose);

    await tester.pumpWidget(_app(session, ManagementRole.barber));
    await tester.pump();

    expect(find.text('Painel da barbearia'), findsOneWidget);
    expect(find.text('Horários'), findsNothing);
    expect(find.text('Comissão'), findsNothing);
  });

  testWidgets(
      'alternâncias repetidas preservam a sessão e não reabrem o splash',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = _ProfessionalSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(_embeddedApp(session, ManagementRole.barber));
    await tester.pump();
    expect(find.text('Agenda do barbeiro'), findsOneWidget);

    for (var index = 0; index < 10; index++) {
      final role = index.isEven ? ManagementRole.admin : ManagementRole.barber;
      await tester.pumpWidget(_embeddedApp(session, role));
      await tester.pump();

      expect(find.text('Preparando sua área profissional...'), findsNothing);
      expect(
        find.text(
          role == ManagementRole.admin
              ? 'Painel da barbearia'
              : 'Agenda do barbeiro',
        ),
        findsOneWidget,
      );
    }

    expect(session.restoreCalls, 1);
  });

  testWidgets(
      'shell preserva destino entre breakpoints com texto ampliado e uma única sessão',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = _ProfessionalSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(
      _scaledEmbeddedApp(
        session,
        ManagementRole.admin,
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byTooltip('Notificações'), findsNothing);
    await tester.tap(find.text('Caixa'));
    await tester.pump();
    expect(find.text('Caixa e estoque'), findsOneWidget);

    for (final width in [599.0, 360.0]) {
      await tester.binding.setSurfaceSize(Size(width, 640));
      await tester.pump();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Caixa e estoque'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    for (final width in [600.0, 768.0, 1023.0]) {
      await tester.binding.setSurfaceSize(Size(width, 720));
      await tester.pump();
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsOneWidget);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
      expect(rail.minWidth, 88);
      expect(find.text('Caixa e estoque'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    for (final width in [1024.0, 1440.0]) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pump();
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsOneWidget);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
      expect(rail.minExtendedWidth, 240);
      expect(find.text('Caixa e estoque'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    expect(session.restoreCalls, 1);
  });
}

Widget _app(ManagementSession session, ManagementRole role) => MaterialApp(
      home: ChangeNotifierProvider<ManagementSession>.value(
        value: session,
        child: ManagementHomeScreen(initialRole: role),
      ),
    );

Widget _embeddedApp(ManagementSession session, ManagementRole role) =>
    MaterialApp(
      home: EmbeddedManagementArea(
        key: const ValueKey('professional-area'),
        session: session,
        initialRole: role,
        onOpenClientMode: () {},
        onSignedOut: () {},
      ),
    );

Widget _scaledEmbeddedApp(
  ManagementSession session,
  ManagementRole role, {
  required TextScaler textScaler,
}) =>
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: EmbeddedManagementArea(
        key: const ValueKey('professional-area-scaled'),
        session: session,
        initialRole: role,
        onOpenClientMode: () {},
        onSignedOut: () {},
      ),
    );

class _ProfessionalSession extends ManagementSession {
  _ProfessionalSession({
    this.barberAccess = true,
    this.ownerAccess = true,
  }) {
    barberShopName = 'Sapao Barber';
    isRestoringSession = false;
  }

  final bool barberAccess;
  final bool ownerAccess;
  final loadedDestinations = <ManagementDestinationId>[];
  var restoreCalls = 0;

  @override
  bool get isSignedIn => true;

  @override
  bool get professionalAccessResolved => true;

  @override
  bool get canWorkAsBarber => barberAccess;

  @override
  bool get canManageShop => ownerAccess;

  @override
  String get barberHeaderName => 'Barbeiro atual';

  @override
  Future<void> restoreUnifiedSession({
    ManagementRole initialRole = ManagementRole.barber,
  }) async {
    restoreCalls++;
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
