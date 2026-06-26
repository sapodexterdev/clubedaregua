import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_colors.dart';
import 'appointment_screen.dart';

class BarberDetailsScreen extends StatelessWidget {
  const BarberDetailsScreen({super.key});

  static const route = '/barber-details';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final barber = state.selectedBarber ??
            (state.barbers.isEmpty ? null : state.barbers.last);

        if (barber == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              SizedBox(
                height: 330,
                width: double.infinity,
                child: Image.network(barber.imageUrl, fit: BoxFit.cover),
              ),
              Positioned(
                left: 22,
                right: 22,
                top: 42,
                child: Row(
                  children: [
                    _CircleButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    _CircleButton(
                      icon: Icons.more_horiz_rounded,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize: .68,
                minChildSize: .68,
                maxChildSize: .92,
                builder: (context, controller) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(34),
                      ),
                    ),
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    barber.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: Color(0xFFFFB000), size: 20),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${barber.rating} (116)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Flexible(
                                        child: Text(
                                          barber.shopName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.orange,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 58,
                              height: 58,
                              decoration: const BoxDecoration(
                                color: AppColors.background,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.red,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 54),
                        Row(
                          children: const [
                            _PillTab(label: 'Agendar', selected: true),
                            SizedBox(width: 12),
                            _PillTab(label: 'Sobre'),
                            SizedBox(width: 12),
                            _PillTab(label: 'Avaliações'),
                          ],
                        ),
                        const SizedBox(height: 34),
                        const Text(
                          'Agosto 2025',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _CalendarStrip(),
                        const SizedBox(height: 32),
                        const Text(
                          'Horários',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _TimeStrip(),
                        const SizedBox(height: 36),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.calendar_month_outlined,
                                  color: AppColors.text),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Quarta-feira, 25 de agosto',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                '11:30 - 12:30',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 74,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppointmentScreen.route,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(36),
                              ),
                            ),
                            child: const Text(
                              'Agendar agora',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.text, size: 28),
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : Colors.white,
          borderRadius: BorderRadius.circular(29),
          border: Border.all(
            color: selected ? AppColors.orange : AppColors.stroke,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CalendarStrip extends StatelessWidget {
  const _CalendarStrip();

  @override
  Widget build(BuildContext context) {
    const days = [
      ('Dom', '12'),
      ('Seg', '13'),
      ('Ter', '14'),
      ('Qua', '15'),
      ('Qui', '16'),
      ('Sex', '17'),
      ('Sáb', '18'),
    ];

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = days[index];
          final selected = day.$1 == 'Qua';
          return Container(
            width: 54,
            decoration: BoxDecoration(
              color: selected ? AppColors.orange : AppColors.background,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.$1,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    day.$2,
                    style: TextStyle(
                      color: selected ? AppColors.orange : AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TimeStrip extends StatelessWidget {
  const _TimeStrip();

  @override
  Widget build(BuildContext context) {
    const times = ['10:30', '11:30', '12:30', '01:30'];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: times.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final selected = times[index] == '11:30';
          return Container(
            width: 94,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.orange : AppColors.background,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Text(
              times[index],
              style: TextStyle(
                color: selected ? Colors.white : AppColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        },
      ),
    );
  }
}
