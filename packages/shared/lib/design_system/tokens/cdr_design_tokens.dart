import 'package:flutter/material.dart';

class CDRColorTokens {
  const CDRColorTokens._();

  static const black = Color(0xFF0D0D0D);
  static const graphite = Color(0xFF1A1A1A);
  static const graphiteLight = Color(0xFF2C2C2C);
  static const gold = Color(0xFFF2C14E);
  static const goldHover = Color(0xFFFFD56A);
  static const goldPressed = Color(0xFFE0AE37);
  static const white = Color(0xFFFFFFFF);
  static const gray = Color(0xFF7A7A7A);
  static const border = Color(0xFF3A3A3A);
  static const disabledBackground = Color(0xFF242424);
  static const disabledForeground = Color(0xFF666666);
}

class CDRSpacingTokens {
  const CDRSpacingTokens._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
}

class CDRRadiusTokens {
  const CDRRadiusTokens._();

  static const button = 18.0;
}

class CDRSizeTokens {
  const CDRSizeTokens._();

  static const buttonHeight = 52.0;
  static const buttonMinWidth = 64.0;
  static const icon = 20.0;
  static const loader = 18.0;
}

class CDRDurationTokens {
  const CDRDurationTokens._();

  static const fast = Duration(milliseconds: 150);
}

class CDRTypographyTokens {
  const CDRTypographyTokens._();

  static const button = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
}
