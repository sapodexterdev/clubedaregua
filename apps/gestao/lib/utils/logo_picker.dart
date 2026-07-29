import 'logo_picker_stub.dart' if (dart.library.html) 'logo_picker_web.dart'
    as picker;
import 'logo_file.dart';

Future<LogoFile?> pickLogoFile({
  required int maxWidth,
  required int maxHeight,
  required int compressionThresholdBytes,
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
