import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_colors.dart';
import 'appointment_screen.dart';

class BarberDetailsScreen extends StatefulWidget {
  const BarberDetailsScreen({super.key});

  static const route = '/barber-details';

  @override
  State<BarberDetailsScreen> createState() => _BarberDetailsScreenState();
}

class _BarberDetailsScreenState extends State<BarberDetailsScreen> {
  int selectedTab = 0;

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
                          children: [
                            _PillTab(
                              label: 'Agendar',
                              selected: selectedTab == 0,
                              onTap: () => setState(() => selectedTab = 0),
                            ),
                            const SizedBox(width: 12),
                            _PillTab(
                              label: 'Sobre',
                              selected: selectedTab == 1,
                              onTap: () => setState(() => selectedTab = 1),
                            ),
                            const SizedBox(width: 12),
                            _PillTab(
                              label: 'Avaliações',
                              selected: selectedTab == 2,
                              onTap: () => setState(() => selectedTab = 2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 34),
                        if (selectedTab == 0)
                          _BookingTab(state: state)
                        else if (selectedTab == 1)
                          _AboutTab(
                            bio: barber.bio,
                            shopName: barber.shopName,
                          )
                        else
                          _ReviewsTab(rating: barber.rating),
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
  const _PillTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(29),
        onTap: onTap,
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
      ),
    );
  }
}

class _BookingTab extends StatelessWidget {
  const _BookingTab({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _monthLabel(state.selectedDate),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        _CalendarStrip(
          selectedDate: state.selectedDate,
          onSelected: state.selectDate,
        ),
        const SizedBox(height: 32),
        const Text(
          'Horários',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        _TimeStrip(
          selectedTime: state.selectedTime,
          onSelected: state.selectTime,
        ),
        const SizedBox(height: 36),
        _BookingSummary(
          date: state.selectedDate,
          time: state.selectedTime,
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
    );
  }

  String _monthLabel(DateTime date) {
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];

    final month = months[date.month - 1];
    return '${month[0].toUpperCase()}${month.substring(1)} ${date.year}';
  }
}

class _CalendarStrip extends StatelessWidget {
  const _CalendarStrip({
    required this.selectedDate,
    required this.onSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(
      10,
      (index) => DateTime(today.year, today.month, today.day + index),
    );

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = days[index];
          final selected = DateUtils.isSameDay(day, selectedDate);

          return InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => onSelected(day),
            child: Container(
              width: 54,
              decoration: BoxDecoration(
                color: selected ? AppColors.orange : AppColors.background,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdayLabel(day.weekday),
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
                      day.day.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: selected ? AppColors.orange : AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = {
      DateTime.monday: 'Seg',
      DateTime.tuesday: 'Ter',
      DateTime.wednesday: 'Qua',
      DateTime.thursday: 'Qui',
      DateTime.friday: 'Sex',
      DateTime.saturday: 'Sáb',
      DateTime.sunday: 'Dom',
    };

    return labels[weekday] ?? '';
  }
}

class _TimeStrip extends StatelessWidget {
  const _TimeStrip({
    required this.selectedTime,
    required this.onSelected,
  });

  final String selectedTime;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const times = ['09:00', '10:30', '11:30', '12:30', '14:30', '16:00'];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: times.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final time = times[index];
          final selected = time == selectedTime;

          return InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () => onSelected(time),
            child: Container(
              width: 94,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.orange : AppColors.background,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Text(
                time,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({
    required this.date,
    required this.time,
  });

  final DateTime date;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined, color: AppColors.text),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _dateLabel(date),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            '$time - ${_endTime(time)}',
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime date) {
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];

    const weekdays = {
      DateTime.monday: 'Segunda-feira',
      DateTime.tuesday: 'Terça-feira',
      DateTime.wednesday: 'Quarta-feira',
      DateTime.thursday: 'Quinta-feira',
      DateTime.friday: 'Sexta-feira',
      DateTime.saturday: 'Sábado',
      DateTime.sunday: 'Domingo',
    };

    return '${weekdays[date.weekday]}, ${date.day} de ${months[date.month - 1]}';
  }

  String _endTime(String value) {
    final parts = value.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final start = DateTime(2025, 1, 1, hour, minute);
    final end = start.add(const Duration(hours: 1));
    final endHour = end.hour.toString().padLeft(2, '0');
    final endMinute = end.minute.toString().padLeft(2, '0');
    return '$endHour:$endMinute';
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({
    required this.bio,
    required this.shopName,
  });

  final String bio;
  final String shopName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sobre o profissional',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        Text(
          bio,
          style: const TextStyle(
            color: AppColors.muted,
            height: 1.55,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        _InfoTile(
          icon: Icons.storefront_rounded,
          title: shopName,
          subtitle: 'Atendimento com horário marcado e experiência premium.',
        ),
        const SizedBox(height: 12),
        const _InfoTile(
          icon: Icons.verified_rounded,
          title: 'Especialista verificado',
          subtitle: 'Profissional ativo na plataforma Clube da Régua.',
        ),
      ],
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$rating de 5,0',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Baseado em 116 avaliações',
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        const _ReviewTile(
          name: 'Lucas Almeida',
          comment: 'Corte muito bem feito, atendimento rápido e pontual.',
        ),
        const SizedBox(height: 12),
        const _ReviewTile(
          name: 'Pedro Henrique',
          comment: 'Ambiente limpo, profissional cuidadoso e acabamento ótimo.',
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.name,
    required this.comment,
  });

  final String name;
  final String comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
              const Spacer(),
              const Icon(Icons.star_rounded, color: Color(0xFFFFB000), size: 18),
              const SizedBox(width: 4),
              const Text('5,0', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}
