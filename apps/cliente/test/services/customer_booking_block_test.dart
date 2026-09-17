import 'package:clubedaregua_gestao/management.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ManagedCustomer booking blocks', () {
    test('distinguishes a general block from a barber-specific block', () {
      final customer = _customer();

      final general = customer.copyWith(isBlocked: true);
      final specific = customer.copyWith(
        blockedBarberIds: {'barber-1', 'barber-2'},
      );

      expect(general.hasBookingBlock, isTrue);
      expect(general.statusLabel, 'Bloqueado');
      expect(specific.hasBookingBlock, isTrue);
      expect(specific.isBlocked, isFalse);
      expect(specific.blockedBarberIds, hasLength(2));
      expect(specific.statusLabel, 'Restrito');
    });

    test('removing the scope restores booking access', () {
      final blocked = _customer().copyWith(
        isBlocked: true,
        blockedBarberIds: {'barber-1'},
      );

      final allowed = blocked.copyWith(
        isBlocked: false,
        blockedBarberIds: <String>{},
      );

      expect(allowed.hasBookingBlock, isFalse);
      expect(allowed.statusLabel, 'Ativo');
    });
  });
}

ManagedCustomer _customer() => const ManagedCustomer(
      relationshipId: 'relationship-1',
      clientId: 'client-1',
      name: 'Cliente',
      phone: '(11) 99999-9999',
      email: 'cliente@example.com',
      avatarUrl: '',
      createdAt: null,
      firstSeenAt: null,
      lastAppointmentAt: null,
      notes: '',
      isBlocked: false,
      blockedBarberIds: <String>{},
      appointmentCount: 0,
      favoriteBarber: 'Não definido',
    );
