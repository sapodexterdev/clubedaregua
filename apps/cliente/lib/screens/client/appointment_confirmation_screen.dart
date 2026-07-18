import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_colors.dart';
import 'home_screen.dart';

class AppointmentConfirmationScreen extends StatelessWidget {
  const AppointmentConfirmationScreen({super.key});

  static const route = '/appointment-confirmation';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final receipt = state.lastBookingReceipt;
        final hasReceipt = state.lastBookingRequestCreated && receipt != null;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: hasReceipt
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
                    children: [
                      const _SuccessMark(),
                      const SizedBox(height: 24),
                      const Text(
                        'Solicitação enviada!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.text,
                          fontFamily: 'Barlow Condensed',
                          fontSize: 34,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Agora a barbearia analisará o pedido e retornará pelo WhatsApp informado.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Center(child: _PendingBadge()),
                      const SizedBox(height: 26),
                      _ReceiptCard(
                        shopName: receipt!.shopName,
                        serviceName: receipt.serviceName,
                        barberName: receipt.barberName,
                        date: receipt.date,
                        time: receipt.time,
                        total: receipt.total,
                      ),
                      const SizedBox(height: 26),
                      const _NextSteps(),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: () => _goHome(context),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: AppColors.orange,
                          foregroundColor: AppColors.onGold,
                        ),
                        child: const Text('VOLTAR PARA DESCOBRIR'),
                      ),
                    ],
                  )
                : _NoReceipt(onHome: () => _goHome(context)),
          ),
        );
      },
    );
  }

  static void _goHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      HomeScreen.route,
      (_) => false,
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: AppColors.orange.withOpacity(.1),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.orange, width: 2),
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 46,
          color: AppColors.orange,
        ),
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.orange.withOpacity(.55)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, color: AppColors.orange, size: 16),
          SizedBox(width: 6),
          Text(
            'AGUARDANDO CONFIRMAÇÃO',
            style: TextStyle(
              color: AppColors.orange,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.shopName,
    required this.serviceName,
    required this.barberName,
    required this.date,
    required this.time,
    required this.total,
  });

  final String shopName;
  final String serviceName;
  final String barberName;
  final DateTime date;
  final String time;
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
          const Text(
            'RESUMO DA SOLICITAÇÃO',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              letterSpacing: .8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            shopName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontFamily: 'Barlow Condensed',
              fontSize: 24,
              height: 1.05,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _ReceiptRow(
            icon: Icons.content_cut_rounded,
            label: 'Serviço',
            value: serviceName,
          ),
          _ReceiptRow(
            icon: Icons.person_outline_rounded,
            label: 'Profissional',
            value: barberName,
          ),
          _ReceiptRow(
            icon: Icons.calendar_month_outlined,
            label: 'Data',
            value: _dateLabel(date),
          ),
          _ReceiptRow(
            icon: Icons.schedule_outlined,
            label: 'Horário solicitado',
            value: time,
          ),
          const Divider(height: 28, color: AppColors.stroke),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Valor informado',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
              Text(
                'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
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

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.orange, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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

class _NextSteps extends StatelessWidget {
  const _NextSteps();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'O que acontece agora',
          style: TextStyle(
            color: AppColors.text,
            fontFamily: 'Barlow Condensed',
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 14),
        _TimelineItem(
          icon: Icons.check_rounded,
          title: 'Solicitação recebida',
          description: 'Os dados foram enviados para a barbearia.',
          active: true,
        ),
        _TimelineItem(
          icon: Icons.storefront_outlined,
          title: 'Análise da barbearia',
          description: 'A equipe verificará o horário solicitado.',
        ),
        _TimelineItem(
          icon: Icons.chat_outlined,
          title: 'Retorno pelo WhatsApp',
          description: 'Você receberá a confirmação ou uma alternativa.',
          last: true,
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.description,
    this.active = false,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.orange : AppColors.muted;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.orange.withOpacity(.12)
                        : AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: color),
                  ),
                  child: Icon(icon, color: color, size: 15),
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 1, color: AppColors.stroke),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoReceipt extends StatelessWidget {
  const _NoReceipt({required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.muted,
              size: 44,
            ),
            const SizedBox(height: 14),
            const Text(
              'Nenhuma solicitação recente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onHome,
              child: const Text('Descobrir barbearias'),
            ),
          ],
        ),
      ),
    );
  }
}

String _dateLabel(DateTime date) {
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
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}
