import 'dart:async';
import 'dart:io';

import 'package:clubedaregua/providers/app_state.dart';
import 'package:clubedaregua/repositories/appointment_repository.dart';
import 'package:clubedaregua/services/supabase_rest_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppointmentRepository availability', () {
    for (final failingTable in const [
      'schedules',
      'booking_interval_availability',
      'booking_request_availability',
    ]) {
      test('fails closed when $failingTable cannot be read', () async {
        final repository = AppointmentRepository(
          rest: _AvailabilityRest(failingTable: failingTable),
        );

        await expectLater(
          repository.fetchAvailableTimes(
            barberId: 'barber-1',
            barberShopId: 'shop-1',
            date: DateTime(2035, 8, 25),
            durationMinutes: 60,
          ),
          throwsA(isA<StateError>()),
        );
      });
    }

    test('does not expose mock slots when Supabase is unavailable', () async {
      final repository = AppointmentRepository(rest: _UnconfiguredRest());

      await expectLater(
        repository.fetchAvailableTimes(
          barberId: 'barber-1',
          barberShopId: 'shop-1',
          date: DateTime(2035, 8, 25),
          durationMinutes: 60,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('removes every overlapping slot and keeps adjacent slots', () async {
      final rest = _AvailabilityRest(
        rows: {
          'booking_interval_availability': [
            {
              'starts_at': '2035-08-25T09:30:00',
              'ends_at': '2035-08-25T10:30:00',
            },
          ],
        },
      );
      final repository = AppointmentRepository(rest: rest);

      final times = await repository.fetchAvailableTimes(
        barberId: 'barber-1',
        barberShopId: 'shop-1',
        date: DateTime(2035, 8, 25),
        durationMinutes: 60,
      );

      expect(times, ['10:30', '11:00']);
      expect(
        rest.filtersByTable['booking_interval_availability']?['or'],
        '(barber_id.eq.barber-1,barber_id.is.null)',
      );
    });
  });

  group('AppState availability selection', () {
    test('keeps the reviewed time visible while revalidation is pending',
        () async {
      final repository = _PendingAvailabilityRepository();
      final state = AppState(appointmentRepository: repository)
        ..availableTimes = ['10:30']
        ..selectedTime = '10:30';
      addTearDown(state.dispose);

      final refresh = state.refreshAvailableTimes(
        preserveSelectedTime: true,
        selectFirstAvailable: false,
      );
      await repository.requestStarted.future;

      expect(state.isLoadingAvailability, isTrue);
      expect(state.selectedTime, '10:30');
      expect(state.hasValidSelectedTime, isFalse);

      repository.response.complete(['10:30']);
      await refresh;
    });

    test('clears a preserved time when it is no longer available', () async {
      final state = AppState(
        appointmentRepository: _FixedAvailabilityRepository(['11:00']),
      )..selectedTime = '10:30';
      addTearDown(state.dispose);

      await state.refreshAvailableTimes(
        preserveSelectedTime: true,
        selectFirstAvailable: false,
      );

      expect(state.availableTimes, ['11:00']);
      expect(state.selectedTime, isEmpty);
      expect(state.hasValidSelectedTime, isFalse);
    });

    test('keeps a preserved time only while it remains in the fresh list',
        () async {
      final state = AppState(
        appointmentRepository: _FixedAvailabilityRepository(['10:30', '11:00']),
      )..selectedTime = '10:30';
      addTearDown(state.dispose);

      await state.refreshAvailableTimes(
        preserveSelectedTime: true,
        selectFirstAvailable: false,
      );

      expect(state.selectedTime, '10:30');
      expect(state.hasValidSelectedTime, isTrue);
    });

    test('rejects a time that is not in the current availability list', () {
      final state = AppState(
        appointmentRepository: _FixedAvailabilityRepository(const []),
      )
        ..availableTimes = ['11:00']
        ..selectedTime = '';
      addTearDown(state.dispose);

      state.selectTime('10:30');

      expect(state.selectedTime, isEmpty);
    });
  });

  test('database hardening covers overlap, locks and public bypass', () {
    final migration = File(
      '../../supabase/issue_024_booking_availability_integrity.sql',
    ).readAsStringSync();

    expect(migration, contains('pg_advisory_xact_lock'));
    expect(migration, contains('appointment.starts_at < new.ends_at'));
    expect(migration, contains('appointment.ends_at > new.starts_at'));
    expect(migration, contains('prevent_booking_request_conflict'));
    expect(migration, contains('lock_blocked_time_schedule'));
    expect(migration, contains('booking_interval_availability'));
    expect(migration, contains('at time zone\n    coalesce'));
    expect(
      migration,
      contains('barber.barber_shop_id = blocked.barber_shop_id'),
    );
    expect(migration, contains('auto_confirm_booking_request'));
    expect(
      migration,
      contains('drop policy if exists appointments_insert_client'),
    );
    expect(
      migration,
      contains('drop policy if exists appointments_insert_staff'),
    );
  });
}

class _AvailabilityRest extends SupabaseRestService {
  _AvailabilityRest({this.failingTable, this.rows = const {}});

  final String? failingTable;
  final Map<String, List<Map<String, dynamic>>> rows;
  final Map<String, Map<String, String>> filtersByTable = {};

  @override
  bool get isConfigured => true;

  @override
  Future<List<Map<String, dynamic>>> getRows(
    String table, {
    required String select,
    Map<String, String> filters = const {},
    String? order,
    int? limit,
    String? accessToken,
  }) async {
    filtersByTable[table] = filters;
    if (table == failingTable) throw StateError('Falha simulada em $table');
    if (table == 'schedules') {
      return const [
        {
          'start_time': '09:00:00',
          'end_time': '12:00:00',
          'slot_minutes': 30,
        },
      ];
    }
    return rows[table] ?? const [];
  }
}

class _UnconfiguredRest extends SupabaseRestService {
  @override
  bool get isConfigured => false;
}

class _FixedAvailabilityRepository extends AppointmentRepository {
  _FixedAvailabilityRepository(this.times);

  final List<String> times;

  @override
  Future<List<String>> fetchAvailableTimes({
    required String barberId,
    required String barberShopId,
    required DateTime date,
    required int durationMinutes,
  }) async =>
      times;
}

class _PendingAvailabilityRepository extends AppointmentRepository {
  final requestStarted = Completer<void>();
  final response = Completer<List<String>>();

  @override
  Future<List<String>> fetchAvailableTimes({
    required String barberId,
    required String barberShopId,
    required DateTime date,
    required int durationMinutes,
  }) {
    requestStarted.complete();
    return response.future;
  }
}
