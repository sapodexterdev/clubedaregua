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
      visualDensity: VisualDensity.standard,
    );
    final textTheme = base.textTheme.copyWith(
      displayLarge: _heading(42, FontWeight.w800),
      displayMedium: _heading(36, FontWeight.w800),
      displaySmall: _heading(32, FontWeight.w800),
      headlineLarge: _heading(30, FontWeight.w800),
      headlineMedium: _heading(26, FontWeight.w800),
      headlineSmall: _heading(22, FontWeight.w700),
      titleLarge: _heading(20, FontWeight.w700),
      titleMedium: const TextStyle(color: CDRColorTokens.white, fontSize: 16, height: 1.3, fontWeight: FontWeight.w700),
      titleSmall: const TextStyle(color: CDRColorTokens.white, fontSize: 14, height: 1.3, fontWeight: FontWeight.w700),
      bodyLarge: const TextStyle(color: CDRColorTokens.white, fontSize: 16, height: 1.5, fontWeight: FontWeight.w400),
      bodyMedium: const TextStyle(color: CDRColorTokens.white, fontSize: 14, height: 1.5, fontWeight: FontWeight.w400),
      bodySmall: const TextStyle(color: CDRColorTokens.gray, fontSize: 12, height: 1.45, fontWeight: FontWeight.w500),
      labelLarge: CDRTypographyTokens.button.copyWith(color: CDRColorTokens.white),
      labelMedium: const TextStyle(color: CDRColorTokens.grayStrong, fontSize: 13, height: 1.3, fontWeight: FontWeight.w700),
      labelSmall: const TextStyle(color: CDRColorTokens.gray, fontSize: 12, height: 1.3, fontWeight: FontWeight.w600),
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
        constraints: const BoxConstraints(minHeight: CDRSizeTokens.inputHeight),
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
      chipTheme: ChipThemeData(
        backgroundColor: CDRColorTokens.graphite,
        selectedColor: CDRColorTokens.brandYellow.withOpacity(.12),
        disabledColor: CDRColorTokens.disabledBackground,
        side: const BorderSide(color: CDRColorTokens.border),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: CDRColorTokens.white),
        padding: const EdgeInsets.symmetric(horizontal: CDRSpacingTokens.sm, vertical: CDRSpacingTokens.xs),
      ),
      cardTheme: CardTheme(color: CDRColorTokens.graphite, surfaceTintColor: Colors.transparent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CDRRadiusTokens.large), side: const BorderSide(color: CDRColorTokens.border))),
      dialogTheme: DialogTheme(backgroundColor: CDRColorTokens.graphite, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CDRRadiusTokens.large))),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CDRColorTokens.graphite,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: CDRColorTokens.graphite,
        showDragHandle: true,
        dragHandleColor: CDRColorTokens.border,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: CDRColorTokens.gray,
        textColor: CDRColorTokens.white,
        contentPadding: EdgeInsets.symmetric(horizontal: CDRSpacingTokens.lg),
        minVerticalPadding: CDRSpacingTokens.md,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? CDRColorTokens.onGold
              : CDRColorTokens.gray,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? CDRColorTokens.brandYellow
              : CDRColorTokens.graphiteLight,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(backgroundColor: CDRColorTokens.graphiteLight, contentTextStyle: TextStyle(color: CDRColorTokens.white), behavior: SnackBarBehavior.floating),
    );
  }

  static TextStyle _heading(double size, FontWeight weight) => TextStyle(
    color: CDRColorTokens.white,
    fontSize: size,
    height: 1.12,
    fontWeight: weight,
    letterSpacing: -.4,
  );
}
