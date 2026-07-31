import 'package:flutter/material.dart';

/// The warm, watercolor palette sampled from `card-background.png`
/// (بيناتنا الثلاثة). This is the single source of truth for color in the
/// app — every screen should read colors from [AppTheme]'s [ColorScheme] /
/// [AppSemanticColors] rather than hard-coding hex values, so the palette
/// stays consistent and can be re-tuned from one place.
abstract final class AppColors {
  static const primary = Color(0xFFD98C83);
  static const primaryDark = Color(0xFFC97168);
  static const primaryLight = Color(0xFFF3CFC6);
  static const accent = Color(0xFFE7A67E);

  static const background = Color(0xFFFFFAF6);
  static const surface = Color(0xFFFFF4EC);
  static const card = Color(0xFFFFF8F2);

  static const textPrimary = Color(0xFF4A2E2A);
  static const textSecondary = Color(0xFF85645B);

  static const decorativeOlive = Color(0xFF8F9C78);

  static const border = Color(0xFFE7D2C8);
  static const divider = Color(0xFFEAD9D2);

  static const success = Color(0xFF8FA87A);
  static const warning = Color(0xFFE7A67E);
  static const error = Color(0xFFC86D69);
  static const info = Color(0xFFCDA88B);

  /// Warm-tinted stand-in for shadow black, so elevation reads as soft
  /// watercolor depth instead of a harsh studio-lighting shadow.
  static const shadow = Color(0xFF4A2E2A);
}
