// lib/screens/nav/goat/modals/options/export_pdf_option.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/common/ui_helpers.dart';

class ExportPdfOption {
  static void show(BuildContext context) {
    UIHelpers.showEnhancedSnackbar(
      context,
      FontAwesomeIcons.filePdf,
      'Generating PDF report...',
      Colors.red[600]!,
    );
  }
}