// lib/screens/nav/cattle/modals/cattle_options_modal.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/modals/options/change_stage_option.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/modals/options/change_status_option.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/modals/options/weight_report_option.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/modals/options/export_pdf_option.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/modals/options/archive_option.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/modals/options/delete_option.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/family_tree_screen.dart';

class CattleOptionsModal {
  static void show({
    required BuildContext context,
    required Cattle cattle,
    required VoidCallback onAddEvent,
    required Function(Cattle) onEditCattle,
    VoidCallback? onCattleUpdated,
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
      shadowColor: Colors.black.withOpacity(0.15),
      constraints: const BoxConstraints(
        minWidth: 250,
        maxWidth: 300,
      ),
      items: [
        _buildDropdownItem(
          value: 'edit',
          icon: Icons.edit_outlined,
          title: 'Edit Cattle',
          subtitle: 'Modify cattle details',
          color: AppColors.vibrantGreen,
        ),
        _buildDropdownItem(
          value: 'add_event',
          icon: Icons.event_note_outlined,
          title: 'Add Event',
          subtitle: 'Record new activity',
          color: AppColors.darkGreen,
        ),
        _buildDropdownItem(
          value: 'family_tree',
          icon: Icons.account_tree_outlined,
          title: 'Family Tree',
          subtitle: 'View family lineage',
          color: AppColors.lightGreen,
        ),
        _buildDivider(),
        _buildDropdownItem(
          value: 'change_stage',
          icon: FontAwesomeIcons.arrowUpRightFromSquare,
          title: 'Change Stage',
          subtitle: 'Update cattle stage',
          color: AppColors.lightGreen,
        ),
        _buildDropdownItem(
          value: 'change_status',
          icon: Icons.swap_horiz,
          title: 'Change Status',
          subtitle: 'Update cattle status',
          color: AppColors.vibrantGreen,
        ),
        _buildDivider(),
        _buildDropdownItem(
          value: 'weight_report',
          icon: FontAwesomeIcons.chartLine,
          title: 'Weight Report',
          subtitle: 'View weight history',
          color: AppColors.gold,
        ),
        _buildDropdownItem(
          value: 'export_pdf',
          icon: FontAwesomeIcons.filePdf,
          title: 'Export PDF',
          subtitle: 'Generate report',
          color: Colors.red[600]!,
        ),
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
          title: 'Delete Cattle',
          subtitle: 'Permanently remove',
          color: Colors.red[600]!,
          isDestructive: true,
        ),
      ],
    ).then((String? selectedValue) {
      if (selectedValue != null) {
        _handleMenuSelection(context, selectedValue, cattle, onAddEvent,
            onEditCattle, onCattleUpdated);
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
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.2),
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
      Cattle cattle,
      VoidCallback onAddEvent,
      Function(Cattle) onEditCattle,
      VoidCallback? onCattleUpdated,
      ) {
    switch (value) {
      case 'edit':
        onEditCattle(cattle);
        break;
      case 'add_event':
        onAddEvent();
        break;
      case 'family_tree':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FamilyTreeScreen(cattle: cattle),
          ),
        );
        break;
      case 'change_stage':
        ChangeStageOption.show(context, cattle, onCattleUpdated);
        break;
      case 'change_status':
        ChangeStatusOption.show(context, cattle, onCattleUpdated);
        break;
      case 'weight_report':
        WeightReportOption.show(context);
        break;
      case 'export_pdf':
        ExportPdfOption.show(context);
        break;
      case 'archive':
        ArchiveOption.show(context, cattle: cattle, onCattleUpdated: onCattleUpdated);
        break;
      case 'delete':
        DeleteOption.show(context);
        break;
    }
  }
}