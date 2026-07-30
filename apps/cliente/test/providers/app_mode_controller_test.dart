import 'package:clubedaregua/core/app_mode.dart';
import 'package:clubedaregua/providers/app_mode_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('migrates the legacy preference to a user-scoped preference', () async {
    SharedPreferences.setMockInitialValues({
      AppModeController.legacyPreferenceKey: 'barber',
    });
    final controller = AppModeController();

    await controller.synchronizeAccess(
      isSignedIn: true,
      userId: 'user-1',
      professionalRoles: const {'barber'},
    );

    expect(controller.currentMode, AppMode.barber);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('clubedaregua.last_mode.user-1'),
      'barber',
    );
  });

  test('does not restore a mode unauthorized for the current user', () async {
    SharedPreferences.setMockInitialValues({
      'clubedaregua.last_mode.user-2': 'owner',
    });
    final controller = AppModeController();

    await controller.synchronizeAccess(
      isSignedIn: true,
      userId: 'user-2',
      professionalRoles: const {'barber'},
    );

    expect(controller.currentMode, AppMode.client);
    expect(await controller.selectMode(AppMode.owner), isFalse);
  });

  test('always keeps anonymous users in discovery mode', () async {
    SharedPreferences.setMockInitialValues({
      AppModeController.legacyPreferenceKey: 'owner',
    });
    final controller = AppModeController();

    await controller.synchronizeAccess(
      isSignedIn: false,
      userId: null,
      professionalRoles: const {'owner'},
    );

    expect(controller.currentMode, AppMode.client);
    expect(controller.availableModes, const {AppMode.client});
  });
}
