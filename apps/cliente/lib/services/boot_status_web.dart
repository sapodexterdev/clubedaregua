import 'dart:js_interop';

@JS('hideBootStatus')
external void _hideWebBootStatus();

void hideBootStatus() => _hideWebBootStatus();
