part of 'management.dart';

class _ServicesPage extends StatelessWidget {
  const _ServicesPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        final services = session.filteredServices;
        final activeCount =
            session.services.where((service) => service.isActive).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActionPanel(
              title: 'Catálogo de serviços',
              subtitle: activeCount == 1
                  ? '1 serviço ativo. Gerencie preço, duração e disponibilidade.'
                  : '$activeCount serviços ativos. Gerencie preços, durações e disponibilidade.',
              buttonLabel: 'Novo serviço',
              icon: Icons.add_circle_rounded,
              onPressed: () => _openServiceForm(context),
            ),
            const SizedBox(height: 22),
            const _SectionTitle(
              'Encontre e organize',
              eyebrow: 'SERVIÇOS',
            ),
            const SizedBox(height: 12),
            _ServiceFilters(session: session),
            const SizedBox(height: 24),
            _SectionTitle(
              'Serviços cadastrados',
              eyebrow: 'CATÁLOGO',
              trailing: services.length == 1
                  ? '1 serviço'
                  : '${services.length} serviços',
            ),
            const SizedBox(height: 12),
            if (session.isServicesLoading) ...[
              const CDRLoading.section(height: 88),
              const SizedBox(height: 12),
            ],
            if (session.servicesError != null)
              _InlineNotice(
                icon: Icons.warning_amber_rounded,
                title: 'Não foi possível carregar os serviços',
                subtitle: session.servicesError!,
                actionLabel: 'TENTAR NOVAMENTE',
                onAction: session.fetchServiceCatalog,
              )
            else if (services.isEmpty)
              const _InlineNotice(
                icon: Icons.content_cut_rounded,
                title: 'Nenhum serviço encontrado',
                subtitle: 'Ajuste os filtros ou cadastre um novo serviço.',
              )
            else
              for (final service in services)
                _ServiceTile(
                  service: service,
                  onTap: () => _openServiceForm(context, service: service),
                ),
          ],
        );
      },
    );
  }

  Future<void> _openServiceForm(
    BuildContext context, {
    ManagedService? service,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: SharedAppColors.card,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ManagementSession>(),
        child: _ServiceForm(service: service),
      ),
    );
  }
}

class _ServiceFilters extends StatelessWidget {
  const _ServiceFilters({required this.session});

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
            onChanged: session.setServiceSearchQuery,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Buscar serviço por nome',
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
                      session.serviceStatusFilter == ServiceStatusFilter.all,
                  onSelected: () =>
                      session.setServiceStatusFilter(ServiceStatusFilter.all),
                ),
                _FilterChipButton(
                  label: 'Ativos',
                  selected:
                      session.serviceStatusFilter == ServiceStatusFilter.active,
                  onSelected: () => session
                      .setServiceStatusFilter(ServiceStatusFilter.active),
                ),
                _FilterChipButton(
                  label: 'Inativos',
                  selected: session.serviceStatusFilter ==
                      ServiceStatusFilter.inactive,
                  onSelected: () => session
                      .setServiceStatusFilter(ServiceStatusFilter.inactive),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _validCategoryFilterValue(session),
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Categoria',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: _allCategoriesDropdownValue,
                child: Text('Todas as categorias'),
              ),
              for (final category
                  in _uniqueCategories(session.serviceCategories))
                DropdownMenuItem<String>(
                  value: category.id,
                  child: Text(category.name),
                ),
            ],
            onChanged: (value) => session.setServiceCategoryFilter(
              value == _allCategoriesDropdownValue ? null : value,
            ),
          ),
        ],
      ),
    );
  }

  String _validCategoryFilterValue(ManagementSession session) {
    final selected = session.selectedServiceCategoryId;
    if (selected == null || selected.isEmpty) {
      return _allCategoriesDropdownValue;
    }
    final exists =
        session.serviceCategories.any((category) => category.id == selected);
    return exists ? selected : _allCategoriesDropdownValue;
  }

  List<ServiceCategory> _uniqueCategories(List<ServiceCategory> categories) {
    final seen = <String>{};
    return [
      for (final category in categories)
        if (category.id.isNotEmpty && seen.add(category.id)) category,
    ];
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: SharedAppColors.orange,
        backgroundColor: SharedAppColors.elevated,
        side: const BorderSide(color: SharedAppColors.stroke),
        labelStyle: TextStyle(
          color: selected ? SharedAppColors.onGold : SharedAppColors.text,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ServiceForm extends StatefulWidget {
  const _ServiceForm({this.service});

  final ManagedService? service;

  @override
  State<_ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<_ServiceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _colorController;
  late bool _isActive;
  String? _categoryId;
  var _isSaving = false;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _nameController = TextEditingController(text: service?.name ?? '');
    _descriptionController =
        TextEditingController(text: service?.description ?? '');
    _priceController = TextEditingController(
      text: service == null ? '' : service.price.toStringAsFixed(2),
    );
    _durationController = TextEditingController(
      text: service == null ? '' : service.durationMinutes.toString(),
    );
    _imageUrlController = TextEditingController(text: service?.imageUrl ?? '');
    _colorController = TextEditingController();
    _isActive = service?.isActive ?? true;
    _categoryId = service?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _imageUrlController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom + 20;
    final categories = context.watch<ManagementSession>().serviceCategories;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              eyebrow: _isEditing ? 'EDITAR SERVIÇO' : 'NOVO SERVIÇO',
              title: _isEditing ? 'Atualize o serviço' : 'Cadastre um serviço',
              onClose: _isSaving ? null : () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
            const Divider(color: SharedAppColors.stroke),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.content_cut_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome do serviço.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _validFormCategoryValue(categories),
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: _noCategoryDropdownValue,
                  child: Text('Sem categoria'),
                ),
                for (final category in _uniqueFormCategories(categories))
                  DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  ),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() {
                        _categoryId =
                            value == _noCategoryDropdownValue ? null : value;
                      }),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            _ResponsiveFieldRow(
              children: [
                TextFormField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Preço',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: _validatePrice,
                ),
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duração (min)',
                    prefixIcon: Icon(Icons.schedule_rounded),
                  ),
                  validator: _validateDuration,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageUrlController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'URL da imagem',
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _colorController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Cor de identificação',
                helperText:
                    'Preparado para integrar quando houver coluna no banco.',
                prefixIcon: Icon(Icons.palette_outlined),
              ),
            ),
            const SizedBox(height: 12),
            _CDRToggleTile(
              value: _isActive,
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _isActive = value),
              title: 'Serviço ativo',
              subtitle: 'Serviços inativos deixam de aparecer.',
            ),
            const SizedBox(height: 12),
            CDRButton.primary(
              label: _isEditing ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR SERVIÇO',
              onPressed: _isSaving ? null : _save,
              isLoading: _isSaving,
              leading: const Icon(Icons.save_outlined),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSaving ? null : _confirmDeleteOrDeactivate,
                child: const Text('Excluir serviço'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _validatePrice(String? value) {
    final parsed = _parseMoney(value);
    if (parsed == null || parsed <= 0) {
      return 'Informe um preço maior que zero.';
    }
    return null;
  }

  String? _validateDuration(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return 'Informe a duração.';
    return null;
  }

  double? _parseMoney(String? value) {
    if (value == null) return null;
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  String _validFormCategoryValue(List<ServiceCategory> categories) {
    final selected = _categoryId;
    if (selected == null || selected.isEmpty) return _noCategoryDropdownValue;
    final exists = categories.any((category) => category.id == selected);
    return exists ? selected : _noCategoryDropdownValue;
  }

  List<ServiceCategory> _uniqueFormCategories(
      List<ServiceCategory> categories) {
    final seen = <String>{};
    return [
      for (final category in categories)
        if (category.id.isNotEmpty && seen.add(category.id)) category,
    ];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final session = context.read<ManagementSession>();
      final service = widget.service;
      if (service == null) {
        await session.createService(
          name: _nameController.text,
          description: _descriptionController.text,
          categoryId: _categoryId,
          price: _parseMoney(_priceController.text)!,
          durationMinutes: int.parse(_durationController.text.trim()),
          imageUrl: _imageUrlController.text,
          isActive: _isActive,
        );
      } else {
        await session.updateService(
          service,
          name: _nameController.text,
          description: _descriptionController.text,
          categoryId: _categoryId,
          price: _parseMoney(_priceController.text)!,
          durationMinutes: int.parse(_durationController.text.trim()),
          imageUrl: _imageUrlController.text,
          isActive: _isActive,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Serviço salvo com sucesso.')),
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

  Future<void> _confirmDeleteOrDeactivate() async {
    final service = widget.service;
    if (service == null) return;
    final session = context.read<ManagementSession>();
    final canDelete = service.appointmentCount == 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          canDelete ? Icons.delete_outline_rounded : Icons.block_outlined,
          color: CDRColorTokens.error,
        ),
        title: Text(canDelete ? 'Excluir serviço?' : 'Inativar serviço?'),
        content: Text(
          canDelete
              ? 'Este serviço não possui agendamentos e será removido do banco.'
              : 'Não é possível excluir este serviço porque existem agendamentos feitos nele. Para preservar o histórico, ele será apenas inativado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: CDRColorTokens.error,
              foregroundColor: Colors.white,
            ),
            child: Text(canDelete ? 'EXCLUIR' : 'INATIVAR'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await session.deleteOrDeactivateService(service);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(canDelete ? 'Serviço excluído.' : 'Serviço inativado.'),
        ),
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
