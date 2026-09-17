import 'package:clubedaregua/providers/app_mode_controller.dart';
import 'package:clubedaregua/screens/client/home_screen.dart';
import 'package:clubedaregua/screens/onboarding_screen.dart';
import 'package:clubedaregua/screens/splash_screen.dart';
import 'package:clubedaregua/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('onboarding never advances without user interaction',
      (tester) async {
    await tester.pumpWidget(_app());
    expect(find.textContaining('Encontre as melhores'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 1 de 3'), findsOneWidget);

    await tester.pump(const Duration(seconds: 8));

    expect(find.textContaining('Encontre as melhores'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 1 de 3'), findsOneWidget);
  });

  testWidgets('skip opens the public exploration step and finishes once',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Explore barbearias'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 3 de 3'), findsOneWidget);
    expect(find.text('EXPLORAR BARBEARIAS'), findsOneWidget);
    var preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(SplashScreen.onboardingSeenKey),
      isNot(true),
    );

    await tester.tap(find.text('EXPLORAR BARBEARIAS'));
    await tester.tap(find.text('EXPLORAR BARBEARIAS'));
    await tester.pumpAndSettle();

    expect(find.text('HOME DE TESTE'), findsOneWidget);
    preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(SplashScreen.onboardingSeenKey), isTrue);
  });

  testWidgets('reduced motion and scaled text keep content reachable',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _app(textScale: 2, disableAnimations: true),
    );
    await tester.ensureVisible(find.text('CONTINUAR'));
    await tester.tap(find.text('CONTINUAR'));
    await tester.pump();

    expect(find.textContaining('Agende seu horário'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 2 de 3'), findsOneWidget);

    await tester.tap(find.text('Pular'));
    await tester.pump();
    await tester.ensureVisible(find.text('EXPLORAR BARBEARIAS'));
    expect(find.textContaining('Explore barbearias'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 3 de 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app({
  double textScale = 1,
  bool disableAnimations = false,
}) {
  return ChangeNotifierProvider<AppModeController>(
    create: (_) => AppModeController(),
    child: MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      routes: {
        OnboardingScreen.route: (_) => const OnboardingScreen(),
        HomeScreen.route: (_) => const Scaffold(
              body: Center(child: Text('HOME DE TESTE')),
            ),
      },
      initialRoute: OnboardingScreen.route,
    ),
  );
}
