import 'package:flutter/material.dart';

import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/barber_form_screen.dart';
import 'screens/admin/service_form_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/barber/barber_agenda_screen.dart';
import 'screens/barber/barber_dashboard_screen.dart';
import 'screens/client/appointment_confirmation_screen.dart';
import 'screens/client/appointment_screen.dart';
import 'screens/client/barber_details_screen.dart';
import 'screens/client/history_screen.dart';
import 'screens/client/home_screen.dart';
import 'screens/client/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class ClubeDaReguaApp extends StatelessWidget {
  const ClubeDaReguaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clube da Regua',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: SplashScreen.route,
      routes: {
        SplashScreen.route: (_) => const SplashScreen(),
        OnboardingScreen.route: (_) => const OnboardingScreen(),
        LoginScreen.route: (_) => const LoginScreen(),
        RegisterScreen.route: (_) => const RegisterScreen(),
        HomeScreen.route: (_) => const HomeScreen(),
        BarberDetailsScreen.route: (_) => const BarberDetailsScreen(),
        AppointmentScreen.route: (_) => const AppointmentScreen(),
        AppointmentConfirmationScreen.route: (_) =>
            const AppointmentConfirmationScreen(),
        HistoryScreen.route: (_) => const HistoryScreen(),
        ProfileScreen.route: (_) => const ProfileScreen(),
        BarberDashboardScreen.route: (_) => const BarberDashboardScreen(),
        BarberAgendaScreen.route: (_) => const BarberAgendaScreen(),
        AdminDashboardScreen.route: (_) => const AdminDashboardScreen(),
        ServiceFormScreen.route: (_) => const ServiceFormScreen(),
        BarberFormScreen.route: (_) => const BarberFormScreen(),
      },
    );
  }
}
