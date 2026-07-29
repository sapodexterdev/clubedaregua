import 'package:flutter/material.dart';

import '../../tokens/cdr_design_tokens.dart';

class CDRTextField extends StatelessWidget {
  const CDRTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.leading,
    this.trailing,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.onChanged,
    this.enabled = true,
    this.obscureText = false,
    this.maxLines = 1,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? leading;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool obscureText;
  final int maxLines;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      cursorColor: CDRColorTokens.brandYellow,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: CDRColorTokens.white,
          ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: leading == null ? null : Icon(leading),
        suffixIcon: trailing,
      ),
    );
  }
}

class CDRPasswordField extends StatefulWidget {
  const CDRPasswordField({
    super.key,
    required this.controller,
    this.label = 'Senha',
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.enabled = true,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final String? errorText;

  @override
  State<CDRPasswordField> createState() => _CDRPasswordFieldState();
}

class _CDRPasswordFieldState extends State<CDRPasswordField> {
  var _visible = false;

  @override
  Widget build(BuildContext context) {
    return CDRTextField(
      controller: widget.controller,
      label: widget.label,
      leading: Icons.lock_outline_rounded,
      obscureText: !_visible,
      enabled: widget.enabled,
      textInputAction: widget.textInputAction,
      autofillHints: const [AutofillHints.password],
      onSubmitted: widget.onSubmitted,
      errorText: widget.errorText,
      trailing: IconButton(
        tooltip: _visible ? 'Ocultar senha' : 'Mostrar senha',
        onPressed: widget.enabled
            ? () => setState(() => _visible = !_visible)
            : null,
        icon: Icon(
          _visible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
        ),
      ),
    );
  }
}
