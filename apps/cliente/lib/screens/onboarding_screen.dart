import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_constants.dart';
import '../theme/app_colors.dart';
import 'client/home_screen.dart';
import 'splash_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const route = '/onboarding';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 700;
          final titleSize = compact ? 50.0 : 60.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                AppConstants.heroBarbershop,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(.62),
                colorBlendMode: BlendMode.darken,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(.18),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xEE0D0D0D), Color(0xAA1A1A1A)],
                  ),
                ),
              ),
              Positioned(
                right: -90,
                top: 60,
                child: Transform.rotate(
                  angle: -.45,
                  child: Icon(
                    Icons.content_cut_rounded,
                    size: compact ? 210 : 260,
                    color: Colors.white.withOpacity(.035),
                  ),
                ),
              ),
              Positioned(
                left: -34,
                bottom: 98,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 138,
                  color: AppColors.orange.withOpacity(.08),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 62,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card.withOpacity(.78),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.orange.withOpacity(.38),
                          ),
                        ),
                        child: Image.asset(
                          AppConstants.brandLogoHorizontal,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'O sistema\noperacional\nda barbearia\nmoderna.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          height: .92,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: compact ? 16 : 22),
                      const Text(
                        'Tecnologia que eleva o nível da sua barbearia.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: compact ? 24 : 32),
                      InkWell(
                        borderRadius: BorderRadius.circular(34),
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool(
                            SplashScreen.onboardingSeenKey,
                            true,
                          );
                          if (!context.mounted) return;
                          Navigator.pushReplacementNamed(
                            context,
                            HomeScreen.route,
                          );
                        },
                        child: Container(
                          height: 70,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.card.withOpacity(.9),
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(
                              color: AppColors.orange.withOpacity(.55),
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.asset(
                                  AppConstants.brandIconCr,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Começar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_double_arrow_right_rounded,
                                color: AppColors.orange,
                                size: 34,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
