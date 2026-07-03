import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../providers/app_state.dart';
import '../../repositories/barber_repository.dart';
import '../../screens/auth/login_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_bottom_nav.dart';
import 'barbershop_profile_screen.dart';
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
          if (index == 1) return;
          if (!state.isSignedIn) {
            Navigator.pushNamed(context, LoginScreen.route);
            return;
          }
          if (index == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Favoritos entram em uma próxima etapa.'),
              ),
            );
          }
          if (index == 3) Navigator.pushNamed(context, ProfileScreen.route);
        },
      ),
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, _) {
            final shops = state.discoveredBarbershops;

            return RefreshIndicator(
              onRefresh: state.loadInitialData,
              color: AppColors.orange,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                children: [
                  const _DiscoveryHeader(),
                  const SizedBox(height: 20),
                  _SearchAndFilter(
                    onChanged: state.updateDiscoveryQuery,
                  ),
                  const SizedBox(height: 18),
                  const _LocationPill(),
                  const SizedBox(height: 24),
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
                      title: 'Próximos horários disponíveis',
                      shops: shops,
                      compact: true,
                    ),
                    _DiscoverySection(
                      title: 'Perto de você',
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
}

class _DiscoveryHeader extends StatelessWidget {
  const _DiscoveryHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          AppConstants.brandIconCr,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Boa busca',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Descubra barbearias',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
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
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: onChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Nome, serviço ou bairro',
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filled(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Filtros avançados entram em uma próxima etapa.'),
              ),
            );
          },
          style: IconButton.styleFrom(
            backgroundColor: AppColors.card,
            foregroundColor: AppColors.orange,
            fixedSize: const Size(58, 58),
            side: const BorderSide(color: AppColors.stroke),
          ),
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: const Row(
        children: [
          Icon(Icons.my_location_rounded, color: AppColors.orange, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Localização atual preparada para geolocalização',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: compact ? 178 : 282,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
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
        ? AppConstants.promoBarber
        : shop.identity.coverUrl;
    final logoUrl = shop.identity.logoUrl;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => _openProfile(context),
      child: Container(
        width: compact ? 278 : 302,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.stroke),
        ),
        child: compact
            ? _CompactCardContent(shop: shop, logoUrl: logoUrl)
            : _LargeCardContent(
                shop: shop,
                coverUrl: coverUrl,
                logoUrl: logoUrl,
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
    required this.logoUrl,
    required this.onSchedule,
  });

  final PublicBarbershop shop;
  final String coverUrl;
  final String logoUrl;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(coverUrl, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShopLogo(url: logoUrl),
            const SizedBox(width: 12),
            Expanded(child: _ShopMainInfo(shop: shop)),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: Text(
                shop.priceRange,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            FilledButton(
              onPressed: onSchedule,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.onGold,
                visualDensity: VisualDensity.compact,
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
  const _CompactCardContent({
    required this.shop,
    required this.logoUrl,
  });

  final PublicBarbershop shop;
  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ShopLogo(url: logoUrl, size: 58),
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
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _TinyMeta(
              icon: Icons.star_rounded,
              text: '${shop.rating} (${shop.reviewCount})',
            ),
            _TinyMeta(icon: Icons.place_outlined, text: shop.distanceLabel),
            _TinyMeta(icon: Icons.schedule_rounded, text: shop.nextSlot),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${shop.statusLabel} • ${shop.neighborhood}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: shop.isOpen ? AppColors.orange : AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TinyMeta extends StatelessWidget {
  const _TinyMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.orange),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ShopLogo extends StatelessWidget {
  const _ShopLogo({required this.url, this.size = 50});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: size,
        height: size,
        color: AppColors.dark,
        child: url.isEmpty
            ? Image.asset(AppConstants.brandIconCr, fit: BoxFit.cover)
            : Image.network(url, fit: BoxFit.cover),
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
      ),
      child: const Text(
        'Nenhuma barbearia encontrada para sua busca.',
        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
      ),
    );
  }
}
