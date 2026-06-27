import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../providers/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/barber_card.dart';
import '../../widgets/premium_bottom_nav.dart';
import '../../widgets/section_header.dart';
import 'barber_details_screen.dart';
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
          if (index == 1) Navigator.pushNamed(context, HistoryScreen.route);
          if (index == 3) Navigator.pushNamed(context, ProfileScreen.route);
        },
      ),
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(AppConstants.defaultAvatar),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bom dia!',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Rafael Sapão',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () {},
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.muted,
                        fixedSize: const Size(58, 58),
                      ),
                      icon: const Icon(Icons.notifications_none_rounded, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: 'Buscar salão, barbeiro ou serviço',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      onPressed: () {},
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.muted,
                        fixedSize: const Size(58, 58),
                      ),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Container(
                  height: 210,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.dark,
                    borderRadius: BorderRadius.circular(26),
                    image: const DecorationImage(
                      image: NetworkImage(AppConstants.promoBarber),
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      opacity: .58,
                    ),
                  ),
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black87, Colors.transparent],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 2,
                        top: 8,
                        bottom: 8,
                        width: 220,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ganhe 20% OFF\nno próximo corte!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                height: 1.08,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                BarberDetailsScreen.route,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.orange,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(138, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: const Text('Agendar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Categorias',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 54,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final category = state.categories[index];
                      final selected = state.selectedCategoryId == category.id;
                      return InkWell(
                        borderRadius: BorderRadius.circular(27),
                        onTap: () => state.selectCategory(category.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.orange : Colors.white,
                            borderRadius: BorderRadius.circular(27),
                          ),
                          child: Text(
                            _categoryLabel(category.name),
                            style: TextStyle(
                              color: selected ? Colors.white : AppColors.muted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),
                SectionHeader(
                  title: state.selectedCategoryTitle,
                  actionLabel: state.selectedCategoryId == null ? null : 'Ver todos',
                  onAction: state.clearCategory,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.filteredBarbers.length,
                    itemBuilder: (context, index) {
                      final barber = state.filteredBarbers[index];
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
              ],
            );
          },
        ),
      ),
    );
  }

  String _categoryLabel(String name) {
    return switch (name.toLowerCase()) {
      'cabelo' => 'Corte',
      _ => name,
    };
  }
}
