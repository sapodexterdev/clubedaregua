part of 'main.dart';

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

class _CustomerDetailsSheetState extends State<_CustomerDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;
  late bool _isActive;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone);
    _notesController = TextEditingController(text: widget.customer.notes);
    _isActive = widget.customer.isActive;
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
            _CDRToggleTile(
              value: _isActive,
              onChanged: _isSaving || !customer.canEdit
                  ? null
                  : (value) => setState(() => _isActive = value),
              title: 'Cliente ativo',
              subtitle: 'Clientes inativos ficam filtráveis.',
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
                leading: const Icon(Icons.save_outlined),
              ),
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
            isActive: _isActive,
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
