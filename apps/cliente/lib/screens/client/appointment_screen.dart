import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/service_card.dart';
import 'appointment_confirmation_screen.dart';

class AppointmentScreen extends StatelessWidget {
  const AppointmentScreen({super.key});

  static const route = '/appointment';

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
                'Selecione o serviço',
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
                    _SummaryRow(label: 'Serviço', value: service?.name ?? '-'),
                    _SummaryRow(
                      label: 'Data',
                      value: DateFormat('dd/MM').format(state.selectedDate),
                    ),
                    _SummaryRow(label: 'Horário', value: state.selectedTime),
                    const Divider(height: 28),
                    _SummaryRow(
                      label: 'Total',
                      value: service == null
                          ? 'R\$ 0'
                          : 'R\$ ${service.price.toStringAsFixed(0)}',
                      strong: true,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.pix_rounded, color: AppColors.orange),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pagamento via PIX: aguardando confirmação',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Agendar agora',
                onPressed: () async {
                  await state.createSelectedAppointment();

                  if (context.mounted) {
                    Navigator.pushReplacementNamed(
                      context,
                      AppointmentConfirmationScreen.route,
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
