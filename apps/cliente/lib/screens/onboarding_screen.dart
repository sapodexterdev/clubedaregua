import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../theme/app_colors.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const route = '/onboarding';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(AppConstants.heroBarbershop, fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Color(0xDD160C09),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  left: 26,
                  top: 24,
                  child: Text(
                    '9:41',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Positioned(
                  right: 24,
                  top: 22,
                  child: Row(
                    children: [
                      Icon(Icons.signal_cellular_4_bar_rounded,
                          color: Colors.white.withOpacity(.9), size: 18),
                      const SizedBox(width: 5),
                      Icon(Icons.wifi_rounded,
                          color: Colors.white.withOpacity(.9), size: 18),
                      const SizedBox(width: 5),
                      Icon(Icons.battery_full_rounded,
                          color: Colors.white.withOpacity(.9), size: 22),
                    ],
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 132,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Descubra sua\nmelhor versão\nhoje',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 43,
                          height: 1.12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: 22),
                      Text(
                        'Realce seu estilo com confiança, elegância\ne um visual que combina com você.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 34,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(34),
                    onTap: () => Navigator.pushNamed(context, LoginScreen.route),
                    child: Container(
                      height: 70,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.32),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(color: Colors.white.withOpacity(.13)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.content_cut_rounded,
                              color: Colors.white,
                              size: 26,
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
                          const Icon(Icons.keyboard_double_arrow_right_rounded,
                              color: Colors.white38, size: 34),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
