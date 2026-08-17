import 'package:flutter/material.dart';

import '../models/models.dart';

/// The copaw color palette, ported from `co-paw/copaw/Views/Theme.swift`.
abstract final class PawColors {
  static const Color green = Color(0xFF298C63);
  static const Color cream = Color(0xFFFCFAF5);
  static const Color blue = Color(0xFF597DE0);
  static const Color purple = Color(0xFF7363E8);
  static const Color purpleDark = Color(0xFF453B8C);
  static const Color lavender = Color(0xFFEDEBFF);
  static const Color peach = Color(0xFFFFDBC9);
  static const Color rose = Color(0xFFFFA19E);
  static const Color yellow = Color(0xFFFFD66E);
  static const Color ink = Color(0xFF26243D);
  static const Color muted = Color(0xFF73708F);
}

/// Per-category accent color and icon (Material equivalents of the SF Symbols
/// used in the SwiftUI original).
Color categoryAccent(CareCategory category) {
  switch (category) {
    case CareCategory.feeding:
      return PawColors.purple;
    case CareCategory.walking:
      return PawColors.blue;
    case CareCategory.medication:
      return PawColors.rose;
    case CareCategory.grooming:
      return PawColors.yellow;
    case CareCategory.other:
      return PawColors.green;
  }
}

IconData categoryIcon(CareCategory category) {
  switch (category) {
    case CareCategory.feeding:
      return Icons.restaurant;
    case CareCategory.walking:
      return Icons.directions_walk;
    case CareCategory.medication:
      return Icons.medication;
    case CareCategory.grooming:
      return Icons.auto_awesome;
    case CareCategory.other:
      return Icons.pets;
  }
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PawColors.purple,
      primary: PawColors.purple,
    ),
    scaffoldBackgroundColor: PawColors.cream,
    fontFamily: null,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: PawColors.ink,
      centerTitle: false,
    ),
  );
}

/// Primary call-to-action button, matching `PawPrimaryButtonStyle`.
ButtonStyle pawPrimaryButtonStyle() {
  return ButtonStyle(
    foregroundColor: WidgetStateProperty.all(Colors.white),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? PawColors.purple.withValues(alpha: 0.45)
          : PawColors.purple,
    ),
    minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 54)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(fontWeight: FontWeight.w600),
    ),
    elevation: const WidgetStatePropertyAll(0),
  );
}

/// Compact secondary button, matching `PawCompactButtonStyle`.
ButtonStyle pawCompactButtonStyle(Color color, {bool filled = false}) {
  return ButtonStyle(
    foregroundColor: WidgetStatePropertyAll(filled ? Colors.white : color),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? color.withValues(alpha: 0.45)
          : (filled ? color : color.withValues(alpha: 0.12)),
    ),
    minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 44)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    ),
    elevation: const WidgetStatePropertyAll(0),
  );
}
