import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';

import '../../core/app_constants.dart';
import '../../providers/app_state.dart';
import '../../repositories/barber_repository.dart';
import '../../screens/auth/login_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_bottom_nav.dart';
import 'barbershop_profile_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({this.onTabSelected, super.key});

  static const route = '/favorites';
  final ValueChanged<int>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Favoritos',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      bottomNavigationBar: onTabSelected == null
          ? PremiumBottomNav(
              currentIndex: 1,
              onTap: (index) => _navigate(context, index),
            )
          : null,
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (!state.isSignedIn) return const _LoginRequired();
          final shops = state.favoriteBarbershops;
          if (state.isLoadingFavorites && shops.isEmpty) {
            return const _FavoritesLoading();
          }
          if (state.favoritesLoadError != null && shops.isEmpty) {
            return CDRErrorState(
              title: 'Não foi possível carregar seus favoritos',
              message: 'Verifique sua conexão e tente novamente.',
              onRetry: state.refreshFavorites,
            );
          }
          if (shops.isEmpty) {
            return CDREmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'Nenhuma barbearia favorita',
              message:
                  'Toque no coração do perfil para guardar suas preferidas.',
              actionLabel: 'Explorar barbearias',
              onAction: () => _navigate(context, 0),
            );
          }
          return RefreshIndicator(
            color: AppColors.orange,
            onRefresh: state.refreshFavorites,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: CDRSizeTokens.clientFrameMaxWidth,
                ),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    CDRSpacingTokens.xxl,
                    CDRSpacingTokens.sm,
                    CDRSpacingTokens.xxl,
                    CDRSpacingTokens.xxxl,
                  ),
                  itemCount: shops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _FavoriteCard(
                    shop: shops[index],
                    removing:
                        state.isFavoriteUpdating(shops[index].identity.id),
                    onOpen: () => _openShop(context, shops[index]),
                    onRemove: () => state.toggleFavorite(shops[index]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static void _openShop(BuildContext context, PublicBarbershop shop) {
    context.read<AppState>().selectBarbershop(shop);
    Navigator.pushNamed(context, BarbershopProfileScreen.route);
  }

  void _navigate(BuildContext context, int index) {
    final shellSelection = onTabSelected;
    if (shellSelection != null) {
      shellSelection(index);
      return;
    }
    final route = switch (index) {
      0 => HomeScreen.route,
      1 => FavoritesScreen.route,
      2 => HistoryScreen.route,
      3 => ProfileScreen.route,
      _ => HomeScreen.route,
    };
    if (route != FavoritesScreen.route) {
      Navigator.pushReplacementNamed(context, route);
    }
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.shop,
    required this.removing,
    required this.onOpen,
    required this.onRemove,
  });

  final PublicBarbershop shop;
  final bool removing;
  final VoidCallback onOpen;
  final Future<bool> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final cover = shop.identity.coverUrl;
    return InkWell(
      borderRadius: BorderRadius.circular(CDRRadiusTokens.large),
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(CDRSpacingTokens.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(CDRRadiusTokens.large),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(CDRRadiusTokens.medium),
              child: SizedBox(
                width: 92,
                height: 98,
                child: cover.isEmpty
                    ? Image.asset(
                        AppConstants.splashBarberReference,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        cover,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          AppConstants.splashBarberReference,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: CDRSpacingTokens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.identity.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    shop.identity.locationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${shop.statusLabel} · ${shop.priceRange}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: shop.isOpen ? AppColors.success : AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remover dos favoritos',
              onPressed: removing ? null : onRemove,
              icon: removing
                  ? const CDRLoading.compact(size: 22)
                  : const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.orange,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired();

  @override
  Widget build(BuildContext context) {
    return CDREmptyState(
      icon: Icons.lock_outline_rounded,
      title: 'Entre para acessar seus favoritos',
      message: 'Suas barbearias preferidas ficam salvas na sua conta.',
      actionLabel: 'Entrar',
      onAction: () => Navigator.pushNamed(
        context,
        LoginScreen.route,
        arguments: FavoritesScreen.route,
      ),
    );
  }
}

class _FavoritesLoading extends StatelessWidget {
  const _FavoritesLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        CDRSpacingTokens.xxl,
        CDRSpacingTokens.sm,
        CDRSpacingTokens.xxl,
        CDRSpacingTokens.xxxl,
      ),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: CDRSpacingTokens.md),
      itemBuilder: (_, __) => const CDRCard(
        padding: EdgeInsets.all(CDRSpacingTokens.md),
        child: Row(
          children: [
            CDRSkeleton(
              width: 92,
              height: 98,
              borderRadius: CDRRadiusTokens.medium,
            ),
            SizedBox(width: CDRSpacingTokens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CDRSkeleton.line(width: 150, height: 18),
                  SizedBox(height: CDRSpacingTokens.md),
                  CDRSkeleton.line(width: 112),
                  SizedBox(height: CDRSpacingTokens.md),
                  CDRSkeleton.line(width: 88),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
