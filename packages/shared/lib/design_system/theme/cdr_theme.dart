import 'package:flutter/material.dart';

import '../tokens/cdr_design_tokens.dart';

class CDRTheme {
  const CDRTheme._();

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: CDRColorTokens.brandYellow,
      onPrimary: CDRColorTokens.onGold,
      secondary: CDRColorTokens.brandYellow,
      onSecondary: CDRColorTokens.onGold,
      surface: CDRColorTokens.graphite,
      onSurface: CDRColorTokens.white,
      error: CDRColorTokens.error,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: CDRColorTokens.night,
      canvasColor: CDRColorTokens.graphite,
      fontFamily: 'Inter',
    );
    final textTheme = base.textTheme.copyWith(
      displayLarge: _heading(42, FontWeight.w800),
      displayMedium: _heading(36, FontWeight.w800),
      displaySmall: _heading(32, FontWeight.w800),
      headlineLarge: _heading(30, FontWeight.w800),
      headlineMedium: _heading(26, FontWeight.w800),
      headlineSmall: _heading(22, FontWeight.w700),
      titleLarge: _heading(20, FontWeight.w700),
      titleMedium: const TextStyle(color: CDRColorTokens.white, fontSize: 16, fontWeight: FontWeight.w700),
      titleSmall: const TextStyle(color: CDRColorTokens.white, fontSize: 14, fontWeight: FontWeight.w700),
      bodyLarge: const TextStyle(color: CDRColorTokens.white, fontSize: 16, height: 1.45),
      bodyMedium: const TextStyle(color: CDRColorTokens.white, fontSize: 14, height: 1.45),
      bodySmall: const TextStyle(color: CDRColorTokens.gray, fontSize: 12, height: 1.4),
      labelLarge: CDRTypographyTokens.button,
      labelMedium: const TextStyle(color: CDRColorTokens.gray, fontSize: 12, fontWeight: FontWeight.w700),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(CDRRadiusTokens.medium),
      borderSide: const BorderSide(color: CDRColorTokens.border),
    );
    return base.copyWith(
      textTheme: textTheme,
      dividerColor: CDRColorTokens.border,
      cardColor: CDRColorTokens.graphite,
      appBarTheme: AppBarTheme(backgroundColor: CDRColorTokens.night, foregroundColor: CDRColorTokens.white, surfaceTintColor: Colors.transparent, elevation: 0, titleTextStyle: textTheme.titleLarge),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CDRColorTokens.graphite,
        labelStyle: const TextStyle(color: CDRColorTokens.gray),
        floatingLabelStyle: const TextStyle(color: CDRColorTokens.brandYellow, fontWeight: FontWeight.w700),
        hintStyle: const TextStyle(color: CDRColorTokens.disabledForeground),
        prefixIconColor: CDRColorTokens.gray,
        suffixIconColor: CDRColorTokens.gray,
        contentPadding: const EdgeInsets.symmetric(horizontal: CDRSpacingTokens.lg, vertical: CDRSpacingTokens.lg),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: CDRColorTokens.brandYellow, width: 1.5)),
        errorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: CDRColorTokens.error)),
        focusedErrorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: CDRColorTokens.error, width: 1.5)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        backgroundColor: CDRColorTokens.brandYellow,
        foregroundColor: CDRColorTokens.onGold,
        disabledBackgroundColor: CDRColorTokens.disabledBackground,
        disabledForegroundColor: CDRColorTokens.disabledForeground,
        minimumSize: const Size(CDRSizeTokens.buttonMinWidth, CDRSizeTokens.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: CDRSpacingTokens.xl, vertical: CDRSpacingTokens.md),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CDRRadiusTokens.medium)),
        textStyle: CDRTypographyTokens.button,
        elevation: 0,
      )),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: CDRColorTokens.brandYellow,
        foregroundColor: CDRColorTokens.onGold,
        minimumSize: const Size(CDRSizeTokens.buttonMinWidth, CDRSizeTokens.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CDRRadiusTokens.medium)),
        textStyle: CDRTypographyTokens.button,
        elevation: 0,
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        foregroundColor: CDRColorTokens.white,
        minimumSize: const Size(CDRSizeTokens.buttonMinWidth, CDRSizeTokens.buttonHeight),
        side: const BorderSide(color: CDRColorTokens.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CDRRadiusTokens.medium)),
        textStyle: CDRTypographyTokens.button,
      )),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
        foregroundColor: CDRColorTokens.brandYellow,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CDRRadiusTokens.small)),
      )),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: CDRColorTokens.gray, highlightColor: CDRColorTokens.brandYellow.withOpacity(.12))),
      cardTheme: CardTheme(color: CDRColorTokens.graphite, surfaceTintColor: Colors.transparent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CDRRadiusTokens.large), side: const BorderSide(color: CDRColorTokens.border))),
      dialogTheme: DialogTheme(backgroundColor: CDRColorTokens.graphite, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CDRRadiusTokens.large))),
      snackBarTheme: const SnackBarThemeData(backgroundColor: CDRColorTokens.graphiteLight, contentTextStyle: TextStyle(color: CDRColorTokens.white), behavior: SnackBarBehavior.floating),
    );
  }

  static TextStyle _heading(double size, FontWeight weight) => TextStyle(
    color: CDRColorTokens.white,
    fontFamily: 'Barlow Condensed',
    fontSize: size,
    height: 1.05,
    fontWeight: weight,
  );
}
