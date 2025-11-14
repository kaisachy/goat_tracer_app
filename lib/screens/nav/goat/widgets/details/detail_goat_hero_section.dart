import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/utils/goat_detail_utils.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/photo_options_modal.dart';
import 'package:goat_tracer_app/screens/nav/goat/widgets/details/goat_schedules_section.dart';
import 'package:goat_tracer_app/services/schedule/schedule_service.dart';
import 'package:goat_tracer_app/services/goat/goat_export_service.dart';
import 'package:goat_tracer_app/services/goat/goat_service.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/change_stage_option.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/change_status_option.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/archive_option.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/delete_option.dart';
import 'package:goat_tracer_app/screens/nav/history/goat_selection_modal.dart';

class goatHeroSection extends StatefulWidget {
  final goat goat;
  final Function(String?) onImageUpdate;
  final Function(goat) onEditgoat;
  final VoidCallback onAddEvent;
  final VoidCallback? ongoatUpdated;
  final bool isUpdatingImage;
  final bool isArchived;

  const goatHeroSection({
    super.key,
    required this.goat,
    required this.onImageUpdate,
    required this.onEditgoat,
    required this.onAddEvent,
    this.ongoatUpdated,
    this.isUpdatingImage = false,
    this.isArchived = false,
  });

  @override
  State<goatHeroSection> createState() => _goatHeroSectionState();
}

class _goatHeroSectionState extends State<goatHeroSection> {
  int _scheduleCount = 0;
  bool _isLoadingSchedules = true;

  @override
  void initState() {
    super.initState();
    _loadScheduleCount();
  }

  Future<void> _loadScheduleCount() async {
    if (widget.goat.tagNo.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingSchedules = false;
        });
      }
      return;
    }
    try {
      final normalizedTag = widget.goat.tagNo.trim().toUpperCase();
      final schedules = await ScheduleService.getSchedulesForgoat(normalizedTag);
      if (mounted) {
        setState(() {
          _scheduleCount = schedules.length;
          _isLoadingSchedules = false;
        });
      }
    } catch (e) {
      log('Error loading schedule count: $e');
      if (mounted) {
        setState(() {
          _isLoadingSchedules = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroPhoto(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.lightGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_offer,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    widget.goat.tagNo,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.goat.status.toUpperCase(),
                              style: TextStyle(
                                color: goatDetailUtils.getStatusColor(widget.goat.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                              softWrap: true, // This is the key for multi-line wrapping
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPhoto(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: _hasValidImage()
              ? ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            child: _buildImageWidget(),
          )
              : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.lightGreen.withValues(alpha: 0.2),
                  AppColors.vibrantGreen.withValues(alpha: 0.1),
                  Colors.white,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.lightGreen.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      FontAwesomeIcons.Doe,
                      size: 50,
                      color: AppColors.lightGreen,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showPhotoModal(context),
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Add Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 20,
          child: _buildFloatingButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.pop(context),
          ),
        ),
        Positioned(
          top: 40,
          right: 20,
          child: _buildMoreOptionsMenu(context),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: _buildFloatingButton(
            icon: Icons.camera_alt,
            onTap: () => _showPhotoModal(context),
          ),
        ),
        if (widget.isUpdatingImage) _buildHeroLoadingOverlay(),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildScheduleCountButton(BuildContext context) {
    return _isLoadingSchedules
        ? _buildFloatingButton(
      icon: Icons.calendar_today,
      onTap: () => _showSchedulesModal(context),
    )
        : Stack(
      children: [
        _buildFloatingButton(
          icon: Icons.calendar_today,
          onTap: () => _showSchedulesModal(context),
        ),
        if (_scheduleCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.yellow[700],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Center(
                child: Text(
                  '$_scheduleCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _hasValidImage() {
    return widget.goat.hasPicture || (widget.goat.goatPicture != null && widget.goat.goatPicture!.isNotEmpty);
  }

  Widget _buildImageWidget() {
    try {
      final imageBytes = widget.goat.imageBytes;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        return Image.memory(
          imageBytes,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
        );
      }
      if (widget.goat.goatPicture != null && widget.goat.goatPicture!.isNotEmpty) {
        final cleanBase64 = widget.goat.goatPicture!.startsWith('data:image')
            ? widget.goat.goatPicture!.split(',')[1]
            : widget.goat.goatPicture!;
        final bytes = base64Decode(cleanBase64);
        return Image.memory(
          bytes,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
        );
      }
      return _buildErrorPlaceholder();
    } catch (e) {
      return _buildErrorPlaceholder();
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightGreen,
            AppColors.vibrantGreen,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: 40,
          color: AppColors.textSecondary.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  void _showPhotoModal(BuildContext context) {
    PhotoOptionsModal.show(
      context: context,
      currentImagePath: widget.goat.goatPicture,
      onImageUpdate: widget.onImageUpdate,
    );
  }

  void _showSchedulesModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.darkGreen,
                        AppColors.vibrantGreen,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.schedule,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Assigned Schedules',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_scheduleCount > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen.withValues(alpha: 0.1),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.lightGreen.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.vibrantGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_scheduleCount Active',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _scheduleCount == 1
                                ? 'This goat has 1 active schedule'
                                : 'This goat has $_scheduleCount active schedules',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                _scheduleCount == 0
                    ? _buildEmptyScheduleState()
                    : Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          goatSchedulesSection(goat: widget.goat),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyScheduleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.lightGreen.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.schedule_outlined,
              size: 50,
              color: AppColors.lightGreen.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Schedules Assigned',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This goat doesn\'t have any schedules yet.\nCreate a new schedule to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.lightGreen.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tap "Add Schedule" to create your first schedule',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreOptionsMenu(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppColors.textPrimary, size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        offset: const Offset(0, 10),
        color: Colors.white,
        shadowColor: Colors.black26,
        onSelected: (value) async {
          switch (value) {
            case 'edit':
              widget.onEditgoat(widget.goat);
              break;
            case 'add_event':
              widget.onAddEvent();
              break;
            case 'change_stage':
              ChangeStageOption.show(context, widget.goat, widget.ongoatUpdated ?? () {});
              break;
            case 'change_status':
              ChangeStatusOption.show(context, widget.goat, widget.ongoatUpdated ?? () {});
              break;
            case 'export_excel':
            case 'export_pdf':
              // Show goat selection modal for export
              final selectedTag = await showDialog<String>(
                context: context,
                builder: (dialogContext) => const goatSelectionModal(),
              );
              if (selectedTag != null) {
                if (!context.mounted) break;
                // Find the selected goat
                final allgoat = await GoatService.getAllGoats();
                if (!context.mounted) break;
                final selectedgoat = allgoat.firstWhere(
                  (c) => c.tagNo == selectedTag,
                  orElse: () => widget.goat,
                );
                if (value == 'export_excel') {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.hideCurrentSnackBar();
                  final ok = await GoatExportService.downloadgoatExcel(selectedgoat.id.toString());
                  if (!context.mounted) break;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Excel report ready! Choose where to open/save.' : 'Failed to download Excel report.'),
                      backgroundColor: ok ? Colors.green.shade600 : Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                } else if (value == 'export_pdf') {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.hideCurrentSnackBar();
                  final ok = await GoatExportService.downloadgoatPdf(selectedgoat.id.toString());
                  if (!context.mounted) break;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'PDF report ready! Choose where to open/save.' : 'Failed to generate PDF report.'),
                      backgroundColor: ok ? Colors.green.shade600 : Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
              break;
            case 'archive':
              ArchiveOption.show(context, goat: widget.goat, ongoatUpdated: widget.ongoatUpdated ?? () {});
              break;
            case 'delete':
              DeleteOption.show(context);
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'edit',
            height: 36,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.vibrantGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.vibrantGreen.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.edit_outlined, color: AppColors.vibrantGreen, size: 14),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Edit goat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'add_event',
            height: 36,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.darkGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.darkGreen.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.event_note_outlined, color: AppColors.darkGreen, size: 14),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Add History Record', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
          PopupMenuItem<String>(
            value: 'change_stage',
            height: 36,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.lightGreen.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.arrow_upward_outlined, color: AppColors.lightGreen, size: 14),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Change Stage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'change_status',
            height: 36,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.vibrantGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.vibrantGreen.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.swap_horiz, color: AppColors.vibrantGreen, size: 14),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Change Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
          PopupMenuItem<String>(
            value: 'export_excel',
            height: 36,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                  ),
                  alignment: Alignment.center,
                  child: const FaIcon(FontAwesomeIcons.fileExcel, color: Colors.green, size: 14),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Download Excel Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'export_pdf',
            height: 36,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 14),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Generate PDF Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
          PopupMenuItem<String>(
            value: 'archive',
            height: 36,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.archive_outlined, color: AppColors.gold, size: 14),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Archive', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            height: 36,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.red.shade600.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade600.withValues(alpha: 0.2)),
                  ),
                  child: Icon(Icons.delete_forever_outlined, color: Colors.red.shade600, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Delete goat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.textPrimary, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildHeroLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkGreen),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Updating Photo...',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Please wait while we save your changes',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
