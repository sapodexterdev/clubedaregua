import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/service_card.dart';
import 'appointment_confirmation_screen.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  static const route = '/appointment';

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  var _selectedPaymentMethod = PaymentMethod.pix;
  bool _isSubmitting = false;

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
        final barber = state.selectedBarber;
        final service = state.selectedService;

        return Scaffold(
          appBar: AppBar(title: const Text('Agendamento')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Selecione o servico',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              ...state.services.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ServiceCard(
                    service: item,
                    isSelected: service?.id == item.id,
                    onTap: () => state.selectService(item),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumo',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 16),
                    _SummaryRow(label: 'Barbeiro', value: barber?.name ?? '-'),
                    _SummaryRow(label: 'Servico', value: service?.name ?? '-'),
                    _SummaryRow(
                      label: 'Data',
                      value: DateFormat('dd/MM').format(state.selectedDate),
                    ),
                    _SummaryRow(label: 'Horario', value: state.selectedTime),
                    const Divider(height: 28),
                    _SummaryRow(
                      label: 'Total',
                      value: service == null
                          ? 'R\$ 0'
                          : 'R\$ ${service.price.toStringAsFixed(0)}',
                      strong: true,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Forma de pagamento',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
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
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Seu nome',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: const [_WhatsappInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'WhatsApp',
                  hintText: '(00)00000-0000',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: _isSubmitting ? 'Enviando...' : 'Agendar agora',
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        final name = _nameController.text.trim();
                        final phone = _phoneController.text.trim();
                        final phoneDigits = _digitsOnly(phone);

                        if (name.length < 3 || phoneDigits.length != 11) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Informe seu nome e WhatsApp no formato (00)00000-0000.',
                              ),
                            ),
                          );
                          return;
                        }

                        setState(() => _isSubmitting = true);
                        final created = await state.createSelectedAppointment(
                          customerName: name,
                          customerPhone: phone,
                          paymentMethodLabel: _selectedPaymentMethod.label,
                        );

                        if (!context.mounted) return;
                        setState(() => _isSubmitting = false);

                        if (created) {
                          Navigator.pushReplacementNamed(
                            context,
                            AppointmentConfirmationScreen.route,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Nao foi possivel enviar agora. Tente novamente.',
                              ),
                            ),
                          );
                        }
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }
}

enum PaymentMethod {
  pix('PIX', 'Pague por PIX na confirmação enviada pela barbearia.'),
  cash('Dinheiro', 'Pague em dinheiro no atendimento.'),
  card('Cartão', 'Pague no débito ou crédito no atendimento.');

  const PaymentMethod(this.label, this.description);

  final String label;
  final String description;
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
            label: Text(method.label),
            selected: selected == method,
            onSelected: (_) => onChanged(method),
            selectedColor: AppColors.orange,
            backgroundColor: AppColors.background,
            side: BorderSide.none,
            labelStyle: TextStyle(
              color: selected == method ? Colors.white : AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: strong ? 20 : 15,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
