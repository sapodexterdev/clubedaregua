import 'logo_picker_stub.dart' if (dart.library.html) 'logo_picker_web.dart'
    as picker;
import 'logo_file.dart';

Future<LogoFile?> pickLogoFile({
  int maxWidth = 1920,
  int maxHeight = 1080,
  int compressionThresholdBytes = 900 * 1024,
  double quality = 0.86,
  bool preserveTransparency = false,
}) =>
    picker.pickLogoFile(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      compressionThresholdBytes: compressionThresholdBytes,
      quality: quality,
      preserveTransparency: preserveTransparency,
    );
