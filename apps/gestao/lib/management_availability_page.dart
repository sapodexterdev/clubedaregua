part of 'main.dart';

class _AvailabilityPage extends StatelessWidget {
  const _AvailabilityPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        final activeDays =
            session.weeklyAvailability.where((day) => day.isActive).length;
        final activeServices =
            session.services.where((service) => service.isActive).length;
        final barber = session.currentBarber;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricsGrid(
              cards: [
                _MetricData(
                  'Dias ativos',
                  '$activeDays',
                  Icons.event_available_rounded,
                ),
                _MetricData(
                  'Serviços ativos',
                  '$activeServices',
                  Icons.content_cut_rounded,
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (barber == null)
              const _InlineNotice(
                icon: Icons.person_off_outlined,
                title: 'Perfil de barbeiro não encontrado',
                subtitle:
                    'Cadastre ou vincule seu perfil profissional antes de configurar a agenda.',
              )
            else ...[
              if (activeServices == 0) ...[
                const _InlineNotice(
                  icon: Icons.info_outline_rounded,
                  title: 'Falta cadastrar um serviço',
                  subtitle:
                      'A agenda só aparece para o cliente quando existe ao menos um serviço ativo. Acesse o modo Dono e abra Serviços.',
                ),
                const SizedBox(height: 18),
              ],
              _SectionTitle(
                'Jornada de ${barber.name}',
                eyebrow: 'DISPONIBILIDADE SEMANAL',
                trailing: '$activeDays dias ativos',
              ),
              const SizedBox(height: 12),
              if (session.isAvailabilityLoading)
                const CDRLoading.section(height: 116)
              else if (session.availabilityError != null)
                _InlineNotice(
                  icon: Icons.warning_amber_rounded,
                  title: 'Não foi possível carregar os horários',
                  subtitle: session.availabilityError!,
                  actionLabel: 'TENTAR NOVAMENTE',
                  onAction: session.fetchWeeklyAvailability,
                )
              else
                for (final day in session.weeklyAvailability)
                  _AvailabilityDayTile(
                    day: day,
                    enabled: !session.isAvailabilitySaving,
                    onChanged: session.updateAvailabilityDay,
                    onPickTime: (isStart) =>
                        _pickTime(context, session, day, isStart),
                  ),
              const SizedBox(height: 12),
              CDRButton.primary(
                label: 'SALVAR HORÁRIOS',
                leading: const Icon(Icons.save_outlined),
                isLoading: session.isAvailabilitySaving,
                onPressed: session.isAvailabilityLoading ||
                        session.isAvailabilitySaving
                    ? null
                    : () => _save(context, session),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 17,
                    color: SharedAppColors.muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Os horários disponíveis consideram a duração do serviço, bloqueios e agendamentos confirmados.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    ManagementSession session,
    BarberAvailabilityDay day,
    bool isStart,
  ) async {
    final current = isStart ? day.startTime : day.endTime;
    final parts = current.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 9,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      ),
      helpText: isStart ? 'HORÁRIO DE INÍCIO' : 'HORÁRIO DE TÉRMINO',
      cancelText: 'CANCELAR',
      confirmText: 'CONFIRMAR',
    );
    if (picked == null) return;
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    session.updateAvailabilityDay(
      isStart ? day.copyWith(startTime: value) : day.copyWith(endTime: value),
    );
  }

  Future<void> _save(
    BuildContext context,
    ManagementSession session,
  ) async {
    try {
      await session.saveWeeklyAvailability();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horários atualizados com sucesso.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(session.availabilityError ?? error.toString())),
      );
    }
  }
}

class _AvailabilityDayTile extends StatelessWidget {
  const _AvailabilityDayTile({
    required this.day,
    required this.enabled,
    required this.onChanged,
    required this.onPickTime,
  });

  final BarberAvailabilityDay day;
  final bool enabled;
  final ValueChanged<BarberAvailabilityDay> onChanged;
  final ValueChanged<bool> onPickTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: day.isActive
              ? SharedAppColors.orange.withOpacity(.32)
              : SharedAppColors.stroke,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final times = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TimeButton(
                label: day.startTime,
                enabled: enabled && day.isActive,
                onPressed: () => onPickTime(true),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child:
                    Text('até', style: TextStyle(color: SharedAppColors.muted)),
              ),
              _TimeButton(
                label: day.endTime,
                enabled: enabled && day.isActive,
                onPressed: () => onPickTime(false),
              ),
            ],
          );
          final heading = Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: day.isActive
                      ? SharedAppColors.orange.withOpacity(.12)
                      : SharedAppColors.elevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  day.isActive
                      ? Icons.event_available_outlined
                      : Icons.event_busy_outlined,
                  size: 19,
                  color: day.isActive
                      ? SharedAppColors.orange
                      : SharedAppColors.muted,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      day.isActive ? 'Atendimento ativo' : 'Dia fechado',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _CDRSwitch(
                value: day.isActive,
                semanticLabel: '${day.label}: atendimento',
                onChanged: enabled
                    ? (value) => onChanged(day.copyWith(isActive: value))
                    : null,
              ),
            ],
          );
          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [heading, const SizedBox(height: 8), times],
                )
              : Row(
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 18),
                    times,
                  ],
                );
        },
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.schedule_rounded, size: 18),
      label: Text(label),
    );
  }
}
