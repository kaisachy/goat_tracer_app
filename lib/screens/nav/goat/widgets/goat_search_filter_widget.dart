import 'package:flutter/material.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';

class GoatSearchFilterWidget extends StatefulWidget {
  // MODIFIED: Callback now accepts breed and group name
  final Function(String, String, String, String, String) onFiltersChanged;
  final Function(String) onSearchChanged;
  final String initialSex;
  final String initialClassification;
  final String initialStatus;
  // NEW: Initial breed and group name properties
  final String initialBreed;
  final String initialGroupName;
  // NEW: Lists for breed and group options (dynamic from goat data)
  final List<String> breedOptions;
  final List<String> groupNameOptions;
  // NEW: Archive button callback
  final VoidCallback? onArchivePressed;

  const GoatSearchFilterWidget({
    super.key,
    required this.onSearchChanged,
    required this.onFiltersChanged,
    required this.initialSex,
    required this.initialClassification,
    required this.initialStatus,
    required this.initialBreed,
    required this.initialGroupName,
    required this.breedOptions,
    required this.groupNameOptions,
    this.onArchivePressed,
  });

  @override
  State<GoatSearchFilterWidget> createState() =>
      _GoatSearchFilterWidgetState();
}

class _GoatSearchFilterWidgetState extends State<GoatSearchFilterWidget> {
  late String _selectedSex;
  late String _selectedClassification;
  late String _selectedStatus;
  // NEW: State for selected breed and group name
  late String _selectedBreed;
  late String _selectedGroupName;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _sexOptions = ['All', 'Male', 'Female', 'Other'];

  final List<String> _allClassificationOptions = [
    'All',
    'Doeling',
    'Doe',
    'Buck',
    'Buckling',
    'Kid',
    'Growers'
  ];

  final List<String> _allStatusOptions = [
    'All',
    'Healthy',
    'Sick',
    'Breeding',
    'Lactating',
    'Pregnant',
    'Lactating & Pregnant',
    'Sold',
    'Mortality',
    'Lost'
  ];

  @override
  void initState() {
    super.initState();
    _selectedSex = widget.initialSex;
    _selectedClassification = widget.initialClassification;
    _selectedStatus = widget.initialStatus;
    // NEW: Initialize breed and group name
    _selectedBreed = widget.initialBreed;
    _selectedGroupName = widget.initialGroupName;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper method for classification options
  List<String> _getFilteredClassificationOptions() {
    switch (_selectedSex) {
      case 'Male':
        return ['All', 'Buck', 'Buckling', 'Kid', 'Growers'];
      case 'Female':
        return ['All', 'Doeling', 'Doe', 'Kid', 'Growers'];
      default:
        return _allClassificationOptions;
    }
  }

  // Helper method for status options
  List<String> _getFilteredStatusOptions() {
    switch (_selectedSex) {
      case 'Male':
      // Removes female-specific statuses
        return ['All', 'Healthy', 'Sick', 'Breeding', 'Sold', 'Mortality', 'Lost'];
      default: // 'Female', 'All', 'Other'
        return _allStatusOptions;
    }
  }

  // MODIFIED: Pass all filters to the callback
  void _updateFilters() {
    widget.onFiltersChanged(
        _selectedSex, _selectedClassification, _selectedStatus, _selectedBreed, _selectedGroupName);
  }

  // MODIFIED: Logic to reset dependent filters when sex changes
  void _showGenderFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showMainFilterDialog();
                        },
                        icon: Icon(Icons.arrow_back, color: AppColors.primary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.male, color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Options
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _sexOptions.map((sex) {
                      bool isSelected = _selectedSex == sex;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSex = sex;

                              // Reset both classification and status if they become invalid
                              final validClassifications =
                              _getFilteredClassificationOptions();
                              if (!validClassifications
                                  .contains(_selectedClassification)) {
                                _selectedClassification = 'All';
                              }

                              final validStatuses = _getFilteredStatusOptions();
                              if (!validStatuses.contains(_selectedStatus)) {
                                _selectedStatus = 'All';
                              }
                            });
                            _updateFilters();
                            Navigator.pop(context);
                            _showMainFilterDialog();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    sex,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check,
                                      color: AppColors.primary, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Clear button
                Container(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedSex = 'All';
                        });
                        _updateFilters();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Clear Gender Filter',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
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

  void _showClassificationFilterDialog() {
    final List<String> currentClassificationOptions =
    _getFilteredClassificationOptions();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showMainFilterDialog();
                        },
                        icon: Icon(Icons.arrow_back, color: AppColors.primary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.category, color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Stage',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Options
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children:
                    currentClassificationOptions.map((classification) {
                      bool isSelected =
                          _selectedClassification == classification;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedClassification = classification;
                            });
                            _updateFilters();
                            Navigator.pop(context);
                            _showMainFilterDialog();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    classification,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check,
                                      color: AppColors.primary, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Clear button
                Container(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedClassification = 'All';
                        });
                        _updateFilters();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Clear Classification Filter',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
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

  void _showStatusFilterDialog() {
    final List<String> currentStatusOptions = _getFilteredStatusOptions();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showMainFilterDialog();
                        },
                        icon: Icon(Icons.arrow_back, color: AppColors.primary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.monitor_heart,
                          color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Options
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: currentStatusOptions.map((status) {
                      bool isSelected = _selectedStatus == status;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedStatus = status;
                            });
                            _updateFilters();
                            Navigator.pop(context);
                            _showMainFilterDialog();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check,
                                      color: AppColors.primary, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Clear button
                Container(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedStatus = 'All';
                        });
                        _updateFilters();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Clear Status Filter',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
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

  // NEW: Dialog for the Breed Filter
  void _showBreedFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showMainFilterDialog();
                        },
                        icon: Icon(Icons.arrow_back, color: AppColors.primary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Image.asset(
                        'assets/images/goat-icons/goat.png',
                        width: 24,
                        height: 24,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ' Breed',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Options
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: widget.breedOptions.map((breed) {
                      bool isSelected = _selectedBreed == breed;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedBreed = breed;
                            });
                            _updateFilters();
                            Navigator.pop(context);
                            _showMainFilterDialog();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    breed,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check,
                                      color: AppColors.primary, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Clear button
                Container(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedBreed = 'All';
                        });
                        _updateFilters();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Clear Breed Filter',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
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

  // NEW: Dialog for the Group Name Filter
  void _showGroupNameFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showMainFilterDialog();
                        },
                        icon: Icon(Icons.arrow_back, color: AppColors.primary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.group, color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Group',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Options
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: widget.groupNameOptions.map((groupName) {
                      bool isSelected = _selectedGroupName == groupName;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedGroupName = groupName;
                            });
                            _updateFilters();
                            Navigator.pop(context);
                            _showMainFilterDialog();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    groupName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check,
                                      color: AppColors.primary, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Clear button
                Container(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedGroupName = 'All';
                        });
                        _updateFilters();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Clear Group Filter',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
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

  // MODIFIED: Added the new Breed and Group Name filter options
  void _showMainFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list,
                          color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Filter Options',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Filter Options
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      // Sort by Gender
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _showGenderFilterDialog();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.male,
                                      color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sort by Gender',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Current: $_selectedSex',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _selectedSex != 'All'
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                          fontWeight: _selectedSex != 'All'
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Divider(height: 1),

                      // Sort by Classification
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _showClassificationFilterDialog();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.category,
                                      color: AppColors.accent, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sort by Classification',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Current: $_selectedClassification',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _selectedClassification !=
                                              'All'
                                              ? AppColors.accent
                                              : AppColors.textSecondary,
                                          fontWeight:
                                          _selectedClassification != 'All'
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Divider(height: 1),

                      // Sort by Status
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _showStatusFilterDialog();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.monitor_heart,
                                      color: Colors.orange, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sort by Status',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Current: $_selectedStatus',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _selectedStatus != 'All'
                                              ? Colors.orange
                                              : AppColors.textSecondary,
                                          fontWeight: _selectedStatus != 'All'
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Divider(height: 1),

                      // NEW: Sort by Breed
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _showBreedFilterDialog();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Image.asset(
                                    'assets/images/goat-icons/goat.png',
                                    width: 20,
                                    height: 20,
                                    color: Colors.purple,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sort by Breed',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Current: $_selectedBreed',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _selectedBreed != 'All'
                                              ? Colors.purple
                                              : AppColors.textSecondary,
                                          fontWeight: _selectedBreed != 'All'
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Divider(height: 1),

                      // NEW: Sort by Group Name
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _showGroupNameFilterDialog();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.group,
                                      color: Colors.teal, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sort by Group',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Current: $_selectedGroupName',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _selectedGroupName != 'All'
                                              ? Colors.teal
                                              : AppColors.textSecondary,
                                          fontWeight: _selectedGroupName != 'All'
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // MODIFIED: Clear All Filters Button condition and action
                if (_selectedSex != 'All' ||
                    _selectedClassification != 'All' ||
                    _selectedStatus != 'All' ||
                    _selectedBreed != 'All' ||
                    _selectedGroupName != 'All')
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedSex = 'All';
                            _selectedClassification = 'All';
                            _selectedStatus = 'All';
                            _selectedBreed = 'All';
                            _selectedGroupName = 'All';
                          });
                          _updateFilters();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Clear All Filters'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: AppColors.textSecondary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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

  // MODIFIED: Updated build method to check for new filters
  @override
  Widget build(BuildContext context) {
    bool hasActiveFilters = _selectedSex != 'All' ||
        _selectedClassification != 'All' ||
        _selectedStatus != 'All' ||
        _selectedBreed != 'All' ||
        _selectedGroupName != 'All';

    int activeFilterCount = 0;
    if (_selectedSex != 'All') activeFilterCount++;
    if (_selectedClassification != 'All') activeFilterCount++;
    if (_selectedStatus != 'All') activeFilterCount++;
    if (_selectedBreed != 'All') activeFilterCount++;
    if (_selectedGroupName != 'All') activeFilterCount++;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border:
                Border.all(color: AppColors.lightGreen.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: widget.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by tag no.',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(Icons.search, color: AppColors.primary),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Filter Button
          Container(
            decoration: BoxDecoration(
              color: hasActiveFilters
                  ? AppColors.primary
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: hasActiveFilters
                      ? AppColors.primary
                      : AppColors.lightGreen.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showMainFilterDialog,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Stack(
                    clipBehavior: Clip.none, // Allow badge to overflow
                    children: [
                      Icon(
                        Icons.filter_list,
                        color:
                        hasActiveFilters ? Colors.white : AppColors.primary,
                        size: 24,
                      ),
                      if (hasActiveFilters)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border:
                              Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                '$activeFilterCount',
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
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Archive Button
          if (widget.onArchivePressed != null)
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onArchivePressed,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      Icons.archive_outlined,
                      color: AppColors.gold,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // MODIFIED: Public methods to access current filter values
  String get selectedGender => _selectedSex;
  String get selectedClassification => _selectedClassification;
  String get selectedStatus => _selectedStatus;
  String get selectedBreed => _selectedBreed;
  String get selectedGroupName => _selectedGroupName;

  // Method to clear search programmatically
  void clearSearch() {
    _searchController.clear();
    widget.onSearchChanged('');
  }

  // MODIFIED: Method to reset all filters programmatically
  void resetAllFilters() {
    setState(() {
      _selectedSex = 'All';
      _selectedClassification = 'All';
      _selectedStatus = 'All';
      _selectedBreed = 'All';
      _selectedGroupName = 'All';
    });
    _updateFilters();
    clearSearch();
  }
}
