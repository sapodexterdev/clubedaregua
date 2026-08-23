import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';

import '../../providers/app_state.dart';
import '../../repositories/guest_identity_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/whatsapp_input_formatter.dart';
import 'appointment_confirmation_screen.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  static const route = '/appointment';

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _guestIdentityRepository = const GuestIdentityRepository();
  var _selectedPaymentMethod = PaymentMethod.pix;
  var _isSubmitting = false;
  var _seededName = false;
  var _seededPhone = false;
  var _rememberData = true;
  var _loadingRememberedData = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final shop = state.selectedBarbershop;
        final barber = state.selectedBarber;
        final service = state.selectedService;
        final hasSelection = shop != null &&
            barber != null &&
            service != null &&
            state.selectedTime.isNotEmpty;

        if (!_seededName) {
          _seededName = true;
          _nameController.text = state.currentUserName?.trim() ?? '';
          _loadRememberedData(state);
        }
        if (!_seededPhone) {
          _seededPhone = true;
          _phoneController.text = formatWhatsapp(state.currentUserPhone);
        }

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
              'Revisar agendamento',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          bottomNavigationBar: _SubmitBar(
            enabled: hasSelection && !_isSubmitting,
            submitting: _isSubmitting,
            onPressed: () => _handlePrimaryAction(state),
          ),
          body: hasSelection
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: CDRSizeTokens.clientFrameMaxWidth,
                    ),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          CDRSpacingTokens.xxl,
                          CDRSpacingTokens.sm,
                          CDRSpacingTokens.xxl,
                          CDRSpacingTokens.xxxl,
                        ),
                        children: [
                          const _Intro(),
                          const SizedBox(height: 20),
                          _AppointmentSummary(
                            shopName: shop.identity.name,
                            serviceName: service.name,
                            barberName: barber.name,
                            date: state.selectedDate,
                            time: state.selectedTime,
                            durationMinutes: service.durationMinutes,
                            total: service.price,
                          ),
                          const SizedBox(height: 22),
                          const _SectionTitle('Seus dados'),
                          const SizedBox(height: 6),
                          const Text(
                            'A barbearia usará estes dados para identificar seu agendamento.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            decoration: const InputDecoration(
                              labelText: 'Nome completo',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (value) =>
                                (value?.trim().length ?? 0) < 3
                                    ? 'Informe seu nome completo.'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [
                              AutofillHints.telephoneNumber
                            ],
                            inputFormatters: const [WhatsappInputFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'WhatsApp',
                              hintText: '(00)00000-0000',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (value) =>
                                _digitsOnly(value ?? '').length != 11
                                    ? 'Use o formato (00)00000-0000.'
                                    : null,
                          ),
                          if (!state.isSignedIn) ...[
                            const SizedBox(height: 8),
                            CheckboxListTile(
                              value: _rememberData,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: AppColors.orange,
                              title: const Text(
                                'Lembrar meus dados neste dispositivo',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: const Text(
                                'Você poderá editar os dados no próximo agendamento.',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                              onChanged: _loadingRememberedData
                                  ? null
                                  : (value) => setState(
                                        () => _rememberData = value ?? true,
                                      ),
                            ),
                          ],
                          const SizedBox(height: 26),
                          const _SectionTitle('Preferência de pagamento'),
                          const SizedBox(height: 6),
                          const Text(
                            'O pagamento será combinado diretamente com a barbearia.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _PaymentMethodSelector(
                            selected: _selectedPaymentMethod,
                            onChanged: (method) {
                              setState(() => _selectedPaymentMethod = method);
                            },
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _selectedPaymentMethod.description,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 22),
                          const _AutomaticConfirmationNotice(),
                        ],
                      ),
                    ),
                  ),
                )
              : const _MissingAppointment(),
        );
      },
    );
  }

  Future<void> _handlePrimaryAction(AppState state) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (state.selectedTime.isEmpty) {
      _showMessage('O horário selecionado não está mais disponível.');
      return;
    }

    setState(() => _isSubmitting = true);
    final created = await state.createSelectedAppointment(
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      paymentMethodLabel: _selectedPaymentMethod.label,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (created) {
      if (!state.isSignedIn) {
        await _guestIdentityRepository.save(
          name: _nameController.text,
          phone: _phoneController.text,
          remember: _rememberData,
        );
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppointmentConfirmationScreen.route,
      );
    } else {
      _showMessage(
        state.lastBookingErrorMessage ??
            'Não foi possível agendar. Confira o horário e tente novamente.',
      );
    }
  }

  Future<void> _loadRememberedData(AppState state) async {
    if (state.isSignedIn || _loadingRememberedData) return;
    _loadingRememberedData = true;
    final identity = await _guestIdentityRepository.load();
    if (!mounted) return;
    setState(() {
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = identity.name;
      }
      if (_phoneController.text.trim().isEmpty) {
        _phoneController.text = formatWhatsapp(identity.phone);
      }
      _rememberData = identity.remember;
      _loadingRememberedData = false;
    });
  }

  void _showMessage(String message) {
    CDRSnackbar.error(context, message);
  }

  static String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Está tudo certo?',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Revise os detalhes antes de confirmar seu agendamento.',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _AppointmentSummary extends StatelessWidget {
  const _AppointmentSummary({
    required this.shopName,
    required this.serviceName,
    required this.barberName,
    required this.date,
    required this.time,
    required this.durationMinutes,
    required this.total,
  });

  final String shopName;
  final String serviceName;
  final String barberName;
  final DateTime date;
  final String time;
  final int durationMinutes;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CDRSpacingTokens.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(CDRRadiusTokens.large),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shopName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 62,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date.day.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        color: AppColors.onGold,
                        fontSize: 22,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _monthShort(date.month).toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.onGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$time · $durationMinutes min',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _fullDate(date),
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
          const Divider(height: 30, color: AppColors.stroke),
          _SummaryLine(
            icon: Icons.content_cut_rounded,
            label: 'Serviço',
            value: serviceName,
          ),
          const SizedBox(height: 11),
          _SummaryLine(
            icon: Icons.person_outline_rounded,
            label: 'Profissional',
            value: barberName,
          ),
          const Divider(height: 30, color: AppColors.stroke),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Valor do serviço',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
              Text(
                'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.orange, size: 18),
        const SizedBox(width: 9),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  const _PaymentMethodSelector({
    required this.selected,
    required this.onChanged,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final method in PaymentMethod.values)
          ChoiceChip(
            avatar: Icon(
              method.icon,
              size: 16,
              color: selected == method ? AppColors.onGold : AppColors.muted,
            ),
            label: Text(method.label),
            selected: selected == method,
            onSelected: (_) => onChanged(method),
            selectedColor: AppColors.orange,
            backgroundColor: AppColors.card,
            side: BorderSide(
              color: selected == method ? AppColors.orange : AppColors.stroke,
            ),
            labelStyle: TextStyle(
              color: selected == method ? AppColors.onGold : AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

enum PaymentMethod {
  pix(
    'PIX',
    'A barbearia enviará as orientações para o pagamento.',
    Icons.pix_rounded,
  ),
  cash(
    'Dinheiro',
    'Pagamento em dinheiro no atendimento.',
    Icons.payments_outlined,
  ),
  card(
    'Cartão',
    'Pagamento no cartão diretamente na barbearia.',
    Icons.credit_card_rounded,
  );

  const PaymentMethod(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;
}

class _AutomaticConfirmationNotice extends StatelessWidget {
  const _AutomaticConfirmationNotice();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: AppColors.muted, size: 17),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Ao confirmar, o horário entra imediatamente na agenda do profissional.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.enabled,
    required this.submitting,
    required this.onPressed,
  });

  final bool enabled;
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          CDRSpacingTokens.xxl,
          CDRSpacingTokens.md,
          CDRSpacingTokens.xxl,
          CDRSpacingTokens.md,
        ),
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
          child: submitting
              ? const CDRLoading.compact(size: 24)
              : Text(
                  'Confirmar agendamento',
                ),
        ),
      ),
    );
  }
}

class _MissingAppointment extends StatelessWidget {
  const _MissingAppointment();

  @override
  Widget build(BuildContext context) {
    return CDREmptyState(
      icon: Icons.event_busy_outlined,
      title: 'Seleção incompleta',
      message: 'Volte e escolha serviço, profissional, data e horário.',
      actionLabel: 'Voltar',
      onAction: () => Navigator.maybePop(context),
    );
  }
}

String _monthShort(int month) {
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
  return months[month - 1];
}

String _fullDate(DateTime date) {
  const weekdays = [
    'segunda-feira',
    'terça-feira',
    'quarta-feira',
    'quinta-feira',
    'sexta-feira',
    'sábado',
    'domingo',
  ];
  const months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
}
