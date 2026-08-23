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
  const HistoryScreen({
    this.onTabSelected,
    this.isActive = true,
    super.key,
  });

  static const route = '/history';
  final ValueChanged<int>? onTabSelected;
  final bool isActive;

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
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) _refresh();
  }

  void _refresh() {
    if (!mounted || !widget.isActive) return;
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
        automaticallyImplyLeading: false,
        leadingWidth: widget.onTabSelected == null ? 68 : null,
        leading: widget.onTabSelected == null
            ? const Padding(
                padding: EdgeInsets.only(left: 16),
                child: CDRBackButton(),
              )
            : null,
        title: Text(
          'Agenda',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      bottomNavigationBar: widget.onTabSelected == null
          ? PremiumBottomNav(
              currentIndex: 2,
              onTap: (index) => _navigate(context, index),
            )
          : null,
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
                  maxWidth: CDRSizeTokens.clientFrameMaxWidth,
                ),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    CDRSpacingTokens.xxl,
                    CDRSpacingTokens.sm,
                    CDRSpacingTokens.xxl,
                    CDRSpacingTokens.xxxl,
                  ),
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
        title: const Text('Cancelar agendamento?'),
        content: const Text(
          'O horário será liberado e esta ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Manter'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancelar agendamento'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _cancellingId = appointment.id);
    final success = await state.cancelAppointment(appointment.id);
    if (!mounted) return;
    setState(() => _cancellingId = null);
    if (success) {
      CDRSnackbar.success(context, 'Agendamento cancelado.');
    } else {
      CDRSnackbar.error(
        context,
        'Não foi possível cancelar o agendamento. Tente novamente.',
      );
    }
  }

  void _navigate(BuildContext context, int index) {
    final shellSelection = widget.onTabSelected;
    if (shellSelection != null) {
      shellSelection(index);
      return;
    }
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
    return CDRCard(
      padding: const EdgeInsets.all(CDRSpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appointment.shopName.isEmpty ? 'Barbearia' : appointment.shopName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: CDRSpacingTokens.md),
          CDRStatusBadge(
            label: status.label,
            tone: status.tone,
            icon: status.icon,
            semanticLabel: status.semanticLabel,
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
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
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

class _StatusInfo {
  const _StatusInfo(
    this.label,
    this.tone,
    this.icon, {
    this.semanticLabel,
  });

  final String label;
  final CDRStatusTone tone;
  final IconData icon;
  final String? semanticLabel;
}

_StatusInfo _statusInfo(String status) {
  return switch (status) {
    'new' => const _StatusInfo(
        'Processando',
        CDRStatusTone.info,
        Icons.schedule_rounded,
        semanticLabel: 'Processando agendamento',
      ),
    'contacted' => const _StatusInfo(
        'Ação necessária',
        CDRStatusTone.warning,
        Icons.notification_important_outlined,
      ),
    'converted' => const _StatusInfo(
        'Confirmado',
        CDRStatusTone.success,
        Icons.check_circle_outline_rounded,
      ),
    'cancelled' => const _StatusInfo(
        'Cancelado',
        CDRStatusTone.neutral,
        Icons.cancel_outlined,
      ),
    _ => const _StatusInfo(
        'Em atualização',
        CDRStatusTone.neutral,
        Icons.info_outline_rounded,
      ),
  };
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired();

  @override
  Widget build(BuildContext context) {
    return CDREmptyState(
      icon: Icons.lock_outline_rounded,
      title: 'Entre para acessar sua agenda',
      message: 'Seus agendamentos ficam protegidos na sua conta.',
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
    return CDREmptyState(
      icon: Icons.calendar_month_outlined,
      title: 'Sua agenda está vazia',
      message: 'Encontre uma barbearia e agende seu primeiro horário.',
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
    return CDRErrorState(
      title: 'Não foi possível carregar sua agenda',
      message: 'Verifique sua conexão e tente novamente.',
      onRetry: onRetry,
    );
  }
}

class _AgendaLoading extends StatelessWidget {
  const _AgendaLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        CDRSpacingTokens.xxl,
        CDRSpacingTokens.sm,
        CDRSpacingTokens.xxl,
        CDRSpacingTokens.xxxl,
      ),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: CDRSpacingTokens.md),
      itemBuilder: (_, __) => const CDRCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: CDRSkeleton.line(width: 156, height: 20)),
                CDRSkeleton(width: 84, height: 28),
              ],
            ),
            SizedBox(height: CDRSpacingTokens.lg),
            CDRSkeleton.line(width: 210),
            SizedBox(height: CDRSpacingTokens.md),
            CDRSkeleton.line(width: 170),
            SizedBox(height: CDRSpacingTokens.md),
            CDRSkeleton.line(width: 130),
          ],
        ),
      ),
    );
  }
}

String _displayDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return value;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}
