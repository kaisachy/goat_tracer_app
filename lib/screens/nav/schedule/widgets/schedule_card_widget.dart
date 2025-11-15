import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart'; // Import the intl package
import '../../../../constants/app_colors.dart';
import '../../../../models/schedule.dart';
import '../../../../utils/schedule_utils.dart';
import '../modals/goat_list_modal.dart';

class ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final bool isToday;
  final Function(String action, Schedule schedule) onMenuAction;

  const ScheduleCard({
    super.key,
    required this.schedule,
    this.isToday = false,
    required this.onMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    final goatTags = schedule.goatTag?.split(', ') ?? [];
    final bool showActionButtons =
        schedule.isScheduled || schedule.isCancelled || schedule.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // Use Material to provide the canvas for the InkWell ripple effect
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onMenuAction('view', schedule),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(context, goatTags),
                const SizedBox(height: 16),
                _buildCardFooter(),
                if (schedule.scheduledBy != null || schedule.details != null || schedule.duration != null || schedule.reminder != null) ...[
                  const SizedBox(height: 12),
                  _buildCardInfo(),
                ],
                if (showActionButtons) ...[
                  const Divider(height: 32), // Adds vertical space and a line
                  _buildActionButtons(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context, List<String> goatTags) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: schedule.statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ScheduleTypeIcon(
            type: schedule.type,
            size: 18,
            color: schedule.statusColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                schedule.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (goatTags.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildgoatClickableIcon(context, goatTags),
              ],
            ],
          ),
        ),
        _buildPopupMenu(),
      ],
    );
  }

  Widget _buildgoatClickableIcon(
      BuildContext context, List<String> goatTags) {
    return GestureDetector(
      onTap: () => GoatListModal.show(context, schedule),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.cow,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              '${goatTags.length} goat',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 10,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) => onMenuAction(value, schedule),
      icon: Icon(
        Icons.more_horiz,
        color: Colors.grey[400],
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color(0xFFF8FFF8), // Light green, more whity background
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 12),
              const Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy_outlined, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 12),
              const Text('Duplicate'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red[400]),
              const SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.red[600])),
            ],
          ),
        ),
      ],
    );
  }

  // --- MODIFIED WIDGET ---
  Widget _buildCardFooter() {
    // Use DateFormat for proper 12-hour time formatting, e.g., "1:30 PM"
    final timeFormat = DateFormat('h:mm a');

    // Use a different format if the date is not today, e.g., "MMM d, h:mm a"
    // which results in "Aug 12, 1:30 PM"
    final dateTimeFormat = DateFormat('MMM d, h:mm a');

    // Choose the format based on the isToday flag
    final String formattedDate = isToday
        ? timeFormat.format(schedule.scheduleDateTime)
        : dateTimeFormat.format(schedule.scheduleDateTime);

    return Row(
      children: [
        Icon(
          isToday ? Icons.access_time : Icons.calendar_today,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          formattedDate, // Use the new formatted string
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const Spacer(),
        if (schedule.duration != null)
          _buildDurationChip(),
        const SizedBox(width: 8),
        ScheduleStatusChip(status: schedule.status, isSmall: true),
      ],
    );
  }

  // Enhanced widget to build the action buttons with centered alignment
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // Center the buttons
      children: [
        if (schedule.isScheduled) ...[
          // Cancel button with gray background container
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100], // Gray background
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => onMenuAction('cancel', schedule),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          // Primary action - Mark Complete
          ElevatedButton(
            onPressed: () => onMenuAction('complete', schedule),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success.withValues(alpha: 0.8), // Lighter green
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Mark Complete'),
          ),
        ],
        if (schedule.isCancelled || schedule.isCompleted)
          ElevatedButton(
            onPressed: () => onMenuAction('reschedule', schedule),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning, // Gold color for reschedule
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Reschedule'),
          ),
      ],
    );
  }

  Widget _buildCardInfo() {
    return Column(
      children: [
        if (schedule.scheduledBy != null)
          _buildInfoRow(Icons.person_outline, 'Scheduled by: ${schedule.scheduledBy!}'),
        if (schedule.reminder != null) ...[
          if (schedule.scheduledBy != null) const SizedBox(height: 8),
          _buildInfoRow(Icons.notifications_outlined, 'Reminder: ${schedule.reminder!}'),
        ],
        if (schedule.details != null) ...[
          if (schedule.scheduledBy != null || schedule.reminder != null) const SizedBox(height: 8),
          _buildInfoRow(Icons.notes_outlined, schedule.details!, maxLines: 2),
        ],
      ],
    );
  }

  Widget _buildDurationChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 12,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 4),
          Text(
            schedule.duration!,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
