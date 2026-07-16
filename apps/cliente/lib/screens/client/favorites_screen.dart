import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../screens/auth/login_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_bottom_nav.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  static const route = '/favorites';

  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.watch<AppState>().isSignedIn;

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
      body: SafeArea(
        top: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: Icon(
                    isSignedIn
                        ? Icons.favorite_border_rounded
                        : Icons.lock_outline_rounded,
                    color: AppColors.orange,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isSignedIn
                      ? 'Suas barbearias favoritas aparecerão aqui.'
                      : 'Entre para acessar seus favoritos.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontFamily: 'Barlow Condensed',
                    fontSize: 24,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isSignedIn
                      ? 'Você ainda não adicionou nenhuma barbearia.'
                      : 'Salve lugares e encontre-os rapidamente depois.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    if (isSignedIn) {
                      Navigator.pushReplacementNamed(context, HomeScreen.route);
                    } else {
                      Navigator.pushNamed(
                        context,
                        LoginScreen.route,
                        arguments: FavoritesScreen.route,
                      );
                    }
                  },
                  child: Text(isSignedIn ? 'Explorar barbearias' : 'Entrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    final route = switch (index) {
      0 => HomeScreen.route,
      1 => FavoritesScreen.route,
      2 => HistoryScreen.route,
      3 => ProfileScreen.route,
      _ => HomeScreen.route,
    };
    if (route == FavoritesScreen.route) return;
    if (route != HomeScreen.route && !context.read<AppState>().isSignedIn) {
      Navigator.pushNamed(
        context,
        LoginScreen.route,
        arguments: route,
      );
      return;
    }
    Navigator.pushReplacementNamed(context, route);
  }
}
