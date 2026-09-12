enum AppMode { client, barber, owner }

class AppModePolicy {
  const AppModePolicy._();

  static Set<AppMode> availableModes({
    required bool isSignedIn,
    required Set<String> professionalRoles,
  }) {
    final modes = <AppMode>{AppMode.client};
    if (!isSignedIn) return modes;

    if (professionalRoles.contains('barber')) {
      modes.add(AppMode.barber);
    }
    if (professionalRoles.any(
      (role) => const {'owner', 'manager', 'admin'}.contains(role),
    )) {
      modes.add(AppMode.owner);
    }
    return modes;
  }

  static AppMode resolveInitialMode({
    required bool isSignedIn,
    required Set<String> professionalRoles,
    AppMode? lastMode,
  }) {
    final available = availableModes(
      isSignedIn: isSignedIn,
      professionalRoles: professionalRoles,
    );
    return lastMode != null && available.contains(lastMode)
        ? lastMode
        : AppMode.client;
  }

  static AppMode? parse(String? value) {
    return switch (value) {
      'client' => AppMode.client,
      'barber' => AppMode.barber,
      'owner' => AppMode.owner,
      _ => null,
    };
  }

  static String serialize(AppMode mode) => mode.name;
}
