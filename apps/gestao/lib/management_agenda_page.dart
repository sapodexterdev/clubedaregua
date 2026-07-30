part of 'main.dart';

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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricsGrid(
              cards: [
                _MetricData(
                  'Agendamentos',
                  '${entries.length}',
                  Icons.calendar_today_rounded,
                ),
                _MetricData(
                  'Confirmados',
                  '$confirmedCount',
                  Icons.event_available_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ScheduleFilters(adminView: adminView),
            const SizedBox(height: 28),
            _SectionTitle(
              'Horários do dia',
              eyebrow: 'AGENDA',
              trailing: _selectedDateLabel(session.selectedScheduleDate),
            ),
            const SizedBox(height: 12),
            if (session.isScheduleLoading) ...[
              const CDRLoading.section(height: 88),
              const SizedBox(height: 12),
            ],
            if (session.scheduleError != null)
              _InlineNotice(
                icon: Icons.warning_amber_rounded,
                title: 'Não foi possível carregar a agenda',
                subtitle: session.scheduleError!,
                actionLabel: 'TENTAR NOVAMENTE',
                onAction: session.fetchScheduleEntries,
              )
            else if (entries.isEmpty)
              const _InlineNotice(
                icon: Icons.event_busy_rounded,
                title: 'Agenda vazia',
                subtitle: 'Nenhum agendamento encontrado para esta data.',
              )
            else
              for (final entry in entries)
                _AppointmentTile(
                  entry: entry,
                  showBarber: adminView,
                  onTap: () => _showScheduleDetails(context, entry),
                ),
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
      builder: (context) {
        return SafeArea(
          child: Padding(
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

class _ScheduleFilters extends StatelessWidget {
  const _ScheduleFilters({required this.adminView});

  final bool adminView;

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        final date = session.selectedScheduleDate;
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
                  decoration: const InputDecoration(
                    labelText: 'Barbeiro',
                    prefixIcon: Icon(Icons.badge_outlined),
                    filled: true,
                    fillColor: SharedAppColors.card,
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: _allBarbersDropdownValue,
                      child: Text('Todos os barbeiros'),
                    ),
                    for (final barber in _uniqueBarbers(session.teamBarbers))
                      DropdownMenuItem<String>(
                        value: barber.id,
                        child: Text(barber.name),
                      ),
                  ],
                  onChanged: (value) => session.selectScheduleBarber(
                    value == _allBarbersDropdownValue ? null : value,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: days.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final selected = DateUtils.isSameDay(day, date);
                    return ChoiceChip(
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
                      side: const BorderSide(color: SharedAppColors.stroke),
                      labelStyle: TextStyle(
                        color: selected
                            ? SharedAppColors.onGold
                            : SharedAppColors.text,
                        fontWeight: FontWeight.w800,
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
