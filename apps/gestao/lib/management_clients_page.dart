part of 'management.dart';

class _ClientsPage extends StatelessWidget {
  const _ClientsPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        final customers = session.filteredCustomers;
        final activeCount =
            session.customers.where((customer) => customer.isActive).length;
        final recentCount =
            session.customers.where((customer) => customer.isRecent).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricsGrid(
              cards: [
                _MetricData(
                  'Clientes ativos',
                  '$activeCount',
                  Icons.people_alt_outlined,
                ),
                _MetricData(
                  'Novos em 30 dias',
                  '$recentCount',
                  Icons.person_add_alt_rounded,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle(
              'Encontre rapidamente',
              eyebrow: 'CLIENTES',
            ),
            const SizedBox(height: 12),
            _CustomerFilters(session: session),
            const SizedBox(height: 24),
            _SectionTitle(
              'Base de clientes',
              eyebrow: 'RELACIONAMENTO',
              trailing: '${customers.length} clientes',
            ),
            const SizedBox(height: 12),
            if (session.isCustomersLoading) ...[
              const CDRLoading.section(height: 88),
              const SizedBox(height: 12),
            ],
            if (session.customersError != null)
              _InlineNotice(
                icon: Icons.warning_amber_rounded,
                title: 'Não foi possível carregar os clientes',
                subtitle: session.customersError!,
                actionLabel: 'TENTAR NOVAMENTE',
                onAction: session.fetchCustomers,
              )
            else if (customers.isEmpty)
              const _InlineNotice(
                icon: Icons.people_alt_rounded,
                title: 'Nenhum cliente encontrado',
                subtitle: 'Ajuste os filtros ou aguarde novos agendamentos.',
              )
            else
              for (final customer in customers)
                _ClientTile(
                  customer: customer,
                  onTap: () => _openCustomerDetails(context, customer),
                ),
          ],
        );
      },
    );
  }

  Future<void> _openCustomerDetails(
    BuildContext context,
    ManagedCustomer customer,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: SharedAppColors.card,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ManagementSession>(),
        child: _CustomerDetailsSheet(customer: customer),
      ),
    );
  }
}

class _CustomerFilters extends StatelessWidget {
  const _CustomerFilters({required this.session});

  final ManagementSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: session.setCustomerSearchQuery,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Buscar por nome ou telefone',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChipButton(
                  label: 'Todos',
                  selected:
                      session.customerStatusFilter == CustomerStatusFilter.all,
                  onSelected: () =>
                      session.setCustomerStatusFilter(CustomerStatusFilter.all),
                ),
                _FilterChipButton(
                  label: 'Ativos',
                  selected: session.customerStatusFilter ==
                      CustomerStatusFilter.active,
                  onSelected: () => session
                      .setCustomerStatusFilter(CustomerStatusFilter.active),
                ),
                _FilterChipButton(
                  label: 'Inativos',
                  selected: session.customerStatusFilter ==
                      CustomerStatusFilter.inactive,
                  onSelected: () => session
                      .setCustomerStatusFilter(CustomerStatusFilter.inactive),
                ),
                _FilterChipButton(
                  label: 'Novos 30 dias',
                  selected: session.customerStatusFilter ==
                      CustomerStatusFilter.recent,
                  onSelected: () => session
                      .setCustomerStatusFilter(CustomerStatusFilter.recent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerDetailsSheet extends StatefulWidget {
  const _CustomerDetailsSheet({required this.customer});

  final ManagedCustomer customer;

  @override
  State<_CustomerDetailsSheet> createState() => _CustomerDetailsSheetState();
}

enum _BookingBlockScope { none, general, barber }

class _CustomerDetailsSheetState extends State<_CustomerDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;
  var _isSaving = false;
  var _isSavingBlock = false;
  late _BookingBlockScope _blockScope;
  String? _blockedBarberId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone);
    _notesController = TextEditingController(text: widget.customer.notes);
    _blockScope = widget.customer.isBlocked
        ? _BookingBlockScope.general
        : widget.customer.blockedBarberIds.isNotEmpty
            ? _BookingBlockScope.barber
            : _BookingBlockScope.none;
    _blockedBarberId = widget.customer.blockedBarberIds.isEmpty
        ? null
        : widget.customer.blockedBarberIds.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ManagementSession>();
    final customer = session.customers.firstWhere(
      (item) => item.clientId == widget.customer.clientId,
      orElse: () => widget.customer,
    );
    final appointments = session.appointmentsForCustomer(customer.clientId);
    final availableBarbers = session.teamBarbers
        .where((barber) => barber.isActive || barber.id == _blockedBarberId)
        .toList();
    String? blockedBarberName;
    for (final barber in availableBarbers) {
      if (barber.id == _blockedBarberId) {
        blockedBarberName = barber.name;
        break;
      }
    }
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom + 20;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              eyebrow: 'PERFIL DO CLIENTE',
              title: customer.name,
              onClose: _isSaving ? null : () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            Center(child: _CustomerAvatar(customer: customer, radius: 34)),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              enabled: customer.canEdit,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome do cliente.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              enabled: customer.canEdit,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            _RequestInfoRow(
              icon: Icons.mail_outline_rounded,
              label: 'E-mail',
              value: customer.email,
            ),
            _RequestInfoRow(
              icon: Icons.event_available_rounded,
              label: 'Cadastro',
              value: customer.firstSeenAt == null
                  ? '-'
                  : ManagedCustomer._formatDate(customer.firstSeenAt!),
            ),
            _RequestInfoRow(
              icon: Icons.content_cut_rounded,
              label: 'Favorito',
              value: customer.favoriteBarber,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              enabled: customer.canEdit,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Observações internas',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            if (!customer.canEdit)
              const _InlineNotice(
                icon: Icons.info_outline_rounded,
                title: 'Cliente vindo de solicitação',
                subtitle:
                    'Este cliente ainda não possui cadastro vinculado. Ele aparece pelo agendamento realizado, mas a edição fica bloqueada.',
              )
            else
              CDRButton.primary(
                label: 'SALVAR ALTERAÇÕES',
                onPressed: _isSaving ? null : () => _save(customer),
                isLoading: _isSaving,
              ),
            if (session.canManageCustomerBlocks) ...[
              const SizedBox(height: 28),
              const Divider(height: 1),
              const SizedBox(height: 20),
              const _SectionTitle(
                'Bloqueio de agendamento',
                eyebrow: 'ACESSO À AGENDA',
              ),
              const SizedBox(height: 8),
              const Text(
                'Configuração exclusiva do Dono. Agendamentos existentes não serão cancelados.',
                style: TextStyle(color: SharedAppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 14),
              _BookingBlockOption(
                title: 'Agendamento liberado',
                subtitle: 'O cliente pode escolher qualquer profissional.',
                icon: Icons.event_available_outlined,
                selected: _blockScope == _BookingBlockScope.none,
                onTap: _isSavingBlock
                    ? null
                    : () => setState(
                          () => _blockScope = _BookingBlockScope.none,
                        ),
              ),
              const SizedBox(height: 10),
              _BookingBlockOption(
                title: 'Bloquear toda a barbearia',
                subtitle: 'Impede novos agendamentos com toda a equipe.',
                icon: Icons.storefront_outlined,
                selected: _blockScope == _BookingBlockScope.general,
                onTap: _isSavingBlock
                    ? null
                    : () => setState(
                          () => _blockScope = _BookingBlockScope.general,
                        ),
              ),
              const SizedBox(height: 10),
              _BookingBlockOption(
                title: 'Bloquear um profissional',
                subtitle: 'Restringe apenas o barbeiro selecionado.',
                icon: Icons.content_cut_rounded,
                selected: _blockScope == _BookingBlockScope.barber,
                onTap: _isSavingBlock
                    ? null
                    : () => setState(() {
                          _blockScope = _BookingBlockScope.barber;
                          if (_blockedBarberId == null &&
                              availableBarbers.isNotEmpty) {
                            _blockedBarberId = availableBarbers.first.id;
                          }
                        }),
              ),
              if (_blockScope == _BookingBlockScope.barber) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: availableBarbers.any(
                    (barber) => barber.id == _blockedBarberId,
                  )
                      ? _blockedBarberId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Barbeiro bloqueado',
                    prefixIcon: Icon(Icons.content_cut_rounded),
                  ),
                  items: [
                    for (final barber in availableBarbers)
                      DropdownMenuItem(
                        value: barber.id,
                        child: Text(barber.name),
                      ),
                  ],
                  onChanged: _isSavingBlock
                      ? null
                      : (value) => setState(() => _blockedBarberId = value),
                ),
              ],
              const SizedBox(height: 14),
              _BookingBlockMessage(
                scope: _blockScope,
                barberName: blockedBarberName,
              ),
              const SizedBox(height: 14),
              CDRButton.primary(
                label: 'SALVAR CONFIGURAÇÃO',
                onPressed:
                    _isSavingBlock ? null : () => _saveBookingBlock(customer),
                isLoading: _isSavingBlock,
              ),
            ],
            const SizedBox(height: 28),
            _SectionTitle(
              'Histórico de agendamentos',
              eyebrow: 'ATENDIMENTOS',
              trailing: '${appointments.length} registros',
            ),
            const SizedBox(height: 12),
            if (appointments.isEmpty)
              const _InlineNotice(
                icon: Icons.event_busy_rounded,
                title: 'Sem histórico',
                subtitle: 'Nenhum atendimento registrado para este cliente.',
              )
            else
              for (final appointment in appointments)
                _CustomerAppointmentTile(appointment: appointment),
          ],
        ),
      ),
    );
  }

  Future<void> _save(ManagedCustomer customer) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await context.read<ManagementSession>().updateCustomer(
            customer,
            name: _nameController.text,
            phone: _phoneController.text,
            notes: _notesController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente salvo com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveBookingBlock(ManagedCustomer customer) async {
    if (_blockScope == _BookingBlockScope.barber && _blockedBarberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o barbeiro do bloqueio.')),
      );
      return;
    }

    setState(() => _isSavingBlock = true);
    try {
      await context.read<ManagementSession>().setCustomerBookingBlock(
            customer,
            blocked: _blockScope != _BookingBlockScope.none,
            barberId: _blockScope == _BookingBlockScope.barber
                ? _blockedBarberId
                : null,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (_blockScope) {
            _BookingBlockScope.none =>
              'Tudo certo! O cliente pode voltar a agendar normalmente.',
            _BookingBlockScope.general =>
              'Configuração salva. Novos agendamentos foram bloqueados para toda a barbearia.',
            _BookingBlockScope.barber =>
              'Configuração salva. O bloqueio vale somente para o profissional escolhido.',
          }),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSavingBlock = false);
    }
  }
}

class _BookingBlockOption extends StatelessWidget {
  const _BookingBlockOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected
            ? SharedAppColors.orange.withOpacity(.08)
            : SharedAppColors.elevated.withOpacity(.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? SharedAppColors.orange : SharedAppColors.stroke,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected
                        ? SharedAppColors.orange.withOpacity(.16)
                        : SharedAppColors.card,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: selected
                        ? SharedAppColors.orange
                        : SharedAppColors.muted,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: selected
                                  ? SharedAppColors.text
                                  : SharedAppColors.muted,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: SharedAppColors.muted,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        selected ? SharedAppColors.orange : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? SharedAppColors.orange
                          : SharedAppColors.stroke,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: SharedAppColors.onGold,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingBlockMessage extends StatelessWidget {
  const _BookingBlockMessage({
    required this.scope,
    required this.barberName,
  });

  final _BookingBlockScope scope;
  final String? barberName;

  @override
  Widget build(BuildContext context) {
    final (icon, title, message) = switch (scope) {
      _BookingBlockScope.none => (
          Icons.check_circle_outline_rounded,
          'Agendamento liberado',
          'Ao salvar, o cliente poderá agendar normalmente com toda a equipe.',
        ),
      _BookingBlockScope.general => (
          Icons.info_outline_rounded,
          'Bloqueio geral',
          'Ao salvar, o cliente não poderá criar novos agendamentos nesta barbearia.',
        ),
      _BookingBlockScope.barber => (
          Icons.info_outline_rounded,
          'Bloqueio específico',
          barberName == null
              ? 'Escolha o profissional para aplicar este bloqueio.'
              : 'Ao salvar, o cliente continuará agendando com a equipe, exceto com $barberName.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SharedAppColors.orange.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SharedAppColors.orange.withOpacity(.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SharedAppColors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: SharedAppColors.orange,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SharedAppColors.text,
                        height: 1.4,
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

class _CustomerAppointmentTile extends StatelessWidget {
  const _CustomerAppointmentTile({required this.appointment});

  final CustomerAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = appointment.status.toLowerCase();
    final statusColor = normalizedStatus.contains('conclu')
        ? CDRColorTokens.success
        : normalizedStatus.contains('cancel')
            ? CDRColorTokens.error
            : SharedAppColors.orange;
    return _SurfaceTile(
      leading: const _IconBadge(Icons.event_available_rounded),
      title: appointment.service,
      subtitle: '${appointment.barber} - ${appointment.dateLabel}',
      trailing: _AvailabilityStatus(
        label: appointment.status.toUpperCase(),
        color: statusColor,
      ),
    );
  }
}
