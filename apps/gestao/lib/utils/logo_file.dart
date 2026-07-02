import 'dart:typed_data';

class LogoFile {
  const LogoFile({
    required this.name,
    required this.bytes,
    required this.contentType,
  });

  final String name;
  final Uint8List bytes;
  final String contentType;
}
