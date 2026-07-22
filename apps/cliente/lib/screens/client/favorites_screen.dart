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
  const FavoritesScreen({super.key});

  static const route = '/favorites';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Favoritos',
          style: TextStyle(
            fontFamily: 'Barlow Condensed',
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: 1,
        onTap: (index) => _navigate(context, index),
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (!state.isSignedIn) return const _LoginRequired();
          final shops = state.favoriteBarbershops;
          if (state.isLoadingFavorites && shops.isEmpty) {
            return const CDRLoading.fullScreen(
              message: 'Carregando seus favoritos...',
            );
          }
          if (state.favoritesLoadError != null && shops.isEmpty) {
            return _FavoriteState(
              icon: Icons.cloud_off_outlined,
              title: 'Não foi possível carregar seus favoritos',
              description: 'Verifique a conexão e tente novamente.',
              actionLabel: 'Tentar novamente',
              onAction: state.refreshFavorites,
            );
          }
          if (shops.isEmpty) {
            return _FavoriteState(
              icon: Icons.favorite_border_rounded,
              title: 'Nenhuma barbearia favorita',
              description:
                  'Toque no coração do perfil para guardar suas preferidas.',
              actionLabel: 'Explorar barbearias',
              onAction: () => _navigate(context, 0),
            );
          }
          return RefreshIndicator(
            color: AppColors.orange,
            onRefresh: state.refreshFavorites,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              itemCount: shops.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _FavoriteCard(
                shop: shops[index],
                removing: state.isFavoriteUpdating(shops[index].identity.id),
                onOpen: () => _openShop(context, shops[index]),
                onRemove: () => state.toggleFavorite(shops[index]),
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

  static void _navigate(BuildContext context, int index) {
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
      borderRadius: BorderRadius.circular(18),
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.identity.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontFamily: 'Barlow Condensed',
                      fontSize: 20,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    shop.identity.locationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${shop.statusLabel} · ${shop.priceRange}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          shop.isOpen ? AppColors.success : AppColors.muted,
                      fontSize: 10,
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
    return _FavoriteState(
      icon: Icons.lock_outline_rounded,
      title: 'Entre para acessar seus favoritos',
      description: 'Suas barbearias preferidas ficam salvas na sua conta.',
      actionLabel: 'Entrar',
      onAction: () => Navigator.pushNamed(
        context,
        LoginScreen.route,
        arguments: FavoritesScreen.route,
      ),
    );
  }
}

class _FavoriteState extends StatelessWidget {
  const _FavoriteState({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.orange, size: 42),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text,
                fontFamily: 'Barlow Condensed',
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
