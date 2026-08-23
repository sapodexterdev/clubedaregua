import 'package:clubedaregua/providers/app_mode_controller.dart';
import 'package:clubedaregua/providers/app_state.dart';
import 'package:clubedaregua/core/app_mode.dart';
import 'package:clubedaregua/screens/auth/login_screen.dart';
import 'package:clubedaregua/screens/client/client_shell.dart';
import 'package:clubedaregua/screens/client/profile_screen.dart';
import 'package:clubedaregua/widgets/premium_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('switching roots keeps one shell and does not grow the stack',
      (tester) async {
    final state = _ShellAppState()..isSignedIn = true;
    final observer = _CountingNavigatorObserver();
    await tester.pumpWidget(_app(state, observer: observer));
    await tester.pump();

    expect(find.byType(PremiumBottomNav), findsOneWidget);
    expect(observer.pushCount, 1);

    for (var cycle = 0; cycle < 5; cycle++) {
      for (final label in ['Favoritos', 'Agenda', 'Perfil', 'Descobrir']) {
        await tester.tap(find.text(label).last);
        await tester.pump();
        expect(find.byType(PremiumBottomNav), findsOneWidget);
      }
    }

    expect(observer.pushCount, 1);
    expect(state.appointmentRefreshes, 5);
  });

  testWidgets('a guest stays in discovery while login is open', (tester) async {
    final state = _ShellAppState();
    await tester.pumpWidget(_app(state));
    await tester.pump();

    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();

    expect(find.text('LOGIN DE TESTE'), findsOneWidget);
    expect(state.appointmentRefreshes, 0);

    Navigator.of(tester.element(find.text('LOGIN DE TESTE'))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(PremiumBottomNav), findsOneWidget);
    expect(
      tester
          .widget<PremiumBottomNav>(find.byType(PremiumBottomNav))
          .currentIndex,
      ClientRootTab.discover.index,
    );
  });

  testWidgets('back from a secondary root returns to discovery',
      (tester) async {
    final state = _ShellAppState()..isSignedIn = true;
    await tester.pumpWidget(
      _app(
        state,
        initialTab: ClientRootTab.agenda,
      ),
    );
    await tester.pump();

    expect(find.text('Agenda'), findsWidgets);
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(
      tester
          .widget<PremiumBottomNav>(find.byType(PremiumBottomNav))
          .currentIndex,
      ClientRootTab.discover.index,
    );
    expect(find.text('Descobrir'), findsOneWidget);
  });

  testWidgets('protected roots are lazy and refresh only when active',
      (tester) async {
    final state = _ShellAppState()..isSignedIn = true;
    await tester.pumpWidget(_app(state));
    await tester.pump();
    expect(state.appointmentRefreshes, 0);

    await tester.tap(find.text('Agenda'));
    await tester.pump();
    expect(state.appointmentRefreshes, 1);

    await tester.tap(find.text('Favoritos').last);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(state.appointmentRefreshes, 1);
  });

  testWidgets('root changes synchronize the platform route without a push',
      (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.navigation,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.navigation,
        null,
      );
    });
    final state = _ShellAppState()..isSignedIn = true;
    await tester.pumpWidget(_app(state));
    await tester.pump();

    await tester.tap(find.text('Favoritos'));
    await tester.pump();
    expect(
      calls.any((call) => call.arguments.toString().contains('/favorites')),
      isTrue,
    );

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(
      calls.any((call) => call.arguments.toString().contains('/home')),
      isTrue,
    );
  });

  testWidgets('returning from a detail restores the active root URL',
      (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.navigation,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.navigation,
        null,
      );
    });
    final state = _ShellAppState()..isSignedIn = true;
    await tester.pumpWidget(_app(state));
    await tester.pump();

    await tester.tap(find.text('Favoritos'));
    await tester.pump();
    calls.clear();
    final navigationContext = tester.element(find.byType(PremiumBottomNav));
    final detailRoute = Navigator.of(navigationContext).pushNamed('/detail');
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('DETALHE'))).pop();
    await tester.pumpAndSettle();
    await detailRoute;

    final routeUpdates = calls
        .where((call) => call.method == 'routeInformationUpdated')
        .toList();
    expect(routeUpdates, isNotEmpty);
    expect(routeUpdates.last.arguments.toString(), contains('/favorites'));
  });

  testWidgets('professional profile has no implicit client navigation',
      (tester) async {
    final state = _ShellAppState()
      ..isSignedIn = true
      ..professionalRoles = const {'owner'};
    final modes = AppModeController()
      ..currentMode = AppMode.owner
      ..availableModes = const {AppMode.client, AppMode.owner};
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: state),
          ChangeNotifierProvider<AppModeController>.value(value: modes),
        ],
        child: MaterialApp(
          navigatorObservers: [clientRootRouteObserver],
          routes: {
            ProfileScreen.route: (_) => const ClientShell(
                  initialTab: ClientRootTab.profile,
                ),
          },
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  ProfileScreen.route,
                  arguments: AppMode.owner,
                ),
                child: const Text('ABRIR PERFIL'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('ABRIR PERFIL'));
    await tester.pumpAndSettle();
    expect(find.byType(PremiumBottomNav), findsNothing);
    expect(find.text('ATIVIDADE'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('ABRIR PERFIL'), findsOneWidget);
    expect(modes.currentMode, AppMode.owner);
  });
}

Widget _app(
  AppState state, {
  ClientRootTab initialTab = ClientRootTab.discover,
  NavigatorObserver? observer,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AppState>.value(value: state),
      ChangeNotifierProvider(create: (_) => AppModeController()),
    ],
    child: MaterialApp(
      navigatorObservers: [
        clientRootRouteObserver,
        if (observer != null) observer,
      ],
      routes: {
        LoginScreen.route: (_) => const Scaffold(
              body: Center(child: Text('LOGIN DE TESTE')),
            ),
        '/detail': (_) => const Scaffold(
              body: Center(child: Text('DETALHE')),
            ),
      },
      home: ClientShell(initialTab: initialTab),
    ),
  );
}

class _ShellAppState extends AppState {
  var appointmentRefreshes = 0;
  var notificationRefreshes = 0;

  @override
  Future<void> refreshAppointments() async {
    appointmentRefreshes++;
  }

  @override
  Future<void> refreshNotifications() async {
    notificationRefreshes++;
  }
}

class _CountingNavigatorObserver extends NavigatorObserver {
  var pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }
}
