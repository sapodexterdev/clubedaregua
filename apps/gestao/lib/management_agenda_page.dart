part of 'management.dart';

class _BarberAgendaPage extends StatelessWidget {
  const _BarberAgendaPage({this.adminView = false});

  final bool adminView;

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        if (session.scheduleAdminView != adminView) {
          Future.microtask(() => session.setScheduleAdminView(adminView));
        }
        final entries = session.scheduleEntries;
        final confirmedCount = entries
            .where((entry) =>
                entry.status == 'Aceito' || entry.status == 'Confirmado')
            .length;
        final isInitialLoading = session.isScheduleLoading && entries.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isInitialLoading) ...[
              _AgendaMetricsGrid(
                appointments: entries.length,
                confirmed: confirmedCount,
              ),
              const SizedBox(height: 18),
            ],
            _ScheduleFilters(adminView: adminView),
            const SizedBox(height: 28),
            _AgendaDayHeader(
              dateLabel: _selectedDateLabel(session.selectedScheduleDate),
            ),
            const SizedBox(height: 12),
            if (isInitialLoading)
              const CDRLoading.section(
                key: ValueKey('agenda-initial-loading'),
                height: 88,
              )
            else if (session.scheduleError != null)
              _InlineNotice(
                icon: Icons.warning_amber_rounded,
                title: 'Não foi possível carregar a agenda',
                subtitle: 'Tente novamente em instantes.',
                actionLabel: 'TENTAR NOVAMENTE',
                onAction: session.fetchScheduleEntries,
              )
            else if (entries.isEmpty)
              const _InlineNotice(
                icon: Icons.event_busy_rounded,
                title: 'Agenda vazia',
                subtitle: 'Nenhum agendamento encontrado para esta data.',
              )
            else ...[
              if (session.isScheduleLoading) ...[
                const CDRLoading.section(
                  key: ValueKey('agenda-refresh-loading'),
                  height: 88,
                ),
                const SizedBox(height: 12),
              ],
              for (final entry in entries)
                _AppointmentTile(
                  entry: entry,
                  showBarber: adminView,
                  onTap: () => _showScheduleDetails(context, entry),
                ),
            ],
          ],
        );
      },
    );
  }

  String _selectedDateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  void _showScheduleDetails(BuildContext context, ScheduleEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .9,
          ),
          child: SingleChildScrollView(
            key: const ValueKey('agenda-details-scroll'),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DETALHES DO ATENDIMENTO',
                  style: TextStyle(
                    color: SharedAppColors.orange,
                    fontSize: 10,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.client,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 6),
                _RequestInfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Horário',
                  value: entry.time,
                ),
                _RequestInfoRow(
                  icon: Icons.content_cut_rounded,
                  label: 'Serviço',
                  value: entry.service,
                ),
                _RequestInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Barbeiro',
                  value: entry.barber,
                ),
                _RequestInfoRow(
                  icon: Icons.info_outline_rounded,
                  label: 'Status',
                  value: entry.status,
                ),
                _RequestInfoRow(
                  icon: Icons.notes_rounded,
                  label: 'Obs.',
                  value: entry.notes,
                ),
                if (entry.canComplete) ...[
                  const SizedBox(height: 18),
                  CDRButton.primary(
                    label: 'CONCLUIR ATENDIMENTO',
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await context
                            .read<ManagementSession>()
                            .completeAppointment(entry.appointmentId!);
                        if (!context.mounted) return;
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Atendimento concluído.'),
                          ),
                        );
                      } catch (_) {
                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Não foi possível concluir o atendimento.',
                            ),
                          ),
                        );
                      }
                    },
                    leading: const Icon(Icons.task_alt_rounded),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AgendaMetricsGrid extends StatelessWidget {
  const _AgendaMetricsGrid({
    required this.appointments,
    required this.confirmed,
  });

  final int appointments;
  final int confirmed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 2 : 1;
        final width =
            (constraints.maxWidth - ((columns - 1) * CDRSpacingTokens.md)) /
                columns;
        return Wrap(
          key: const ValueKey('agenda-metrics'),
          spacing: CDRSpacingTokens.md,
          runSpacing: CDRSpacingTokens.md,
          children: [
            SizedBox(
              width: width,
              child: _AgendaMetricCard(
                key: const ValueKey('agenda-metric-appointments'),
                icon: Icons.calendar_today_rounded,
                value: '$appointments',
                label: 'Agendamentos no dia',
              ),
            ),
            SizedBox(
              width: width,
              child: _AgendaMetricCard(
                key: const ValueKey('agenda-metric-confirmed'),
                icon: Icons.event_available_rounded,
                value: '$confirmed',
                label: 'Confirmados no dia',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AgendaMetricCard extends StatelessWidget {
  const _AgendaMetricCard({
    required this.icon,
    required this.value,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return CDRCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ExcludeSemantics(child: _IconBadge(icon)),
          const SizedBox(width: CDRSpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: CDRSpacingTokens.xs),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaDayHeader extends StatelessWidget {
  const _AgendaDayHeader({required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520 || textScale > 1.5;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AGENDA',
              style: CDRTypographyTokens.overline,
            ),
            const SizedBox(height: CDRSpacingTokens.xs),
            Text(
              'Horários do dia',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        );
        final date = Semantics(
          label: 'Data selecionada: $dateLabel',
          child: ExcludeSemantics(
            child: Container(
              key: const ValueKey('agenda-selected-date'),
              padding: const EdgeInsets.symmetric(
                horizontal: CDRSpacingTokens.md,
                vertical: CDRSpacingTokens.sm,
              ),
              decoration: BoxDecoration(
                color: CDRColorTokens.graphite,
                borderRadius: BorderRadius.circular(CDRRadiusTokens.pill),
                border: Border.all(color: CDRColorTokens.border),
              ),
              child: Text(dateLabel, style: CDRTypographyTokens.label),
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: CDRSpacingTokens.md),
              date,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: title),
            const SizedBox(width: CDRSpacingTokens.md),
            date,
          ],
        );
      },
    );
  }
}

class _ScheduleFilters extends StatelessWidget {
  const _ScheduleFilters({required this.adminView});

  final bool adminView;

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        final date = session.selectedScheduleDate;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final selectorHeight =
            58.0 + (28.0 * (textScale - 1).clamp(0.0, 2.0)).toDouble();
        final days = List.generate(7, (index) {
          final now = DateTime.now();
          return DateTime(now.year, now.month, now.day + index);
        });

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SharedAppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SharedAppColors.stroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (adminView) ...[
                DropdownButtonFormField<String>(
                  value: _validBarberDropdownValue(session),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Barbeiro',
                    prefixIcon: Icon(Icons.badge_outlined),
                    filled: true,
                    fillColor: SharedAppColors.card,
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: _allBarbersDropdownValue,
                      child: Text(
                        'Todos os barbeiros',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    for (final barber in _uniqueBarbers(session.teamBarbers))
                      DropdownMenuItem<String>(
                        value: barber.id,
                        child: Text(
                          barber.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => session.selectScheduleBarber(
                    value == _allBarbersDropdownValue ? null : value,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                height: selectorHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: days.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final selected = DateUtils.isSameDay(day, date);
                    final semanticLabel = '${_fullWeekdayLabel(day)}, '
                        '${_fullDateLabel(day)}';
                    return Semantics(
                      key: ValueKey('schedule-day-${_dateKey(day)}'),
                      label: semanticLabel,
                      button: true,
                      selected: selected,
                      onTap: () => session.selectScheduleDate(day),
                      child: ExcludeSemantics(
                        child: ChoiceChip(
                          label: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _weekdayLabel(day),
                                style: const TextStyle(fontSize: 10),
                              ),
                              const SizedBox(height: 2),
                              Text(_dayLabel(day)),
                            ],
                          ),
                          selected: selected,
                          onSelected: (_) => session.selectScheduleDate(day),
                          selectedColor: SharedAppColors.orange,
                          backgroundColor: SharedAppColors.elevated,
                          side: const BorderSide(
                            color: SharedAppColors.stroke,
                          ),
                          labelStyle: TextStyle(
                            color: selected
                                ? SharedAppColors.onGold
                                : SharedAppColors.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _dayLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String _weekdayLabel(DateTime date) {
    const labels = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
    return labels[date.weekday - 1];
  }

  String _fullWeekdayLabel(DateTime date) {
    const labels = [
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo',
    ];
    return labels[date.weekday - 1];
  }

  String _fullDateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _validBarberDropdownValue(ManagementSession session) {
    final selected = session.selectedScheduleBarberId;
    if (selected == null || selected.isEmpty) return _allBarbersDropdownValue;
    final exists = session.teamBarbers.any((barber) => barber.id == selected);
    return exists ? selected : _allBarbersDropdownValue;
  }

  List<TeamBarber> _uniqueBarbers(List<TeamBarber> barbers) {
    final seen = <String>{};
    return [
      for (final barber in barbers)
        if (barber.id.isNotEmpty && seen.add(barber.id)) barber,
    ];
  }
}
