import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_semantic_colors.dart';

/// The app has one visual identity — a warm, hand-painted watercolor look
/// matching `card-background.png` — so there is deliberately no separate
/// dark palette. [BetweenThreeApp] pins `themeMode` to [ThemeMode.light] so
/// the game always reads the same regardless of a phone's system setting.
abstract final class AppTheme {
  static final ColorScheme _colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: AppColors.background,
    primaryContainer: AppColors.primaryLight,
    onPrimaryContainer: AppColors.textPrimary,
    secondary: AppColors.accent,
    onSecondary: AppColors.textPrimary,
    secondaryContainer: AppColors.primaryLight,
    onSecondaryContainer: AppColors.textPrimary,
    tertiary: AppColors.decorativeOlive,
    onTertiary: AppColors.background,
    tertiaryContainer: AppColors.surface,
    onTertiaryContainer: AppColors.textPrimary,
    error: AppColors.error,
    onError: AppColors.background,
    errorContainer: Color.lerp(AppColors.error, AppColors.card, 0.85),
    onErrorContainer: AppColors.textPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerLowest: AppColors.background,
    surfaceContainerLow: AppColors.background,
    surfaceContainer: AppColors.card,
    surfaceContainerHigh: AppColors.card,
    surfaceContainerHighest: AppColors.primaryLight,
    outline: AppColors.border,
    outlineVariant: AppColors.divider,
    shadow: AppColors.shadow,
    scrim: AppColors.shadow,
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.background,
    inversePrimary: AppColors.primaryLight,
    surfaceTint: AppColors.primary,
  );

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, colorScheme: _colorScheme, brightness: Brightness.light);
    final textTheme = _buildTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      extensions: const [AppSemanticColors.light],

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: AppColors.shadow.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          disabledForegroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),

      iconTheme: const IconThemeData(color: AppColors.textSecondary),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryLight,
        disabledColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: AppColors.background),
        actionTextColor: AppColors.primaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 24),

      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textSecondary,
        tileColor: Colors.transparent,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryLight,
        circularTrackColor: AppColors.primaryLight,
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent,
        ),
        side: const BorderSide(color: AppColors.border, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.card,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primaryLight : AppColors.border,
        ),
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primaryDark,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primaryLight.withValues(alpha: 0.6),
        selectionHandleColor: AppColors.primary,
      ),

      splashFactory: InkRipple.splashFactory,
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    return base
        .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary)
        .copyWith(
          labelLarge: base.labelLarge?.copyWith(color: AppColors.textSecondary, letterSpacing: 0),
          labelMedium: base.labelMedium?.copyWith(color: AppColors.textSecondary, letterSpacing: 0),
          labelSmall: base.labelSmall?.copyWith(color: AppColors.textSecondary, letterSpacing: 0),
          bodySmall: base.bodySmall?.copyWith(color: AppColors.textSecondary, letterSpacing: 0),
          bodyMedium: base.bodyMedium?.copyWith(letterSpacing: 0),
          bodyLarge: base.bodyLarge?.copyWith(letterSpacing: 0),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
          titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
          headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0),
        );
  }
}
