import 'package:flutter/material.dart';
import 'package:war_armies_app/theme/war_colors.dart';

class WarTheme {
  const WarTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: WarColors.primary),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: WarColors.primary,
          brightness: Brightness.dark,
        ),
      );
}
