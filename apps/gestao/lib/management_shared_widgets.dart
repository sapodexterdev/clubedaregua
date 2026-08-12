part of 'management.dart';

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.eyebrow,
    required this.title,
    required this.onClose,
  });

  final String eyebrow;
  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: SharedAppColors.orange,
                  fontSize: 9,
                  letterSpacing: 1.25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Fechar',
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
          style: IconButton.styleFrom(
            backgroundColor: SharedAppColors.elevated,
            foregroundColor: SharedAppColors.muted,
            side: const BorderSide(color: SharedAppColors.stroke),
          ),
        ),
      ],
    );
  }
}

class _ResponsiveFieldRow extends StatelessWidget {
  const _ResponsiveFieldRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 560;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index < children.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _CDRSwitch extends StatelessWidget {
  const _CDRSwitch({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Semantics(
      label: semanticLabel,
      toggled: value,
      enabled: enabled,
      button: true,
      child: Opacity(
        opacity: enabled ? 1 : .48,
        child: InkWell(
          onTap: enabled ? () => onChanged!(!value) : null,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 58,
            height: 48,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: 52,
                height: 30,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: value ? SharedAppColors.orange : SharedAppColors.dark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        value ? SharedAppColors.orange : SharedAppColors.stroke,
                  ),
                  boxShadow: value
                      ? [
                          BoxShadow(
                            color: SharedAppColors.orange.withOpacity(.18),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment:
                      value ? Alignment.centerRight : Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: value
                          ? SharedAppColors.onGold
                          : SharedAppColors.muted,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: value
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: SharedAppColors.orange,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CDRToggleTile extends StatelessWidget {
  const _CDRToggleTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return InkWell(
      onTap: enabled ? () => onChanged!(!value) : null,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Opacity(
                opacity: enabled ? 1 : .55,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _CDRSwitch(
              value: value,
              onChanged: onChanged,
              semanticLabel: title,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: SharedAppColors.dark,
            labelStyle: const TextStyle(color: SharedAppColors.muted),
            helperStyle: const TextStyle(color: SharedAppColors.muted),
            prefixIconColor: SharedAppColors.orange,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SharedAppColors.stroke),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SharedAppColors.orange),
            ),
          ),
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: SharedAppColors.text,
                displayColor: SharedAppColors.text,
              ),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: SharedAppColors.text),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _BusinessDayEditor extends StatelessWidget {
  const _BusinessDayEditor({
    required this.day,
    required this.onChanged,
  });

  final ShopBusinessDay day;
  final ValueChanged<ShopBusinessDay> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          _CDRToggleTile(
            value: day.isOpen,
            title: day.label,
            subtitle: day.isOpen ? 'Aberto' : 'Fechado',
            onChanged: (value) => onChanged(day.copyWith(isOpen: value)),
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  enabled: day.isOpen,
                  initialValue: day.openTime,
                  decoration: const InputDecoration(labelText: 'Abertura'),
                  validator: (value) {
                    if (!day.isOpen) return null;
                    if (value == null ||
                        !RegExp(r'^\d{2}:\d{2}$').hasMatch(value.trim())) {
                      return 'HH:mm';
                    }
                    return null;
                  },
                  onChanged: (value) =>
                      onChanged(day.copyWith(openTime: value.trim())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  enabled: day.isOpen,
                  initialValue: day.closeTime,
                  decoration: const InputDecoration(labelText: 'Fechamento'),
                  validator: (value) {
                    if (!day.isOpen) return null;
                    if (value == null ||
                        !RegExp(r'^\d{2}:\d{2}$').hasMatch(value.trim())) {
                      return 'HH:mm';
                    }
                    return null;
                  },
                  onChanged: (value) =>
                      onChanged(day.copyWith(closeTime: value.trim())),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.cards});

  final List<_MetricData> cards;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? cards.length.clamp(1, 4)
              : cards.length == 1
                  ? 1
                  : 2;
          final width = (constraints.maxWidth - ((columns - 1) * 10)) / columns;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final card in cards)
                SizedBox(width: width, child: _MetricCard(data: card)),
            ],
          );
        },
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: SharedAppColors.orange.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: SharedAppColors.orange, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 3),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.eyebrow, this.trailing});

  final String title;
  final String? eyebrow;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!,
                  style: const TextStyle(
                    color: SharedAppColors.orange,
                    fontSize: 9,
                    letterSpacing: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: SharedAppColors.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: SharedAppColors.stroke),
            ),
            child: Text(
              trailing!,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _IconBadge(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            CDRButton.outlined(
              label: actionLabel!,
              onPressed: onAction,
              leading: const Icon(Icons.refresh_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({
    required this.entry,
    required this.showBarber,
    required this.onTap,
  });

  final ScheduleEntry entry;
  final bool showBarber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = entry.status.toLowerCase();
    final statusColor = normalizedStatus.contains('conclu')
        ? CDRColorTokens.success
        : normalizedStatus.contains('cancel')
            ? CDRColorTokens.error
            : normalizedStatus.contains('confirm') ||
                    normalizedStatus.contains('aceito')
                ? CDRColorTokens.info
                : SharedAppColors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _TimeBadge(entry.time),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.client,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      entry.service,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (showBarber) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 14,
                            color: SharedAppColors.muted,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              entry.barber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 104),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      entry.status.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        letterSpacing: .3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: SharedAppColors.muted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingRequestTile extends StatelessWidget {
  const _BookingRequestTile({
    required this.request,
    required this.total,
    required this.onAccepted,
    required this.onDeclined,
    required this.onCancelled,
  });

  final BookingRequest request;
  final String total;
  final VoidCallback onAccepted;
  final VoidCallback onDeclined;
  final VoidCallback onCancelled;

  @override
  Widget build(BuildContext context) {
    final status = request.status;
    final isClosed = status == 'converted' || status == 'cancelled';
    final wasDeclined =
        status == 'cancelled' && request.notes.contains('Motivo:');
    final statusLabel = switch (status) {
      'contacted' => 'Contatado',
      'converted' => 'Aceito',
      'cancelled' => wasDeclined ? 'Recusado' : 'Cancelado',
      _ => 'Novo',
    };
    final statusColor = switch (status) {
      'contacted' => CDRColorTokens.info,
      'converted' => CDRColorTokens.success,
      'cancelled' => CDRColorTokens.error,
      _ => SharedAppColors.orange,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 2,
            color: isClosed ? SharedAppColors.stroke : statusColor,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ClientAvatar(photoUrl: request.clientPhotoUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.client,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.phone.isEmpty
                                ? 'Telefone não informado'
                                : request.phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(total,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              letterSpacing: .4,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 6),
                _RequestInfoRow(
                  icon: Icons.content_cut_rounded,
                  label: 'Serviço',
                  value: request.service,
                ),
                _RequestInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Barbeiro',
                  value: request.barber,
                ),
                _RequestInfoRow(
                  icon: Icons.event_rounded,
                  label: 'Data e horário',
                  value: request.formattedDateTime,
                ),
                _RequestInfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Pagamento',
                  value: request.paymentMethod,
                ),
                _RequestInfoRow(
                  icon: Icons.notes_rounded,
                  label: 'Observações',
                  value: request.observation,
                ),
                if (!isClosed) ...[
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 430;
                      final decline = CDRButton.outlined(
                        label: 'RECUSAR',
                        onPressed: onDeclined,
                        isExpanded: compact,
                        leading: const Icon(Icons.block_rounded),
                      );
                      final accept = CDRButton.primary(
                        label: 'ACEITAR',
                        onPressed: onAccepted,
                        isExpanded: compact,
                        leading: const Icon(Icons.check_rounded),
                      );
                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            accept,
                            const SizedBox(height: 10),
                            decline,
                            const SizedBox(height: 4),
                            TextButton.icon(
                              onPressed: onCancelled,
                              icon: const Icon(Icons.close_rounded),
                              label: const Text('Cancelar solicitação'),
                            ),
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: onCancelled,
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          decline,
                          const SizedBox(width: 10),
                          accept,
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientAvatar extends StatelessWidget {
  const _ClientAvatar({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(photoUrl),
        backgroundColor: SharedAppColors.orange.withOpacity(.12),
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: SharedAppColors.orange.withOpacity(.12),
      child: const Icon(Icons.person_rounded, color: SharedAppColors.orange),
    );
  }
}

class _RequestInfoRow extends StatelessWidget {
  const _RequestInfoRow({
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
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: SharedAppColors.muted),
          const SizedBox(width: 8),
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: SharedAppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  const _TimeBadge(this.time);

  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SharedAppColors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SharedAppColors.orange.withOpacity(.22),
        ),
      ),
      child: Text(
        time,
        style: const TextStyle(
          color: SharedAppColors.orange,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.day, required this.hours});

  final String day;
  final String hours;

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      leading: const _IconBadge(Icons.schedule_rounded),
      title: day,
      subtitle: hours,
      trailing: const _AvailabilityStatus(
        label: 'ABERTO',
        color: CDRColorTokens.success,
      ),
    );
  }
}

class _BlockedTile extends StatelessWidget {
  const _BlockedTile({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      leading: const _IconBadge(Icons.block_rounded),
      title: title,
      subtitle: detail,
      trailing: const _AvailabilityStatus(
        label: 'BLOQUEADO',
        color: CDRColorTokens.error,
      ),
    );
  }
}

class _AvailabilityStatus extends StatelessWidget {
  const _AvailabilityStatus({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9,
          letterSpacing: .4,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({
    required this.customer,
    required this.onTap,
  });

  final ManagedCustomer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = customer.isBlocked
        ? CDRColorTokens.error
        : customer.blockedBarberIds.isNotEmpty
            ? SharedAppColors.orange
            : CDRColorTokens.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              _CustomerAvatar(customer: customer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      customer.phone.isEmpty
                          ? 'Telefone não informado'
                          : customer.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Último atendimento: ${customer.lastAppointmentLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _AvailabilityStatus(
                    label: customer.appointmentCount == 1
                        ? '1 ATENDIMENTO'
                        : '${customer.appointmentCount} ATEND.',
                    color: SharedAppColors.orange,
                  ),
                  const SizedBox(height: 6),
                  _AvailabilityStatus(
                    label: customer.statusLabel.toUpperCase(),
                    color: statusColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerAvatar extends StatelessWidget {
  const _CustomerAvatar({
    required this.customer,
    this.radius = 25,
  });

  final ManagedCustomer customer;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          customer.isActive ? SharedAppColors.orange : SharedAppColors.muted,
      backgroundImage:
          customer.avatarUrl.isEmpty ? null : NetworkImage(customer.avatarUrl),
      child: customer.avatarUrl.isEmpty
          ? const Icon(Icons.person_rounded, color: Colors.white)
          : null,
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.onTap,
  });

  final ManagedService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        service.isActive ? CDRColorTokens.success : CDRColorTokens.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SharedAppColors.stroke),
            ),
            child: Row(
              children: [
                service.imageUrl.isEmpty
                    ? const _IconBadge(Icons.content_cut_rounded)
                    : CircleAvatar(
                        radius: 27,
                        backgroundColor:
                            SharedAppColors.orange.withOpacity(0.12),
                        backgroundImage: NetworkImage(service.imageUrl),
                      ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${service.categoryName} • ${service.durationLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      _AvailabilityStatus(
                        label: service.statusLabel.toUpperCase(),
                        color: statusColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      service.formattedPrice,
                      style: const TextStyle(
                        color: SharedAppColors.orange,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      service.appointmentCount == 1
                          ? '1 agendamento'
                          : '${service.appointmentCount} agendamentos',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: SharedAppColors.muted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamBarberTile extends StatelessWidget {
  const _TeamBarberTile({
    required this.barber,
    required this.onTap,
  });

  final TeamBarber barber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundColor:
            barber.isActive ? SharedAppColors.dark : SharedAppColors.muted,
        backgroundImage:
            barber.photoUrl.isEmpty ? null : NetworkImage(barber.photoUrl),
        child: barber.photoUrl.isEmpty
            ? const Icon(Icons.person_rounded, color: Colors.white)
            : null,
      ),
      title: barber.name,
      subtitle: '${barber.role} - ${barber.detail}',
      trailing: IconButton(
        tooltip: 'Editar barbeiro',
        onPressed: onTap,
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _CashMovementTile extends StatelessWidget {
  const _CashMovementTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isPositive = value.trim().startsWith('+');
    return _SurfaceTile(
      leading: _IconBadge(
        isPositive ? Icons.south_west_rounded : Icons.north_east_rounded,
      ),
      title: title,
      subtitle: isPositive ? 'Entrada' : 'Saída',
      trailing: Text(
        value,
        style: TextStyle(
          color: isPositive ? CDRColorTokens.success : CDRColorTokens.error,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({required this.name, required this.quantity});

  final String name;
  final String quantity;

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      leading: const _IconBadge(Icons.inventory_2_rounded),
      title: name,
      subtitle: 'Reposição recomendada',
      trailing: Text(
        quantity,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      leading: const _IconBadge(Icons.insights_rounded),
      title: value,
      subtitle: '$title · $subtitle',
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
    this.onPressed,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final content = Row(
          children: [
            _IconBadge(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        );

        final action = onPressed == null
            ? const _AvailabilityStatus(
                label: 'EM BREVE',
                color: SharedAppColors.muted,
              )
            : CDRButton.primary(
                label: buttonLabel.toUpperCase(),
                onPressed: onPressed,
                isExpanded: compact,
              );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SharedAppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SharedAppColors.stroke),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    content,
                    const SizedBox(height: 16),
                    action,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 16),
                    action,
                  ],
                ),
        );
      },
    );
  }
}

class _SurfaceTile extends StatelessWidget {
  const _SurfaceTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: SharedAppColors.muted),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SharedAppColors.orange.withOpacity(.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: SharedAppColors.orange, size: 21),
    );
  }
}
