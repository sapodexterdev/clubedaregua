import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  static const _pageCount = 3;
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  final _slides = const [
    _WelcomeSlideData(
      icon: Icons.location_on_outlined,
      title: 'Encontre as melhores\nbarbearias perto de você.',
      subtitle:
          'Avaliações reais, horários disponíveis e tudo o que você precisa para escolher bem.',
      imageAsset: AppConstants.onboardingV3Discover,
      discoverV3: true,
    ),
    _WelcomeSlideData(
      icon: Icons.calendar_month_outlined,
      title: 'Agende seu horário\nem poucos segundos.',
      subtitle: 'Selecione data, horário e siga sem complicação.',
      imageUrl: AppConstants.heroBarbershop,
      showSlots: true,
    ),
    _WelcomeSlideData(
      icon: Icons.workspace_premium_outlined,
      title: 'Pronto para renovar\nseu visual?',
      subtitle:
          'O Clube da Régua conecta você às melhores barbearias da cidade.',
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

  void _skipToExplore() {
    _timer?.cancel();
    _controller.animateToPage(
      _pageCount - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _continue() {
    _timer?.cancel();
    if (_page == _pageCount - 1) {
      _finish();
      return;
    }
    _controller.animateToPage(
      _page + 1,
      duration: const Duration(milliseconds: 300),
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
              child: _page < _pageCount - 1
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                      child: TextButton(
                        onPressed: _skipToExplore,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.text,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: const Text(
                          'Pular',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          _WelcomeFooter(
            page: _page,
            pageCount: _pageCount,
            onTap: _continue,
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
    this.imageUrl,
    this.imageAsset,
    this.discoverV3 = false,
    this.showBarbers = false,
    this.showSlots = false,
    this.showLogo = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? imageAsset;
  final bool discoverV3;
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
            Transform.scale(scale: scale, child: _background()),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: data.discoverV3
                      ? const [
                          Color(0x5C050505),
                          Color(0x7A09090B),
                          Color(0xF009090B),
                        ]
                      : const [
                          Color(0x880D0D0D),
                          Color(0xAA0D0D0D),
                          AppColors.background,
                        ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 168),
                child: Column(
                  children: [
                    if (data.showLogo)
                      Center(
                        child: SvgPicture.asset(
                          AppConstants.brandV3LogoPrincipal,
                          width: 190,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      )
                    else
                      const SizedBox(height: 42),
                    const Spacer(),
                    if (data.showLogo)
                      Semantics(
                        image: true,
                        label: 'Símbolo premium Clube da Régua',
                        child: SvgPicture.asset(
                          AppConstants.brandV3Crown,
                          width: 64,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      )
                    else
                      Icon(
                        data.icon,
                        color: AppColors.orange,
                        size: data.discoverV3 ? 40 : 52,
                      ),
                    SizedBox(height: data.discoverV3 ? 20 : 24),
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
                              fontFamily: 'Barlow Condensed',
                              fontSize: 32,
                              height: 1.125,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            data.subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                              height: 1.43,
                              fontWeight: FontWeight.w400,
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

  Widget _background() {
    if (data.imageAsset != null) {
      return Image.asset(
        data.imageAsset!,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    }
    return Image.network(
      data.imageUrl!,
      fit: BoxFit.cover,
      color: Colors.black.withOpacity(.66),
      colorBlendMode: BlendMode.darken,
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
                height: 56,
                child: FilledButton(
                  onPressed: onTap,
                  child: Text(
                    page == pageCount - 1
                        ? 'EXPLORAR BARBEARIAS'
                        : 'CONTINUAR',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: AppColors.onGold,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                label: 'Etapa ${page + 1} de $pageCount',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(pageCount, (index) {
                    final selected = index == page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: selected ? 24 : 9,
                      height: 9,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.orange : AppColors.stroke,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
