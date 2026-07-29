// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void clearAuthCallbackUrl() {
  final uri = Uri.base;
  final cleanUri = Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: '/',
    queryParameters: const {'email_confirmed': '1'},
  );
  html.window.history.replaceState(null, '', cleanUri.toString());
}
