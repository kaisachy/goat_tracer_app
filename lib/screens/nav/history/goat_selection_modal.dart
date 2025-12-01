import 'package:flutter/material.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/services/goat/goat_service.dart';

class GoatSelectionModal extends StatefulWidget {
  final String? historyType; // Optional: filter goat by history type applicability

  const GoatSelectionModal({super.key, this.historyType});

  @override
  State<GoatSelectionModal> createState() => _GoatSelectionModalState();
}

class _GoatSelectionModalState extends State<GoatSelectionModal> {
  List<Goat> allGoats = [];
  List<Goat> filteredGoat = [];
  bool isLoading = true;
  String? error;
  String searchQuery = '';
  Goat? selectedGoat;

  @override
  void initState() {
    super.initState();
    _loadgoat();
  }

  Future<void> _loadgoat() async {
    try {
      setState(() => isLoading = true);
      final goat = await GoatService.getAllGoats();

      if (mounted) {
        setState(() {
          allGoats = goat;
          // Apply initial filter based on history type if provided
          final base = widget.historyType == null
              ? allGoats
              : allGoats.where(_matchesHistoryClassification).toList();
          filteredGoat = base;
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

  void _filtergoat(String query) {
    setState(() {
      searchQuery = query;
      final base = widget.historyType == null
          ? allGoats
          : allGoats.where(_matchesHistoryClassification).toList();

      if (query.isEmpty) {
        filteredGoat = base;
      } else {
        filteredGoat = base.where((goat) {
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

  bool _matchesHistoryClassification(Goat goat) {
    final type = (widget.historyType ?? '').toLowerCase();
    final sex = (goat.sex).toLowerCase();
    final cls = (goat.classification).toLowerCase();

    // Female-only history types
    const femaleOnly = {
      'dry off', 'kidding', 'pregnant', 'aborted', 'breeding'
    };
    // Male-only history types
    const maleOnly = {
      'castrated'
    };
    // Kid-only history types
    const kidOnly = {
      'weaned'
    };

    if (femaleOnly.contains(type)) {
      final isFemaleEligible = sex == 'female' && (cls == 'doe' || cls == 'doeling');
      return isFemaleEligible;
    }
    if (maleOnly.contains(type)) {
      return sex == 'male';
    }
    if (kidOnly.contains(type)) {
      return cls == 'kid';
    }

    // Default: applicable to all classifications
    return true;
  }

  void _selectGoat(Goat goat) {
    setState(() {
      selectedGoat = goat;
    });
  }

  void _confirmSelection() {
    if (selectedGoat != null) {
      // Fix: Use the correct property name
      Navigator.of(context).pop(selectedGoat!.tagNo); // Assuming your property is 'tagNo'
    }
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
                    child: Image.asset(
                      'assets/images/goat-icons/goat.png',
                      width: 18,
                      height: 18,
                      color: AppColors.vibrantGreen,
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
                  : filteredGoat.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filteredGoat.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final goat = filteredGoat[index];
                  // Fix: Use the correct property name for comparison
                  final isSelected = selectedGoat?.tagNo == goat.tagNo; // Assuming your property is 'tagNo'
                  return _buildGoatCard(goat, isSelected);
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
                          onPressed: selectedGoat != null ? _confirmSelection : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedGoat != null
                                ? AppColors.vibrantGreen
                                : Colors.grey.shade300,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: selectedGoat != null ? 2 : 0,
                          ),
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: selectedGoat != null ? Colors.white : Colors.grey.shade500,
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

  Widget _buildGoatCard(Goat goat, bool isSelected) {
    return InkWell(
      onTap: () => _selectGoat(goat),
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
              child: Image.asset(
                'assets/images/goat-icons/goat.png',
                width: 16,
                height: 16,
                color: isSelected ? AppColors.vibrantGreen : Colors.grey.shade600,
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
            _buildGoatOptionsMenu(),
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

  Widget _buildGoatOptionsMenu() {
    return const SizedBox.shrink();
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
            child: searchQuery.isEmpty
                ? Image.asset(
                    'assets/images/goat-icons/goat.png',
                    width: 48,
                    height: 48,
                    color: Colors.grey.shade500,
                  )
                : Icon(
                    Icons.search_off_rounded,
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
