import 'package:clubedaregua_shared/clubedaregua_shared.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_mode.dart';
import '../providers/app_mode_controller.dart';
import '../providers/app_state.dart';
import '../repositories/owner_onboarding_repository.dart';
import '../theme/app_colors.dart';
import 'professional_mode_screen.dart';

class OwnerOnboardingScreen extends StatefulWidget {
  const OwnerOnboardingScreen({super.key});

  static const route = '/cadastrar-barbearia';

  @override
  State<OwnerOnboardingScreen> createState() =>
      _OwnerOnboardingScreenState();
}

class _OwnerOnboardingScreenState extends State<OwnerOnboardingScreen> {
  final _repository = const OwnerOnboardingRepository();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  var _step = 0;
  var _servesAsBarber = false;
  var _isSaving = false;
  var _completed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final profilePhone = context.read<AppState>().currentUserPhone ?? '';
    _phoneController.text = profilePhone;
    _whatsappController.text = profilePhone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leadingWidth: 68,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: CDRBackButton(),
        ),
        title: const Text('Cadastrar minha barbearia'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              children: [
                _ProgressHeader(step: _step, completed: _completed),
                const SizedBox(height: 22),
                if (_completed)
                  _SuccessStep(
                    servesAsBarber: _servesAsBarber,
                    onEnter: _enterOwnerMode,
                  )
                else ...[
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: switch (_step) {
                      0 => _BusinessStep(
                          key: const ValueKey('business'),
                          nameController: _nameController,
                          phoneController: _phoneController,
                          whatsappController: _whatsappController,
                        ),
                      1 => _AddressStep(
                          key: const ValueKey('address'),
                          addressController: _addressController,
                          cityController: _cityController,
                          stateController: _stateController,
                        ),
                      _ => _ConfirmationStep(
                          key: const ValueKey('confirmation'),
                          shopName: _nameController.text.trim(),
                          city: _cityController.text.trim(),
                          state: _stateController.text.trim(),
                          servesAsBarber: _servesAsBarber,
                          onServesChanged: (value) {
                            setState(() => _servesAsBarber = value);
                          },
                        ),
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    _ErrorNotice(message: _errorMessage!),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      if (_step > 0) ...[
                        Expanded(
                          child: CDRButton.outlined(
                            label: 'VOLTAR',
                            onPressed: _isSaving ? null : _back,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: CDRButton.primary(
                          label: _step == 2
                              ? 'INICIAR TESTE GRÁTIS'
                              : 'CONTINUAR',
                          onPressed: _isSaving
                              ? null
                              : () => _continue(state),
                          isLoading: _isSaving,
                          trailing: _step == 2
                              ? const Icon(Icons.rocket_launch_outlined)
                              : const Icon(Icons.arrow_forward_rounded),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _back() {
    setState(() {
      _errorMessage = null;
      _step -= 1;
    });
  }

  Future<void> _continue(AppState state) async {
    final error = _validateStep();
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    if (_step < 2) {
      setState(() {
        _errorMessage = null;
        _step += 1;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await _repository.createBarbershop(
        name: _nameController.text,
        phone: _phoneController.text,
        whatsapp: _whatsappController.text,
        address: _addressController.text,
        city: _cityController.text,
        state: _stateController.text,
        ownerName: state.currentUserName ?? '',
        servesAsBarber: _servesAsBarber,
      );
      await state.loadInitialData();
      if (!mounted) return;
      setState(() => _completed = true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error
            .toString()
            .replaceFirst('Bad state: ', '')
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validateStep() {
    if (_step == 0) {
      if (_nameController.text.trim().length < 3) {
        return 'Informe o nome da barbearia.';
      }
      if (_whatsappController.text.replaceAll(RegExp(r'\D'), '').length < 10) {
        return 'Informe um WhatsApp válido para a barbearia.';
      }
    }
    if (_step == 1) {
      if (_addressController.text.trim().length < 5) {
        return 'Informe o endereço da barbearia.';
      }
      if (_cityController.text.trim().length < 2) {
        return 'Informe a cidade.';
      }
      if (_stateController.text.trim().length != 2) {
        return 'Informe a sigla do estado com duas letras.';
      }
    }
    return null;
  }

  Future<void> _enterOwnerMode() async {
    final state = context.read<AppState>();
    final modes = context.read<AppModeController>();
    await modes.synchronizeAccess(
      isSignedIn: state.isSignedIn,
      userId: AuthService().currentUser?.id,
      professionalRoles: state.professionalRoles,
    );
    final selected = await modes.selectMode(AppMode.owner);
    if (!selected || !mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      ProfessionalModeScreen.ownerRoute,
      (_) => false,
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.step,
    required this.completed,
  });

  final int step;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final current = completed ? 3 : step;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CLUBE DA RÉGUA PARA NEGÓCIOS',
          style: TextStyle(
            color: AppColors.orange,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          completed
              ? 'Sua barbearia está pronta'
              : 'Comece seu período gratuito',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (var index = 0; index < 3; index++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 5,
                  decoration: BoxDecoration(
                    color: index <= current
                        ? AppColors.orange
                        : AppColors.stroke,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              if (index < 2) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _BusinessStep extends StatelessWidget {
  const _BusinessStep({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.whatsappController,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController whatsappController;

  @override
  Widget build(BuildContext context) {
    return _OnboardingCard(
      icon: Icons.storefront_rounded,
      title: 'Sobre a barbearia',
      subtitle: 'Essas informações serão exibidas para seus clientes.',
      children: [
        CDRTextField(
          controller: nameController,
          label: 'Nome da barbearia',
          leading: Icons.storefront_outlined,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        CDRTextField(
          controller: whatsappController,
          label: 'WhatsApp',
          leading: Icons.chat_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        CDRTextField(
          controller: phoneController,
          label: 'Telefone (opcional)',
          leading: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

class _AddressStep extends StatelessWidget {
  const _AddressStep({
    super.key,
    required this.addressController,
    required this.cityController,
    required this.stateController,
  });

  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController stateController;

  @override
  Widget build(BuildContext context) {
    return _OnboardingCard(
      icon: Icons.location_on_rounded,
      title: 'Localização',
      subtitle: 'O endereço ajuda clientes próximos a encontrarem você.',
      children: [
        CDRTextField(
          controller: addressController,
          label: 'Endereço completo',
          leading: Icons.location_on_outlined,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: CDRTextField(
                controller: cityController,
                label: 'Cidade',
                leading: Icons.location_city_outlined,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CDRTextField(
                controller: stateController,
                label: 'UF',
                textInputAction: TextInputAction.done,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConfirmationStep extends StatelessWidget {
  const _ConfirmationStep({
    super.key,
    required this.shopName,
    required this.city,
    required this.state,
    required this.servesAsBarber,
    required this.onServesChanged,
  });

  final String shopName;
  final String city;
  final String state;
  final bool servesAsBarber;
  final ValueChanged<bool> onServesChanged;

  @override
  Widget build(BuildContext context) {
    return _OnboardingCard(
      icon: Icons.workspace_premium_rounded,
      title: 'Tudo certo para começar',
      subtitle: '$shopName • $city/${state.toUpperCase()}',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.orange.withOpacity(.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.orange.withOpacity(.45)),
          ),
          child: const Row(
            children: [
              Icon(Icons.rocket_launch_outlined, color: AppColors.orange),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plano Pro • 14 dias grátis',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sem cobrança agora. Configure sua operação e conheça todos os recursos.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.orange,
          value: servesAsBarber,
          onChanged: onServesChanged,
          title: const Text(
            'Também trabalho como barbeiro',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: const Text(
            'Criaremos sua agenda profissional junto com a barbearia.',
          ),
        ),
      ],
    );
  }
}

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({
    required this.servesAsBarber,
    required this.onEnter,
  });

  final bool servesAsBarber;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return _OnboardingCard(
      icon: Icons.check_circle_rounded,
      title: 'Bem-vindo ao Clube',
      subtitle: servesAsBarber
          ? 'Seus acessos de Dono e Barbeiro já estão disponíveis.'
          : 'Seu acesso de Dono já está disponível.',
      children: [
        const Text(
          'Agora você pode configurar serviços, equipe, horários e começar a receber agendamentos.',
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 22),
        CDRButton.primary(
          label: 'ENTRAR NA GESTÃO',
          onPressed: onEnter,
          trailing: const Icon(Icons.arrow_forward_rounded),
        ),
      ],
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: AppColors.orange),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0x1FEF4444),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x66EF4444)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFFFA3A3)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFFA3A3),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
