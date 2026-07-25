import 'package:flutter/services.dart';

class WhatsappInputFormatter extends TextInputFormatter {
  const WhatsappInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buffer = StringBuffer();

    for (var index = 0; index < limited.length; index++) {
      if (index == 0) buffer.write('(');
      if (index == 2) buffer.write(')');
      if (index == 7) buffer.write('-');
      buffer.write(limited[index]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

String formatWhatsapp(String? value) {
  final source = value?.trim() ?? '';
  if (source.isEmpty) return '';

  return const WhatsappInputFormatter()
      .formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
          text: source,
          selection: TextSelection.collapsed(offset: source.length),
        ),
      )
      .text;
}
