import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';

import '../../core/app_constants.dart';
import '../../providers/app_state.dart';
import '../../repositories/barber_repository.dart';
import '../../screens/auth/login_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/service_card.dart';
import 'barber_details_screen.dart';

class BarbershopProfileScreen extends StatelessWidget {
  const BarbershopProfileScreen({super.key});

  static const route = '/barbershop-profile';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final shop = state.selectedBarbershop;
        if (shop == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              leadingWidth: 68,
              leading: const Padding(
                padding: EdgeInsets.only(left: 16),
                child: CDRBackButton(),
              ),
            ),
            body: const _MissingShop(),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          bottomNavigationBar: _ScheduleBar(shop: shop),
          body: CustomScrollView(
            slivers: [
              _CoverAppBar(
                shop: shop,
                favorite: state.isFavorite(shop.identity.id),
                updating: state.isFavoriteUpdating(shop.identity.id),
                onFavorite: () async {
                  if (!state.isSignedIn) {
                    Navigator.pushNamed(
                      context,
                      LoginScreen.route,
                      arguments: BarbershopProfileScreen.route,
                    );
                    return;
                  }
                  final success = await state.toggleFavorite(shop);
                  if (!context.mounted || success) return;
                  CDRSnackbar.error(
                    context,
                    'Não foi possível atualizar o favorito. Tente novamente.',
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: CDRSizeTokens.clientFrameMaxWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        CDRSpacingTokens.xxl,
                        CDRSpacingTokens.xs,
                        CDRSpacingTokens.xxl,
                        CDRSpacingTokens.xxxl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileHeader(shop: shop),
                          const SizedBox(height: 20),
                          _QuickFacts(shop: shop),
                          const SizedBox(height: 28),
                          const _SectionTitle('Sobre'),
                          const SizedBox(height: 10),
                          _AboutShop(shop: shop),
                          if (_hasContact(shop)) ...[
                            const SizedBox(height: 28),
                            const _SectionTitle('Contato e localização'),
                            const SizedBox(height: 12),
                            _ContactActions(shop: shop),
                          ],
                          if (shop.services.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            _SectionHeader(
                              title: 'Serviços',
                              caption: '${shop.services.length} disponíveis',
                            ),
                            const SizedBox(height: 12),
                            ...shop.services.map(
                              (service) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ServiceCard(
                                  service: service,
                                  isSelected:
                                      state.selectedService?.id == service.id,
                                  onTap: () => state.selectService(service),
                                ),
                              ),
                            ),
                          ],
                          if (shop.barbers.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            _SectionHeader(
                              title: 'Profissionais',
                              caption: '${shop.barbers.length} na equipe',
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 142.0 +
                                  (MediaQuery.textScalerOf(context)
                                              .scale(1)
                                              .clamp(1.0, 2.0) -
                                          1) *
                                      36,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: shop.barbers.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final barber = shop.barbers[index];
                                  return _ProfessionalCard(
                                    name: barber.name,
                                    imageUrl: barber.imageUrl,
                                    rating: barber.rating,
                                    selected:
                                        state.selectedBarber?.id == barber.id,
                                    onTap: () => state.selectBarber(barber),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _hasContact(PublicBarbershop shop) {
    final identity = shop.identity;
    return identity.phone.isNotEmpty ||
        identity.whatsapp.isNotEmpty ||
        identity.instagram.isNotEmpty ||
        identity.address.isNotEmpty;
  }
}

class _CoverAppBar extends StatelessWidget {
  const _CoverAppBar({
    required this.shop,
    required this.favorite,
    required this.updating,
    required this.onFavorite,
  });

  final PublicBarbershop shop;
  final bool favorite;
  final bool updating;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final coverUrl = shop.identity.coverUrl;
    return SliverAppBar(
      expandedHeight: 238,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: const CDRBackButton(),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: _RoundAction(
            tooltip: favorite ? 'Remover dos favoritos' : 'Favoritar',
            icon: favorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            loading: updating,
            onTap: updating ? null : onFavorite,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (coverUrl.isEmpty)
              Image.asset(
                AppConstants.splashBarberReference,
                fit: BoxFit.cover,
              )
            else
              Image.network(
                coverUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const CDRSkeleton(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 0,
                      ),
                errorBuilder: (_, __, ___) => Image.asset(
                  AppConstants.splashBarberReference,
                  fit: BoxFit.cover,
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CDRColorTokens.black,
                    Color(0x00000000),
                    AppColors.background,
                  ],
                  stops: [0, .55, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CDRColorTokens.black.withOpacity(.72),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        padding: EdgeInsets.zero,
        icon: loading
            ? const CDRLoading.compact(size: CDRSizeTokens.icon)
            : Icon(icon, color: AppColors.text),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.shop});

  final PublicBarbershop shop;

  @override
  Widget build(BuildContext context) {
    final identity = shop.identity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _ShopLogo(shop: shop),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  identity.locationLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          identity.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            if (shop.reviewCount > 0)
              _InlineMeta(
                icon: Icons.star_rounded,
                value:
                    '${shop.rating.toStringAsFixed(1)} (${shop.reviewCount})',
              )
            else
              const _InlineMeta(
                icon: Icons.verified_outlined,
                value: 'Nova no Clube',
              ),
            _InlineMeta(
              icon: Icons.schedule_rounded,
              value: identity.isOpenNow
                  ? 'Aberto agora · ${identity.currentHoursDetail}'
                  : identity.currentHoursDetail,
              positive: identity.isOpenNow,
            ),
            if (shop.distanceKm.isFinite)
              _InlineMeta(
                icon: Icons.near_me_outlined,
                value: shop.distanceLabel,
              ),
          ],
        ),
      ],
    );
  }
}

class _ShopLogo extends StatelessWidget {
  const _ShopLogo({required this.shop});

  final PublicBarbershop shop;

  @override
  Widget build(BuildContext context) {
    final logoUrl = shop.identity.logoUrl;
    return Container(
      width: 68,
      height: 68,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(CDRRadiusTokens.large),
        border: Border.all(color: AppColors.stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isEmpty
          ? Image.asset(AppConstants.brandIconCr, fit: BoxFit.contain)
          : Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                AppConstants.brandIconCr,
                fit: BoxFit.contain,
              ),
            ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({
    required this.icon,
    required this.value,
    this.positive = false,
  });

  final IconData icon;
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.success : AppColors.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _QuickFacts extends StatelessWidget {
  const _QuickFacts({required this.shop});

  final PublicBarbershop shop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = MediaQuery.textScalerOf(context).scale(1) >= 1.6 ||
            constraints.maxWidth < CDRBreakpointTokens.compact;
        final cards = [
          _FactCard(
            label: 'Funcionamento',
            value: shop.identity.openingHoursLabel,
            icon: Icons.schedule_outlined,
          ),
          _FactCard(
            label: 'Serviços',
            value: shop.priceRange,
            icon: Icons.content_cut_rounded,
          ),
        ];
        if (vertical) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: cards.first),
              const SizedBox(height: CDRSpacingTokens.md),
              SizedBox(width: double.infinity, child: cards.last),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: cards.first),
            const SizedBox(width: CDRSpacingTokens.md),
            Expanded(child: cards.last),
          ],
        );
      },
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(CDRRadiusTokens.large),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.orange),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutShop extends StatelessWidget {
  const _AboutShop({required this.shop});

  final PublicBarbershop shop;

  @override
  Widget build(BuildContext context) {
    final professionals = shop.barbers.length;
    final services = shop.services.length;
    return Text(
      '${shop.identity.name} atende em ${shop.identity.locationLabel}. '
      'Confira ${services == 1 ? '1 serviço disponível' : '$services serviços disponíveis'}'
      '${professionals > 0 ? ' com ${professionals == 1 ? '1 profissional' : '$professionals profissionais'}' : ''} '
      'e escolha a melhor opção para o seu próximo horário.',
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 14,
        height: 1.55,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _ContactActions extends StatelessWidget {
  const _ContactActions({required this.shop});

  final PublicBarbershop shop;

  @override
  Widget build(BuildContext context) {
    final identity = shop.identity;
    final actions = <_ContactItem>[
      if (identity.phone.isNotEmpty)
        _ContactItem(Icons.call_outlined, 'Telefone', identity.phone),
      if (identity.whatsapp.isNotEmpty)
        _ContactItem(Icons.chat_outlined, 'WhatsApp', identity.whatsapp),
      if (identity.instagram.isNotEmpty)
        _ContactItem(
          Icons.alternate_email_rounded,
          'Instagram',
          identity.instagram,
        ),
      if (identity.address.isNotEmpty)
        _ContactItem(
          Icons.directions_outlined,
          'Endereço',
          identity.address,
        ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions
          .map(
            (action) => _ContactButton(
              item: action,
              onTap: () => _copy(context, action.value, action.label),
            ),
          )
          .toList(),
    );
  }

  Future<void> _copy(
    BuildContext context,
    String value,
    String label,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    CDRSnackbar.success(context, '$label copiado.');
  }
}

class _ContactItem {
  const _ContactItem(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({required this.item, required this.onTap});

  final _ContactItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Copiar ${item.label}',
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(item.icon, size: 18),
        label: Text(item.label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.stroke),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String imageUrl;
  final double rating;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Profissional $name',
      child: InkWell(
        borderRadius: BorderRadius.circular(CDRRadiusTokens.large),
        onTap: onTap,
        child: AnimatedContainer(
          duration: CDRDurationTokens.fast,
          width: 128,
          padding: const EdgeInsets.all(CDRSpacingTokens.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.orange : AppColors.card,
            borderRadius: BorderRadius.circular(CDRRadiusTokens.large),
            border: Border.all(
              color: selected ? AppColors.orange : AppColors.stroke,
            ),
          ),
          child: Column(
            children: [
              CDRAvatar(
                name: name,
                imageUrl: imageUrl,
                size: 58,
                excludeFromSemantics: true,
              ),
              const SizedBox(height: 10),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ).copyWith(color: selected ? AppColors.onGold : AppColors.text),
              ),
              if (rating > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${rating.toStringAsFixed(1)} ★',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ).copyWith(
                    color: selected ? AppColors.onGold : AppColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 22,
          ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.caption});

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SectionTitle(title)),
        Text(
          caption,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ScheduleBar extends StatelessWidget {
  const _ScheduleBar({required this.shop});

  final PublicBarbershop shop;

  @override
  Widget build(BuildContext context) {
    final enabled = shop.services.isNotEmpty && shop.barbers.isNotEmpty;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          CDRSpacingTokens.xxl,
          CDRSpacingTokens.md,
          CDRSpacingTokens.xxl,
          CDRSpacingTokens.md,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.stroke)),
        ),
        child: FilledButton(
          onPressed: enabled
              ? () {
                  final state = context.read<AppState>();
                  state.selectService(
                    state.selectedService != null &&
                            shop.services.any(
                              (item) => item.id == state.selectedService!.id,
                            )
                        ? state.selectedService!
                        : shop.services.first,
                  );
                  state.selectBarber(
                    state.selectedBarber != null &&
                            shop.barbers.any(
                              (item) => item.id == state.selectedBarber!.id,
                            )
                        ? state.selectedBarber!
                        : shop.barbers.first,
                  );
                  Navigator.pushNamed(context, BarberDetailsScreen.route);
                }
              : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: AppColors.orange,
            foregroundColor: AppColors.onGold,
          ),
          child: Text(
            enabled ? 'Ver horários disponíveis' : 'Agenda indisponível',
          ),
        ),
      ),
    );
  }
}

class _MissingShop extends StatelessWidget {
  const _MissingShop();

  @override
  Widget build(BuildContext context) {
    return CDREmptyState(
      icon: Icons.storefront_outlined,
      title: 'Barbearia não encontrada',
      message: 'Volte para descobrir outras barbearias disponíveis.',
      actionLabel: 'Voltar para descobrir',
      onAction: () => Navigator.maybePop(context),
    );
  }
}
