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
    final previousMode = currentMode;
    final previousAvailableModes = availableModes;
    final nextUserId = isSignedIn && userId?.isNotEmpty == true ? userId : null;
    final nextAvailableModes = AppModePolicy.availableModes(
      isSignedIn: isSignedIn,
      professionalRoles: professionalRoles,
    );

    final preferences = await SharedPreferences.getInstance();
    final scopedValue = nextUserId == null
        ? null
        : preferences.getString(_preferenceKey(nextUserId));
    final nextMode = AppModePolicy.resolveInitialMode(
      isSignedIn: isSignedIn,
      professionalRoles: professionalRoles,
      lastMode: AppModePolicy.parse(scopedValue),
    );

    _userId = nextUserId;
    availableModes = nextAvailableModes;
    currentMode = nextMode;

    // A preferência global anterior não pode ser herdada por outra conta no
    // mesmo dispositivo. As escolhas válidas vivem somente na chave do usuário.
    await preferences.remove(legacyPreferenceKey);
    if (nextUserId != null && scopedValue == null) {
      await preferences.setString(
        _preferenceKey(nextUserId),
        AppModePolicy.serialize(nextMode),
      );
    }

    if (previousMode != currentMode ||
        !setEquals(previousAvailableModes, availableModes)) {
      notifyListeners();
    }
  }

  Future<bool> selectMode(
    AppMode mode, {
    bool notify = true,
  }) async {
    if (!availableModes.contains(mode)) return false;
    if (currentMode == mode) return true;

    currentMode = mode;
    if (notify) notifyListeners();
    await _persistCurrentMode();
    return true;
  }

  Future<void> resetToClient() async {
    final changed = currentMode != AppMode.client ||
        !setEquals(availableModes, const {AppMode.client});
    _userId = null;
    availableModes = const {AppMode.client};
    currentMode = AppMode.client;
    if (changed) notifyListeners();
  }

  Future<void> _persistCurrentMode([
    SharedPreferences? existingPreferences,
  ]) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;

    final preferences =
        existingPreferences ?? await SharedPreferences.getInstance();
    await preferences.setString(
      _preferenceKey(userId),
      AppModePolicy.serialize(currentMode),
    );
  }

  static String _preferenceKey(String userId) => '$_preferencePrefix$userId';
}
