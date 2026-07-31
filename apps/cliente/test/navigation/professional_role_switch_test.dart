import 'package:clubedaregua_gestao/management.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'switches repeatedly between barber and owner without remounting all requests',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final session = _ProfessionalSession.withRequests(200);
      final roleChanges = <ManagementRole>[];

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ManagementSession>.value(
            value: session,
            child: ManagementHomeScreen(
              initialRole: ManagementRole.barber,
              onRoleChanged: (role) async => roleChanges.add(role),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Solicitações recebidas'), findsOneWidget);
      expect(find.text('Cliente 0'), findsOneWidget);
      expect(find.text('Cliente 1'), findsNothing);

      for (var index = 0; index < 6; index++) {
        final target = index.isEven ? 'Dono' : 'Barbeiro';
        await tester.tap(_roleOption(target));
        await tester.pump();

        expect(
          find.text('Preparando sua área profissional...'),
          findsNothing,
        );
      }

      await tester.tap(_roleOption('Dono'));
      await tester.pump();

      expect(find.text('Sapao Barber'), findsOneWidget);
      expect(find.text('Cliente 0'), findsOneWidget);
      expect(find.text('Cliente 19'), findsOneWidget);
      expect(find.text('Cliente 20'), findsNothing);
      expect(find.text('CARREGAR MAIS (180)'), findsOneWidget);

      final loadMore = find.text('CARREGAR MAIS (180)');
      await tester.dragUntilVisible(
        loadMore,
        find.byType(ListView),
        const Offset(0, -500),
      );
      await tester.tap(loadMore);
      await tester.pump();

      expect(find.text('Cliente 39'), findsOneWidget);
      expect(find.text('Cliente 40'), findsNothing);
      expect(find.text('CARREGAR MAIS (160)'), findsOneWidget);
      expect(roleChanges, hasLength(7));
    },
  );

  testWidgets(
    'keeps owner requests bounded while switching roles on desktop',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final session = _ProfessionalSession.withRequests(200);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ManagementSession>.value(
            value: session,
            child: ManagementHomeScreen(
              initialRole: ManagementRole.barber,
              onRoleChanged: (_) async {},
            ),
          ),
        ),
      );
      await tester.pump();

      for (var index = 0; index < 6; index++) {
        final target = index.isEven ? 'Dono' : 'Barbeiro';
        await tester.tap(_roleOption(target));
        await tester.pump();
      }

      await tester.tap(_roleOption('Dono'));
      await tester.pump();

      expect(find.text('Cliente 19'), findsOneWidget);
      expect(find.text('Cliente 20'), findsNothing);
      expect(find.text('CARREGAR MAIS (180)'), findsOneWidget);
      expect(
        find.text('Preparando sua área profissional...'),
        findsNothing,
      );
    },
  );
}

Finder _roleOption(String label) => find.descendant(
      of: find.byWidgetPredicate(
        (widget) => widget is SegmentedButton<ManagementRole>,
      ),
      matching: find.text(label),
    );

class _ProfessionalSession extends ManagementSession {
  _ProfessionalSession.withRequests(int count) {
    barberShopName = 'Sapao Barber';
    bookingRequests = List.generate(
      count,
      (index) => BookingRequest(
        id: 'request-$index',
        barberId: index == 0 ? 'current-barber' : 'other-barber',
        client: 'Cliente $index',
        phone: '(11) 99999-0000',
        clientPhotoUrl: '',
        service: 'Corte',
        barber: index == 0 ? 'Barbeiro atual' : 'Outro barbeiro',
        date: '2026-07-30',
        time: '20:00',
        status: 'new',
        total: 50,
        notes: '',
        updatedAt: '2026-07-30T20:00:00Z',
      ),
    );
  }

  @override
  bool get canWorkAsBarber => true;

  @override
  bool get canManageShop => true;

  @override
  String get barberHeaderName => 'Barbeiro atual';

  @override
  List<BookingRequest> get currentBarberBookingRequests =>
      bookingRequests.take(1).toList();
}
