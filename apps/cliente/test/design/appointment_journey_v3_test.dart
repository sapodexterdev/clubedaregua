import 'package:clubedaregua/models/service_item.dart';
import 'package:clubedaregua/providers/app_state.dart';
import 'package:clubedaregua/screens/client/appointment_confirmation_screen.dart';
import 'package:clubedaregua/theme/app_theme.dart';
import 'package:clubedaregua/widgets/service_card.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('confirmation without receipt uses the shared neutral state',
      (tester) async {
    await tester.pumpWidget(
      _app(_AppointmentVisualState(), const AppointmentConfirmationScreen()),
    );

    expect(find.byType(CDREmptyState), findsOneWidget);
    expect(find.text('Nenhum agendamento recente'), findsOneWidget);
  });

  testWidgets('confirmed appointment uses success semantics and automatic copy',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final state = _AppointmentVisualState()
      ..lastBookingRequestCreated = true
      ..lastBookingReceipt = BookingReceipt(
        shopName: 'Barbearia com um nome suficientemente longo',
        serviceName: 'Corte, barba e acabamento premium',
        barberName: 'Profissional com nome longo',
        date: DateTime(2026, 8, 23),
        time: '10:30',
        total: 75,
      );

    await tester.pumpWidget(
      _app(
        state,
        const AppointmentConfirmationScreen(),
        textScale: 2,
      ),
    );

    final badge = tester.widget<CDRStatusBadge>(find.byType(CDRStatusBadge));
    expect(badge.tone, CDRStatusTone.success);
    expect(find.text('Seu horário já entrou na agenda do profissional.'),
        findsOneWidget);
    expect(
        find.textContaining('solicitação', findRichText: true), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected service remains readable and selected at 200 percent',
      (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    addTearDown(semanticsHandle.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const service = ServiceItem(
      id: 'service-1',
      name: 'Corte e barba com acabamento premium',
      durationMinutes: 60,
      price: 75,
      barberShopId: 'shop-1',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(24),
              child: ServiceCard(
                service: service,
                isSelected: true,
                onTap: _ignoreTap,
              ),
            ),
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(
      find.bySemanticsLabel(
        'Corte e barba com acabamento premium, 60 minutos, R\$ 75',
      ),
    );
    final semanticsData = semantics.getSemanticsData();
    expect(semanticsData.hasFlag(SemanticsFlag.isSelected), isTrue);
    expect(semanticsData.hasAction(SemanticsAction.tap), isTrue);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _ignoreTap() {}

Widget _app(
  AppState state,
  Widget child, {
  double textScale = 1,
}) {
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: MaterialApp(
      theme: AppTheme.light,
      builder: (context, appChild) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: appChild ?? const SizedBox.shrink(),
      ),
      home: child,
    ),
  );
}

class _AppointmentVisualState extends AppState {}
