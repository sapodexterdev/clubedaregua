import 'package:flutter/material.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    return CDRTheme.dark().copyWith(
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
