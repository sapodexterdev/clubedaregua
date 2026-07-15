import 'dart:async';

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
                  content: Text('Favoritos entram em uma próxima etapa.')),
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
                  _DiscoveryHeader(greeting: state.discoveryGreeting),
                  const SizedBox(height: 24),
                  _SearchAndFilter(
                    onChanged: state.updateDiscoveryQuery,
                    onFilterTap: () => _showFilters(context),
                  ),
                  const SizedBox(height: 12),
                  _LocationPill(
                    label: state.discoveryLocationLabel,
                    locations: state.availableDiscoveryLocations,
                    onSelected: state.selectDiscoveryLocation,
                    isLocating: state.isLocating,
                    onUseCurrentLocation: state.locateDevice,
                  ),
                  const SizedBox(height: 20),
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

  void _showFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Consumer<AppState>(
            builder: (context, state, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtros',
                      style: TextStyle(
                        color: AppColors.text,
                        fontFamily: 'Barlow Condensed',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.orange,
                      title: const Text('Aberto agora'),
                      value: state.discoveryOpenNowOnly,
                      onChanged: state.setDiscoveryOpenNowOnly,
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.orange,
                      title: const Text('Avaliação 4,5 ou superior'),
                      value: state.discoveryHighlyRatedOnly,
                      onChanged: state.setDiscoveryHighlyRatedOnly,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: state.clearDiscoveryFilters,
                        child: const Text('Limpar filtros'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _DiscoveryHeader extends StatelessWidget {
  const _DiscoveryHeader({required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.38,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Onde você quer dar\naquela renovada hoje?',
                style: TextStyle(
                  color: AppColors.text,
                  fontFamily: 'Barlow Condensed',
                  fontSize: 32,
                  height: 1.125,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
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

class _SearchAndFilter extends StatefulWidget {
  const _SearchAndFilter({
    required this.onChanged,
    required this.onFilterTap,
  });

  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  @override
  State<_SearchAndFilter> createState() => _SearchAndFilterState();
}

class _SearchAndFilterState extends State<_SearchAndFilter> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => widget.onChanged(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TextField(
        onChanged: _onChanged,
        style: const TextStyle(color: AppColors.text),
        cursorColor: AppColors.orange,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
          suffixIcon: IconButton(
            tooltip: 'Filtros',
            onPressed: widget.onFilterTap,
            icon: const Icon(Icons.tune_rounded, color: AppColors.orange),
          ),
          hintText: 'Buscar barbearias, serviços...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({
    required this.label,
    required this.locations,
    required this.onSelected,
    required this.isLocating,
    required this.onUseCurrentLocation,
  });

  final String label;
  final List<String> locations;
  final ValueChanged<String?> onSelected;
  final bool isLocating;
  final Future<bool> Function() onUseCurrentLocation;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _selectLocation(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: AppColors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }

  void _selectLocation(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    'Escolha sua localização',
                    style: TextStyle(
                      color: AppColors.text,
                      fontFamily: 'Barlow Condensed',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ListTile(
                  enabled: !isLocating,
                  leading: isLocating
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.orange,
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.orange,
                        ),
                  title: const Text('Usar minha localização'),
                  subtitle: const Text('Mostrar barbearias em até 10 km'),
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await onUseCurrentLocation();
                    if (!context.mounted) return;
                    if (success) {
                      navigator.pop();
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Não foi possível acessar sua localização. Você pode escolher uma cidade abaixo.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.public_rounded,
                    color: AppColors.orange,
                  ),
                  title: const Text('Todas as localizações'),
                  onTap: () {
                    onSelected('');
                    Navigator.pop(context);
                  },
                ),
                for (final location in locations)
                  ListTile(
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.orange,
                    ),
                    title: Text(location),
                    onTap: () {
                      onSelected(location);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
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

    if (!compact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: title),
            const SizedBox(height: 12),
            if (visible.isNotEmpty)
              _BarbershopCard(
                shop: visible.first,
                compact: false,
                fullWidth: true,
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title),
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
    this.fullWidth = false,
  });

  final PublicBarbershop shop;
  final bool compact;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final coverUrl = shop.identity.coverUrl.isEmpty
        ? AppConstants.heroBarbershop
        : shop.identity.coverUrl;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openProfile(context),
      child: Container(
        width: fullWidth ? double.infinity : (compact ? 282 : 300),
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
        const SizedBox(height: 8),
        _ShopMainInfo(shop: shop),
        const SizedBox(height: 8),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.local_fire_department_rounded,
          color: AppColors.orange,
          size: 15,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Text(
          'Ver todas',
          style: TextStyle(
            color: AppColors.orange,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
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
