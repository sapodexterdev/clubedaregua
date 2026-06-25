import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../services/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/date_selector.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/time_selector.dart';
import 'appointment_screen.dart';

class BarberDetailsScreen extends StatelessWidget {
  const BarberDetailsScreen({super.key});

  static const route = '/barber-details';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final barber = state.selectedBarber;

        if (barber == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 330,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.more_horiz_rounded),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.network(barber.imageUrl, fit: BoxFit.cover),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          barber.name,
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          barber.shopName,
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton.filled(
                                    onPressed: () {},
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.background,
                                      foregroundColor: AppColors.orange,
                                    ),
                                    icon: const Icon(Icons.favorite_rounded),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: AppColors.orange),
                                  Text(
                                    ' ${barber.rating}  ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const Text(
                                    '(126 avaliacoes)',
                                    style: TextStyle(color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const DefaultTabController(
                          length: 3,
                          child: TabBar(
                            labelColor: AppColors.text,
                            indicatorColor: AppColors.orange,
                            tabs: [
                              Tab(text: 'Agendamento'),
                              Tab(text: 'Sobre'),
                              Tab(text: 'Avaliacoes'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Escolha a data',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        DateSelector(
                          selectedDate: state.selectedDate,
                          onSelected: state.selectDate,
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Horarios livres',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        TimeSelector(
                          times: MockData.times,
                          selectedTime: state.selectedTime,
                          onSelected: state.selectTime,
                        ),
                        const SizedBox(height: 22),
                        Text(
                          barber.bio,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Resumo do agendamento',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                              Text(
                                state.selectedService == null
                                    ? 'R\$ 0'
                                    : 'R\$ ${state.selectedService!.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        PrimaryButton(
                          label: 'Agendar agora',
                          onPressed: () =>
                              Navigator.pushNamed(context, AppointmentScreen.route),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
