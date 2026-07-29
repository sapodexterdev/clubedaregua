// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'logo_file.dart';

Future<LogoFile?> pickLogoFile() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/jpeg,image/png,image/webp'
    ..multiple = false;
  input.style
    ..position = 'fixed'
    ..left = '-10000px'
    ..top = '0'
    ..width = '1px'
    ..height = '1px'
    ..opacity = '0';
  html.document.body?.append(input);

  final completer = Completer<LogoFile?>();
  StreamSubscription<html.Event>? changeSubscription;
  StreamSubscription<html.Event>? inputSubscription;
  StreamSubscription<html.Event>? focusSubscription;
  Timer? safetyTimer;
  var selectionHandled = false;

  void cleanup() {
    changeSubscription?.cancel();
    inputSubscription?.cancel();
    focusSubscription?.cancel();
    safetyTimer?.cancel();
    input.remove();
  }

  void complete(LogoFile? file) {
    if (completer.isCompleted) return;
    cleanup();
    completer.complete(file);
  }

  void readSelection() {
    if (selectionHandled || completer.isCompleted) return;
    final file = input.files?.isEmpty == false ? input.files!.first : null;
    if (file == null) return;
    selectionHandled = true;

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
  }

  // Safari/WebKit no iPhone pode disparar `input`, `change` ou ambos,
  // dependendo de o usuário escolher Câmera, Fotos ou Arquivos.
  changeSubscription = input.onChange.listen((_) => readSelection());
  inputSubscription = input.onInput.listen((_) => readSelection());

  // O navegador não dispara `change` quando o usuário fecha o seletor sem
  // escolher um arquivo. Quando a janela recupera o foco, damos tempo para o
  // evento chegar e então conferimos diretamente a lista de arquivos.
  focusSubscription = html.window.onFocus.listen((_) {
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (completer.isCompleted) return;
      readSelection();
      if (!selectionHandled) complete(null);
    });
  });

  // Proteção adicional para nenhum navegador manter o loading indefinidamente.
  safetyTimer = Timer(const Duration(minutes: 5), () => complete(null));

  input.click();
  return completer.future;
}
