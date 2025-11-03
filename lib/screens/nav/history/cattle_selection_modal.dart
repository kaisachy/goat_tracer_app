import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_service.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_history_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CattleSelectionModal extends StatefulWidget {
  final String? historyType; // Optional: filter cattle by history type applicability

  const CattleSelectionModal({super.key, this.historyType});

  @override
  State<CattleSelectionModal> createState() => _CattleSelectionModalState();
}

class _CattleSelectionModalState extends State<CattleSelectionModal> {
  List<Cattle> allCattle = [];
  List<Cattle> filteredCattle = [];
  bool isLoading = true;
  String? error;
  String searchQuery = '';
  Cattle? selectedCattle;
  final Set<String> _tagsWithBreeding = {};
  final Set<String> _tagsWithPregnant = {};
  final Set<String> _tagsWithSick = {};

  @override
  void initState() {
    super.initState();
    _loadCattle();
  }

  Future<void> _loadCattle() async {
    try {
      setState(() => isLoading = true);
      final cattle = await CattleService.getAllCattle();
      // Optionally load history to support type-specific eligibility
      await _maybeLoadHistoryEligibility();

      if (mounted) {
        setState(() {
          allCattle = cattle;
          // Apply initial filter based on history type if provided
          final base = widget.historyType == null
              ? allCattle
              : allCattle.where(_matchesHistoryClassification).toList();
          filteredCattle = base;
          isLoading = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Failed to load cattle: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _maybeLoadHistoryEligibility() async {
    final type = (widget.historyType ?? '').toLowerCase();
    if (type != 'pregnant' && type != 'gives birth' && type != 'treated') return;

    try {
      final events = await CattleHistoryService.getCattleHistory();
      _tagsWithBreeding.clear();
      _tagsWithPregnant.clear();
      for (final e in events) {
        final tag = (e['cattle_tag'] ?? '').toString().trim();
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

  void _filterCattle(String query) {
    setState(() {
      searchQuery = query;
      final base = widget.historyType == null
          ? allCattle
          : allCattle.where(_matchesHistoryClassification).toList();

      if (query.isEmpty) {
        filteredCattle = base;
      } else {
        filteredCattle = base.where((cattle) {
          // Fix: Use the correct property name from your Cattle model
          // Replace 'tagNo' with whatever your actual property name is
          final tagNo = (cattle.tagNo).toLowerCase(); // Assuming your property is 'tagNo'
          final breed = (cattle.breed ?? '').toLowerCase();
          final classification = (cattle.classification).toLowerCase();
          final searchLower = query.toLowerCase();
          return tagNo.contains(searchLower) || breed.contains(searchLower) || classification.contains(searchLower);
        }).toList();
      }
    });
  }

  bool _matchesHistoryClassification(Cattle cattle) {
    final type = (widget.historyType ?? '').toLowerCase();
    final sex = (cattle.sex).toLowerCase();
    final cls = (cattle.classification).toLowerCase();

    // Female-only history types
    const femaleOnly = {
      'dry off', 'gives birth', 'pregnant', 'aborted pregnancy', 'breeding'
    };
    // Male-only history types
    const maleOnly = {
      'castrated'
    };
    // Calf-only history types
    const calfOnly = {
      'weaned'
    };

    if (femaleOnly.contains(type)) {
      final isFemaleEligible = sex == 'female' && (cls == 'cow' || cls == 'heifer');
      if (!isFemaleEligible) return false;
      // Extra eligibility rules
      if (type == 'pregnant') {
        // Require an existing Breeding record
        return _tagsWithBreeding.contains(cattle.tagNo);
      }
      if (type == 'gives birth') {
        // Require an existing Pregnant record
        return _tagsWithPregnant.contains(cattle.tagNo);
      }
      return true; // breeding/dry off/aborted pregnancy baseline
    }
    if (maleOnly.contains(type)) {
      return sex == 'male';
    }
    if (calfOnly.contains(type)) {
      return cls == 'calf';
    }

    // Treated requires an existing Sick record
    if (type == 'treated') {
      return _tagsWithSick.contains(cattle.tagNo);
    }

    // Default: applicable to all classifications
    return true;
  }

  void _selectCattle(Cattle cattle) {
    setState(() {
      selectedCattle = cattle;
    });
  }

  void _confirmSelection() {
    if (selectedCattle != null) {
      // Fix: Use the correct property name
      Navigator.of(context).pop(selectedCattle!.tagNo); // Assuming your property is 'tagNo'
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.vibrantGreen.withOpacity(0.1),
                    AppColors.lightGreen.withOpacity(0.05),
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
                    color: AppColors.vibrantGreen.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.vibrantGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.vibrantGreen.withOpacity(0.3)),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.cow,
                      color: AppColors.vibrantGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Cattle',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Choose a cattle to add a history record for',
                          style: TextStyle(
                            fontSize: 14,
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
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: _filterCattle,
                decoration: InputDecoration(
                  hintText: 'Search by cattle tagNo or breed...',
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Cattle list
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
                  : filteredCattle.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredCattle.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cattle = filteredCattle[index];
                  // Fix: Use the correct property name for comparison
                  final isSelected = selectedCattle?.tagNo == cattle.tagNo; // Assuming your property is 'tagNo'
                  return _buildCattleCard(cattle, isSelected);
                },
              ),
            ),

            // Footer with action buttons
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedCattle != null ? _confirmSelection : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedCattle != null
                            ? AppColors.vibrantGreen
                            : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: selectedCattle != null ? 2 : 0,
                      ),
                      child: Text(
                        'Select',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: selectedCattle != null ? Colors.white : Colors.grey.shade500,
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
    );
  }

  Widget _buildCattleCard(Cattle cattle, bool isSelected) {
    return InkWell(
      onTap: () => _selectCattle(cattle),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.vibrantGreen.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.vibrantGreen.withOpacity(0.5)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColors.vibrantGreen.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.vibrantGreen.withOpacity(0.2)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.vibrantGreen.withOpacity(0.3)
                      : Colors.grey.shade300,
                ),
              ),
              child: FaIcon(
                FontAwesomeIcons.cow,
                color: isSelected ? AppColors.vibrantGreen : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Fix: Use the correct property name
                    cattle.tagNo, // Assuming your property is 'tagNo'
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.vibrantGreen : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${cattle.classification}'
                    '${(cattle.breed != null && cattle.breed!.isNotEmpty && cattle.breed!.toLowerCase() != 'unknown') ? ' • ${cattle.breed}' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
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
              searchQuery.isEmpty ? FontAwesomeIcons.cow : Icons.search_off_rounded,
              size: 48,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? 'No Cattle Found' : 'No Results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'No cattle records are available in the system.'
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
            'Error Loading Cattle',
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
            onPressed: _loadCattle,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}