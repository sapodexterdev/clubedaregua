Exit code: 0
Wall time: 0.8 seconds
Output:
part of 'management.dart';

class _TeamPage extends StatelessWidget {
  const _TeamPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        final activeCount =
            session.teamBarbers.where((barber) => barber.isActive).length;
        final pendingCount =
            session.teamBarbers.where((barber) => barber.userId.isEmpty).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricsGrid(
              cards: [
                _MetricData(
                  'Profissionais ativos',
                  '$activeCount',
                  Icons.groups_2_outlined,
                ),
                _MetricData(
                  'Convites pendentes',
                  '$pendingCount',
                  Icons.mark_email_unread_outlined,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ActionPanel(
              title: 'Equipe da unidade',
              subtitle:
                  '$activeCount barbeiro(s) ativo(s). Gerencie percentuais e agenda.',
              buttonLabel: 'Novo barbeiro',
              icon: Icons.person_add_alt_1_rounded,
              onPressed: () => _openTeamBarberForm(context),
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              'Profissionais cadastrados',
              eyebrow: 'EQUIPE',
              trailing: '${session.teamBarbers.length} no total',
            ),
            const SizedBox(height: 12),
            if (session.isLoading) ...[
              const CDRLoading.section(height: 88),
              const SizedBox(height: 12),
            ],
            if (session.errorMessage != null)
              _InlineNotice(
                icon: Icons.warning_amber_rounded,
                title: 'NÃ£o foi possÃ­vel carregar a equipe',
                subtitle: session.errorMessage!,
                actionLabel: 'TENTAR NOVAMENTE',
                onAction: session.fetchTeamBarbers,
              )
            else if (session.teamBarbers.isEmpty)
              const _InlineNotice(
                icon: Icons.groups_rounded,
                title: 'Nenhum barbeiro cadastrado',
                subtitle: 'Cadastre o primeiro profissional da unidade.',
              )
            else
              for (final barber in session.teamBarbers)
                _TeamBarberTile(
                  barber: barber,
                  onTap: () => _openTeamBarberForm(context, barber: barber),
                ),
          ],
        );
      },
    );
  }

  Future<void> _openTeamBarberForm(
    BuildContext context, {
    TeamBarber? barber,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: SharedAppColors.card,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ManagementSession>(),
        child: _TeamBarberForm(barber: barber),
      ),
    );
  }
}

class _TeamBarberForm extends StatefulWidget {
  const _TeamBarberForm({this.barber});

  final TeamBarber? barber;

  @override
  State<_TeamBarberForm> createState() => _TeamBarberFormState();
}

class _TeamBarberFormState extends State<_TeamBarberForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  late final TextEditingController _photoUrlController;
  late final TextEditingController _startingPriceController;
  late final TextEditingController _commissionController;
  late bool _isActive;
  var _isSaving = false;
  var _isUploadingPhoto = false;

  bool get _isEditing => widget.barber != null;
  bool get _isBusy => _isSaving || _isUploadingPhoto;

  @override
  void initState() {
    super.initState();
    final barber = widget.barber;
    _nameController = TextEditingController(text: barber?.name ?? '');
    _emailController = TextEditingController();
    _bioController = TextEditingController(text: barber?.bio ?? '');
    _photoUrlController = TextEditingController(text: barber?.photoUrl ?? '');
    _startingPriceController = TextEditingController(
      text: barber == null ? '' : barber.startingPrice.toStringAsFixed(2),
    );
    _commissionController = TextEditingController(
      text: barber == null ? '' : barber.commissionPercent.toStringAsFixed(0),
    );
    _isActive = barber?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _photoUrlController.dispose();
    _startingPriceController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              eyebrow: _isEditing ? 'EDITAR PROFISSIONAL' : 'NOVA CONTRATAÃ‡ÃƒO',
              title: _isEditing ? 'Dados do barbeiro' : 'Convide um barbeiro',
              onClose: _isBusy ? null : () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Informe o nome do barbeiro.';
                }
                return null;
              },
            ),
            if (!_isEditing) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'E-mail de acesso',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                  helperText: 'O convite serÃ¡ vÃ¡lido somente para este e-mail.',
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return 'Informe um e-mail vÃ¡lido.';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _bioController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _photoUrlController,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Foto do profissional',
                      hintText: 'Selecione uma imagem',
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: _isBusy ? null : _pickAndUploadPhoto,
                  style: IconButton.styleFrom(
                    backgroundColor: SharedAppColors.orange,
                    foregroundColor: SharedAppColors.onGold,
                  ),
                  icon: _isUploadingPhoto
                      ? const CDRLoading.compact(size: 22)
                      : const Icon(Icons.upload_rounded),
                  tooltip: 'Enviar foto do profissional',
                ),
              ],
            ),
            if (_photoUrlController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: ClipOval(
                  child: Image.network(
                    _photoUrlController.text.trim(),
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 88,
                      height: 88,
                      color: SharedAppColors.elevated,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: SharedAppColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _ResponsiveFieldRow(
              children: [
                TextFormField(
                  controller: _startingPriceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'PreÃ§o inicial',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: _validateMoney,
                ),
                TextFormField(
                  controller: _commissionController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'ComissÃ£o %',
                    prefixIcon: Icon(Icons.percent),
                  ),
                  validator: _validateCommission,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _CDRToggleTile(
              value: _isActive,
              onChanged:
                  _isBusy ? null : (value) => setState(() => _isActive = value),
              title: 'Agenda ativa',
              subtitle: 'Barbeiros inativos deixam de aparecer.',
            ),
            const SizedBox(height: 12),
            CDRButton.primary(
              onPressed: _isBusy ? null : _save,
              label: 'SALVAR PROFISSIONAL',
              isLoading: _isSaving,
              leading: const Icon(Icons.save_outlined),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isBusy ? null : _deactivate,
                child: const Text('Desativar barbeiro'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _validateMoney(String? value) {
    final parsed = _parseNumber(value);
    if (parsed == null || parsed < 0) return 'Valor invÃ¡lido.';
    return null;
  }

  String? _validateCommission(String? value) {
    final parsed = _parseNumber(value);
    if (parsed == null || parsed < 0 || parsed > 100) {
      return 'Use 0 a 100.';
    }
    return null;
  }

  double? _parseNumber(String? value) {
    if (value == null) return null;
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  Future<void> _pickAndUploadPhoto() async {
    setState(() => _isUploadingPhoto = true);
    try {
      final file = await pickLogoFile(
        maxWidth: 1024,
        maxHeight: 1024,
        compressionThresholdBytes: 600 * 1024,
        quality: 0.86,
      );
      if (file == null) return;

      final url = await context
          .read<ManagementSession>()
          .uploadShopMedia(file, folder: 'barbers');
      if (!mounted) return;
      setState(() => _photoUrlController.text = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto enviada com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final session = context.read<ManagementSession>();
      final barber = widget.barber;
      if (barber == null) {
        final invitation = await session.createTeamBarber(
          email: _emailController.text,
          name: _nameController.text,
          bio: _bioController.text,
          photoUrl: _photoUrlController.text,
          startingPrice: _parseNumber(_startingPriceController.text)!,
          commissionPercent: _parseNumber(_commissionController.text)!,
        );
        if (!mounted) return;
        await _showInvitationCreated(invitation);
      } else {
        await session.updateTeamBarber(
          barber,
          name: _nameController.text,
          bio: _bioController.text,
          photoUrl: _photoUrlController.text,
          startingPrice: _parseNumber(_startingPriceController.text)!,
          commissionPercent: _parseNumber(_commissionController.text)!,
          isActive: _isActive,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showInvitationCreated(TeamInvitationLink invitation) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.mark_email_read_outlined,
          color: SharedAppColors.orange,
          size: 34,
        ),
        title: const Text('Convite criado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Envie este link para ${invitation.email}. '
              'O profissional deverÃ¡ entrar ou criar a conta usando esse mesmo e-mail.',
            ),
            const SizedBox(height: 14),
            SelectableText(
              invitation.url,
              style: const TextStyle(
                color: SharedAppColors.muted,
                fontSize: 12,
              ),
            ),
            if (invitation.setupWarning != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SharedAppColors.orange.withOpacity(.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: SharedAppColors.orange.withOpacity(.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: SharedAppColors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        invitation.setupWarning!,
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CONCLUIR'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: invitation.url));
              if (!dialogContext.mounted) return;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Link do convite copiado.')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('COPIAR LINK'),
          ),
        ],
      ),
    );
  }

  Future<void> _deactivate() async {
    final barber = widget.barber;
    if (barber == null) return;

    setState(() => _isSaving = true);
    try {
      await context.read<ManagementSession>().deactivateTeamBarber(barber);
      if (mounted) Navigator.pop(context);
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

