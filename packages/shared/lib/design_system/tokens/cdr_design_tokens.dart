import 'package:flutter/material.dart';

class CDRColorTokens {
  const CDRColorTokens._();

  static const black = Color(0xFF000000);
  static const brandBlack = Color(0xFF050505);
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
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF97316);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF38BDF8);
}

class CDRSpacingTokens {
  const CDRSpacingTokens._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const section = 40.0;
  static const sectionLarge = 48.0;
  static const sectionHero = 64.0;
}

class CDRRadiusTokens {
  const CDRRadiusTokens._();

  static const small = 8.0;
  static const medium = 14.0;
  static const button = 18.0;
  static const large = 22.0;
  static const app = 28.0;
  static const pill = 999.0;
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
  static const standard = Duration(milliseconds: 250);
  static const emphasis = Duration(milliseconds: 400);
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
