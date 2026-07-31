import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_mode.dart';

class AppModeController extends ChangeNotifier {
  static const legacyPreferenceKey = 'clubedaregua.last_mode';
  static const _preferencePrefix = 'clubedaregua.last_mode.';

  AppMode currentMode = AppMode.client;
  Set<AppMode> availableModes = const {AppMode.client};
  String? _userId;

  bool get canUseBarberMode => availableModes.contains(AppMode.barber);
  bool get canUseOwnerMode => availableModes.contains(AppMode.owner);

  Future<void> synchronizeAccess({
    required bool isSignedIn,
    required String? userId,
    required Set<String> professionalRoles,
  }) async {
    _userId = isSignedIn ? userId : null;
    availableModes = AppModePolicy.availableModes(
      isSignedIn: isSignedIn,
      professionalRoles: professionalRoles,
    );

    final preferences = await SharedPreferences.getInstance();
    final scopedValue = _userId == null
        ? null
        : preferences.getString(_preferenceKey(_userId!));
    final legacyValue = preferences.getString(legacyPreferenceKey);
    currentMode = AppModePolicy.resolveInitialMode(
      isSignedIn: isSignedIn,
      professionalRoles: professionalRoles,
      lastMode: AppModePolicy.parse(scopedValue ?? legacyValue),
    );

    if (_userId != null && scopedValue == null) {
      await _persistCurrentMode(preferences);
    }
    notifyListeners();
  }

  Future<bool> selectMode(
    AppMode mode, {
    bool notify = true,
  }) async {
    if (!availableModes.contains(mode)) return false;
    if (currentMode != mode) {
      currentMode = mode;
      if (notify) notifyListeners();
    }
    await _persistCurrentMode();
    return true;
  }

  Future<void> resetToClient() async {
    _userId = null;
    availableModes = const {AppMode.client};
    currentMode = AppMode.client;
    notifyListeners();
  }

  Future<void> _persistCurrentMode([
    SharedPreferences? existingPreferences,
  ]) async {
    final preferences =
        existingPreferences ?? await SharedPreferences.getInstance();
    final value = AppModePolicy.serialize(currentMode);
    await preferences.setString(legacyPreferenceKey, value);
    final userId = _userId;
    if (userId != null && userId.isNotEmpty) {
      await preferences.setString(_preferenceKey(userId), value);
    }
  }

  static String _preferenceKey(String userId) => '$_preferencePrefix$userId';
}
