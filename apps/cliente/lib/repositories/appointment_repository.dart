import '../models/appointment.dart';
import '../services/auth_service.dart';
import '../services/mock_data.dart';
import '../services/supabase_rest_service.dart';

class AppointmentRepository {
  const AppointmentRepository({SupabaseRestService? rest})
      : _rest = rest ?? const SupabaseRestService();

  final SupabaseRestService _rest;

  Future<List<Appointment>> fetchAppointments() async {
    if (!_rest.isConfigured) return const [];
    final session = await _authenticatedSession();
    if (session == null) return const [];

    final rows = await _rest.getRows(
      'booking_requests',
      select:
          'id,requested_date,requested_time,status,total_price,barbers(name),services(name),barber_shops(name)',
      filters: {'client_id': 'eq.${session.user.id}'},
      order: 'requested_date.desc,requested_time.desc',
      accessToken: session.accessToken,
    );
    return rows.map(Appointment.fromMap).toList();
  }

  Future<bool> createAppointment({
    required String barberId,
    required String serviceId,
    required DateTime date,
    required String time,
    required double total,
    required String barberShopId,
    required String customerName,
    required String customerPhone,
    required String paymentMethodLabel,
  }) async {
    if (!_rest.isConfigured || barberShopId.isEmpty) return false;

    try {
      final session = await _authenticatedSession();
      final hasConflict = await hasBookingConflict(
        barberId: barberId,
        date: date,
        time: time,
      );
      if (hasConflict) return false;

      return await _rest.insertRow('booking_requests', {
        'barber_shop_id': barberShopId,
        if (session != null) 'client_id': session.user.id,
        'barber_id': barberId,
        'service_id': serviceId,
        'requested_date': _dateOnly(date),
        'requested_time': time,
        'customer_name': customerName.trim(),
        'customer_phone': customerPhone.trim(),
        'total_price': total,
        'notes':
            'Solicitacao criada pelo PWA Cliente. Pagamento: $paymentMethodLabel',
      }, accessToken: session?.accessToken);
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> fetchAvailableTimes({
    required String barberId,
    required String barberShopId,
    required DateTime date,
    required int durationMinutes,
  }) async {
    if (!_rest.isConfigured || barberId.isEmpty || barberShopId.isEmpty) {
      return MockData.times;
    }

    try {
      final weekday = date.weekday == DateTime.sunday ? 0 : date.weekday;
      final schedules = await _rest.getRows(
        'schedules',
        select: 'start_time,end_time,slot_minutes',
        filters: {
          'barber_id': 'eq.$barberId',
          'weekday': 'eq.$weekday',
          'is_active': 'eq.true',
        },
        order: 'start_time.asc',
      );

      if (schedules.isEmpty) return const [];

      final blockedTimes = await _blockedIntervals(
        table: 'blocked_times',
        barberId: barberId,
        date: date,
        startsColumn: 'starts_at',
        endsColumn: 'ends_at',
        extraFilters: const {},
      );
      final appointments = await _blockedIntervals(
        table: 'appointment_availability',
        barberId: barberId,
        date: date,
        startsColumn: 'starts_at',
        endsColumn: 'ends_at',
        extraFilters: const {},
      );
      final requests = await _bookingRequestIntervals(
        barberId: barberId,
        date: date,
        durationMinutes: durationMinutes,
      );

      final blocked = [...blockedTimes, ...appointments, ...requests];
      final times = <String>[];
      final now = DateTime.now();
      final selectedDay = DateTime(date.year, date.month, date.day);
      final today = DateTime(now.year, now.month, now.day);

      for (final schedule in schedules) {
        final start = _timeOfDay(schedule['start_time']?.toString());
        final end = _timeOfDay(schedule['end_time']?.toString());
        final slotMinutes =
            (schedule['slot_minutes'] as num?)?.toInt() ?? 30;
        if (start == null ||
            end == null ||
            slotMinutes <= 0 ||
            durationMinutes <= 0) {
          continue;
        }

        final startMinutes = start.hour * 60 + start.minute;
        final endMinutes = end.hour * 60 + end.minute;

        for (var minute = startMinutes;
            minute + durationMinutes <= endMinutes;
            minute += slotMinutes) {
          final slotStart = DateTime(
            date.year,
            date.month,
            date.day,
            minute ~/ 60,
            minute % 60,
          );
          final slotEnd = slotStart.add(Duration(minutes: durationMinutes));
          final isPast = selectedDay.isAtSameMomentAs(today) &&
              !slotStart.isAfter(now);
          final conflicts = blocked.any(
            (interval) => _overlaps(
              slotStart,
              slotEnd,
              interval.start,
              interval.end,
            ),
          );

          if (!isPast && !conflicts) times.add(_formatTime(slotStart));
        }
      }

      return times.toSet().toList()..sort();
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> hasBookingConflict({
    required String barberId,
    required DateTime date,
    required String time,
  }) async {
    if (!_rest.isConfigured) return false;

    try {
      return await _rest.exists(
        'booking_request_availability',
        filters: {
          'barber_id': 'eq.$barberId',
          'requested_date': 'eq.${_dateOnly(date)}',
          'requested_time': 'eq.$time',
          'status': 'in.(new,contacted)',
        },
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    if (!_rest.isConfigured || appointmentId.isEmpty) return false;
    final session = await _authenticatedSession();
    if (session == null) return false;
    return _rest.updateRows(
      'booking_requests',
      data: const {'status': 'cancelled'},
      filters: {
        'id': 'eq.$appointmentId',
        'client_id': 'eq.${session.user.id}',
        'status': 'in.(new,contacted)',
      },
      accessToken: session.accessToken,
    );
  }

  String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<AuthSession?> _authenticatedSession() async {
    final auth = AuthService();
    var session = auth.currentSession ?? await auth.restoreSession();
    if (session?.isExpired == true) {
      session = await auth.refreshSession();
    }
    return session;
  }

  Future<List<_Interval>> _blockedIntervals({
    required String table,
    required String barberId,
    required DateTime date,
    required String startsColumn,
    required String endsColumn,
    required Map<String, String> extraFilters,
  }) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final rows = await _rest.getRows(
        table,
        select: '$startsColumn,$endsColumn',
        filters: {
          'barber_id': 'eq.$barberId',
          startsColumn: 'lt.${end.toIso8601String()}',
          endsColumn: 'gt.${start.toIso8601String()}',
          ...extraFilters,
        },
      );

      return rows
          .map(
            (row) => _Interval(
              DateTime.parse(row[startsColumn].toString()).toLocal(),
              DateTime.parse(row[endsColumn].toString()).toLocal(),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<_Interval>> _bookingRequestIntervals({
    required String barberId,
    required DateTime date,
    required int durationMinutes,
  }) async {
    try {
      final rows = await _rest.getRows(
        'booking_request_availability',
        select: 'requested_time,duration_minutes',
        filters: {
          'barber_id': 'eq.$barberId',
          'requested_date': 'eq.${_dateOnly(date)}',
          'status': 'in.(new,contacted)',
        },
      );

      return rows.map((row) {
        final time = _timeOfDay(row['requested_time']?.toString());
        final start = _dateTimeFor(date, time ?? const _TimeParts(0, 0));
        final existingDuration =
            (row['duration_minutes'] as num?)?.toInt() ?? durationMinutes;
        return _Interval(
          start,
          start.add(Duration(minutes: existingDuration)),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  _TimeParts? _timeOfDay(String? value) {
    if (value == null || value.length < 5) return null;
    final parts = value.substring(0, 5).split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return _TimeParts(hour, minute);
  }

  DateTime _dateTimeFor(DateTime date, _TimeParts time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _overlaps(
    DateTime start,
    DateTime end,
    DateTime otherStart,
    DateTime otherEnd,
  ) {
    return start.isBefore(otherEnd) && end.isAfter(otherStart);
  }
}

class _Interval {
  const _Interval(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

class _TimeParts {
  const _TimeParts(this.hour, this.minute);

  final int hour;
  final int minute;
}
