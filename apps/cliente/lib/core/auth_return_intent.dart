import 'package:flutter/foundation.dart';

class AuthReturnIntent {
  const AuthReturnIntent({
    required this.route,
    this.onAuthenticated,
  });

  final String route;
  final AsyncCallback? onAuthenticated;
}
