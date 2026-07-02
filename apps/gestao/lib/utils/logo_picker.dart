import 'logo_picker_stub.dart' if (dart.library.html) 'logo_picker_web.dart'
    as picker;
import 'logo_file.dart';

Future<LogoFile?> pickLogoFile() => picker.pickLogoFile();
