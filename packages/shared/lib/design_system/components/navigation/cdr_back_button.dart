import 'package:flutter/material.dart';

import '../../../src/shared_app_colors.dart';

class CDRBackButton extends StatelessWidget {
  const CDRBackButton({
    super.key,
    this.onPressed,
    this.tooltip = 'Voltar',
  });

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: SharedAppColors.card,
        shape: const CircleBorder(
          side: BorderSide(color: SharedAppColors.stroke),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed ?? () => Navigator.maybePop(context),
          child: const SizedBox.square(
            dimension: 44,
            child: Icon(
              Icons.arrow_back_rounded,
              size: 22,
              color: SharedAppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
