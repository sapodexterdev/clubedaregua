import 'dart:io';

import 'package:clubedaregua/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('native scene fits mobile and becomes static before slow state',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_app());
    expect(find.bySemanticsLabel('Clube da Régua'), findsOneWidget);
    expect(
      find.textContaining('O SISTEMA FEITO PARA', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('CARREGANDO...'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1999));
    expect(find.text('CARREGANDO...'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('CARREGANDO...'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion uses only a finite 200ms fade', (tester) async {
    await tester.pumpWidget(_app(disableAnimations: true));

    Opacity brandOpacity() => tester.widget<Opacity>(
          find.byKey(const ValueKey('splash-brand-opacity')),
        );
    Transform brandScale() => tester.widget<Transform>(
          find.byKey(const ValueKey('splash-brand-scale')),
        );

    expect(brandOpacity().opacity, 0);
    expect(brandScale().transform.entry(0, 0), 1);
    await tester.pump(const Duration(milliseconds: 100));
    expect(brandOpacity().opacity, closeTo(.5, .1));
    expect(brandScale().transform.entry(0, 0), 1);
    await tester.pump(const Duration(milliseconds: 100));
    expect(brandOpacity().opacity, 1);
    expect(brandScale().transform.entry(0, 0), 1);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('Flutter splash is finite, local and does not duplicate web work', () {
    final source = File('lib/screens/splash_screen.dart').readAsStringSync();

    expect(source, contains('AppConstants.brandV3LogoPrincipal'));
    expect(source, contains('O SISTEMA FEITO PARA '));
    expect(source, contains('BARBEARIAS.'));
    expect(source, contains('MediaQuery.of(context).disableAnimations'));
    expect(source, contains('_slowLoadingDelay'));
    expect(source, contains('hideBootStatus()'));

    expect(source, isNot(contains('.repeat(')));
    expect(source, isNot(contains('ImageFilter')));
    expect(source, isNot(contains('splashV3UrbanBarbershop')));
    expect(source, isNot(contains('brandV3SecondaryLogo')));
  });

  test('web boot has one finite owner and an accessible slow state', () {
    final html = File('web/index.html').readAsStringSync();

    expect(html, contains('viewport-fit=cover'));
    expect(html, contains('prefers-reduced-motion: reduce'));
    expect(html, contains('#boot-splash.is-waiting'));
    expect(html, contains('Clube da Régua carregando'));
    expect(html, contains('O SISTEMA FEITO PARA'));
    expect(html, contains('let bootHidden = false'));
    expect(html, contains("font-family: 'Inter'"));
    expect(html, contains('content="black"'));

    expect(html, isNot(contains('infinite')));
    expect(html, isNot(contains('__BOOT_SPLASH_DATA__')));
    expect(html, isNot(contains('boot-background')));
    expect(html, isNot(contains("addEventListener('hashchange'")));
    expect(html, isNot(contains('MutationObserver')));
    expect('function hideBootStatus'.allMatches(html), hasLength(1));
    expect(html, contains('bootFailSafeTimer'));
    expect(html, contains('is-error'));
    expect(html, contains('TENTAR NOVAMENTE'));
    expect(html, contains('window.location.reload()'));
  });

  test('Vercel build copies the principal logo without embedding the photo',
      () {
    final buildScript =
        File('../../scripts/vercel-build.sh').readAsStringSync();

    expect(buildScript, contains('brand_v3_logo_principal.svg'));
    expect(buildScript, contains('Inter-Variable.ttf'));
    expect(buildScript, isNot(contains('brand_v3_segunda_logo.svg')));
    expect(buildScript, isNot(contains('boot-splash.b64')));
    expect(buildScript, isNot(contains('__BOOT_SPLASH_DATA__')));
    expect(buildScript, contains('--pwa-strategy=none'));
    expect(buildScript, contains('serviceWorkerSettings: null'));
  });
}

Widget _app({bool disableAnimations = false}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: disableAnimations,
      ),
      child: child ?? const SizedBox.shrink(),
    ),
    home: const SplashScreen(runInitialNavigation: false),
  );
}
