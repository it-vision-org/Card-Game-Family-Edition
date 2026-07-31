import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Success/warning/info tones that Material's [ColorScheme] has no slot for
/// (it only reserves one for `error`). Reach these via
/// `Theme.of(context).extension<AppSemanticColors>()!` instead of
/// hard-coding a [Colors.green] or similar wherever a status color is needed.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.info,
  });

  static const light = AppSemanticColors(
    success: AppColors.success,
    warning: AppColors.warning,
    info: AppColors.info,
  );

  final Color success;
  final Color warning;
  final Color info;

  @override
  AppSemanticColors copyWith({Color? success, Color? warning, Color? info}) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}
