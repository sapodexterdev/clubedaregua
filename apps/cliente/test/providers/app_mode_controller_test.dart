import 'package:clubedaregua/core/app_mode.dart';
import 'package:clubedaregua/providers/app_mode_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ignores and removes the legacy preference for an authenticated user',
      () async {
    SharedPreferences.setMockInitialValues({
      AppModeController.legacyPreferenceKey: 'barber',
    });
    final controller = AppModeController();

    await controller.synchronizeAccess(
      isSignedIn: true,
      userId: 'user-1',
      professionalRoles: const {'barber'},
    );

    expect(controller.currentMode, AppMode.client);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('clubedaregua.last_mode.user-1'),
      'client',
    );
    expect(
      preferences.getString(AppModeController.legacyPreferenceKey),
      isNull,
    );
  });

  test('keeps the last mode isolated between two users', () async {
    SharedPreferences.setMockInitialValues({
      'clubedaregua.last_mode.user-a': 'owner',
      AppModeController.legacyPreferenceKey: 'barber',
    });
    final controller = AppModeController();

    await controller.synchronizeAccess(
      isSignedIn: true,
      userId: 'user-a',
      professionalRoles: const {'owner', 'barber'},
    );
    expect(controller.currentMode, AppMode.owner);

    await controller.synchronizeAccess(
      isSignedIn: true,
      userId: 'user-b',
      professionalRoles: const {'owner', 'barber'},
    );
    expect(controller.currentMode, AppMode.client);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('clubedaregua.last_mode.user-a'), 'owner');
    expect(preferences.getString('clubedaregua.last_mode.user-b'), 'client');
    expect(
      preferences.getString(AppModeController.legacyPreferenceKey),
      isNull,
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
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(AppModeController.legacyPreferenceKey),
      isNull,
    );
  });

  test('synchronizeAccess only notifies when observable state changes',
      () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppModeController();
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.synchronizeAccess(
      isSignedIn: false,
      userId: null,
      professionalRoles: const {},
    );
    expect(notifications, 0);

    await controller.synchronizeAccess(
      isSignedIn: true,
      userId: 'barber-user',
      professionalRoles: const {'barber'},
    );
    expect(notifications, 1);

    await controller.synchronizeAccess(
      isSignedIn: true,
      userId: 'barber-user',
      professionalRoles: const {'barber'},
    );
    expect(notifications, 1);
  });

  test('selectMode does not notify or persist when mode is already active',
      () async {
    SharedPreferences.setMockInitialValues({
      'clubedaregua.last_mode.owner-user': 'owner',
    });
    final controller = AppModeController();
    await controller.synchronizeAccess(
      isSignedIn: true,
      userId: 'owner-user',
      professionalRoles: const {'owner'},
    );
    var notifications = 0;
    controller.addListener(() => notifications++);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('clubedaregua.last_mode.owner-user', 'client');

    expect(await controller.selectMode(AppMode.owner), isTrue);
    expect(notifications, 0);
    expect(
      preferences.getString('clubedaregua.last_mode.owner-user'),
      'client',
    );
  });

  test('persists repeated professional switches without rebuilding the app',
      () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppModeController();

    await controller.synchronizeAccess(
      isSignedIn: true,
      userId: 'professional-user',
      professionalRoles: const {'barber', 'owner'},
    );

    var notifications = 0;
    controller.addListener(() => notifications++);

    for (var index = 0; index < 10; index++) {
      final mode = index.isEven ? AppMode.owner : AppMode.barber;
      expect(
        await controller.selectMode(mode, notify: false),
        isTrue,
      );
    }

    expect(notifications, 0);
    expect(controller.currentMode, AppMode.barber);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(AppModeController.legacyPreferenceKey),
      isNull,
    );
    expect(
      preferences.getString('clubedaregua.last_mode.professional-user'),
      'barber',
    );
  });
}
