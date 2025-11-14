// lib/screens/nav/goat/modals/options/weight_report_option.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/common/ui_helpers.dart';

class WeightReportOption {
  static void show(BuildContext context) {
    UIHelpers.showEnhancedSnackbar(
      context,
      FontAwesomeIcons.chartLine,
      'Opening weight report...',
      AppColors.gold,
    );
  }
}