import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';

import '../../models/barber.dart';
import '../../models/service_item.dart';
import '../../providers/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/service_card.dart';
import 'appointment_screen.dart';

class BarberDetailsScreen extends StatelessWidget {
  const BarberDetailsScreen({super.key});

  static const route = '/barber-details';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final shop = state.selectedBarbershop;
        if (shop == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              leadingWidth: 68,
              leading: const Padding(
                padding: EdgeInsets.only(left: 16),
                child: CDRBackButton(),
              ),
            ),
            body: const _MissingSelection(
              message: 'Escolha uma barbearia para consultar os horários.',
            ),
          );
        }

        final services = state.servicesForSelectedBarber;
        final canContinue = state.selectedService != null &&
            state.selectedBarber != null &&
            state.selectedTime.isNotEmpty &&
            !state.isLoadingAvailability;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.text,
            elevation: 0,
            leadingWidth: 68,
            leading: const Padding(
              padding: EdgeInsets.only(left: 16),
              child: CDRBackButton(),
            ),
            title: Text(
              'Escolha seu horário',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          bottomNavigationBar: _ContinueBar(
            enabled: canContinue,
            onPressed: () => Navigator.pushNamed(
              context,
              AppointmentScreen.route,
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: CDRSizeTokens.contentMaxWidth,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                children: [
              _ShopContext(
                name: shop.identity.name,
                location: shop.identity.locationLabel,
              ),
              const SizedBox(height: 28),
              _StepHeader(
                number: 1,
                title: 'Escolha o serviço',
                caption: state.selectedService == null
                    ? 'Selecione uma opção para continuar'
                    : _serviceCaption(state.selectedService!),
              ),
              const SizedBox(height: 12),
              if (services.isEmpty)
                const _EmptyBlock('Nenhum serviço disponível para a equipe.')
              else
                ...services.map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ServiceCard(
                      service: service,
                      isSelected: state.selectedService?.id == service.id,
                      onTap: () => state.selectService(service),
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              _StepHeader(
                number: 2,
                title: 'Escolha o profissional',
                caption: state.selectedBarber?.name ??
                    'Selecione quem fará o atendimento',
              ),
              const SizedBox(height: 12),
              if (shop.barbers.isEmpty)
                const _EmptyBlock('Nenhum profissional disponível.')
              else
                _BarberStrip(
                  barbers: shop.barbers,
                  selected: state.selectedBarber,
                  onSelected: state.selectBarber,
                ),
              const SizedBox(height: 28),
              _StepHeader(
                number: 3,
                title: 'Escolha a data',
                caption: _longDate(state.selectedDate),
              ),
              const SizedBox(height: 12),
              _DateStrip(
                selectedDate: state.selectedDate,
                daysAhead: shop.identity.bookingDaysAhead,
                onSelected: state.selectDate,
              ),
              const SizedBox(height: 28),
              _StepHeader(
                number: 4,
                title: 'Escolha o horário',
                caption: state.selectedTime.isEmpty
                    ? 'Horários livres para a data selecionada'
                    : 'Selecionado às ${state.selectedTime}',
              ),
              const SizedBox(height: 14),
              _Availability(
                loading: state.isLoadingAvailability,
                error: state.availabilityError,
                times: state.availableTimes,
                selectedTime: state.selectedTime,
                onSelected: state.selectTime,
                onRetry: state.refreshAvailableTimes,
              ),
              if (canContinue) ...[
                const SizedBox(height: 26),
                _BookingSummary(
                  service: state.selectedService!,
                  barber: state.selectedBarber!,
                  date: state.selectedDate,
                  time: state.selectedTime,
                ),
              ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _serviceCaption(ServiceItem service) {
    return '${service.durationMinutes} min · R\$ ${service.price.toStringAsFixed(0)}';
  }
}

class _ShopContext extends StatelessWidget {
  const _ShopContext({required this.name, required this.location});

  final String name;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.number,
    required this.title,
    required this.caption,
  });

  final int number;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.orange,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: AppColors.onGold,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                caption,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarberStrip extends StatelessWidget {
  const _BarberStrip({
    required this.barbers,
    required this.selected,
    required this.onSelected,
  });

  final List<Barber> barbers;
  final Barber? selected;
  final ValueChanged<Barber> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: barbers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final barber = barbers[index];
          final isSelected = selected?.id == barber.id;
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onSelected(barber),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 112,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.orange.withOpacity(.1)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.orange : AppColors.stroke,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: AppColors.elevated,
                    backgroundImage: barber.imageUrl.isEmpty
                        ? null
                        : NetworkImage(barber.imageUrl),
                    child: barber.imageUrl.isEmpty
                        ? const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.orange,
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    barber.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.selectedDate,
    required this.daysAhead,
    required this.onSelected,
  });

  final DateTime selectedDate;
  final int daysAhead;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final count = (daysAhead.clamp(0, 60) + 1).toInt();
    final days = List.generate(
      count,
      (index) => today.add(Duration(days: index)),
    );

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = days[index];
          final selected = DateUtils.isSameDay(date, selectedDate);
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSelected(date),
            child: Container(
              width: 58,
              decoration: BoxDecoration(
                color: selected ? AppColors.orange : AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.orange : AppColors.stroke,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekday(date.weekday),
                    style: TextStyle(
                      color: selected ? AppColors.onGold : AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${date.day}'.padLeft(2, '0'),
                    style: TextStyle(
                      color: selected ? AppColors.onGold : AppColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
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
}

class _Availability extends StatelessWidget {
  const _Availability({
    required this.loading,
    required this.error,
    required this.times,
    required this.selectedTime,
    required this.onSelected,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final List<String> times;
  final String selectedTime;
  final ValueChanged<String> onSelected;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const CDRLoading.section(
        height: 90,
      );
    }
    if (error != null) {
      return _StateBlock(
        icon: Icons.cloud_off_outlined,
        message: error!,
        actionLabel: 'Tentar novamente',
        onAction: onRetry,
      );
    }
    if (times.isEmpty) {
      return const _StateBlock(
        icon: Icons.event_busy_outlined,
        message: 'Nenhum horário disponível para esta data.',
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final time in times)
          ChoiceChip(
            label: Text(time),
            selected: time == selectedTime,
            onSelected: (_) => onSelected(time),
            selectedColor: AppColors.orange,
            backgroundColor: AppColors.card,
            side: BorderSide(
              color: time == selectedTime
                  ? AppColors.orange
                  : AppColors.stroke,
            ),
            labelStyle: TextStyle(
              color: time == selectedTime ? AppColors.onGold : AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({
    required this.service,
    required this.barber,
    required this.date,
    required this.time,
  });

  final ServiceItem service;
  final Barber barber;
  final DateTime date;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seu horário',
            style: TextStyle(
              color: AppColors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${service.name} com ${barber.name}',
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${_longDate(date)} às $time · R\$ ${service.price.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueBar extends StatelessWidget {
  const _ContinueBar({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.stroke)),
        ),
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: AppColors.orange,
            foregroundColor: AppColors.onGold,
          ),
          child: const Text('CONTINUAR'),
        ),
      ),
    );
  }
}

class _StateBlock extends StatelessWidget {
  const _StateBlock({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.muted, size: 28),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 10),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return _StateBlock(icon: Icons.info_outline_rounded, message: message);
  }
}

class _MissingSelection extends StatelessWidget {
  const _MissingSelection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: _StateBlock(
          icon: Icons.calendar_month_outlined,
          message: message,
        ),
      ),
    );
  }
}

String _weekday(int weekday) {
  const labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  return labels[weekday - 1];
}

String _longDate(DateTime date) {
  const months = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
  return '${_weekday(date.weekday)}, ${date.day} de ${months[date.month - 1]}';
}
