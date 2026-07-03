import 'dart:async';

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
  Timer? _timer;
  int _page = 0;
  static const _pageCount = 3;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final nextPage = (_page + 1) % _pageCount;
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _finish() async {
    _timer?.cancel();
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
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (value) => setState(() => _page = value),
            children: [
              const _DiscoveryIntroStep(),
              _OnboardingStep(
                imageUrl: AppConstants.heroBarbershop,
                icon: Icons.calendar_month_outlined,
                title: 'Agende com praticidade\ne sem complicacao.',
                subtitle:
                    'Escolha servico, profissional e horario ideal para voce.',
                onNext: _next,
              ),
              _ExploreStep(onNext: _next),
            ],
          ),
          _FixedOnboardingOverlay(
            page: _page,
            pageCount: _pageCount,
            onTap: _finish,
          ),
        ],
      ),
    );
  }
}

class _DiscoveryIntroStep extends StatelessWidget {
  const _DiscoveryIntroStep();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppConstants.splashBarberReference,
      fit: BoxFit.cover,
      alignment: Alignment.center,
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.imageUrl,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onNext,
  });

  final String imageUrl;
  final IconData icon;
  final String title;
  final String subtitle;
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
                  const Spacer(flex: 4),
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
  const _ExploreStep({required this.onNext});

  final VoidCallback onNext;

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
                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FixedOnboardingOverlay extends StatelessWidget {
  const _FixedOnboardingOverlay({
    required this.page,
    required this.pageCount,
    required this.onTap,
  });

  final int page;
  final int pageCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 0, 36, 84),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 62,
                child: Semantics(
                  button: true,
                  label: 'Encontrar barbearias',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      splashColor: AppColors.orange.withOpacity(.16),
                      highlightColor: AppColors.orange.withOpacity(.08),
                      onTap: onTap,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pageCount, (index) {
                  final selected = index == page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: selected ? 22 : 9,
                    height: 9,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.orange : AppColors.muted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
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
