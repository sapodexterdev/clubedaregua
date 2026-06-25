import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const route = '/onboarding';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(AppConstants.heroBarbershop, fit: BoxFit.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 24,
                        right: 24,
                        bottom: 28,
                        child: Text(
                          'Seu corte, sua agenda, sua experiencia premium.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            height: 1.04,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Encontre barbeiros, escolha horarios livres e acompanhe seus pontos em um unico lugar.',
                style: TextStyle(color: AppColors.muted, fontSize: 16),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Comecar',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => Navigator.pushNamed(context, LoginScreen.route),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
