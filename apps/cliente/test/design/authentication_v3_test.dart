import 'package:clubedaregua/providers/app_mode_controller.dart';
import 'package:clubedaregua/providers/app_state.dart';
import 'package:clubedaregua/screens/auth/login_screen.dart';
import 'package:clubedaregua/screens/auth/password_recovery_screen.dart';
import 'package:clubedaregua/screens/auth/register_screen.dart';
import 'package:clubedaregua/theme/app_theme.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('authentication screens follow the client frame at 200 percent',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final screens = <Widget>[
      const LoginScreen(),
      const RegisterScreen(),
      const PasswordRecoveryScreen(),
    ];
    const actions = ['Entrar', 'Criar conta', 'Atualizar senha'];
    for (var index = 0; index < screens.length; index++) {
      await tester.pumpWidget(_app(screens[index], textScale: 2));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byType(CDRButton),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.descendant(
          of: find.byType(CDRButton),
          matching: find.text(actions[index]),
        ),
        findsOneWidget,
      );

      final clientFrames = tester
          .widgetList<ConstrainedBox>(find.byType(ConstrainedBox))
          .where(
            (box) =>
                box.constraints.maxWidth == CDRSizeTokens.clientFrameMaxWidth,
          );
      expect(clientFrames, isNotEmpty);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('login and registration use shared fields and actions',
      (tester) async {
    await tester.pumpWidget(_app(const LoginScreen()));
    await tester.scrollUntilVisible(
      find.byType(CDRButton),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(AutofillGroup), findsOneWidget);
    expect(find.byType(CDRTextField), findsNWidgets(2));
    expect(find.byType(CDRButton), findsOneWidget);

    await tester.pumpWidget(_app(const RegisterScreen()));
    await tester.scrollUntilVisible(
      find.byType(CDRButton),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(AutofillGroup), findsOneWidget);
    expect(find.byType(CDRTextField), findsNWidgets(3));
    expect(find.byType(CDRButton), findsOneWidget);
  });

  testWidgets(
      'password reset keeps validation inline and shared primary action',
      (tester) async {
    await tester.pumpWidget(_app(const PasswordRecoveryScreen()));
    expect(find.byType(CDRBackButton), findsNothing);
    expect(find.byType(AutofillGroup), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(CDRButton), findsOneWidget);

    await tester.ensureVisible(find.text('Atualizar senha'));
    await tester.tap(find.text('Atualizar senha'));
    await tester.pump();

    expect(find.text('Use pelo menos 8 caracteres.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '12345678');
    await tester.enterText(find.byType(TextFormField).at(1), '87654321');
    await tester.tap(find.text('Atualizar senha'));
    await tester.pump();
    expect(find.text('As senhas não coincidem.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget child, {double textScale = 1}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AppState>(create: (_) => _AuthVisualAppState()),
      ChangeNotifierProvider<AppModeController>(
        create: (_) => AppModeController(),
      ),
    ],
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

class _AuthVisualAppState extends AppState {}
