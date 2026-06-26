import 'package:flutter/material.dart';

import '../../core/app_constants.dart';
import '../../services/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/premium_bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const route = '/profile';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) Navigator.pop(context);
        },
      ),
      body: ListView(
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
                  backgroundImage: NetworkImage(AppConstants.defaultAvatar),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rafael Sapão',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
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
                color: item.isRead ? Colors.white : const Color(0xFFFFEFE8),
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
        ],
      ),
    );
  }
}
