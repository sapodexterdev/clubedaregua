import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../providers/app_state.dart';
import '../../screens/auth/login_screen.dart';
import '../../services/auth_service.dart';
import '../../services/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/premium_bottom_nav.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const route = '/profile';

  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.watch<AppState>().isSignedIn;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: 3,
        onTap: (index) {
          final route = switch (index) {
            0 => HomeScreen.route,
            1 => FavoritesScreen.route,
            2 => HistoryScreen.route,
            3 => ProfileScreen.route,
            _ => HomeScreen.route,
          };
          if (route != ProfileScreen.route) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
      body: isSignedIn
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundImage:
                            NetworkImage(AppConstants.defaultAvatar),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rafael Sapão',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'Cliente premium',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: 'Pontos',
                        value: '1.240',
                        icon: Icons.workspace_premium_rounded,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        title: 'Cupons',
                        value: '3',
                        icon: Icons.local_offer_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Notificações',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                ...MockData.notifications.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          item.isRead ? Colors.white : const Color(0xFFFFEFE8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.notifications_rounded,
                          color: AppColors.orange),
                      title: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(item.message),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        LoginScreen.route,
                        (_) => false,
                      );
                    }
                  },
                  child: const Text('Sair da conta'),
                ),
              ],
            )
          : const _ProfileLoginRequired(),
    );
  }
}

class _ProfileLoginRequired extends StatelessWidget {
  const _ProfileLoginRequired();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline_rounded, color: AppColors.orange),
            const SizedBox(height: 12),
            const Text(
              'Entre para ver perfil, favoritos e preferências.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, LoginScreen.route),
              child: const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}
