// lib/screens/nav/goat/modals/goat_options_modal.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/change_stage_option.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/change_status_option.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/weight_report_option.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/export_pdf_option.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/archive_option.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/delete_option.dart';

class GoatOptionsModal {
  static void show({
    required BuildContext context,
    required Goat goat,
    required VoidCallback onAddEvent,
    required Function(Goat) onEditGoat,
    VoidCallback? onGoatUpdated,
    bool isArchived = false,
  }) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox;

    // Original button rectangle
    final Rect buttonRect = Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(button.size.bottomRight(Offset.zero),
          ancestor: overlay),
    );

    // Create a new, shifted rectangle for the menu's position
    // You can adjust the dx (right) and dy (up/down) values for precise placement
    final Rect shiftedRect = buttonRect.shift(const Offset(40, -56));

    // Use the shifted rectangle to calculate the RelativeRect
    final RelativeRect position = RelativeRect.fromRect(
      shiftedRect,
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position, // Use the new adjusted position
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      constraints: const BoxConstraints(
        minWidth: 250,
        maxWidth: 300,
      ),
      items: isArchived ? [
        // Only show Delete goat for archived goat
        // _buildDropdownItem(
        //   value: 'export_pdf',
        //   icon: FontAwesomeIcons.filePdf,
        //   title: 'Export PDF',
        //   subtitle: 'Generate report',
        //   color: Colors.red[600]!,
        // ),
        _buildDropdownItem(
          value: 'delete',
          icon: Icons.delete_forever_outlined,
          title: 'Delete goat',
          subtitle: 'Permanently remove',
          color: Colors.red[600]!,
          isDestructive: true,
        ),
      ] : [
        // Full menu for active goat
        _buildDropdownItem(
          value: 'edit',
          icon: Icons.edit_outlined,
          title: 'Edit goat',
          subtitle: 'Modify goat details',
          color: AppColors.vibrantGreen,
        ),
        _buildDropdownItem(
          value: 'add_event',
          icon: Icons.event_note_outlined,
          title: 'Add History Record',
          subtitle: 'Record new history',
          color: AppColors.darkGreen,
        ),
        _buildDivider(),
        _buildDropdownItem(
          value: 'change_stage',
          icon: FontAwesomeIcons.arrowUpRightFromSquare,
          title: 'Change Stage',
          subtitle: 'Update goat stage',
          color: AppColors.lightGreen,
        ),
        _buildDropdownItem(
          value: 'change_status',
          icon: Icons.swap_horiz,
          title: 'Change Status',
          subtitle: 'Update goat status',
          color: AppColors.vibrantGreen,
        ),
        // _buildDivider(),
        // _buildDropdownItem(
        //   value: 'weight_report',
        //   icon: FontAwesomeIcons.chartLine,
        //   title: 'Weight Report',
        //   subtitle: 'View weight history',
        //   color: AppColors.gold,
        // ),
        // _buildDropdownItem(
        //   value: 'export_pdf',
        //   icon: FontAwesomeIcons.filePdf,
        //   title: 'Export PDF',
        //   subtitle: 'Generate report',
        //   color: Colors.red[600]!,
        // ),
        _buildDivider(),
        _buildDropdownItem(
          value: 'archive',
          icon: Icons.archive_outlined,
          title: 'Archive',
          subtitle: 'Move to archive',
          color: AppColors.gold,
        ),
        _buildDropdownItem(
          value: 'delete',
          icon: Icons.delete_forever_outlined,
          title: 'Delete goat',
          subtitle: 'Permanently remove',
          color: Colors.red[600]!,
          isDestructive: true,
        ),
      ],
    ).then((String? selectedValue) {
      if (!context.mounted) return;
      if (selectedValue != null) {
        _handleMenuSelection(
          context,
          selectedValue,
          goat,
          onAddEvent,
          onEditGoat,
          onGoatUpdated,
          isArchived,
        );
      }
    });
  }

  static PopupMenuItem<String> _buildDropdownItem({
    required String value,
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    bool isDestructive = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: subtitle != null ? 72 : 56,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red[600] : color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? Colors.red[600]
                          : AppColors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isDestructive
                            ? Colors.red[400]
                            : AppColors.textSecondary,
                        letterSpacing: 0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static PopupMenuItem<String> _buildDivider() {
    return const PopupMenuItem<String>(
      enabled: false,
      height: 8,
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: Colors.grey,
      ),
    );
  }

  static void _handleMenuSelection(
      BuildContext context,
      String value,
      Goat goat,
      VoidCallback onAddEvent,
      Function(Goat) onEditGoat,
      VoidCallback? onGoatUpdated,
      bool isArchived,
      ) {
    switch (value) {
      case 'edit':
        onEditGoat(goat);
        break;
      case 'add_event':
        onAddEvent();
        break;
      case 'change_stage':
        ChangeStageOption.show(context, goat, onGoatUpdated);
        break;
      case 'change_status':
        ChangeStatusOption.show(context, goat, onGoatUpdated);
        break;
      case 'weight_report':
        WeightReportOption.show(context);
        break;
      case 'export_pdf':
        ExportPdfOption.show(context);
        break;
      case 'archive':
        ArchiveOption.show(context, goat: goat, onGoatUpdated: onGoatUpdated);
        break;
      case 'delete':
        DeleteOption.show(context);
        break;
    }
  }
}
