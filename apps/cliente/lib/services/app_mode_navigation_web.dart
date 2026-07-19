import 'dart:html' as html;

void openProfessionalMode() {
  html.window.location.assign(Uri.base.resolve('/gestao/').toString());
}
