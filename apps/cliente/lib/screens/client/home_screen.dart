import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';

import '../../core/app_constants.dart';
import '../../models/service_category.dart';
import '../../providers/app_state.dart';
import '../../repositories/barber_repository.dart';
import '../../screens/auth/login_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_bottom_nav.dart';
import 'barbershop_profile_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    this.onTabSelected,
    this.isActive = true,
    super.key,
  });

  static const route = '/home';
  final ValueChanged<int>? onTabSelected;
  final bool isActive;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _notificationRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshNotificationCount();
    });
    _notificationRefreshTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _refreshNotificationCount(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _refreshNotificationCount();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      _refreshNotificationCount();
    }
  }

  void _refreshNotificationCount() {
    if (!mounted || !widget.isActive) return;
    context.read<AppState>().refreshNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: widget.onTabSelected == null
          ? PremiumBottomNav(
              currentIndex: 0,
              onTap: (index) {
                _selectTab(context, index);
              },
            )
          : null,
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, _) {
            final shops = state.discoveredBarbershops;
            final topRated = state.topRatedBarbershops;
            final featured = topRated.isEmpty ? null : topRated.first;
            final usedIds = <String>{
              if (featured != null) featured.identity.id,
            };
            final openShops = state.openBarbershops
                .where((shop) => !usedIds.contains(shop.identity.id))
                .toList();
            usedIds.addAll(openShops.map((shop) => shop.identity.id));
            final nearbyShops = state.useCurrentLocation
                ? state.nearbyBarbershops
                    .where((shop) => !usedIds.contains(shop.identity.id))
                    .toList()
                : const <PublicBarbershop>[];
            usedIds.addAll(nearbyShops.map((shop) => shop.identity.id));
            final otherShops = shops
                .where((shop) => !usedIds.contains(shop.identity.id))
                .toList();

            return LayoutBuilder(
              builder: (context, _) {
                return RefreshIndicator(
                  color: AppColors.orange,
                  backgroundColor: AppColors.card,
                  onRefresh: state.loadInitialData,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: CDRSizeTokens.clientFrameMaxWidth,
                      ),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          CDRSpacingTokens.xxl,
                          CDRSpacingTokens.lg,
                          CDRSpacingTokens.xxl,
                          CDRSpacingTokens.xxxl,
                        ),
                        children: [
                          _DiscoveryHeader(
                            greeting: state.discoveryGreeting,
                            unreadCount: state.unreadNotificationCount,
                            onNotificationsTap: () async {
                              if (!state.isSignedIn) {
                                Navigator.pushNamed(
                                  context,
                                  LoginScreen.route,
                                  arguments: NotificationsScreen.route,
                                );
                                return;
                              }
                              await state.refreshNotifications();
                              if (!context.mounted) return;
                              Navigator.pushNamed(
                                  context, NotificationsScreen.route);
                            },
                          ),
                          const SizedBox(height: 24),
                          _SearchAndFilter(
                            value: state.discoveryQuery,
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
                          const SizedBox(height: 12),
                          _DiscoveryCategories(
                            categories: state.discoveryCategories,
                            selectedId: state.discoveryCategoryId,
                            onSelected: state.toggleDiscoveryCategory,
                          ),
                          const SizedBox(height: 20),
                          if (state.isLoading && shops.isEmpty)
                            const _DiscoveryLoading()
                          else if (state.discoveryLoadError != null &&
                              shops.isEmpty)
                            _DiscoveryError(onRetry: state.loadInitialData)
                          else if (shops.isEmpty)
                            _EmptyDiscovery(
                              isSearch: state.hasDiscoveryQuery,
                              onClear: state.clearDiscoveryFilters,
                            )
                          else if (state.hasDiscoveryQuery)
                            _SearchResults(shops: shops)
                          else ...[
                            if (featured != null)
                              _DiscoverySection(
                                title: 'Destaque para você',
                                shops: [featured],
                                viewAllTitle: 'Todas as barbearias',
                                viewAllShops: shops,
                              ),
                            if (openShops.isNotEmpty)
                              _DiscoverySection(
                                title: 'Abertas agora',
                                shops: openShops,
                                compact: true,
                              ),
                            if (nearbyShops.isNotEmpty)
                              _DiscoverySection(
                                title: 'Perto de você',
                                shops: nearbyShops,
                                compact: true,
                              ),
                            if (otherShops.isNotEmpty)
                              _DiscoverySection(
                                title: 'Outras barbearias',
                                shops: otherShops,
                                compact: true,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _selectTab(BuildContext context, int index) {
    final shellSelection = widget.onTabSelected;
    if (shellSelection != null) {
      shellSelection(index);
      return;
    }
    final state = context.read<AppState>();
    if (index == 0) return;
    final destination = switch (index) {
      1 => FavoritesScreen.route,
      2 => HistoryScreen.route,
      3 => ProfileScreen.route,
      _ => HomeScreen.route,
    };
    if (!state.isSignedIn) {
      Navigator.pushNamed(
        context,
        LoginScreen.route,
        arguments: destination,
      );
      return;
    }
    Navigator.pushNamed(context, destination);
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
                        fontSize: 24,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
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
  const _DiscoveryHeader({
    required this.greeting,
    required this.unreadCount,
    required this.onNotificationsTap,
  });

  final String greeting;
  final int unreadCount;
  final VoidCallback onNotificationsTap;

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
              Text(
                'Onde você quer dar aquela renovada hoje?',
                style: CDRTypographyTokens.title1.copyWith(
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onNotificationsTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.stroke),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.orange,
                  size: 22,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(9),
                        border:
                            Border.all(color: AppColors.background, width: 2),
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: AppColors.onGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchAndFilter extends StatefulWidget {
  const _SearchAndFilter({
    required this.value,
    required this.onChanged,
    required this.onFilterTap,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  @override
  State<_SearchAndFilter> createState() => _SearchAndFilterState();
}

class _SearchAndFilterState extends State<_SearchAndFilter> {
  Timer? _debounce;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _SearchAndFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
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
      height: CDRSizeTokens.inputHeight,
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        style: Theme.of(context).textTheme.bodyLarge,
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
                  fontSize: 14,
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
                      fontSize: 24,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ListTile(
                  enabled: !isLocating,
                  leading: isLocating
                      ? const CDRLoading.compact(size: 24)
                      : const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.orange,
                        ),
                  title: const Text('Usar minha localização'),
                  subtitle: const Text('Mostrar barbearias em até 10 km'),
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final success = await onUseCurrentLocation();
                    if (!context.mounted) return;
                    if (success) {
                      navigator.pop();
                    } else {
                      CDRSnackbar.warning(
                        context,
                        'Não foi possível acessar sua localização. Escolha uma cidade abaixo.',
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

class _DiscoveryCategories extends StatelessWidget {
  const _DiscoveryCategories({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ServiceCategory> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category.id == selectedId;
          return FilterChip(
            selected: selected,
            onSelected: (_) => onSelected(category.id),
            avatar: Icon(
              _categoryIcon(category.name),
              size: 18,
              color: selected ? AppColors.orange : AppColors.muted,
            ),
            label: Text(category.name),
            labelStyle: TextStyle(
              color: selected ? AppColors.text : AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: AppColors.card,
            selectedColor: AppColors.card,
            side: BorderSide(
              color: selected ? AppColors.orange : AppColors.stroke,
            ),
            shape: const StadiumBorder(),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          );
        },
      ),
    );
  }

  IconData _categoryIcon(String name) {
    switch (name.trim().toLowerCase()) {
      case 'barba':
        return Icons.face_retouching_natural_rounded;
      case 'combo':
        return Icons.auto_awesome_rounded;
      case 'infantil':
        return Icons.child_care_rounded;
      case 'premium':
        return Icons.workspace_premium_outlined;
      default:
        return Icons.content_cut_rounded;
    }
  }
}

class _DiscoverySection extends StatelessWidget {
  const _DiscoverySection({
    required this.title,
    required this.shops,
    this.compact = false,
    this.viewAllTitle,
    this.viewAllShops,
  });

  final String title;
  final List<PublicBarbershop> shops;
  final bool compact;
  final String? viewAllTitle;
  final List<PublicBarbershop>? viewAllShops;

  @override
  Widget build(BuildContext context) {
    final visible = shops.take(6).toList();

    if (!compact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: CDRSpacingTokens.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: title,
              icon: _sectionIcon,
              onViewAll: () => _showAllBarbershops(context),
            ),
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
      padding: const EdgeInsets.only(bottom: CDRSpacingTokens.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: title,
            icon: _sectionIcon,
            onViewAll: () => _showAllBarbershops(context),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: compact ? 164 : 304,
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

  void _showAllBarbershops(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (context) => _AllBarbershopsSheet(
        title: viewAllTitle ?? title,
        shops: viewAllShops ?? shops,
      ),
    );
  }

  IconData get _sectionIcon {
    if (title == 'Abertas agora') return Icons.schedule_rounded;
    if (title == 'Perto de você') return Icons.near_me_outlined;
    if (title == 'Outras barbearias') return Icons.storefront_outlined;
    return Icons.workspace_premium_outlined;
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.shops});

  final List<PublicBarbershop> shops;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${shops.length} ${shops.length == 1 ? 'resultado' : 'resultados'}',
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 22,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        for (final shop in shops) ...[
          _BarbershopCard(
            shop: shop,
            compact: false,
            fullWidth: true,
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _AllBarbershopsSheet extends StatelessWidget {
  const _AllBarbershopsSheet({
    required this.title,
    required this.shops,
  });

  final String title;
  final List<PublicBarbershop> shops;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .88,
        minChildSize: .55,
        maxChildSize: .96,
        builder: (context, controller) {
          return Column(
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.stroke,
                  borderRadius: BorderRadius.circular(CDRRadiusTokens.pill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 26,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${shops.length} ${shops.length == 1 ? 'barbearia disponível' : 'barbearias disponíveis'}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                  itemCount: shops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _BarbershopCard(
                    shop: shops[index],
                    compact: true,
                    fullWidth: true,
                  ),
                ),
              ),
            ],
          );
        },
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
    final coverUrl = shop.identity.coverUrl;

    return InkWell(
      borderRadius: BorderRadius.circular(CDRRadiusTokens.large),
      onTap: () => _openProfile(context),
      child: Container(
        width: fullWidth ? double.infinity : (compact ? 282 : 300),
        padding: const EdgeInsets.all(CDRSpacingTokens.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(CDRRadiusTokens.large),
          border: Border.all(color: AppColors.stroke.withOpacity(.8)),
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
              borderRadius: BorderRadius.circular(CDRRadiusTokens.medium),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: coverUrl.isEmpty
                    ? Image.asset(
                        AppConstants.splashBarberReference,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const CDRSkeleton(
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: 0,
                          );
                        },
                        errorBuilder: (_, __, ___) => Image.asset(
                          AppConstants.splashBarberReference,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            if (shop.reviewCount >= 5)
              Positioned(
                right: 8,
                bottom: 8,
                child: _RatingBadge(rating: shop.rating),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _ShopMainInfo(shop: shop),
        if (shop.services.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final service in shop.services.take(3))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.elevated,
                    borderRadius: BorderRadius.circular(CDRRadiusTokens.pill),
                  ),
                  child: Text(
                    service.name,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
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
                  fontSize: 13,
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
              child: const Text('Ver horários'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onViewAll,
  });

  final String title;
  final IconData icon;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.orange,
          size: CDRSizeTokens.icon,
        ),
        const SizedBox(width: CDRSpacingTokens.sm),
        Expanded(
          child: Text(
            title,
            style: CDRTypographyTokens.title2.copyWith(
              color: AppColors.text,
              fontSize: 22,
            ),
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.orange,
            minimumSize: const Size(64, 44),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: const Text(
            'Ver todas',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
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
    final coverUrl = shop.identity.coverUrl;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(CDRRadiusTokens.medium),
          child: SizedBox(
            width: 72,
            height: 104,
            child: coverUrl.isEmpty
                ? Image.asset(
                    AppConstants.splashBarberReference,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      AppConstants.splashBarberReference,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shop.identity.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.orange,
                    size: 14,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    shop.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shop.distanceKm.isFinite
                          ? shop.distanceLabel
                          : shop.neighborhood,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${shop.statusLabel} · ${shop.nextSlot}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: shop.isOpen ? AppColors.success : AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                shop.priceRange,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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
              shop.reviewCount > 0
                  ? '${shop.rating} (${shop.reviewCount})'
                  : '${shop.rating} · equipe',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              shop.distanceKm.isFinite
                  ? shop.distanceLabel
                  : shop.identity.city,
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
          '${shop.statusLabel} agora · ${shop.nextSlot}',
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
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(.9),
        borderRadius: BorderRadius.circular(CDRRadiusTokens.medium),
        border: Border.all(color: AppColors.orange),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: CDRTypographyTokens.title3.copyWith(
              color: AppColors.text,
              fontFamily: CDRTypographyTokens.displayFontFamily,
            ),
          ),
          const Text(
            'CDR SCORE',
            style: TextStyle(
              color: AppColors.orange,
              fontSize: 8,
              height: 1.25,
              fontWeight: FontWeight.w700,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CDRSkeleton.line(width: 156, height: 18),
        const SizedBox(height: 12),
        const CDRCard(
          padding: EdgeInsets.all(CDRSpacingTokens.md),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CDRSkeleton(
                  width: double.infinity,
                  height: 180,
                ),
              ),
              SizedBox(height: 12),
              CDRSkeleton.line(width: 210, height: 18),
              SizedBox(height: 10),
              CDRSkeleton.line(width: 150, height: 12),
              SizedBox(height: 14),
              CDRSkeleton(width: double.infinity, height: 40),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const CDRSkeleton.line(width: 130, height: 18),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(child: CDRSkeleton(width: 280, height: 138)),
            SizedBox(width: 12),
            SizedBox(
              width: 44,
              child: CDRSkeleton(width: 44, height: 138),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyDiscovery extends StatelessWidget {
  const _EmptyDiscovery({
    required this.isSearch,
    required this.onClear,
  });

  final bool isSearch;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return CDRCard(
      padding: EdgeInsets.zero,
      child: CDREmptyState(
        icon: Icons.search_off_rounded,
        title: isSearch
            ? 'Nenhuma barbearia corresponde à sua busca.'
            : 'Nenhuma barbearia encontrada nesta localização.',
        message: 'Tente alterar a busca, os filtros ou a localização.',
        actionLabel: 'Limpar filtros',
        onAction: onClear,
      ),
    );
  }
}

class _DiscoveryError extends StatelessWidget {
  const _DiscoveryError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return CDRCard(
      padding: EdgeInsets.zero,
      child: CDRErrorState(
        title: 'Não foi possível carregar as barbearias.',
        message: 'Verifique sua conexão e tente novamente.',
        onRetry: onRetry,
      ),
    );
  }
}
