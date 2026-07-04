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
  static const _pageCount = 4;
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  final _slides = const [
    _WelcomeSlideData(
      icon: Icons.location_on_outlined,
      title: 'Descubra as melhores\nbarbearias perto de voce.',
      subtitle: 'Compare opcoes, veja avaliacoes e encontre seu proximo corte.',
      imageUrl: AppConstants.heroBarbershop,
    ),
    _WelcomeSlideData(
      icon: Icons.people_outline_rounded,
      title: 'Escolha o barbeiro ideal\npara o seu estilo.',
      subtitle:
          'Conheca profissionais, especialidades e notas antes de marcar.',
      imageUrl: AppConstants.promoBarber,
      showBarbers: true,
    ),
    _WelcomeSlideData(
      icon: Icons.calendar_month_outlined,
      title: 'Agende seu horario\nem poucos segundos.',
      subtitle: 'Selecione data, horario e siga sem complicacao.',
      imageUrl: AppConstants.heroBarbershop,
      showSlots: true,
    ),
    _WelcomeSlideData(
      icon: Icons.workspace_premium_outlined,
      title: 'Pronto para renovar\nseu visual?',
      subtitle:
          'O Clube da Regua conecta voce as melhores barbearias da cidade.',
      imageUrl: AppConstants.promoBarber,
      showLogo: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted || !_controller.hasClients) return;
      final nextPage = (_page + 1) % _pageCount;
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 420),
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
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, index) {
              return _WelcomeSlide(
                data: _slides[index],
                selected: _page == index,
              );
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.text,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text(
                    'Pular',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
          _WelcomeFooter(
            page: _page,
            pageCount: _pageCount,
            onTap: _finish,
          ),
        ],
      ),
    );
  }
}

class _WelcomeSlideData {
  const _WelcomeSlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.showBarbers = false,
    this.showSlots = false,
    this.showLogo = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String imageUrl;
  final bool showBarbers;
  final bool showSlots;
  final bool showLogo;
}

class _WelcomeSlide extends StatelessWidget {
  const _WelcomeSlide({
    required this.data,
    required this.selected,
  });

  final _WelcomeSlideData data;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: selected ? .98 : 1, end: selected ? 1 : .98),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: scale,
              child: Image.network(
                data.imageUrl,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(.66),
                colorBlendMode: BlendMode.darken,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x880D0D0D),
                    Color(0xAA0D0D0D),
                    AppColors.background,
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 28, 30, 160),
                child: Column(
                  children: [
                    if (data.showLogo)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          AppConstants.brandLogoHorizontal,
                          width: 216,
                          fit: BoxFit.contain,
                        ),
                      )
                    else
                      const SizedBox(height: 42),
                    const Spacer(),
                    if (data.showLogo)
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.orange, width: 2),
                        ),
                        child:
                            Icon(data.icon, color: AppColors.orange, size: 52),
                      )
                    else
                      Icon(data.icon, color: AppColors.orange, size: 52),
                    const SizedBox(height: 24),
                    AnimatedOpacity(
                      opacity: selected ? 1 : .55,
                      duration: const Duration(milliseconds: 250),
                      child: Column(
                        children: [
                          Text(
                            data.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 26,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            data.subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                              height: 1.45,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (data.showBarbers) const _BarberPreview(),
                    if (data.showSlots) const _SlotPreview(),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BarberPreview extends StatelessWidget {
  const _BarberPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
            child: const CircleAvatar(
              radius: 23,
              backgroundImage: NetworkImage(AppConstants.defaultAvatar),
            ),
          );
        }),
      ),
    );
  }
}

class _SlotPreview extends StatelessWidget {
  const _SlotPreview();

  @override
  Widget build(BuildContext context) {
    const slots = ['09:00', '10:30', '15:00'];
    return Wrap(
      spacing: 10,
      children: slots.map((slot) {
        final selected = slot == '15:00';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.orange : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.orange : AppColors.stroke,
            ),
          ),
          child: Text(
            slot,
            style: TextStyle(
              color: selected ? AppColors.onGold : AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WelcomeFooter extends StatelessWidget {
  const _WelcomeFooter({
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
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 62,
                child: FilledButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.search_rounded, size: 31),
                  label: const Text('ENCONTRAR BARBEARIAS'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: AppColors.onGold,
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pageCount, (index) {
                  final selected = index == page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: selected ? 24 : 9,
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
