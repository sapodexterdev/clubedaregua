import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';

import '../../models/appointment.dart';
import '../../providers/app_state.dart';
import '../../screens/auth/login_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_bottom_nav.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  static const route = '/history';

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with WidgetsBindingObserver {
  String? _cancellingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    context.read<AppState>().refreshAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text(
          'Agenda',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: 2,
        onTap: (index) => _navigate(context, index),
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (!state.isSignedIn) return const _LoginRequired();
          if (state.isLoadingAppointments && state.appointments.isEmpty) {
            return const _AgendaLoading();
          }
          if (state.appointmentsLoadError != null &&
              state.appointments.isEmpty) {
            return _AgendaError(onRetry: state.refreshAppointments);
          }
          if (state.appointments.isEmpty) {
            return _EmptyAgenda(onExplore: () => _navigate(context, 0));
          }
          return RefreshIndicator(
            color: AppColors.orange,
            onRefresh: state.refreshAppointments,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: CDRSizeTokens.contentMaxWidth,
                ),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                  itemCount: state.appointments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final appointment = state.appointments[index];
                    return _AppointmentCard(
                      appointment: appointment,
                      cancelling: _cancellingId == appointment.id,
                      onCancel: _canCancel(appointment.status)
                          ? () => _cancel(state, appointment)
                          : null,
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _cancel(AppState state, Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Cancelar solicitação?'),
        content: const Text(
          'O horário será liberado e esta ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Manter'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar solicitação'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _cancellingId = appointment.id);
    final success = await state.cancelAppointment(appointment.id);
    if (!mounted) return;
    setState(() => _cancellingId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Solicitação cancelada.'
              : 'Não foi possível cancelar. Tente novamente.',
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    final route = switch (index) {
      0 => HomeScreen.route,
      1 => FavoritesScreen.route,
      2 => HistoryScreen.route,
      3 => ProfileScreen.route,
      _ => HomeScreen.route,
    };
    if (route != HistoryScreen.route) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  bool _canCancel(String status) => status == 'new' || status == 'contacted';
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.cancelling,
    required this.onCancel,
  });

  final Appointment appointment;
  final bool cancelling;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final status = _statusInfo(appointment.status);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  appointment.shopName.isEmpty
                      ? 'Barbearia'
                      : appointment.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              _StatusBadge(info: status),
            ],
          ),
          const SizedBox(height: 14),
          _DetailLine(
            icon: Icons.calendar_month_outlined,
            value:
                '${_displayDate(appointment.dateLabel)} às ${appointment.time}',
          ),
          const SizedBox(height: 8),
          _DetailLine(
            icon: Icons.content_cut_rounded,
            value: appointment.serviceName,
          ),
          const SizedBox(height: 8),
          _DetailLine(
            icon: Icons.person_outline_rounded,
            value: appointment.barberName,
          ),
          const Divider(height: 28, color: AppColors.stroke),
          Row(
            children: [
              Text(
                'R\$ ${appointment.total.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (onCancel != null)
                TextButton(
                  onPressed: cancelling ? null : onCancel,
                  child: cancelling
                      ? const CDRLoading.compact(size: 20)
                      : const Text('Cancelar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.orange, size: 17),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.info});

  final _StatusInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: info.color.withOpacity(.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: info.color.withOpacity(.5)),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          color: info.color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusInfo {
  const _StatusInfo(this.label, this.color);

  final String label;
  final Color color;
}

_StatusInfo _statusInfo(String status) {
  return switch (status) {
    'new' => const _StatusInfo('SOLICITADO', AppColors.orange),
    'contacted' => const _StatusInfo('EM CONTATO', Colors.lightBlueAccent),
    'converted' => const _StatusInfo('CONFIRMADO', AppColors.success),
    'cancelled' => const _StatusInfo('CANCELADO', AppColors.muted),
    _ => const _StatusInfo('EM ANÁLISE', AppColors.muted),
  };
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired();

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.lock_outline_rounded,
      title: 'Entre para acessar sua agenda',
      description: 'Suas solicitações ficam protegidas na sua conta.',
      actionLabel: 'Entrar',
      onAction: () => Navigator.pushNamed(
        context,
        LoginScreen.route,
        arguments: HistoryScreen.route,
      ),
    );
  }
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.calendar_month_outlined,
      title: 'Sua agenda está vazia',
      description: 'Encontre uma barbearia e solicite seu primeiro horário.',
      actionLabel: 'Descobrir barbearias',
      onAction: onExplore,
    );
  }
}

class _AgendaError extends StatelessWidget {
  const _AgendaError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.cloud_off_outlined,
      title: 'Não foi possível carregar sua agenda',
      description: 'Verifique a conexão e tente novamente.',
      actionLabel: 'Tentar novamente',
      onAction: onRetry,
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.orange, size: 40),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _AgendaLoading extends StatelessWidget {
  const _AgendaLoading();

  @override
  Widget build(BuildContext context) {
    return const CDRLoading.section(
      height: 132,
      message: 'Atualizando sua agenda...',
    );
  }
}

String _displayDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return value;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}
