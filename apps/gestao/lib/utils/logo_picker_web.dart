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
  input.onChange.first.then((_) {
    final file = input.files?.isEmpty == false ? input.files!.first : null;
    if (file == null) {
      completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.onError.first.then((_) {
      if (!completer.isCompleted) completer.complete(null);
    });
    reader.onLoad.first.then((_) {
      final result = reader.result;
      if (result is Uint8List) {
        completer.complete(
          LogoFile(
            name: file.name,
            bytes: result,
            contentType: file.type.isEmpty ? 'image/png' : file.type,
          ),
        );
      } else if (result is List<int>) {
        completer.complete(
          LogoFile(
            name: file.name,
            bytes: Uint8List.fromList(result),
            contentType: file.type.isEmpty ? 'image/png' : file.type,
          ),
        );
      } else {
        completer.complete(null);
      }
    });
    reader.readAsArrayBuffer(file);
  });

  input.click();
  return completer.future;
}
