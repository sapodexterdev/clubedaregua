import 'dart:html' as html;

void openClientMode() {
  html.window.location.assign(Uri.base.resolve('/?mode=client').toString());
}
