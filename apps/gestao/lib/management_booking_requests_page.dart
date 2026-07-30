part of 'main.dart';

class _BookingRequestsPage extends StatelessWidget {
  const _BookingRequestsPage({this.adminView = false});

  final bool adminView;

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        final requests = adminView
            ? session.bookingRequests
            : session.currentBarberBookingRequests;
        final newCount =
            requests.where((request) => request.status == 'new').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricsGrid(
              cards: [
                _MetricData(
                  'Novas',
                  '$newCount',
                  Icons.mark_email_unread_rounded,
                ),
                _MetricData(
                    'Pedidos', '${requests.length}', Icons.today_rounded),
              ],
            ),
            const SizedBox(height: 28),
            _SectionTitle(
              newCount > 0 ? 'Novas solicitações' : 'Solicitações',
              eyebrow: 'PEDIDOS',
              trailing: requests.isEmpty ? null : '${requests.length} no total',
            ),
            const SizedBox(height: 12),
            if (session.isBookingRequestsLoading) ...[
              const CDRLoading.section(height: 88),
              const SizedBox(height: 12),
            ],
            if (session.bookingRequestsError != null)
              _InlineNotice(
                icon: Icons.warning_amber_rounded,
                title: 'Não foi possível carregar',
                subtitle: session.bookingRequestsError!,
                actionLabel: 'TENTAR NOVAMENTE',
                onAction: session.fetchBookingRequests,
              )
            else if (session.bookingRequestActionError != null) ...[
              _InlineNotice(
                icon: Icons.event_busy_rounded,
                title: 'Não foi possível aceitar a solicitação',
                subtitle: session.bookingRequestActionError!,
              ),
              const SizedBox(height: 12),
            ],
            if (requests.isEmpty && session.bookingRequestsError == null)
              const _InlineNotice(
                icon: Icons.inbox_rounded,
                title: 'Nenhum pedido por enquanto',
                subtitle: 'As solicitações do app cliente aparecerão aqui.',
              )
            else if (requests.isNotEmpty)
              for (final request in requests)
                _BookingRequestTile(
                  request: request,
                  total: _formatCurrency(request.total),
                  onAccepted: () => _runRequestAction(
                    context,
                    () => session.updateBookingRequestStatus(
                      request.id,
                      'converted',
                    ),
                  ),
                  onDeclined: () => _declineRequest(context, session, request),
                  onCancelled: () => _runRequestAction(
                    context,
                    () => session.updateBookingRequestStatus(
                      request.id,
                      'cancelled',
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  Future<void> _declineRequest(
    BuildContext context,
    ManagementSession session,
    BookingRequest request,
  ) async {
    final reason = await _askOptionalReason(context);
    if (!context.mounted) return;
    await _runRequestAction(
      context,
      () => session.updateBookingRequestStatus(
        request.id,
        'cancelled',
        reason: reason,
      ),
    );
  }

  Future<String?> _askOptionalReason(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(
            Icons.block_outlined,
            color: SharedAppColors.orange,
          ),
          title: const Text('Recusar solicitação'),
          content: CDRTextField(
            controller: controller,
            maxLines: 3,
            label: 'Motivo opcional',
            leading: Icons.notes_outlined,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('VOLTAR'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('RECUSAR'),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<void> _runRequestAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (!context.mounted) return;
      final message = error
          .toString()
          .replaceFirst(RegExp(r'^\s*Bad state:\s*', caseSensitive: false), '')
          .replaceFirst(RegExp(r'^\s*Exception:\s*', caseSensitive: false), '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  String _formatCurrency(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    return 'R\$ ${parts[0]},${parts[1]}';
  }
}
