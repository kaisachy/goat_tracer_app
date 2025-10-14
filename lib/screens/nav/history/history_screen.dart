// lib/screens/nav/history/history_screen.dart
import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_history_service.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/widgets/history/history_search_filter_bar.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/cattle_history_form_screen.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/modals/history_duplication_modal.dart';
import 'package:cattle_tracer_app/utils/history_type_utils.dart';
import '../../../models/cattle.dart';
import 'cattle_selection_modal.dart';

  class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> allHistoryRecords = [];
  bool isLoading = true;
  String? error;

  String searchQuery = '';
  String selectedHistoryType = 'All';
  Set<int> expandedCards = <int>{};

  // All possible history types
  List<String> get historyTypes {
    return [
      'All', 'Dry off', 'Treated', 'Breeding', 'Weighed', 'Gives Birth',
      'Vaccinated', 'Pregnant', 'Aborted Pregnancy', 'Deworming',
      'Hoof Trimming', 'Castrated', 'Weaned', 'Deceased', 'Lost', 'Sold', 'Other',
    ];
  }

  // List of history types that can be duplicated
  final List<String> _duplicatableHistoryTypes = [
    'dry off',
    'treated',
    'breeding',
    'vaccinated',
    'deworming',
    'hoof trimming',
    'deceased',
    'lost',
    'sold',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllCattleHistory();
  }

  Future<void> _loadAllCattleHistory() async {
    try {
      print('DEBUG: _loadAllCattleHistory started');
      setState(() => isLoading = true);
      final historyRecords = await CattleHistoryService.getCattleHistory();
      print('DEBUG: Loaded ${historyRecords.length} history records from service');

      // Remove duplicates and delete them from database
      final uniqueHistoryRecords = await _removeDuplicateHistoryRecordsFromDB(historyRecords);

      // Sort history records by date to show latest first
      uniqueHistoryRecords.sort((a, b) {
        final dateA = DateTime.tryParse(a['history_date'] ?? '1900-01-01') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b['history_date'] ?? '1900-01-01') ?? DateTime(1900);
        return dateB.compareTo(dateA); // Descending order (latest first)
      });

      // Calf tags are now stored directly in the database as comma-separated values
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
    print('DEBUG: _refreshHistory called');
    await _loadAllCattleHistory();
    print('DEBUG: _refreshHistory completed');
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
            final success = await CattleHistoryService.deleteCattleHistory(historyRecordId);
            if (success) {
              deletedCount++;
            } else {
              print('Failed to delete duplicate history record with ID: $historyRecordId');
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
        print('Error deleting duplicate history records: $e');
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
    if (!_compareFieldValues(historyRecord1['cattle_tag'], historyRecord2['cattle_tag'])) return false;
    if (!_compareFieldValues(historyRecord1['notes'], historyRecord2['notes'])) return false;

    // Compare history-specific fields based on history type
    switch (historyType1) {
      case 'dry off':
      case 'aborted pregnancy':
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

      case 'gives birth':
        return _compareFieldValues(historyRecord1['bull_tag'], historyRecord2['bull_tag']) &&
            _compareFieldValues(historyRecord1['calf_tag'], historyRecord2['calf_tag']);

      case 'vaccinated':
        return _compareFieldValues(historyRecord1['medicine_given'], historyRecord2['medicine_given']) &&
            _compareFieldValues(historyRecord1['technician'], historyRecord2['technician']);

      case 'pregnant':
        return _compareFieldValues(historyRecord1['breeding_date'], historyRecord2['breeding_date']) &&
            _compareFieldValues(historyRecord1['expected_delivery_date'], historyRecord2['expected_delivery_date']) &&
            _compareFieldValues(historyRecord1['bull_tag'], historyRecord2['bull_tag']);

      case 'deworming':
        return _compareFieldValues(historyRecord1['medicine_given'], historyRecord2['medicine_given']);

      case 'castrated':
        return _compareFieldValues(historyRecord1['technician'], historyRecord2['technician']);

      case 'deceased':
        return _compareFieldValues(historyRecord1['cause_of_death'], historyRecord2['cause_of_death']);

      case 'sold':
        return _compareFieldValues(historyRecord1['sold_amount'], historyRecord2['sold_amount']) &&
            _compareFieldValues(historyRecord1['buyer'], historyRecord2['buyer']);

      case 'sick':
        return _compareFieldValues(historyRecord1['disease_type'], historyRecord2['disease_type']);

      case 'lost':
        return _compareFieldValues(historyRecord1['last_known_location'], historyRecord2['last_known_location']);

      case 'other':
      default:
      // For 'other' history records, compare all potentially relevant fields
        return _compareFieldValues(historyRecord1['bull_tag'], historyRecord2['bull_tag']) &&
            _compareFieldValues(historyRecord1['calf_tag'], historyRecord2['calf_tag']) &&
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
      final cattleTag = (historyRecord['cattle_tag'] ?? '').toString().toLowerCase();
      final query = searchQuery.toLowerCase();

      final matchesSearch = type.contains(query) ||
          notes.contains(query) ||
          diagnosis.contains(query) ||
          cattleTag.contains(query);

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
    final canDuplicate = _canDuplicateHistory(historyType);

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
              Text('Delete History Record', style: TextStyle(color: Colors.red.shade400)),
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
      // Create a CattleHistoryRecord object from the history record data
      final cattleHistoryRecord = CattleHistoryRecord(
        id: historyRecord['id'] ?? 0,
        userId: historyRecord['user_id'] ?? 0,
        cattleTag: historyRecord['cattle_tag']?.toString() ?? '',
        bullTag: historyRecord['bull_tag']?.toString(),
        calfTag: historyRecord['calf_tag']?.toString(),
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
      );

      // Navigate to edit screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CattleHistoryFormScreen(
            historyRecord: cattleHistoryRecord,
            cattleTag: historyRecord['cattle_tag']?.toString() ?? '',
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
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red.shade400),
              const SizedBox(width: 8),
              const Text('Delete History Record'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete this history record?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${historyRecord['history_type']} - ${historyRecord['cattle_tag']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Date: ${_formatDate(historyRecord['history_date'])}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performDelete(historyRecord);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
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

      final success = await CattleHistoryService.deleteCattleHistory(historyRecord['id']);

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

// Replace your existing _onAddHistory method with this updated version
  void _onAddHistory() async {
    try {
      // First, show cattle selection modal
      final selectedCattleTag = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const CattleSelectionModal();
        },
      );

      // If user cancelled or no cattle was selected, return
      if (selectedCattleTag == null) return;

      // Navigate to the history form with the selected cattle tag
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CattleHistoryFormScreen(
            cattleTag: selectedCattleTag,
          ),
        ),
      );

      // Handle the result from the form
      if (result == true && mounted) {
        await _refreshHistory();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text('History record added successfully!'),
              ],
            ),
            backgroundColor: AppColors.vibrantGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Error adding history record: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
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
            const SizedBox(height: 16),
            _buildHistorySummary(),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshHistory,
                color: AppColors.vibrantGreen,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.vibrantGreen))
                    : error != null
                    ? _buildErrorState()
                    : _filteredHistoryRecords.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: _filteredHistoryRecords.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildHistoryAccordion(_filteredHistoryRecords[index], index),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddHistory,
        backgroundColor: AppColors.vibrantGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add History Record',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
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

    // Get unique cattle count
    final _ = allHistoryRecords
        .map((historyRecord) => historyRecord['cattle_tag']?.toString() ?? '')
        .where((tag) => tag.isNotEmpty)
        .toSet();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
    final cattleTag = historyRecord['cattle_tag']?.toString() ?? 'Unknown';
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
            color: historyColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: historyColor.withOpacity(0.2)),
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
                      color: historyColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: historyColor.withOpacity(0.3)),
                    ),
                    child: Icon(HistoryTypeUtils.getHistoryIcon(historyType), color: historyColor, size: 24),
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
                            color: historyColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: historyColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            cattleTag,
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
                        builder: (context) => IconButton(
                          onPressed: () => _showHistoryMenu(context, historyRecord, index),
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          tooltip: 'More options',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
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
            height: isExpanded && details.isNotEmpty && historyType.toLowerCase() != 'other' ? null : 0,
            child: isExpanded && details.isNotEmpty && historyType.toLowerCase() != 'other'
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
                    color: historyColor.withOpacity(0.2),
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
              color: AppColors.textPrimary.withOpacity(0.7),
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

  List<MapEntry<String, String>> _getHistoryDetails(Map<String, dynamic> historyRecord) {
    final historyType = (historyRecord['history_type'] ?? '').toString().toLowerCase();
    final originalHistoryType = historyRecord['history_type']?.toString();
    final Map<String, String?> relevantDetails = {};

    // Always show notes if available
    if (historyRecord['notes'] != null && historyRecord['notes'].toString().isNotEmpty && historyRecord['notes'] != 'N/A') {
      relevantDetails['Notes'] = historyRecord['notes'].toString();
    }

    // Special handling for Gives Birth history records (check both lowercase and original case)
    if (historyType == 'gives birth' || originalHistoryType?.toLowerCase() == 'gives birth') {
      if (historyRecord['bull_tag'] != null && historyRecord['bull_tag'].toString().isNotEmpty && historyRecord['bull_tag'] != 'N/A') {
        relevantDetails['Bull Tag (Father)'] = historyRecord['bull_tag'].toString();
      }
      
      // Handle calf tags - check if it's comma-separated (multiple calves)
      final calfTagValue = historyRecord['calf_tag']?.toString();
      if (calfTagValue != null && calfTagValue.isNotEmpty && calfTagValue != 'N/A') {
        if (calfTagValue.contains(',')) {
          // Multiple calves - split by comma and count
          final calfTags = calfTagValue.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
          relevantDetails['Calf Tags'] = calfTags.join(', ');
          relevantDetails['Litter Size'] = '${calfTags.length}';
        } else {
          // Single calf
          relevantDetails['Calf Tag'] = calfTagValue;
          relevantDetails['Litter Size'] = '1';
        }
      } else {
        // No calf tags found - show 0 litter size
        relevantDetails['Litter Size'] = '0';
      }
    }

    // Add history-specific fields based on history type
    switch (historyType) {
      case 'dry off':
      case 'aborted pregnancy':
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

      case 'gives birth':
        // Already handled above in the special Gives Birth section
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
        if (historyRecord['bull_tag'] != null && historyRecord['bull_tag'].toString().isNotEmpty && historyRecord['bull_tag'] != 'N/A') {
          relevantDetails['Bull Tag (Father)'] = historyRecord['bull_tag'].toString();
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

      case 'deceased':
        if (historyRecord['cause_of_death'] != null && historyRecord['cause_of_death'].toString().isNotEmpty && historyRecord['cause_of_death'].toString() != 'N/A') {
          relevantDetails['Cause of Death'] = historyRecord['cause_of_death'].toString();
        }
        break;

      case 'sold':
        if (historyRecord['sold_amount'] != null && historyRecord['sold_amount'].toString().isNotEmpty && historyRecord['sold_amount'] != 'N/A') {
          relevantDetails['Sold Amount'] = '₱${historyRecord['sold_amount'].toString()}';
        }
        if (historyRecord['buyer'] != null && historyRecord['buyer'].toString().isNotEmpty && historyRecord['buyer'] != 'N/A') {
          relevantDetails['Buyer'] = historyRecord['buyer'].toString();
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

      case 'other':
        // For 'other' history records, only show notes (no additional details)
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
                      AppColors.lightGreen.withOpacity(0.1),
                      AppColors.vibrantGreen.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.lightGreen.withOpacity(0.2)),
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
                    : 'No cattle history records have been recorded yet.\nTap "Add History Record" to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              if (!isFiltering) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _onAddHistory,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add First History Record'),
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