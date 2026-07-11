import 'package:flutter/material.dart';

class CDRColorTokens {
  const CDRColorTokens._();

  static const black = Color(0xFF000000);
  static const night = Color(0xFF09090B);
  static const graphite = Color(0xFF18181B);
  static const graphiteLight = Color(0xFF27272A);
  static const brandYellow = Color(0xFFF3B200);
  static const brandYellowHover = Color(0xFFFFC62B);
  static const brandYellowPressed = Color(0xFFD99F00);
  static const gold = brandYellow;
  static const goldHover = brandYellowHover;
  static const goldPressed = brandYellowPressed;
  static const white = Color(0xFFFFFFFF);
  static const gray = Color(0xFFA1A1AA);
  static const border = Color(0xFF3F3F46);
  static const disabledBackground = Color(0xFF27272A);
  static const disabledForeground = Color(0xFF71717A);
  static const onGold = Color(0xFF09090B);
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
