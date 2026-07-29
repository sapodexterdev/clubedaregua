// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'logo_file.dart';

Future<LogoFile?> pickLogoFile() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = false;

  final completer = Completer<LogoFile?>();
  StreamSubscription<html.Event>? focusSubscription;
  var selectionChanged = false;

  void complete(LogoFile? file) {
    if (completer.isCompleted) return;
    focusSubscription?.cancel();
    completer.complete(file);
  }

  input.onChange.first.then((_) {
    selectionChanged = true;
    final file = input.files?.isEmpty == false ? input.files!.first : null;
    if (file == null) {
      complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.onError.first.then((_) {
      complete(null);
    });
    reader.onLoad.first.then((_) {
      final result = reader.result;
      if (result is Uint8List) {
        complete(
          LogoFile(
            name: file.name,
            bytes: result,
            contentType: file.type.isEmpty ? 'image/png' : file.type,
          ),
        );
      } else if (result is ByteBuffer) {
        complete(
          LogoFile(
            name: file.name,
            bytes: result.asUint8List(),
            contentType: file.type.isEmpty ? 'image/png' : file.type,
          ),
        );
      } else if (result is List<int>) {
        complete(
          LogoFile(
            name: file.name,
            bytes: Uint8List.fromList(result),
            contentType: file.type.isEmpty ? 'image/png' : file.type,
          ),
        );
      } else {
        complete(null);
      }
    });
    reader.readAsArrayBuffer(file);
  });

  // O navegador não dispara `change` quando o usuário fecha o seletor sem
  // escolher um arquivo. Quando a janela recupera o foco, damos tempo para o
  // `change` chegar e concluímos com null caso a seleção tenha sido cancelada.
  focusSubscription = html.window.onFocus.listen((_) {
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!selectionChanged) complete(null);
    });
  });

  input.click();
  return completer.future;
}
