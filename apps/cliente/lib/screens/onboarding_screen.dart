import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';

import '../core/app_constants.dart';
import '../core/app_mode.dart';
import '../providers/app_mode_controller.dart';
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
  int _page = 0;
  bool _isFinishing = false;

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
      subtitle:
          'Escolha o serviço, o profissional e o melhor horário para você.',
      imageAsset: AppConstants.onboardingV3Schedule,
      scheduleV3: true,
      showSlots: true,
    ),
    _WelcomeSlideData(
      icon: Icons.storefront_outlined,
      title: 'Explore barbearias\nno seu ritmo.',
      subtitle:
          'Conheça serviços, profissionais e avaliações antes de criar sua conta.',
      showLogo: true,
    ),
  ];

  Future<void> _finish() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(SplashScreen.onboardingSeenKey, true);
      if (!mounted) return;
      await context.read<AppModeController>().selectMode(AppMode.client);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, HomeScreen.route);
    } catch (_) {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  void _skipToExplore() {
    _goToPage(_pageCount - 1);
  }

  void _continue() {
    if (_isFinishing) return;
    if (_page == _pageCount - 1) {
      _finish();
      return;
    }
    _goToPage(_page + 1);
  }

  void _goToPage(int page) {
    if (MediaQuery.of(context).disableAnimations) {
      _controller.jumpToPage(page);
      return;
    }
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
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
            onTap: _isFinishing ? null : _continue,
            isLoading: _isFinishing,
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
    this.imageAsset,
    this.discoverV3 = false,
    this.scheduleV3 = false,
    this.showSlots = false,
    this.showLogo = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? imageAsset;
  final bool discoverV3;
  final bool scheduleV3;
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
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Stack(
      fit: StackFit.expand,
      children: [
        _background(),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: data.discoverV3 || data.scheduleV3
                  ? const [
                      Color(0x5C050505),
                      Color(0x7A09090B),
                      Color(0xF009090B),
                    ]
                  : const [
                      Color(0x0009090B),
                      Color(0xB809090B),
                      AppColors.background,
                    ],
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final minimumHeight = (constraints.maxHeight - 270)
                  .clamp(0.0, double.infinity)
                  .toDouble();
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  CDRSpacingTokens.xxl,
                  80,
                  CDRSpacingTokens.xxl,
                  176,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minimumHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (data.showLogo)
                        Semantics(
                          image: true,
                          label: 'Clube da Régua',
                          child: SvgPicture.asset(
                            AppConstants.brandV3LogoPrincipal,
                            width: 180,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        )
                      else
                        Icon(
                          data.icon,
                          color: AppColors.orange,
                          size: 40,
                        ),
                      const SizedBox(height: CDRSpacingTokens.xl),
                      AnimatedOpacity(
                        opacity: selected ? 1 : .55,
                        duration: reduceMotion
                            ? Duration.zero
                            : CDRDurationTokens.fast,
                        child: Column(
                          children: [
                            Text(
                              data.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontFamily:
                                    CDRTypographyTokens.displayFontFamily,
                                fontSize: 32,
                                height: 1.125,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: CDRSpacingTokens.md),
                            Text(
                              data.subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 14,
                                height: 1.43,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (data.showSlots) ...[
                        const SizedBox(height: CDRSpacingTokens.xxl),
                        const _SlotPreview(),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
    return const ColoredBox(
      color: AppColors.background,
      child: SizedBox.expand(),
    );
  }
}

class _SlotPreview extends StatelessWidget {
  const _SlotPreview();

  @override
  Widget build(BuildContext context) {
    const slots = ['09:00', '10:30', '15:00'];
    return Row(
      children: slots.map((slot) {
        final selected = slot == '15:00';
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: slot == slots.first ? 0 : 8),
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.orange : AppColors.card,
                borderRadius: BorderRadius.circular(CDRRadiusTokens.small),
                border: Border.all(
                  color: selected ? AppColors.orange : AppColors.stroke,
                ),
              ),
              child: Text(
                slot,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? AppColors.onGold : AppColors.text,
                  fontSize: 13,
                  height: 1.38,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
    required this.isLoading,
  });

  final int page;
  final int pageCount;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CDRSpacingTokens.xxl,
            0,
            CDRSpacingTokens.xxl,
            CDRSpacingTokens.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: onTap,
                  child: isLoading
                      ? const CDRLoading.compact(size: 20)
                      : Text(
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
                      borderRadius:
                          BorderRadius.circular(CDRRadiusTokens.medium),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: CDRSpacingTokens.xl),
              Semantics(
                label: 'Etapa ${page + 1} de $pageCount',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(pageCount, (index) {
                    final selected = index == page;
                    return AnimatedContainer(
                      duration: reduceMotion
                          ? Duration.zero
                          : CDRDurationTokens.standard,
                      width: selected ? 24 : 9,
                      height: 9,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.orange : AppColors.stroke,
                        borderRadius:
                            BorderRadius.circular(CDRRadiusTokens.pill),
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
