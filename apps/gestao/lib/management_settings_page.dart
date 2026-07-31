part of 'main.dart';

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        final config = session.shopConfiguration;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActionPanel(
              title: 'Configuração da barbearia',
              subtitle: 'Defina dados públicos, horários e regras de agenda.',
              buttonLabel: 'Atualizar',
              icon: Icons.refresh_rounded,
              onPressed: session.fetchShopConfiguration,
            ),
            const SizedBox(height: 18),
            if (session.isSettingsLoading) ...[
              const CDRLoading.section(height: 88),
              const SizedBox(height: 12),
            ],
            if (session.settingsError != null)
              _InlineNotice(
                icon: Icons.warning_amber_rounded,
                title: 'Não foi possível carregar as configurações',
                subtitle: session.settingsError!,
                actionLabel: 'TENTAR NOVAMENTE',
                onAction: session.fetchShopConfiguration,
              )
            else if (config == null)
              const _InlineNotice(
                icon: Icons.settings_outlined,
                title: 'Configuração não carregada',
                subtitle: 'Toque em Atualizar para buscar os dados.',
              )
            else
              _SettingsForm(config: config),
          ],
        );
      },
    );
  }
}

class _SettingsForm extends StatefulWidget {
  const _SettingsForm({required this.config});

  final ShopConfiguration config;

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _logoController;
  late final TextEditingController _coverController;
  late final TextEditingController _documentController;
  late final TextEditingController _phoneController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _emailController;
  late final TextEditingController _instagramController;
  late final TextEditingController _addressController;
  late final TextEditingController _zipController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _lunchStartController;
  late final TextEditingController _lunchEndController;
  late final TextEditingController _bookingDaysController;
  late final TextEditingController _minNoticeController;
  late final TextEditingController _maxDelayController;
  late final TextEditingController _cancelHoursController;
  late final TextEditingController _secondaryColorController;
  late List<ShopBusinessDay> _days;
  late bool _lunchEnabled;
  late int _bookingInterval;
  var _applyHoursToTeam = false;
  var _isSaving = false;
  var _isUploadingLogo = false;
  var _isUploadingCover = false;

  @override
  void initState() {
    super.initState();
    final config = widget.config;
    _nameController = TextEditingController(text: config.name);
    _logoController = TextEditingController(text: config.logoUrl);
    _coverController = TextEditingController(text: config.coverUrl);
    _documentController = TextEditingController(text: config.document);
    _phoneController = TextEditingController(text: config.phone);
    _whatsappController = TextEditingController(text: config.whatsapp);
    _emailController = TextEditingController(text: config.email);
    _instagramController = TextEditingController(text: config.instagram);
    _addressController = TextEditingController(text: config.address);
    _zipController = TextEditingController(text: config.zipCode);
    _cityController = TextEditingController(text: config.city);
    _stateController = TextEditingController(text: config.state);
    _lunchStartController = TextEditingController(text: config.lunchStart);
    _lunchEndController = TextEditingController(text: config.lunchEnd);
    _bookingDaysController =
        TextEditingController(text: config.bookingDaysAhead.toString());
    _minNoticeController =
        TextEditingController(text: config.minNoticeMinutes.toString());
    _maxDelayController =
        TextEditingController(text: config.maxDelayMinutes.toString());
    _cancelHoursController =
        TextEditingController(text: config.minCancelHours.toString());
    _secondaryColorController =
        TextEditingController(text: config.secondaryColor);
    _days = List.of(config.days);
    _lunchEnabled = config.lunchEnabled;
    _bookingInterval = config.bookingIntervalMinutes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _logoController.dispose();
    _coverController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _instagramController.dispose();
    _addressController.dispose();
    _zipController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _lunchStartController.dispose();
    _lunchEndController.dispose();
    _bookingDaysController.dispose();
    _minNoticeController.dispose();
    _maxDelayController.dispose();
    _cancelHoursController.dispose();
    _secondaryColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            'Informações gerais',
            eyebrow: 'PERFIL DA BARBEARIA',
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da barbearia',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _logoController,
                      decoration: const InputDecoration(
                        labelText: 'URL da logo',
                        helperText:
                            'Faça upload pelo Storage ou cole uma URL pública.',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: _isUploadingLogo ? null : _pickAndUploadLogo,
                    style: IconButton.styleFrom(
                      backgroundColor: SharedAppColors.orange,
                      foregroundColor: SharedAppColors.onGold,
                    ),
                    icon: _isUploadingLogo
                        ? const CDRLoading.compact(size: 22)
                        : const Icon(Icons.upload_rounded),
                    tooltip: 'Enviar logo',
                  ),
                ],
              ),
              if (_logoController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    _logoController.text.trim(),
                    height: 88,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _coverController,
                      decoration: const InputDecoration(
                        labelText: 'URL da foto de capa',
                        helperText: 'Banner publico usado no app Cliente.',
                        prefixIcon: Icon(Icons.landscape_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: _isUploadingCover ? null : _pickAndUploadCover,
                    style: IconButton.styleFrom(
                      backgroundColor: SharedAppColors.orange,
                      foregroundColor: SharedAppColors.onGold,
                    ),
                    icon: _isUploadingCover
                        ? const CDRLoading.compact(size: 22)
                        : const Icon(Icons.upload_rounded),
                    tooltip: 'Enviar foto de capa',
                  ),
                ],
              ),
              if (_coverController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    _coverController.text.trim(),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _documentController,
                decoration: const InputDecoration(
                  labelText: 'CNPJ',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              _ResponsiveFieldRow(
                children: [
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  TextFormField(
                    controller: _whatsappController,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp',
                      prefixIcon: Icon(Icons.chat_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _instagramController,
                decoration: const InputDecoration(
                  labelText: 'Instagram',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Endereço completo',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              _ResponsiveFieldRow(
                children: [
                  TextFormField(
                    controller: _zipController,
                    decoration: const InputDecoration(labelText: 'CEP'),
                  ),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'Cidade'),
                  ),
                  TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(labelText: 'UF'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _secondaryColorController,
                decoration: const InputDecoration(
                  labelText: 'Cor secundaria da barbearia',
                  helperText:
                      'Use apenas como detalhe do estabelecimento. A marca Clube da Regua permanece fixa.',
                  prefixIcon: Icon(Icons.palette_outlined),
                ),
                validator: _validateHexColor,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            'Horário de funcionamento',
            eyebrow: 'OPERAÇÃO',
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              for (var index = 0; index < _days.length; index++)
                _BusinessDayEditor(
                  day: _days[index],
                  onChanged: (day) => setState(() => _days[index] = day),
                ),
              const Divider(color: SharedAppColors.stroke, height: 28),
              _CDRToggleTile(
                value: _applyHoursToTeam,
                title: 'Aplicar à agenda dos profissionais',
                subtitle:
                    'Substitui a disponibilidade semanal dos barbeiros ativos pelos horários acima.',
                onChanged: (value) => setState(() => _applyHoursToTeam = value),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            'Intervalo',
            eyebrow: 'PAUSAS',
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _CDRToggleTile(
                value: _lunchEnabled,
                title: 'Almoço',
                subtitle: 'Bloqueia intervalo recorrente.',
                onChanged: (value) => setState(() => _lunchEnabled = value),
              ),
              _ResponsiveFieldRow(
                children: [
                  TextFormField(
                    enabled: _lunchEnabled,
                    controller: _lunchStartController,
                    decoration: const InputDecoration(labelText: 'Início'),
                    validator: _validateTime,
                  ),
                  TextFormField(
                    enabled: _lunchEnabled,
                    controller: _lunchEndController,
                    decoration: const InputDecoration(labelText: 'Fim'),
                    validator: _validateTime,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            'Configuração de agendamento',
            eyebrow: 'REGRAS DA AGENDA',
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              DropdownButtonFormField<int>(
                value: _bookingInterval,
                decoration: const InputDecoration(
                  labelText: 'Tempo entre atendimentos',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                items: const [5, 10, 15, 20, 30]
                    .map(
                      (value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value minutos'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _bookingInterval = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bookingDaysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dias no futuro para agendar',
                  prefixIcon: Icon(Icons.event_available_outlined),
                ),
                validator: _positiveInt,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minNoticeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Antecedência mínima em minutos',
                  prefixIcon: Icon(Icons.schedule_outlined),
                ),
                validator: _positiveInt,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxDelayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tempo maximo de atraso em minutos',
                  prefixIcon: Icon(Icons.hourglass_bottom_rounded),
                ),
                validator: _positiveInt,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cancelHoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cancelamento permitido até X horas antes',
                  prefixIcon: Icon(Icons.event_busy_outlined),
                ),
                validator: _positiveInt,
              ),
            ],
          ),
          const SizedBox(height: 18),
          CDRButton.primary(
            onPressed: _isSaving ? null : _save,
            label: 'SALVAR CONFIGURAÇÕES',
            isLoading: _isSaving,
            leading: const Icon(Icons.save_outlined),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório.';
    return null;
  }

  String? _positiveInt(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return 'Informe um número válido.';
    return null;
  }

  String? _validateHexColor(String? value) {
    final color = value?.trim() ?? '';
    if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(color)) {
      return 'Use uma cor no formato #F3B200.';
    }
    return null;
  }

  String? _validateTime(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o horário.';
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(value.trim())) {
      return 'Use HH:mm.';
    }
    return null;
  }

  Future<void> _pickAndUploadLogo() async {
    final session = context.read<ManagementSession>();
    setState(() => _isUploadingLogo = true);
    try {
      final file = await pickLogoFile(
        maxWidth: 1024,
        maxHeight: 1024,
        compressionThresholdBytes: 500 * 1024,
        quality: 0.88,
        preserveTransparency: true,
      );
      if (file == null) return;
      final url = await session.uploadShopMedia(file, folder: 'logos');
      await session.saveShopMediaUrl(logoUrl: url);
      if (!mounted) return;
      setState(() => _logoController.text = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo enviada e salva com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _pickAndUploadCover() async {
    final session = context.read<ManagementSession>();
    setState(() => _isUploadingCover = true);
    try {
      final file = await pickLogoFile(
        maxWidth: 1920,
        maxHeight: 1080,
        compressionThresholdBytes: 900 * 1024,
        quality: 0.86,
      );
      if (file == null) return;
      final url = await session.uploadShopMedia(file, folder: 'banners');
      await session.saveShopMediaUrl(coverUrl: url);
      if (!mounted) return;
      setState(() => _coverController.text = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de capa enviada e salva com sucesso.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final current = widget.config;
      final config = ShopConfiguration(
        shopId: current.shopId,
        settingsId: current.settingsId,
        name: _nameController.text,
        logoUrl: _logoController.text,
        coverUrl: _coverController.text,
        document: _documentController.text,
        phone: _phoneController.text,
        whatsapp: _whatsappController.text,
        email: _emailController.text,
        instagram: _instagramController.text,
        address: _addressController.text,
        zipCode: _zipController.text,
        city: _cityController.text,
        state: _stateController.text,
        days: _days,
        lunchEnabled: _lunchEnabled,
        lunchStart: _lunchStartController.text,
        lunchEnd: _lunchEndController.text,
        bookingIntervalMinutes: _bookingInterval,
        bookingDaysAhead: int.parse(_bookingDaysController.text.trim()),
        minNoticeMinutes: int.parse(_minNoticeController.text.trim()),
        maxDelayMinutes: int.parse(_maxDelayController.text.trim()),
        minCancelHours: int.parse(_cancelHoursController.text.trim()),
        secondaryColor: _secondaryColorController.text,
      );
      await context.read<ManagementSession>().saveShopConfiguration(
            config,
            applyHoursToTeam: _applyHoursToTeam,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _applyHoursToTeam
                ? 'Configurações e agendas da equipe atualizadas.'
                : 'Configurações salvas com sucesso.',
          ),
        ),
      );
      setState(() => _applyHoursToTeam = false);
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
