import 'dart:html' as html;

const appLastModeKey = 'clubedaregua.last_mode';

void openBarberMode() {
  _openProfessionalMode('barber');
}

void openOwnerMode() {
  _openProfessionalMode('owner');
}

void _openProfessionalMode(String mode) {
  html.window.location.assign(
    Uri.base.resolve('/gestao/?mode=$mode').toString(),
  );
}
