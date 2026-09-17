import 'package:clubedaregua/core/app_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppModePolicy', () {
    test('keeps discovery as the only anonymous mode', () {
      final modes = AppModePolicy.availableModes(
        isSignedIn: false,
        professionalRoles: const {'barber', 'owner'},
      );

      expect(modes, const {AppMode.client});
    });

    test('maps professional roles without granting permissions', () {
      expect(
        AppModePolicy.availableModes(
          isSignedIn: true,
          professionalRoles: const {'barber'},
        ),
        const {AppMode.client, AppMode.barber},
      );
      expect(
        AppModePolicy.availableModes(
          isSignedIn: true,
          professionalRoles: const {'manager'},
        ),
        const {AppMode.client, AppMode.owner},
      );
      expect(
        AppModePolicy.availableModes(
          isSignedIn: true,
          professionalRoles: const {'barber', 'owner'},
        ),
        const {AppMode.client, AppMode.barber, AppMode.owner},
      );
    });

    test('restores only an authorized last mode', () {
      expect(
        AppModePolicy.resolveInitialMode(
          isSignedIn: true,
          professionalRoles: const {'barber'},
          lastMode: AppMode.barber,
        ),
        AppMode.barber,
      );
      expect(
        AppModePolicy.resolveInitialMode(
          isSignedIn: true,
          professionalRoles: const {'barber'},
          lastMode: AppMode.owner,
        ),
        AppMode.client,
      );
    });
  });
}
