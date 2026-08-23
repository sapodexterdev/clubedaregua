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
      fontFamily: CDRTypographyTokens.interfaceFontFamily,
      scaffoldBackgroundColor: CDRColorTokens.night,
      canvasColor: CDRColorTokens.graphite,
      visualDensity: VisualDensity.standard,
    );
    final textTheme = base.textTheme.copyWith(
      displayLarge: _displayStyle(CDRTypographyTokens.display),
      displayMedium: _displayStyle(
        CDRTypographyTokens.title1.copyWith(fontSize: 36),
      ),
      displaySmall: _displayStyle(CDRTypographyTokens.title1),
      headlineLarge: _displayStyle(CDRTypographyTokens.title1),
      headlineMedium: _displayStyle(CDRTypographyTokens.title2),
      headlineSmall: _displayStyle(CDRTypographyTokens.title2),
      titleLarge: _interfaceStyle(CDRTypographyTokens.title3),
      titleMedium: _interfaceStyle(
        CDRTypographyTokens.label.copyWith(
          fontSize: 16,
          height: 1.3,
          fontWeight: FontWeight.w700,
        ),
      ),
      titleSmall: _interfaceStyle(
        CDRTypographyTokens.label.copyWith(fontWeight: FontWeight.w700),
      ),
      bodyLarge: _interfaceStyle(CDRTypographyTokens.body),
      bodyMedium: _interfaceStyle(CDRTypographyTokens.bodySmall),
      bodySmall: _interfaceStyle(
        CDRTypographyTokens.caption,
        color: CDRColorTokens.gray,
      ),
      labelLarge: _interfaceStyle(CDRTypographyTokens.button),
      labelMedium: _interfaceStyle(
        CDRTypographyTokens.label,
        color: CDRColorTokens.grayStrong,
      ),
      labelSmall: _interfaceStyle(
        CDRTypographyTokens.caption.copyWith(fontWeight: FontWeight.w600),
        color: CDRColorTokens.gray,
      ),
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
        selectedColor: CDRColorTokens.brandYellow,
        disabledColor: CDRColorTokens.disabledBackground,
        checkmarkColor: CDRColorTokens.onGold,
        side: const BorderSide(color: CDRColorTokens.border),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: CDRColorTokens.onGold,
        ),
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

  static TextStyle _displayStyle(TextStyle style) => style.copyWith(
        color: CDRColorTokens.white,
        fontFamily: CDRTypographyTokens.displayFontFamily,
      );

  static TextStyle _interfaceStyle(
    TextStyle style, {
    Color color = CDRColorTokens.white,
  }) =>
      style.copyWith(
        color: color,
        fontFamily: CDRTypographyTokens.interfaceFontFamily,
      );
}
