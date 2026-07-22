import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';

import '../../providers/app_state.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../theme/app_colors.dart';
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
  var _selectedPaymentMethod = PaymentMethod.pix;
  var _isSubmitting = false;
  var _seededName = false;
  var _seededPhone = false;

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
        }
        if (!_seededPhone) {
          _seededPhone = true;
          _phoneController.text = state.currentUserPhone?.trim() ?? '';
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.text,
            elevation: 0,
            title: const Text(
              'Revisar agendamento',
              style: TextStyle(
                fontFamily: 'Barlow Condensed',
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          bottomNavigationBar: _SubmitBar(
            signedIn: state.isSignedIn,
            enabled: hasSelection && !_isSubmitting,
            submitting: _isSubmitting,
            onPressed: () => _handlePrimaryAction(state),
          ),
          body: hasSelection
              ? Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
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
                      if (!state.isSignedIn)
                        _AuthRequired(
                          onLogin: () => _openLogin(context),
                          onRegister: () => _openRegister(context),
                        )
                      else ...[
                        const _SectionTitle('Seus dados'),
                        const SizedBox(height: 6),
                        const Text(
                          'A barbearia usará estes dados para confirmar a solicitação.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
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
                          autofillHints: const [AutofillHints.telephoneNumber],
                          inputFormatters: const [_WhatsappInputFormatter()],
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
                        const SizedBox(height: 26),
                        const _SectionTitle('Preferência de pagamento'),
                        const SizedBox(height: 6),
                        const Text(
                          'O pagamento será combinado diretamente com a barbearia.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
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
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const _RequestNotice(),
                      ],
                    ],
                  ),
                )
              : const _MissingAppointment(),
        );
      },
    );
  }

  void _openLogin(BuildContext context) {
    Navigator.pushNamed(
      context,
      LoginScreen.route,
      arguments: AppointmentScreen.route,
    );
  }

  void _openRegister(BuildContext context) {
    Navigator.pushNamed(
      context,
      RegisterScreen.route,
      arguments: AppointmentScreen.route,
    );
  }

  Future<void> _handlePrimaryAction(AppState state) async {
    if (!state.isSignedIn) {
      _openLogin(context);
      return;
    }
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
      Navigator.pushReplacementNamed(
        context,
        AppointmentConfirmationScreen.route,
      );
    } else {
      _showMessage(
        'Não foi possível enviar. Confira o horário e tente novamente.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Está tudo certo?',
          style: TextStyle(
            color: AppColors.text,
            fontFamily: 'Barlow Condensed',
            fontSize: 31,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Revise os detalhes antes de enviar sua solicitação.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
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
                        fontSize: 9,
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
                        fontSize: 11,
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
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
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

class _AuthRequired extends StatelessWidget {
  const _AuthRequired({required this.onLogin, required this.onRegister});

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Entre para enviar a solicitação',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontFamily: 'Barlow Condensed',
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Suas escolhas serão mantidas após o acesso.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onRegister,
              child: const Text('Criar uma conta'),
            ),
          ),
          TextButton(
            onPressed: onLogin,
            child: const Text('Já tenho uma conta'),
          ),
        ],
      ),
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
      style: const TextStyle(
        color: AppColors.text,
        fontFamily: 'Barlow Condensed',
        fontSize: 23,
        fontWeight: FontWeight.w700,
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

class _RequestNotice extends StatelessWidget {
  const _RequestNotice();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: AppColors.muted, size: 17),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'O envio não confirma automaticamente o horário. A barbearia retornará pelo WhatsApp.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.signedIn,
    required this.enabled,
    required this.submitting,
    required this.onPressed,
  });

  final bool signedIn;
  final bool enabled;
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
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
                  signedIn
                      ? 'ENVIAR SOLICITAÇÃO'
                      : 'ENTRAR PARA CONTINUAR',
                ),
        ),
      ),
    );
  }
}

class _WhatsappInputFormatter extends TextInputFormatter {
  const _WhatsappInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buffer = StringBuffer();
    for (var index = 0; index < limited.length; index++) {
      if (index == 0) buffer.write('(');
      if (index == 2) buffer.write(')');
      if (index == 7) buffer.write('-');
      buffer.write(limited[index]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _MissingAppointment extends StatelessWidget {
  const _MissingAppointment();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              color: AppColors.muted,
              size: 42,
            ),
            const SizedBox(height: 14),
            const Text(
              'Seleção incompleta.',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Volte e escolha serviço, profissional, data e horário.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
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
