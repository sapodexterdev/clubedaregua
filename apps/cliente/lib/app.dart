import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/client/appointment_confirmation_screen.dart';
import 'screens/client/appointment_screen.dart';
import 'screens/client/barber_details_screen.dart';
import 'screens/client/history_screen.dart';
import 'screens/client/home_screen.dart';
import 'screens/client/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';

class ClubeDaReguaApp extends StatelessWidget {
  const ClubeDaReguaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clube da Régua',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) => _ResponsivePhoneFrame(child: child),
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
      },
    );
  }
}

class _ResponsivePhoneFrame extends StatelessWidget {
  const _ResponsivePhoneFrame({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final currentChild = child;
    if (currentChild == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 520) {
          return currentChild;
        }

        final height = (constraints.maxHeight - 36).clamp(640.0, 900.0).toDouble();

        return ColoredBox(
          color: AppColors.softBackground,
          child: Center(
            child: Container(
              width: 430,
              height: height,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(44),
                border: Border.all(color: Colors.white, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: Size(430, height),
                  padding: EdgeInsets.zero,
                ),
                child: currentChild,
              ),
            ),
          ),
        );
      },
    );
  }
}
