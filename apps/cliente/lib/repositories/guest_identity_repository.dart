import 'package:shared_preferences/shared_preferences.dart';

class GuestIdentity {
  const GuestIdentity({
    required this.name,
    required this.phone,
    required this.remember,
  });

  final String name;
  final String phone;
  final bool remember;
}

class GuestIdentityRepository {
  const GuestIdentityRepository();

  static const _nameKey = 'clubedaregua.guest.name';
  static const _phoneKey = 'clubedaregua.guest.phone';
  static const _rememberKey = 'clubedaregua.guest.remember';

  Future<GuestIdentity> load() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_rememberKey) ?? true;
    return GuestIdentity(
      name: remember ? prefs.getString(_nameKey) ?? '' : '',
      phone: remember ? prefs.getString(_phoneKey) ?? '' : '',
      remember: remember,
    );
  }

  Future<void> save({
    required String name,
    required String phone,
    required bool remember,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, remember);
    if (!remember) {
      await prefs.remove(_nameKey);
      await prefs.remove(_phoneKey);
      return;
    }
    await prefs.setString(_nameKey, name.trim());
    await prefs.setString(_phoneKey, phone.trim());
  }
}
