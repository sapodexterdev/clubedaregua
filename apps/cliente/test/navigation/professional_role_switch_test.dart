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

    for (final label in ['Painel', 'Agenda', 'Clientes', 'Caixa', 'Mais']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Serviços'), findsNothing);
    expect(find.byType(SegmentedButton<ManagementRole>), findsNothing);

    await tester.tap(find.text('Mais'));
    await tester.pumpAndSettle();
    for (final label in ['Pedidos', 'Serviços', 'Equipe', 'Configurações']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Serviços'));
    await tester.pumpAndSettle();
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
    expect(find.text('Painel administrativo'), findsOneWidget);
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
              ? 'Painel administrativo'
              : 'Agenda do barbeiro',
        ),
        findsOneWidget,
      );
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

class _ProfessionalSession extends ManagementSession {
  _ProfessionalSession() {
    barberShopName = 'Sapao Barber';
    isRestoringSession = false;
  }

  final loadedDestinations = <ManagementDestinationId>[];
  var restoreCalls = 0;

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
