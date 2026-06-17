import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Risk classification for a subject's attendance state.
enum RiskLevel {
  safe,
  warning,
  critical;

  /// Sort weight: critical subjects surface first.
  int get sortOrder => switch (this) {
        RiskLevel.critical => 0,
        RiskLevel.warning => 1,
        RiskLevel.safe => 2,
      };

  String get label => switch (this) {
        RiskLevel.safe => 'Safe',
        RiskLevel.warning => 'Warning',
        RiskLevel.critical => 'Critical',
      };

  String get emoji => switch (this) {
        RiskLevel.safe => '🟢',
        RiskLevel.warning => '🟡',
        RiskLevel.critical => '🔴',
      };

  Color get color => switch (this) {
        RiskLevel.safe => AppColors.success,
        RiskLevel.warning => AppColors.warning,
        RiskLevel.critical => AppColors.error,
      };

  Color get containerColor => switch (this) {
        RiskLevel.safe => AppColors.successContainer,
        RiskLevel.warning => AppColors.warningContainer,
        RiskLevel.critical => AppColors.errorContainer,
      };

  Color get onContainerColor => switch (this) {
        RiskLevel.safe => AppColors.onSuccessContainer,
        RiskLevel.warning => AppColors.onWarningContainer,
        RiskLevel.critical => AppColors.onErrorContainer,
      };
}
