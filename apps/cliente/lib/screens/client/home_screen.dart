import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../providers/app_state.dart';
import '../../repositories/barber_repository.dart';
import '../../screens/auth/login_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_bottom_nav.dart';
import 'barbershop_profile_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const route = '/home';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: 0,
        onTap: (index) {
          final state = context.read<AppState>();
          if (index == 0) return;
          if (!state.isSignedIn) {
            Navigator.pushNamed(context, LoginScreen.route);
            return;
          }
          if (index == 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Favoritos entram em uma proxima etapa.')),
            );
          }
          if (index == 2) Navigator.pushNamed(context, HistoryScreen.route);
          if (index == 3) Navigator.pushNamed(context, ProfileScreen.route);
        },
      ),
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, _) {
            final shops = state.discoveredBarbershops;

            return RefreshIndicator(
              color: AppColors.orange,
              backgroundColor: AppColors.card,
              onRefresh: state.loadInitialData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                children: [
                  const _DiscoveryHeader(),
                  const SizedBox(height: 18),
                  _SearchAndFilter(onChanged: state.updateDiscoveryQuery),
                  const SizedBox(height: 14),
                  const _LocationPill(),
                  const SizedBox(height: 16),
                  _CategoryChips(labels: _categoryLabels(state)),
                  const SizedBox(height: 22),
                  if (state.isLoading && shops.isEmpty)
                    const _DiscoveryLoading()
                  else if (shops.isEmpty)
                    const _EmptyDiscovery()
                  else ...[
                    _DiscoverySection(
                      title: 'Mais bem avaliadas',
                      shops: state.topRatedBarbershops,
                    ),
                    _DiscoverySection(
                      title: 'Proximos horarios disponiveis',
                      shops: shops,
                      compact: true,
                    ),
                    _DiscoverySection(
                      title: 'Perto de voce',
                      shops: state.nearbyBarbershops,
                    ),
                    _DiscoverySection(
                      title: 'Mais procuradas',
                      shops: state.popularBarbershops,
                      compact: true,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static List<String> _categoryLabels(AppState state) {
    if (state.categories.isEmpty) {
      return const ['Corte', 'Barba', 'Premium', 'Infantil', 'Combo'];
    }
    return state.categories.take(5).map((item) => item.name).toList();
  }
}

class _DiscoveryHeader extends StatelessWidget {
  const _DiscoveryHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Boa tarde, Rafael',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Onde vamos dar\naquela renovada hoje?',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 27,
                  height: 1.06,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.stroke),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.orange,
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  const _SearchAndFilter({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.text),
      cursorColor: AppColors.orange,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.muted),
        suffixIcon: Icon(Icons.tune_rounded, color: AppColors.orange),
        hintText: 'Buscar barbearias, servicos...',
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined,
            color: AppColors.orange, size: 18),
        const SizedBox(width: 7),
        const Text(
          'Uberaba, MG',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.muted),
        const Spacer(),
        IconButton(
          tooltip: 'Filtros',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Filtros avancados entram em uma proxima etapa.')),
            );
          },
          icon: const Icon(Icons.tune_rounded, color: AppColors.orange),
        ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.content_cut_rounded,
      Icons.face_retouching_natural_outlined,
      Icons.workspace_premium_outlined,
      Icons.child_care_outlined,
      Icons.auto_awesome_outlined,
    ];

    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 58,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: Icon(
                    icons[index % icons.length],
                    color: AppColors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DiscoverySection extends StatelessWidget {
  const _DiscoverySection({
    required this.title,
    required this.shops,
    this.compact = false,
  });

  final String title;
  final List<PublicBarbershop> shops;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visible = shops.take(6).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Text(
                'Ver todas',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: compact ? 150 : 292,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _BarbershopCard(
                  shop: visible[index],
                  compact: compact,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BarbershopCard extends StatelessWidget {
  const _BarbershopCard({
    required this.shop,
    required this.compact,
  });

  final PublicBarbershop shop;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final coverUrl = shop.identity.coverUrl.isEmpty
        ? AppConstants.heroBarbershop
        : shop.identity.coverUrl;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openProfile(context),
      child: Container(
        width: compact ? 282 : 300,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.stroke),
        ),
        child: compact
            ? _CompactCardContent(shop: shop)
            : _LargeCardContent(
                shop: shop,
                coverUrl: coverUrl,
                onSchedule: () => _openProfile(context),
              ),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    context.read<AppState>().selectBarbershop(shop);
    Navigator.pushNamed(context, BarbershopProfileScreen.route);
  }
}

class _LargeCardContent extends StatelessWidget {
  const _LargeCardContent({
    required this.shop,
    required this.coverUrl,
    required this.onSchedule,
  });

  final PublicBarbershop shop;
  final String coverUrl;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(coverUrl, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: _RatingBadge(rating: shop.rating),
            ),
          ],
        ),
        const SizedBox(height: 9),
        _ShopMainInfo(shop: shop),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                shop.priceRange,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            FilledButton(
              onPressed: onSchedule,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.onGold,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
              child: const Text('Agendar'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactCardContent extends StatelessWidget {
  const _CompactCardContent({required this.shop});

  final PublicBarbershop shop;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RatingBadge(rating: shop.rating),
        const SizedBox(width: 12),
        Expanded(child: _ShopMainInfo(shop: shop)),
        const Icon(Icons.chevron_right_rounded, color: AppColors.orange),
      ],
    );
  }
}

class _ShopMainInfo extends StatelessWidget {
  const _ShopMainInfo({required this.shop});

  final PublicBarbershop shop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          shop.identity.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: AppColors.orange, size: 15),
            const SizedBox(width: 4),
            Text(
              '${shop.rating} (${shop.reviewCount})',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              shop.distanceLabel,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${shop.statusLabel} agora - ${shop.nextSlot}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: shop.isOpen ? AppColors.success : AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.orange),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'CDR',
            style: TextStyle(
              color: AppColors.orange,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoveryLoading extends StatelessWidget {
  const _DiscoveryLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      ),
    );
  }
}

class _EmptyDiscovery extends StatelessWidget {
  const _EmptyDiscovery();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: const Text(
        'Nenhuma barbearia encontrada para sua busca.',
        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
      ),
    );
  }
}
