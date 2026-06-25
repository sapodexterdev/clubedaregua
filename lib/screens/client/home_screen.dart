import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../providers/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/barber_card.dart';
import '../../widgets/premium_bottom_nav.dart';
import '../../widgets/section_header.dart';
import '../../widgets/service_card.dart';
import 'barber_details_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const route = '/home';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, HistoryScreen.route);
          if (index == 3) Navigator.pushNamed(context, ProfileScreen.route);
        },
      ),
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(AppConstants.defaultAvatar),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bom dia, Rafael',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Pronto para renovar o visual?',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () {},
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.text,
                      ),
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: 'Buscar servico, salao ou barbeiro',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      onPressed: () {},
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        fixedSize: const Size(56, 56),
                      ),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.dark,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '20% OFF no proximo corte',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Use o cupom REGUA20 hoje.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          BarberDetailsScreen.route,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Agendar agora'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final category = state.categories[index];
                      return Chip(
                        avatar: const Icon(Icons.content_cut, size: 18),
                        label: Text(category.name),
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Barbeiros em destaque'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.barbers.length,
                    itemBuilder: (context, index) {
                      final barber = state.barbers[index];
                      return BarberCard(
                        barber: barber,
                        onTap: () {
                          state.selectBarber(barber);
                          Navigator.pushNamed(context, BarberDetailsScreen.route);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Servicos populares'),
                const SizedBox(height: 12),
                ...state.services.map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ServiceCard(
                      service: service,
                      isSelected: state.selectedService?.id == service.id,
                      onTap: () => state.selectService(service),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
