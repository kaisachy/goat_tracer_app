import 'package:flutter/material.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/services/goat/goat_service.dart';
import 'package:goat_tracer_app/services/goat/goat_history_service.dart';
import 'package:goat_tracer_app/services/goat/goat_export_service.dart';
import 'package:goat_tracer_app/screens/nav/goat/goat_form_screen.dart';
import 'package:goat_tracer_app/screens/nav/goat/goat_history_form_screen.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/change_stage_option.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/change_status_option.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/archive_option.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/delete_option.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class goatSelectionModal extends StatefulWidget {
  final String? historyType; // Optional: filter goat by history type applicability

  const goatSelectionModal({super.key, this.historyType});

  @override
  State<goatSelectionModal> createState() => _goatSelectionModalState();
}

class _goatSelectionModalState extends State<goatSelectionModal> {
  List<goat> allgoat = [];
  List<goat> filteredgoat = [];
  bool isLoading = true;
  String? error;
  String searchQuery = '';
  goat? selectedgoat;
  final Set<String> _tagsWithBreeding = {};
  final Set<String> _tagsWithPregnant = {};
  final Set<String> _tagsWithSick = {};

  @override
  void initState() {
    super.initState();
    _loadgoat();
  }

  Future<void> _loadgoat() async {
    try {
      setState(() => isLoading = true);
      final goat = await GoatService.getAllGoats();
      // Optionally load history to support type-specific eligibility
      await _maybeLoadHistoryEligibility();

      if (mounted) {
        setState(() {
          allgoat = goat;
          // Apply initial filter based on history type if provided
          final base = widget.historyType == null
              ? allgoat
              : allgoat.where(_matchesHistoryClassification).toList();
          filteredgoat = base;
          isLoading = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Failed to load goat: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _maybeLoadHistoryEligibility() async {
    final type = (widget.historyType ?? '').toLowerCase();
    if (type != 'pregnant' && type != 'gives birth' && type != 'treated') return;

    try {
      final events = await GoatHistoryService.getgoatHistory();
      _tagsWithBreeding.clear();
      _tagsWithPregnant.clear();
      for (final e in events) {
        final tag = (e['goat_tag'] ?? '').toString().trim();
        if (tag.isEmpty) continue;
        final evType = (e['history_type'] ?? '').toString().toLowerCase();
        if (evType == 'breeding') {
          _tagsWithBreeding.add(tag);
        } else if (evType == 'pregnant') {
          _tagsWithPregnant.add(tag);
        } else if (evType == 'sick') {
          _tagsWithSick.add(tag);
        }
      }
    } catch (_) {
      // If history cannot be loaded, leave sets empty and fall back to basic filters
    }
  }

  void _filtergoat(String query) {
    setState(() {
      searchQuery = query;
      final base = widget.historyType == null
          ? allgoat
          : allgoat.where(_matchesHistoryClassification).toList();

      if (query.isEmpty) {
        filteredgoat = base;
      } else {
        filteredgoat = base.where((goat) {
          // Fix: Use the correct property name from your goat model
          // Replace 'tagNo' with whatever your actual property name is
          final tagNo = (goat.tagNo).toLowerCase(); // Assuming your property is 'tagNo'
          final breed = (goat.breed ?? '').toLowerCase();
          final classification = (goat.classification).toLowerCase();
          final searchLower = query.toLowerCase();
          return tagNo.contains(searchLower) || breed.contains(searchLower) || classification.contains(searchLower);
        }).toList();
      }
    });
  }

  bool _matchesHistoryClassification(goat goat) {
    final type = (widget.historyType ?? '').toLowerCase();
    final sex = (goat.sex).toLowerCase();
    final cls = (goat.classification).toLowerCase();

    // Female-only history types
    const femaleOnly = {
      'dry off', 'gives birth', 'pregnant', 'aborted pregnancy', 'breeding'
    };
    // Male-only history types
    const maleOnly = {
      'castrated'
    };
    // Kid-only history types
    const KidOnly = {
      'weaned'
    };

    if (femaleOnly.contains(type)) {
      final isFemaleEligible = sex == 'female' && (cls == 'Doe' || cls == 'Doeling');
      if (!isFemaleEligible) return false;
      // Extra eligibility rules
      if (type == 'pregnant') {
        // Require an existing Breeding record
        return _tagsWithBreeding.contains(goat.tagNo);
      }
      if (type == 'gives birth') {
        // Require an existing Pregnant record
        return _tagsWithPregnant.contains(goat.tagNo);
      }
      return true; // breeding/dry off/aborted pregnancy baseline
    }
    if (maleOnly.contains(type)) {
      return sex == 'male';
    }
    if (KidOnly.contains(type)) {
      return cls == 'Kid';
    }

    // Treated requires an existing Sick record
    if (type == 'treated') {
      return _tagsWithSick.contains(goat.tagNo);
    }

    // Default: applicable to all classifications
    return true;
  }

  void _selectgoat(goat goat) {
    setState(() {
      selectedgoat = goat;
    });
  }

  void _confirmSelection() {
    if (selectedgoat != null) {
      // Fix: Use the correct property name
      Navigator.of(context).pop(selectedgoat!.tagNo); // Assuming your property is 'tagNo'
    }
  }

  Future<void> _exportExcel() async {
    if (selectedgoat == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final ok = await GoatExportService.downloadgoatExcel(selectedgoat!.id.toString());
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Excel report ready! Choose where to open/save.' : 'Failed to download Excel report.'),
        backgroundColor: ok ? Colors.green.shade600 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (selectedgoat == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final ok = await GoatExportService.downloadgoatPdf(selectedgoat!.id.toString());
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'PDF report ready! Choose where to open/save.' : 'Failed to generate PDF report.'),
        backgroundColor: ok ? Colors.green.shade600 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.vibrantGreen.withValues(alpha: 0.1),
                    AppColors.lightGreen.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.vibrantGreen.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.vibrantGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.vibrantGreen.withValues(alpha: 0.3)),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.Doe,
                      color: AppColors.vibrantGreen,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select goat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Choose a goat to add a history record for',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: _filtergoat,
                decoration: InputDecoration(
                  hintText: 'Search by Goat TagNo or breed...',
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.vibrantGreen, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),

            // goat list
            Flexible(
              child: isLoading
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.vibrantGreen),
                ),
              )
                  : error != null
                  ? _buildErrorState()
                  : filteredgoat.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filteredgoat.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final goat = filteredgoat[index];
                  // Fix: Use the correct property name for comparison
                  final isSelected = selectedgoat?.tagNo == goat.tagNo; // Assuming your property is 'tagNo'
                  return _buildgoatCard(goat, isSelected);
                },
              ),
            ),

            // Footer with action buttons
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Export buttons (only show when goat is selected)
                  if (selectedgoat != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _exportExcel,
                            icon: const FaIcon(FontAwesomeIcons.fileExcel, size: 14),
                            label: const Text('Export Excel', style: TextStyle(fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              side: BorderSide(color: Colors.green.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _exportPdf,
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 14),
                            label: const Text('Export PDF', style: TextStyle(fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              side: BorderSide(color: Colors.red.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedgoat != null ? _confirmSelection : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedgoat != null
                                ? AppColors.vibrantGreen
                                : Colors.grey.shade300,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: selectedgoat != null ? 2 : 0,
                          ),
                          child: Text(
                            'Select',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: selectedgoat != null ? Colors.white : Colors.grey.shade500,
                            ),
                          ),
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
    );
  }

  Widget _buildgoatCard(goat goat, bool isSelected) {
    return InkWell(
      onTap: () => _selectgoat(goat),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.vibrantGreen.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.vibrantGreen.withValues(alpha: 0.5)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColors.vibrantGreen.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.vibrantGreen.withValues(alpha: 0.2)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.vibrantGreen.withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                ),
              ),
              child: FaIcon(
                FontAwesomeIcons.Doe,
                color: isSelected ? AppColors.vibrantGreen : Colors.grey.shade600,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Fix: Use the correct property name
                    goat.tagNo, // Assuming your property is 'tagNo'
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.vibrantGreen : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${goat.classification}'
                    '${(goat.breed != null && goat.breed!.isNotEmpty && goat.breed!.toLowerCase() != 'unknown') ? ' • ${goat.breed}' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _buildgoatOptionsMenu(goat),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.vibrantGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildgoatOptionsMenu(goat goat) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: AppColors.textSecondary.withValues(alpha: 0.8),
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      offset: const Offset(0, 10),
      color: Colors.white,
      shadowColor: Colors.black26,
      onSelected: (String value) async {
        switch (value) {
          case 'edit':
            if (!mounted) break;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => goatFormScreen(goat: goat),
              ),
            );
            if (!mounted) break;
            _loadgoat();
            break;
          case 'add_event':
            if (!mounted) break;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => goatHistoryFormScreen(goatTag: goat.tagNo),
              ),
            );
            if (!mounted) break;
            _loadgoat();
            break;
          case 'change_stage':
            if (!mounted) break;
            ChangeStageOption.show(context, goat, () {
              _loadgoat();
            });
            break;
          case 'change_status':
            if (!mounted) break;
            ChangeStatusOption.show(context, goat, () {
              _loadgoat();
            });
            break;
          case 'export_excel':
            final messenger = ScaffoldMessenger.of(context);
            messenger.hideCurrentSnackBar();
            final ok = await GoatExportService.downloadgoatExcel(goat.id.toString());
            if (!mounted) break;
            messenger.showSnackBar(
              SnackBar(
                content: Text(ok ? 'Excel report ready! Choose where to open/save.' : 'Failed to download Excel report.'),
                backgroundColor: ok ? Colors.green.shade600 : Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            break;
          case 'export_pdf':
            final messenger = ScaffoldMessenger.of(context);
            messenger.hideCurrentSnackBar();
            final ok = await GoatExportService.downloadgoatPdf(goat.id.toString());
            if (!mounted) break;
            messenger.showSnackBar(
              SnackBar(
                content: Text(ok ? 'PDF report ready! Choose where to open/save.' : 'Failed to generate PDF report.'),
                backgroundColor: ok ? Colors.green.shade600 : Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            break;
          case 'archive':
            if (!mounted) break;
            ArchiveOption.show(context, goat: goat, ongoatUpdated: () {
              _loadgoat();
            });
            break;
          case 'delete':
            if (!mounted) break;
            DeleteOption.show(context);
            _loadgoat();
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
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
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(
              searchQuery.isEmpty ? FontAwesomeIcons.Doe : Icons.search_off_rounded,
              size: 48,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? 'No goat Found' : 'No Results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'No goat records are available in the system.'
                : 'Try adjusting your search terms.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading goat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadgoat,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
