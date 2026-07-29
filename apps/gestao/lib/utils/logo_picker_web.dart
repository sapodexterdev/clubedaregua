// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'logo_file.dart';

Future<LogoFile?> pickLogoFile({
  required int maxWidth,
  required int maxHeight,
  required int compressionThresholdBytes,
  double quality = 0.86,
  bool preserveTransparency = false,
}) async {
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

  Future<void> complete(LogoFile? file) async {
    if (completer.isCompleted) return;
    if (file != null) {
      file = await _optimizeImage(
        file,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        compressionThresholdBytes: compressionThresholdBytes,
        quality: quality,
        preserveTransparency: preserveTransparency,
      );
    }
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

Future<LogoFile> _optimizeImage(
  LogoFile original, {
  required int maxWidth,
  required int maxHeight,
  required int compressionThresholdBytes,
  required double quality,
  required bool preserveTransparency,
}) async {
  String? objectUrl;
  try {
    final sourceBlob = html.Blob(
      [original.bytes],
      original.contentType,
    );
    objectUrl = html.Url.createObjectUrlFromBlob(sourceBlob);
    final image = html.ImageElement(src: objectUrl);
    await image.onLoad.first.timeout(const Duration(seconds: 20));

    final sourceWidth = image.naturalWidth;
    final sourceHeight = image.naturalHeight;
    if (sourceWidth <= 0 || sourceHeight <= 0) return original;

    final scale = [
      1.0,
      maxWidth / sourceWidth,
      maxHeight / sourceHeight,
    ].reduce((current, value) => value < current ? value : current);
    final targetWidth =
        (sourceWidth * scale).round().clamp(1, maxWidth).toInt();
    final targetHeight =
        (sourceHeight * scale).round().clamp(1, maxHeight).toInt();
    final needsResize =
        targetWidth != sourceWidth || targetHeight != sourceHeight;
    final needsCompression =
        original.bytes.length > compressionThresholdBytes;

    if (!needsResize && !needsCompression) return original;

    final canvas = html.CanvasElement(
      width: targetWidth,
      height: targetHeight,
    );
    canvas.context2D.drawImageScaled(
      image,
      0,
      0,
      targetWidth,
      targetHeight,
    );

    final sourceType = original.contentType.toLowerCase();
    final outputType = preserveTransparency &&
            (sourceType == 'image/png' || sourceType == 'image/webp')
        ? 'image/png'
        : 'image/jpeg';
    final dataUrl = canvas.toDataUrl(outputType, quality);
    final separator = dataUrl.indexOf(',');
    if (separator < 0) return original;
    final optimizedBytes = base64Decode(dataUrl.substring(separator + 1));

    if (!needsResize && optimizedBytes.length >= original.bytes.length) {
      return original;
    }

    return LogoFile(
      name: _optimizedFileName(original.name, outputType),
      bytes: optimizedBytes,
      contentType: outputType,
    );
  } catch (_) {
    // A otimização nunca deve impedir o upload da imagem original.
    return original;
  } finally {
    if (objectUrl != null) html.Url.revokeObjectUrl(objectUrl);
  }
}

String _optimizedFileName(String originalName, String contentType) {
  final dot = originalName.lastIndexOf('.');
  final baseName = dot > 0 ? originalName.substring(0, dot) : originalName;
  final extension = contentType == 'image/png' ? 'png' : 'jpg';
  return '$baseName-otimizada.$extension';
}
