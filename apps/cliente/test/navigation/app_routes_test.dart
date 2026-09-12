import 'package:clubedaregua/core/app_mode.dart';
import 'package:clubedaregua/screens/auth/password_recovery_screen.dart';
import 'package:clubedaregua/screens/client/home_screen.dart';
import 'package:clubedaregua/screens/professional_mode_screen.dart';
import 'package:clubedaregua/screens/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps every app mode inside the Cliente navigator', () {
    expect(SplashScreen.route, '/');
    expect(
      ProfessionalModeScreen.routeFor(AppMode.client),
      HomeScreen.route,
    );
    expect(
      ProfessionalModeScreen.routeFor(AppMode.barber),
      ProfessionalModeScreen.barberRoute,
    );
    expect(
      ProfessionalModeScreen.routeFor(AppMode.owner),
      ProfessionalModeScreen.ownerRoute,
    );
    expect(PasswordRecoveryScreen.route, '/auth/recover');

    for (final route in [
      ProfessionalModeScreen.barberRoute,
      ProfessionalModeScreen.ownerRoute,
      PasswordRecoveryScreen.route,
    ]) {
      expect(route, isNot(contains('/gestao')));
      expect(route, isNot(contains('?mode=')));
    }
  });
}
