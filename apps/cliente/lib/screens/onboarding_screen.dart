import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_constants.dart';
import '../theme/app_colors.dart';
import 'client/home_screen.dart';
import 'splash_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const route = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SplashScreen.onboardingSeenKey, true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, HomeScreen.route);
  }

  void _next() {
    if (_page == 2) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _controller,
        onPageChanged: (value) => setState(() => _page = value),
        children: [
          _OnboardingStep(
            imageUrl: AppConstants.promoBarber,
            icon: Icons.workspace_premium_outlined,
            title: 'Encontre as melhores\nbarbearias perto de voce.',
            subtitle: 'Avaliacoes reais, horarios disponiveis e muito mais.',
            page: _page,
            onNext: _next,
          ),
          _OnboardingStep(
            imageUrl: AppConstants.heroBarbershop,
            icon: Icons.calendar_month_outlined,
            title: 'Agende com praticidade\ne sem complicacao.',
            subtitle:
                'Escolha servico, profissional e horario ideal para voce.',
            page: _page,
            onNext: _next,
          ),
          _ExploreStep(
            page: _page,
            onPrimary: _finish,
            onSecondary: _finish,
          ),
        ],
      ),
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.imageUrl,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.page,
    required this.onNext,
  });

  final String imageUrl;
  final IconData icon;
  final String title;
  final String subtitle;
  final int page;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onNext,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(.54),
            colorBlendMode: BlendMode.darken,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x440D0D0D),
                  Color(0xAA0D0D0D),
                  AppColors.background,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
              child: Column(
                children: [
                  const Spacer(flex: 5),
                  Icon(icon, color: AppColors.orange, size: 50),
                  const SizedBox(height: 22),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 24,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      height: 1.55,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(flex: 3),
                  _ProgressDots(page: page),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreStep extends StatelessWidget {
  const _ExploreStep({
    required this.page,
    required this.onPrimary,
    required this.onSecondary,
  });

  final int page;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          AppConstants.heroBarbershop,
          fit: BoxFit.cover,
          color: Colors.black.withOpacity(.72),
          colorBlendMode: BlendMode.darken,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xDD0D0D0D), AppColors.background],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _MapPinPainter()),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    AppConstants.brandLogoHorizontal,
                    width: 210,
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orange.withOpacity(.12),
                    border: Border.all(color: AppColors.orange, width: 2),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: AppColors.orange,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Pronto para descobrir?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Explore as melhores barbearias\ne agende do seu jeito.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 30),
                const SizedBox(height: 8),
                _PrimaryBoardButton(
                  label: 'Explorar barbearias',
                  icon: Icons.search_rounded,
                  onTap: onPrimary,
                ),
                const SizedBox(height: 12),
                _SecondaryBoardButton(
                  label: 'Continuar sem cadastro',
                  onTap: onSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final selected = index == page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 24 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.orange : AppColors.muted,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

class _PrimaryBoardButton extends StatelessWidget {
  const _PrimaryBoardButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.onGold,
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _SecondaryBoardButton extends StatelessWidget {
  const _SecondaryBoardButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orange,
          side: const BorderSide(color: AppColors.orange),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _MapPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orange.withOpacity(.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final points = [
      Offset(size.width * .18, size.height * .28),
      Offset(size.width * .78, size.height * .20),
      Offset(size.width * .28, size.height * .48),
      Offset(size.width * .82, size.height * .58),
    ];

    for (final point in points) {
      canvas.drawCircle(point, 8, paint);
      canvas.drawLine(
        Offset(point.dx, point.dy + 8),
        Offset(point.dx, point.dy + 24),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
