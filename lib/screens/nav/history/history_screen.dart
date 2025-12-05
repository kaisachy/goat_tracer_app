// lib/screens/nav/history/history_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/services/goat/goat_history_service.dart';
import 'package:goat_tracer_app/services/goat/goat_history_export_service.dart';
import 'package:goat_tracer_app/screens/nav/goat/widgets/history/history_search_filter_bar.dart';
import 'package:goat_tracer_app/screens/nav/goat/goat_history_form_screen.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/history_duplication_modal.dart';
import 'package:goat_tracer_app/utils/history_type_utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/goat.dart';
import 'goat_selection_modal.dart';
import 'package:goat_tracer_app/services/user_guide_service.dart';
import 'package:showcaseview/showcaseview.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  HistoryScreenState createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> allHistoryRecords = [];
  bool isLoading = true;
  String? error;

  String searchQuery = '';
  String selectedHistoryType = 'All';
  Set<int> expandedCards = <int>{};
  String _addTabCategoryFilter = 'Health'; // Health, Reproduction, Lifecycle
  late TabController _tabController;

  // History report export
  String? _selectedReportHistoryType;

  // User guide keys
  final GlobalKey _tabBarKey = GlobalKey();
  final GlobalKey _addGridKey = GlobalKey();
  final GlobalKey _categoryNavKey = GlobalKey();
  final GlobalKey _historySearchKey = GlobalKey();
  final GlobalKey _historySummaryKey = GlobalKey();
  final GlobalKey _historyListKey = GlobalKey();
  final GlobalKey _historyMenuKey = GlobalKey();

  BuildContext? _showCaseContext;
  final ScrollController _addTabScrollController = ScrollController();
  final ScrollController _historyListScrollController = ScrollController();

  // All possible history types
  List<String> get historyTypes {
    // Reference order for grid: use HistoryTypeUtils for 'Doe' (most complete)
    final doeTypes = HistoryTypeUtils.getHistoryTypesForSex(null, classification: 'Doe');
    return [...doeTypes];
  }

  List<String> get _healthTypes {
    final allTypes = historyTypes.where((t) => t != 'Select type of history record').toList();
    return allTypes
        .where((t) => {
              'Vaccinated',
              'Sick',
              'Treated',
              'Deworming',
              'Hoof Trimming',
            }.contains(t))
        .toList();
  }

  List<String> get _breedingTypes {
    final allTypes = historyTypes.where((t) => t != 'Select type of history record').toList();
    return allTypes
        .where((t) => {
              'Breeding',
              'Pregnant',
              'Kidding',
              'Aborted',
            }.contains(t))
        .toList();
  }

  List<String> get _lifecycleTypes {
    final allTypes = historyTypes.where((t) => t != 'Select type of history record').toList();
    final lifecycleTypes = allTypes
        .where((t) => {
              'Dry off',
              'Weighed',
              'Weaned',
              'Castrated',
              'Mortality',
              'Lost',
              'Sold',
              'Slaughtered',
            }.contains(t))
        .toList();

    final List<String> lifecyclePriority = ['Weaned', 'Castrated'];
    for (final p in lifecyclePriority.reversed) {
      if (lifecycleTypes.remove(p)) {
        lifecycleTypes.insert(0, p);
      }
    }
    return lifecycleTypes;
  }

  Widget _buildAddTabBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildCategoryNavItem(
            label: 'Health',
            value: 'Health',
            icon: Icons.medical_services_rounded,
          ),
          _buildCategoryNavItem(
            label: 'Reproduction',
            value: 'Reproduction',
            icon: Icons.favorite_rounded,
            imagePath: 'assets/images/goat-icons/lactating_pregnant.png',
          ),
          _buildCategoryNavItem(
            label: 'Lifecycle',
            value: 'Lifecycle',
            icon: Icons.timeline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryNavItem({
    required String label,
    required String value,
    required IconData icon,
    String? imagePath,
  }) {
    final bool selected = _addTabCategoryFilter == value;
    final Color activeColor = AppColors.vibrantGreen;
    final Color inactiveColor = Colors.grey.shade500;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            _addTabCategoryFilter = value;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              imagePath != null
                  ? Image.asset(
                      imagePath,
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                      color: selected ? activeColor : inactiveColor,
                      colorBlendMode: BlendMode.srcIn,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          icon,
                          size: 20,
                          color: selected ? activeColor : inactiveColor,
                        );
                      },
                    )
                  : Icon(
                      icon,
                      size: 20,
                      color: selected ? activeColor : inactiveColor,
                    ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: selected ? 18 : 0,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCategorySection({
    required String title,
    required String subtitle,
    required List<String> types,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 4 / 3,
            ),
            itemCount: types.length,
            itemBuilder: (gridContext, index) {
              final type = types[index];
              final color = HistoryTypeUtils.getHistoryColor(type);
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final selectedgoatTag = await showDialog<String>(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) {
                      return GoatSelectionModal(historyType: type);
                    },
                  );
                  if (!mounted || selectedgoatTag == null) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (routeContext) => GoatHistoryFormScreen(
                        goatTag: selectedgoatTag,
                        initialHistoryType: type,
                      ),
                    ),
                  );
                  if (!mounted) return;
                  await _refreshHistory();
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: _buildHistoryIconForGrid(type, color),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // List of history types that can be duplicated
  final List<String> _duplicatableHistoryTypes = [
    'dry off',
    'treated',
    'breeding',
    'vaccinated',
    'deworming',
    'hoof trimming',
    'mortality',
    'lost',
    'sold',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadAllgoatHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _addTabScrollController.dispose();
    _historyListScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAllgoatHistory() async {
    try {
      debugPrint('DEBUG: _loadAllgoatHistory started');
      setState(() => isLoading = true);
      final historyRecords = await GoatHistoryService.getgoatHistory();
      debugPrint('DEBUG: Loaded ${historyRecords.length} history records from service');

      // Remove duplicates and delete them from database
      final uniqueHistoryRecords = await _removeDuplicateHistoryRecordsFromDB(historyRecords);

      // Sort history records by date to show latest first
      uniqueHistoryRecords.sort((a, b) {
        final dateA = DateTime.tryParse(a['history_date'] ?? '1900-01-01') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b['history_date'] ?? '1900-01-01') ?? DateTime(1900);
        return dateB.compareTo(dateA); // Descending order (latest first)
      });

      // Kid tags are now stored directly in the database as comma-separated values
      // No need for complex aggregation logic

      if (mounted) {
        setState(() {
          allHistoryRecords = uniqueHistoryRecords;
          isLoading = false;
          error = null;

          // Auto-expand the latest history record (index 0 after sorting)
          if (allHistoryRecords.isNotEmpty) {
            expandedCards.add(0);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Failed to load history records: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshHistory() async {
    debugPrint('DEBUG: _refreshHistory called');
    await _loadAllgoatHistory();
    debugPrint('DEBUG: _refreshHistory completed');
  }

  Future<void> _scrollToShowcase(GlobalKey key) async {
    final context = key.currentContext;
    if (context != null) {
      try {
        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
      } catch (e) {
        debugPrint('Error scrolling to showcase: $e');
      }
    }
  }

  void startUserGuide() async {
    if (_showCaseContext == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait a moment and try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    await UserGuideService.resetGuide('goat_history');

    if (mounted && _showCaseContext != null) {
      try {
        await Future.delayed(const Duration(milliseconds: 300));

        final showcaseKeys = <GlobalKey>[_tabBarKey];
        if (_tabController.index == 0) {
          showcaseKeys.addAll([
            _addGridKey,
            _categoryNavKey,
          ]);
        } else {
          showcaseKeys.add(_historySearchKey);
          if (allHistoryRecords.isNotEmpty) {
            showcaseKeys.add(_historySummaryKey);
          }
          showcaseKeys.add(_historyListKey);
          if (_filteredHistoryRecords.isNotEmpty) {
            showcaseKeys.add(_historyMenuKey);
          }
        }

        ShowCaseWidget.of(_showCaseContext!).startShowCase(showcaseKeys);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unable to start user guide. Please try again.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  // Helper method to remove duplicate history records and delete them from database
  Future<List<Map<String, dynamic>>> _removeDuplicateHistoryRecordsFromDB(List<Map<String, dynamic>> historyRecords) async {
    final List<Map<String, dynamic>> uniqueHistoryRecords = [];
    final List<Map<String, dynamic>> duplicatesToDelete = [];
    int deletedCount = 0;

    for (final historyRecord in historyRecords) {
      final existingHistoryRecordIndex = uniqueHistoryRecords.indexWhere((existingHistoryRecord) =>
          _areHistoryRecordsIdentical(historyRecord, existingHistoryRecord));

      if (existingHistoryRecordIndex == -1) {
        // No duplicate found, add to unique history records
        uniqueHistoryRecords.add(historyRecord);
      } else {
        // Duplicate found - decide which one to keep and which to delete
        final existingHistoryRecord = uniqueHistoryRecords[existingHistoryRecordIndex];
        final currentHistoryRecordDate = DateTime.tryParse(historyRecord['history_date'] ?? '1900-01-01') ?? DateTime(1900);
        final existingHistoryRecordDate = DateTime.tryParse(existingHistoryRecord['history_date'] ?? '1900-01-01') ?? DateTime(1900);

        // Keep the more recent history record, or the one with higher ID if dates are same
        if (currentHistoryRecordDate.isAfter(existingHistoryRecordDate) ||
            (currentHistoryRecordDate == existingHistoryRecordDate && (historyRecord['id'] ?? 0) > (existingHistoryRecord['id'] ?? 0))) {
          // Current history record is newer/better, replace existing and mark old for deletion
          duplicatesToDelete.add(existingHistoryRecord);
          uniqueHistoryRecords[existingHistoryRecordIndex] = historyRecord;
        } else {
          // Existing history record is newer/better, mark current for deletion
          duplicatesToDelete.add(historyRecord);
        }
      }
    }

    // Delete duplicates from database
    if (duplicatesToDelete.isNotEmpty) {
      try {
        for (final duplicate in duplicatesToDelete) {
          final historyRecordId = duplicate['id'];
          if (historyRecordId != null) {
            final success = await GoatHistoryService.deletegoatHistory(historyRecordId);
            if (success) {
              deletedCount++;
            } else {
              debugPrint('Failed to delete duplicate history record with ID: $historyRecordId');
            }
          }
        }

        // Show notification about deleted duplicates
        if (mounted && deletedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed $deletedCount duplicate history record${deletedCount > 1 ? 's' : ''} from database'),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting duplicate history records: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Warning: Some duplicate history records could not be removed from database'),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }

    return uniqueHistoryRecords;
  }

  // Helper method to check if two history records are identical
  bool _areHistoryRecordsIdentical(Map<String, dynamic> historyRecord1, Map<String, dynamic> historyRecord2) {
    // Get the history type to determine which fields to compare
    final historyType1 = (historyRecord1['history_type'] ?? '').toString().toLowerCase();
    final historyType2 = (historyRecord2['history_type'] ?? '').toString().toLowerCase();

    // If history types are different, they're not identical
    if (historyType1 != historyType2) return false;

    // Compare basic fields that are always relevant
    if (!_compareFieldValues(historyRecord1['history_date'], historyRecord2['history_date'])) return false;
    if (!_compareFieldValues(historyRecord1['goat_tag'], historyRecord2['goat_tag'])) return false;
    if (!_compareFieldValues(historyRecord1['notes'], historyRecord2['notes'])) return false;

    // Compare history-specific fields based on history type
    switch (historyType1) {
      case 'dry off':
      case 'aborted':
      case 'hoof trimming':
      case 'weaned':
        return true;

      case 'treated':
        return _compareFieldValues(historyRecord1['disease_type'], historyRecord2['disease_type']) &&
            _compareFieldValues(historyRecord1['diagnosis'], historyRecord2['diagnosis']) &&
            _compareFieldValues(historyRecord1['technician'], historyRecord2['technician']) &&
            _compareFieldValues(historyRecord1['medicine_given'], historyRecord2['medicine_given']);

      case 'breeding':
        return _compareFieldValues(historyRecord1['semen_used'], historyRecord2['semen_used']) &&
            _compareFieldValues(historyRecord1['technician'], historyRecord2['technician']) &&
            _compareFieldValues(historyRecord1['estimated_return_date'], historyRecord2['estimated_return_date']);

      case 'weighed':
        return _compareFieldValues(historyRecord1['weighed_result'], historyRecord2['weighed_result']);

      case 'kidding':
        return _compareFieldValues(historyRecord1['Buck_tag'], historyRecord2['Buck_tag']) &&
            _compareFieldValues(historyRecord1['Kid_tag'], historyRecord2['Kid_tag']);

      case 'vaccinated':
        return _compareFieldValues(historyRecord1['medicine_given'], historyRecord2['medicine_given']) &&
            _compareFieldValues(historyRecord1['technician'], historyRecord2['technician']);

      case 'pregnant':
        return _compareFieldValues(historyRecord1['breeding_date'], historyRecord2['breeding_date']) &&
            _compareFieldValues(historyRecord1['expected_delivery_date'], historyRecord2['expected_delivery_date']) &&
            _compareFieldValues(historyRecord1['Buck_tag'], historyRecord2['Buck_tag']);

      case 'deworming':
        return _compareFieldValues(historyRecord1['medicine_given'], historyRecord2['medicine_given']);

      case 'castrated':
        return _compareFieldValues(historyRecord1['technician'], historyRecord2['technician']);

      case 'mortality':
        return _compareFieldValues(historyRecord1['cause_of_death'], historyRecord2['cause_of_death']);

      case 'sold':
        return _compareFieldValues(historyRecord1['sold_amount'], historyRecord2['sold_amount']) &&
            _compareFieldValues(historyRecord1['buyer'], historyRecord2['buyer']);

      case 'sick':
        return _compareFieldValues(historyRecord1['disease_type'], historyRecord2['disease_type']);

      case 'lost':
        return _compareFieldValues(historyRecord1['last_known_location'], historyRecord2['last_known_location']);

      default:
        return _compareFieldValues(historyRecord1['Buck_tag'], historyRecord2['Buck_tag']) &&
            _compareFieldValues(historyRecord1['Kid_tag'], historyRecord2['Kid_tag']) &&
            _compareFieldValues(historyRecord1['technician'], historyRecord2['technician']) &&
            _compareFieldValues(historyRecord1['sickness_symptoms'], historyRecord2['sickness_symptoms']) &&
            _compareFieldValues(historyRecord1['diagnosis'], historyRecord2['diagnosis']) &&
            _compareFieldValues(historyRecord1['medicine_given'], historyRecord2['medicine_given']) &&
            _compareFieldValues(historyRecord1['semen_used'], historyRecord2['semen_used']) &&
            _compareFieldValues(historyRecord1['estimated_return_date'], historyRecord2['estimated_return_date']) &&
            _compareFieldValues(historyRecord1['weighed_result'], historyRecord2['weighed_result']) &&
            _compareFieldValues(historyRecord1['breeding_date'], historyRecord2['breeding_date']) &&
            _compareFieldValues(historyRecord1['expected_delivery_date'], historyRecord2['expected_delivery_date']) &&
            _compareFieldValues(historyRecord1['sold_amount'], historyRecord2['sold_amount']) &&
            _compareFieldValues(historyRecord1['buyer'], historyRecord2['buyer']) &&
            _compareFieldValues(historyRecord1['last_known_location'], historyRecord2['last_known_location']);
    }
  }

  // Helper method to compare field values, treating null, empty, and 'N/A' as equivalent
  bool _compareFieldValues(dynamic value1, dynamic value2) {
    final normalizedValue1 = _normalizeFieldValue(value1);
    final normalizedValue2 = _normalizeFieldValue(value2);
    return normalizedValue1 == normalizedValue2;
  }

  // Helper method to normalize field values for comparison
  String? _normalizeFieldValue(dynamic value) {
    if (value == null) return null;
    final stringValue = value.toString().trim();
    if (stringValue.isEmpty || stringValue.toLowerCase() == 'n/a') {
      return null;
    }
    return stringValue.toLowerCase();
  }


  List<Map<String, dynamic>> get _filteredHistoryRecords {
    return allHistoryRecords.where((historyRecord) {
      final type = (historyRecord['history_type'] ?? '').toString().toLowerCase();
      final notes = (historyRecord['notes'] ?? '').toString().toLowerCase();
      final diagnosis = (historyRecord['diagnosis'] ?? '').toString().toLowerCase();
      final goatTag = (historyRecord['goat_tag'] ?? '').toString().toLowerCase();
      final query = searchQuery.toLowerCase();

      final matchesSearch = type.contains(query) ||
          notes.contains(query) ||
          diagnosis.contains(query) ||
          goatTag.contains(query);

      final matchesFilter = selectedHistoryType == 'All' ||
          type == selectedHistoryType.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() => searchQuery = query);
  }

  void _onFilterChanged(String filter) {
    setState(() => selectedHistoryType = filter);
  }

  void _onClearFilter() {
    setState(() => selectedHistoryType = 'All');
  }

  // Check if a history type can be duplicated
  bool _canDuplicateHistory(String historyType) {
    return _duplicatableHistoryTypes.contains(historyType.toLowerCase());
  }

  bool _isAutoGeneratedBuckBreeding(Map<String, dynamic> historyRecord) {
    final type = (historyRecord['history_type'] ?? '').toString().toLowerCase();
    if (type != 'breeding') return false;
    final notes = (historyRecord['notes'] ?? '').toString().toLowerCase();
    return notes.startsWith('breeding with');
  }

  void _showHistoryMenu(BuildContext context, Map<String, dynamic> historyRecord, int index) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final historyType = historyRecord['history_type']?.toString() ?? '';
    final isAutoBuckBreeding = _isAutoGeneratedBuckBreeding(historyRecord);
    final canDuplicate = _canDuplicateHistory(historyType) && !isAutoBuckBreeding;

    showMenu(
      context: context,
      position: position,
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      items: [
        if (canDuplicate)
          PopupMenuItem(
            value: 'duplicate',
            child: Row(
              children: [
                Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                const Text('Duplicate History Record'),
              ],
            ),
          ),
        if (!isAutoBuckBreeding)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_rounded, color: AppColors.vibrantGreen, size: 20),
                const SizedBox(width: 12),
                const Text('Edit History Record'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, color: Colors.red.shade400, size: 20),
              const SizedBox(width: 12),
              Text('Delete History', style: TextStyle(color: Colors.red.shade400)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        if (value == 'duplicate') {
          _duplicateHistory(historyRecord);
        } else if (value == 'edit') {
          _editHistory(historyRecord);
        } else if (value == 'delete') {
          _deleteHistory(historyRecord);
        }
      }
    });
  }

  void _duplicateHistory(Map<String, dynamic> historyRecord) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return HistoryDuplicationModal(originalEvent: historyRecord);
        },
      );

      if (result == true) {
        await _refreshHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening duplication modal: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _editHistory(Map<String, dynamic> historyRecord) async {
    try {
      // Create a GoatHistoryRecord object from the history record data
      final historyRecordObj = GoatHistoryRecord(
        id: historyRecord['id'] ?? 0,
        userId: historyRecord['user_id'] ?? 0,
        goatTag: historyRecord['goat_tag']?.toString() ?? '',
        buckTag: historyRecord['buck_tag']?.toString() ?? historyRecord['Buck_tag']?.toString(),
        kidTag: historyRecord['kid_tag']?.toString() ?? historyRecord['Kid_tag']?.toString(),
        historyType: historyRecord['history_type']?.toString() ?? '',
        historyDate: historyRecord['history_date']?.toString() ?? '',
        sicknessSymptoms: historyRecord['sickness_symptoms']?.toString(),
        diagnosis: historyRecord['diagnosis']?.toString(),
        technician: historyRecord['technician']?.toString(),
        medicineGiven: historyRecord['medicine_given']?.toString(),
        semenUsed: historyRecord['semen_used']?.toString(),
        estimatedReturnDate: historyRecord['estimated_return_date']?.toString(),
        weighedResult: historyRecord['weighed_result'] != null
            ? double.tryParse(historyRecord['weighed_result'].toString())
            : null,
        breedingDate: historyRecord['breeding_date']?.toString(),
        expectedDeliveryDate: historyRecord['expected_delivery_date']?.toString(),
        notes: historyRecord['notes']?.toString(),
        lastKnownLocation: historyRecord['last_known_location']?.toString(),
        soldAmount: historyRecord['sold_amount'] != null
            ? double.tryParse(historyRecord['sold_amount'].toString())
            : null,
        buyer: historyRecord['buyer']?.toString(),
        diseaseType: historyRecord['disease_type']?.toString(),
        diseaseTypeOther: historyRecord['disease_type_other']?.toString(),
      );

      // Navigate to edit screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GoatHistoryFormScreen(
            historyRecord: historyRecordObj,
            goatTag: historyRecord['goat_tag']?.toString() ?? '',
          ),
        ),
      );

      if (result == true) {
        await _refreshHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('History record updated successfully!'),
              backgroundColor: AppColors.vibrantGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening edit screen: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _deleteHistory(Map<String, dynamic> historyRecord) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Widget buildInfoRow(IconData icon, String label, String value) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final historyType = (historyRecord['history_type'] ?? 'History').toString();
        final goatTag = (historyRecord['goat_tag'] ?? 'Unknown').toString();
        final historyDate = _formatDate(historyRecord['history_date']);

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(
                      bottom: BorderSide(color: Colors.red.shade100),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.delete_forever_rounded, color: Colors.red.shade700),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Delete History',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'This action cannot be undone',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Removing this history record will permanently erase it from the timeline.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildInfoRow(Icons.timeline_rounded, 'History Type', historyType),
                            buildInfoRow(Icons.tag_rounded, 'Goat Tag', goatTag),
                            buildInfoRow(Icons.calendar_today_rounded, 'Date', historyDate),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _performDelete(historyRecord);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            shadowColor: Colors.red.shade200,
                          ),
                          child: const Text('Delete Record'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _performDelete(Map<String, dynamic> historyRecord) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Deleting history record...'),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            duration: const Duration(seconds: 10),
          ),
        );
      }

      final success = await GoatHistoryService.deletegoatHistory(historyRecord['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (success) {
        await _refreshHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('History record "${historyRecord['history_type']}" deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete history record "${historyRecord['history_type']}"'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting history record: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      enableAutoScroll: true,
      scrollDuration: const Duration(milliseconds: 300),
      onFinish: () async {
        await UserGuideService.markGuideCompleted('goat_history');
      },
      onStart: (index, key) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToShowcase(key);
        });
      },
      builder: (showCaseContext) {
        _showCaseContext = showCaseContext;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Showcase(
                  key: _tabBarKey,
                  title: 'History Tabs',
                  description:
                      'Switch between adding new history entries or reviewing everything recorded.',
                  targetShapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tooltipBackgroundColor: AppColors.primary,
                  textColor: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.vibrantGreen,
                    labelColor: AppColors.vibrantGreen,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Add History'),
                      Tab(text: 'History List'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Add History
                    Column(
                      children: [
                        Expanded(
                          child: Showcase(
                            key: _addGridKey,
                            title: 'History Type Grid',
                            description:
                                'Pick which goat history record you´d like to add. Each tile opens the matching form automatically.',
                            targetShapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            tooltipBackgroundColor: AppColors.primary,
                            textColor: Colors.white,
                            child: ListView(
                              controller: _addTabScrollController,
                              padding: const EdgeInsets.all(16),
                              children: [
                                if (_addTabCategoryFilter == 'Health' && _healthTypes.isNotEmpty)
                                  _buildHistoryCategorySection(
                                    title: 'Goat Health & Treatment',
                                    subtitle:
                                        'Record sickness, treatments, vaccinations, weighing, and other health-related events.',
                                    types: _healthTypes,
                                  ),
                                if (_addTabCategoryFilter == 'Reproduction' && _breedingTypes.isNotEmpty)
                                  _buildHistoryCategorySection(
                                    title: 'Breeding & Reproduction',
                                    subtitle: 'Log breeding, pregnancies, kidding, and reproductive events.',
                                    types: _breedingTypes,
                                  ),
                                if (_addTabCategoryFilter == 'Lifecycle' && _lifecycleTypes.isNotEmpty)
                                  _buildHistoryCategorySection(
                                    title: 'Goat Lifecycle Management',
                                    subtitle: 'Track dry-off, weaning, sales, losses, and other lifecycle changes.',
                                    types: _lifecycleTypes,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SafeArea(
                          top: false,
                          minimum: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Showcase(
                              key: _categoryNavKey,
                              title: 'Category Filter',
                              description: 'Toggle categories to quickly focus the grid.',
                              targetShapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              tooltipBackgroundColor: AppColors.primary,
                              textColor: Colors.white,
                              child: _buildAddTabBottomNav(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Tab 2: History List
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Showcase(
                            key: _historySearchKey,
                            title: 'Search & Filter',
                            description:
                                'Search by goat tag, history type, or notes. Filter to focus on a specific event type.',
                            targetShapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            tooltipBackgroundColor: AppColors.primary,
                            textColor: Colors.white,
                            child: Row(
                              children: [
                                Expanded(
                                  child: HistorySearchFilterBar(
                                    initialSearchQuery: searchQuery,
                                    initialEventType: selectedHistoryType,
                                    eventTypes: historyTypes,
                                    onSearchChanged: _onSearchChanged,
                                    onFilterChanged: _onFilterChanged,
                                    onClearFilter: _onClearFilter,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (allHistoryRecords.isNotEmpty) ...[
                            Showcase(
                              key: _historySummaryKey,
                              title: 'History Insights',
                              description:
                                  'See totals, filtered counts, and the latest record date at a glance.',
                              targetShapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              tooltipBackgroundColor: AppColors.primary,
                              textColor: Colors.white,
                              child: _buildHistorySummary(),
                            ),
                            const SizedBox(height: 16),
                            // History report type & export buttons (Excel / PDF)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedReportHistoryType,
                                      items: [
                                        const DropdownMenuItem<String>(
                                          value: null,
                                          child: Text('Select history type'),
                                        ),
                                        ...historyTypes
                                            .where((t) => t != 'Select type of history record')
                                            .map(
                                              (t) => DropdownMenuItem<String>(
                                                value: t,
                                                child: Text(t),
                                              ),
                                            ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedReportHistoryType = value;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'History report type',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF107C41),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: IconButton(
                                          tooltip: 'Export Excel',
                                          icon: const FaIcon(
                                            FontAwesomeIcons.fileExcel,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            if (_selectedReportHistoryType == null ||
                                                _selectedReportHistoryType!.isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Please select a history type first.'),
                                                  duration: Duration(seconds: 2),
                                                ),
                                              );
                                              return;
                                            }

                                            final messenger = ScaffoldMessenger.of(context);
                                            messenger.hideCurrentSnackBar();
                                            final ok = await GoatHistoryExportService
                                                .downloadHistoryExcel(_selectedReportHistoryType!);
                                            if (!mounted) return;
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  ok
                                                      ? 'Excel history report ready! Choose where to open/save.'
                                                      : 'Failed to download Excel history report.',
                                                ),
                                                backgroundColor: ok
                                                    ? Colors.green.shade600
                                                    : Colors.red.shade700,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade600,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: IconButton(
                                          tooltip: 'Export PDF',
                                          icon: const Icon(
                                            Icons.picture_as_pdf_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            if (_selectedReportHistoryType == null ||
                                                _selectedReportHistoryType!.isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Please select a history type first.'),
                                                  duration: Duration(seconds: 2),
                                                ),
                                              );
                                              return;
                                            }

                                            final messenger = ScaffoldMessenger.of(context);
                                            messenger.hideCurrentSnackBar();
                                            final ok = await GoatHistoryExportService
                                                .downloadHistoryPdf(_selectedReportHistoryType!);
                                            if (!mounted) return;
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  ok
                                                      ? 'PDF history report ready! Choose where to open/save.'
                                                      : 'Failed to generate PDF history report.',
                                                ),
                                                backgroundColor: ok
                                                    ? Colors.green.shade600
                                                    : Colors.red.shade700,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Expanded(
                            child: Showcase(
                              key: _historyListKey,
                              title: 'History Timeline',
                              description:
                                  'Scroll through the complete goat history timeline. Tap any card to expand details or open quick actions.',
                              targetShapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              tooltipBackgroundColor: AppColors.primary,
                              textColor: Colors.white,
                              child: RefreshIndicator(
                                onRefresh: _refreshHistory,
                                color: AppColors.vibrantGreen,
                                child: isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(color: AppColors.vibrantGreen),
                                      )
                                    : error != null
                                        ? _buildErrorState()
                                        : _filteredHistoryRecords.isEmpty
                                            ? _buildEmptyState()
                                            : ListView.separated(
                                                controller: _historyListScrollController,
                                                physics: const AlwaysScrollableScrollPhysics(),
                                                padding: const EdgeInsets.only(bottom: 20),
                                                itemCount: _filteredHistoryRecords.length,
                                                separatorBuilder: (context, index) =>
                                                    const SizedBox(height: 12),
                                                itemBuilder: (context, index) =>
                                                    _buildHistoryAccordion(_filteredHistoryRecords[index], index),
                                              ),
                              ),
                            ),
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
      },
    );
  }

  Widget _buildHistorySummary() {
    if (allHistoryRecords.isEmpty) return const SizedBox.shrink();

    final totalHistoryRecords = allHistoryRecords.length;
    final filteredCount = _filteredHistoryRecords.length;
    final recentHistoryRecord = allHistoryRecords.isNotEmpty
        ? allHistoryRecords.reduce((a, b) =>
    DateTime.parse(a['history_date'] ?? '1900-01-01')
        .isAfter(DateTime.parse(b['history_date'] ?? '1900-01-01')) ? a : b)
        : null;

    // Get unique goat count
    final _ = allHistoryRecords
        .map((historyRecord) => historyRecord['goat_tag']?.toString() ?? '')
        .where((tag) => tag.isNotEmpty)
        .toSet();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.history_rounded,
              label: 'Total History Records',
              value: '$totalHistoryRecords',
              color: AppColors.vibrantGreen,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.filter_list_rounded,
              label: 'Showing',
              value: '$filteredCount',
              color: AppColors.lightGreen,
            ),
          ),
          if (recentHistoryRecord != null) ...[
            Container(width: 1, height: 40, color: Colors.grey.shade200),
            Expanded(
              child: _buildSummaryItem(
                icon: Icons.schedule_rounded,
                label: 'Latest',
                value: _formatDate(recentHistoryRecord['history_date']),
                color: Colors.blue.shade400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryAccordion(Map<String, dynamic> historyRecord, int index) {
    final historyType = historyRecord['history_type'] ?? 'Unknown';
    final historyDate = historyRecord['history_date'];
    final goatTag = historyRecord['goat_tag']?.toString() ?? 'Unknown';
    final historyColor = HistoryTypeUtils.getHistoryColor(historyType);
    final details = _getHistoryDetails(historyRecord);
    final isExpanded = expandedCards.contains(index);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: historyColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: historyColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Header - Always visible (clickable)
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  expandedCards.remove(index);
                } else {
                  expandedCards.add(index);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: historyColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: historyColor.withValues(alpha: 0.3)),
                    ),
                    child: _buildHistoryIcon(historyType, historyColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          historyType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: historyColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: historyColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: historyColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            goatTag,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(historyDate),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(
                        builder: (context) {
                          final iconButton = IconButton(
                            onPressed: () => _showHistoryMenu(context, historyRecord, index),
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            tooltip: 'More options',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          );

                          if (index == 0) {
                            return Showcase(
                              key: _historyMenuKey,
                              title: 'Entry Actions',
                              description:
                                  'Tap here to duplicate, edit, or delete a goat history record. Every card has its own menu.',
                              targetShapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              tooltipBackgroundColor: AppColors.primary,
                              textColor: Colors.white,
                              child: iconButton,
                            );
                          }

                          return iconButton;
                        },
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: historyColor,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Expandable Details section
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isExpanded && details.isNotEmpty ? null : 0,
            child: isExpanded && details.isNotEmpty
                ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: historyColor.withValues(alpha: 0.2),
                    margin: const EdgeInsets.only(bottom: 16),
                  ),
                  ...details.asMap().entries.map((entry) {
                    final index = entry.key;
                    final detail = entry.value;
                    return Column(
                      children: [
                        if (index > 0) const SizedBox(height: 12),
                        _buildDetailRow(detail.key, detail.value),
                      ],
                    );
                  }),
                ],
              ),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryIcon(String historyType, Color color) {
    final imagePath = HistoryTypeUtils.getHistoryImagePath(historyType);
    if (imagePath != null) {
      return Image.asset(
        imagePath,
        width: 18,
        height: 18,
        fit: BoxFit.contain,
        color: color,
        colorBlendMode: BlendMode.srcIn,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails to load
          return Icon(HistoryTypeUtils.getHistoryIcon(historyType), color: color, size: 24);
        },
      );
    } else {
      return Icon(HistoryTypeUtils.getHistoryIcon(historyType), color: color, size: 24);
    }
  }

  Widget _buildHistoryIconForGrid(String historyType, Color color) {
    final imagePath = HistoryTypeUtils.getHistoryImagePath(historyType);
    return Center(
      child: imagePath != null
          ? Image.asset(
              imagePath,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              color: color,
              colorBlendMode: BlendMode.srcIn,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to icon if image fails to load
                return Icon(HistoryTypeUtils.getHistoryIcon(historyType), color: color, size: 24);
              },
            )
          : Icon(HistoryTypeUtils.getHistoryIcon(historyType), color: color, size: 24),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }

  String? _normalizeHistoryValue(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase() == 'n/a') {
        return null;
      }
      return trimmed;
    }
    final stringValue = value.toString().trim();
    if (stringValue.isEmpty || stringValue.toLowerCase() == 'n/a') {
      return null;
    }
    return stringValue;
  }

  String? _getFieldValue(
    Map<String, dynamic> record,
    List<String> candidateKeys,
  ) {
    if (record.isEmpty) return null;

    final normalized = <String, dynamic>{};
    record.forEach((key, value) {
      normalized[key.toString().toLowerCase()] = value;
    });

    for (final key in candidateKeys) {
      dynamic raw;
      if (record.containsKey(key)) {
        raw = record[key];
      } else {
        raw = normalized[key.toLowerCase()];
      }

      final normalizedValue = _normalizeHistoryValue(raw);
      if (normalizedValue != null) {
        return normalizedValue;
      }
    }
    return null;
  }

  List<String> _extractKidTags(Map<String, dynamic> historyRecord) {
    final tags = <String>[];

    void addTag(dynamic value) {
      final normalizedTag = _normalizeHistoryValue(value);
      if (normalizedTag != null && normalizedTag.isNotEmpty) {
        tags.add(normalizedTag);
      }
    }

    void collectFromEntry(dynamic entry) {
      if (entry is Map<String, dynamic>) {
        final tag = _getFieldValue(
          entry,
          ['Kid_tag', 'kid_tag', 'KidTag', 'kidTag', 'tag', 'Tag', 'tag_no', 'tagNo'],
        );
        if (tag != null) {
          tags.add(tag);
        }
      } else if (entry is Map) {
        collectFromEntry(
          entry.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        );
      } else if (entry is Iterable) {
        for (final nested in entry) {
          collectFromEntry(nested);
        }
      } else if (entry is String) {
        addTag(entry);
      }
    }

    final dynamic kidDataRaw = historyRecord['Kid_data'] ?? historyRecord['kid_data'];
    if (kidDataRaw is String && kidDataRaw.trim().isNotEmpty) {
      final raw = kidDataRaw.trim();
      try {
        final decoded = jsonDecode(raw);
        collectFromEntry(decoded);
      } catch (_) {
        for (final chunk in raw.split(',')) {
          addTag(chunk);
        }
      }
    } else if (kidDataRaw is Iterable) {
      collectFromEntry(kidDataRaw);
    } else if (kidDataRaw is Map) {
      collectFromEntry(kidDataRaw);
    }

    if (tags.isEmpty) {
      final fallback = _getFieldValue(
        historyRecord,
        ['Kid_tag', 'kid_tag', 'KidTag', 'kidTag', 'Kid_tags', 'kid_tags'],
      );
      if (fallback != null) {
        if (fallback.contains(',')) {
          for (final chunk in fallback.split(',')) {
            addTag(chunk);
          }
        } else {
          addTag(fallback);
        }
      }
    }

    final deduped = <String>{};
    for (final tag in tags) {
      final normalized = tag.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (normalized.isNotEmpty) {
        deduped.add(normalized);
      }
    }

    return deduped.toList();
  }

  List<MapEntry<String, String>> _getHistoryDetails(Map<String, dynamic> historyRecord) {
    final historyType = (historyRecord['history_type'] ?? '').toString().toLowerCase();
    final originalHistoryType = historyRecord['history_type']?.toString();
    final Map<String, String?> relevantDetails = {};

    // Always show notes if available
    if (historyRecord['notes'] != null && historyRecord['notes'].toString().isNotEmpty && historyRecord['notes'] != 'N/A') {
      relevantDetails['Notes'] = historyRecord['notes'].toString();
    }

    // Special handling for Kidding history records (check both lowercase and original case)
    if (historyType == 'kidding' || originalHistoryType?.toLowerCase() == 'kidding') {
      final buckTag = _getFieldValue(
        historyRecord,
        [
          'Buck_tag',
          'buck_tag',
          'BuckTag',
          'buckTag',
          'partner_tag',
          'partnerTag',
          'sire_tag',
          'Sire_tag',
        ],
      );
      if (buckTag != null) {
        relevantDetails['Buck Tag (Father)'] = buckTag;
      }

      final kidTags = _extractKidTags(historyRecord);
      if (kidTags.isNotEmpty) {
        relevantDetails[kidTags.length > 1 ? 'Kid Tags' : 'Kid Tag'] = kidTags.join(', ');
        relevantDetails['Litter Size'] = '${kidTags.length}';
      } else {
        relevantDetails['Kid Tag'] = '—';
        relevantDetails['Litter Size'] = '0';
      }
    }

    // Add history-specific fields based on history type
    switch (historyType) {
      case 'dry off':
      case 'aborted':
      case 'hoof trimming':
      case 'weaned':
      // No additional fields for these history types
        break;

      case 'treated':
        if (historyRecord['disease_type'] != null && historyRecord['disease_type'].toString().isNotEmpty && historyRecord['disease_type'] != 'N/A') {
          relevantDetails['Type of Disease'] = historyRecord['disease_type'].toString();
        }
        if (historyRecord['diagnosis'] != null && historyRecord['diagnosis'].toString().isNotEmpty && historyRecord['diagnosis'] != 'N/A') {
          relevantDetails['Diagnosis'] = historyRecord['diagnosis'].toString();
        }
        if (historyRecord['technician'] != null && historyRecord['technician'].toString().isNotEmpty && historyRecord['technician'] != 'N/A') {
          relevantDetails['Technician'] = historyRecord['technician'].toString();
        }
        if (historyRecord['medicine_given'] != null && historyRecord['medicine_given'].toString().isNotEmpty && historyRecord['medicine_given'] != 'N/A') {
          relevantDetails['Medicine Given'] = historyRecord['medicine_given'].toString();
        }
        break;

      case 'breeding':
        if (historyRecord['semen_used'] != null && historyRecord['semen_used'].toString().isNotEmpty && historyRecord['semen_used'] != 'N/A') {
          relevantDetails['Semen Used'] = historyRecord['semen_used'].toString();
        }
        if (historyRecord['technician'] != null && historyRecord['technician'].toString().isNotEmpty && historyRecord['technician'] != 'N/A') {
          relevantDetails['Technician'] = historyRecord['technician'].toString();
        }
        if (historyRecord['estimated_return_date'] != null && historyRecord['estimated_return_date'].toString().isNotEmpty && historyRecord['estimated_return_date'] != 'N/A') {
          relevantDetails['Est. Return to Heat'] = _formatDate(historyRecord['estimated_return_date']);
        }
        break;

      case 'weighed':
        if (historyRecord['weighed_result'] != null && historyRecord['weighed_result'].toString().isNotEmpty && historyRecord['weighed_result'] != 'N/A') {
          relevantDetails['Weight (kg)'] = historyRecord['weighed_result'].toString();
        }
        break;

      case 'kidding':
        // Already handled above in the special Kidding section
        break;

      case 'vaccinated':
        if (historyRecord['medicine_given'] != null && historyRecord['medicine_given'].toString().isNotEmpty && historyRecord['medicine_given'] != 'N/A') {
          relevantDetails['Vaccine Given'] = historyRecord['medicine_given'].toString();
        }
        if (historyRecord['technician'] != null && historyRecord['technician'].toString().isNotEmpty && historyRecord['technician'] != 'N/A') {
          relevantDetails['Technician'] = historyRecord['technician'].toString();
        }
        break;

      case 'pregnant':
        if (historyRecord['breeding_date'] != null && historyRecord['breeding_date'].toString().isNotEmpty && historyRecord['breeding_date'] != 'N/A') {
          relevantDetails['Breeding Date'] = _formatDate(historyRecord['breeding_date']);
        }
        if (historyRecord['expected_delivery_date'] != null && historyRecord['expected_delivery_date'].toString().isNotEmpty && historyRecord['expected_delivery_date'] != 'N/A') {
          relevantDetails['Expected Delivery'] = _formatDate(historyRecord['expected_delivery_date']);
        }
        if (historyRecord['Buck_tag'] != null && historyRecord['Buck_tag'].toString().isNotEmpty && historyRecord['Buck_tag'] != 'N/A') {
          relevantDetails['Buck Tag (Father)'] = historyRecord['Buck_tag'].toString();
        }
        break;

      case 'deworming':
        if (historyRecord['medicine_given'] != null && historyRecord['medicine_given'].toString().isNotEmpty && historyRecord['medicine_given'] != 'N/A') {
          relevantDetails['Deworming Medicine'] = historyRecord['medicine_given'].toString();
        }
        break;

      case 'castrated':
        if (historyRecord['technician'] != null && historyRecord['technician'].toString().isNotEmpty && historyRecord['technician'].toString() != 'N/A') {
          relevantDetails['Technician'] = historyRecord['technician'].toString();
        }
        break;

      case 'mortality':
        if (historyRecord['cause_of_death'] != null && historyRecord['cause_of_death'].toString().isNotEmpty && historyRecord['cause_of_death'].toString() != 'N/A') {
          relevantDetails['Cause of Death'] = historyRecord['cause_of_death'].toString();
        }
        break;

      case 'sold':
        if (historyRecord['sold_amount'] != null && historyRecord['sold_amount'].toString().isNotEmpty && historyRecord['sold_amount'] != 'N/A') {
          relevantDetails['Sold Amount'] = '₱${historyRecord['sold_amount'].toString()}';
        }
        if (historyRecord['buyer'] != null && historyRecord['buyer'].toString().isNotEmpty && historyRecord['buyer'] != 'N/A') {
          relevantDetails['Seller'] = historyRecord['buyer'].toString();
        }
        break;

      case 'sick':
        if (historyRecord['disease_type'] != null && historyRecord['disease_type'].toString().isNotEmpty && historyRecord['disease_type'] != 'N/A') {
          relevantDetails['Type of Disease'] = historyRecord['disease_type'].toString();
        }
        break;

      case 'lost':
        if (historyRecord['last_known_location'] != null && historyRecord['last_known_location'].toString().isNotEmpty && historyRecord['last_known_location'].toString() != 'N/A') {
          relevantDetails['Last Known Location'] = historyRecord['last_known_location'].toString();
        }
        break;

      default:
        // For any other history types, show basic information
        break;
    }

    final result = relevantDetails.entries
        .map((entry) => MapEntry(entry.key, entry.value!))
        .toList();
    
    return result;
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildEmptyState() {
    final bool isFiltering = searchQuery.isNotEmpty || selectedHistoryType != 'All';

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.lightGreen.withValues(alpha: 0.1),
                      AppColors.vibrantGreen.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.lightGreen.withValues(alpha: 0.2)),
                ),
                child: Icon(
                  isFiltering ? Icons.search_off_rounded : Icons.event_note_rounded,
                  size: 60,
                  color: AppColors.lightGreen,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isFiltering ? 'No Results Found' : 'No History Records',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isFiltering
                    ? 'Try adjusting your search or filter\nto find what you\'re looking for.'
                    : 'No Goat History records have been recorded yet.\nTap "Add History Record" to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Icon(Icons.error_outline_rounded,
                    size: 64, color: Colors.red.shade400),
              ),
              const SizedBox(height: 24),
              Text(
                'Error Loading History Records',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _refreshHistory,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vibrantGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
