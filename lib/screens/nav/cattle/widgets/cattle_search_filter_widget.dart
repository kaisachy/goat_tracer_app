import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CattleSearchFilterWidget extends StatefulWidget {
  // MODIFIED: Callback now accepts breed and group name
  final Function(String, String, String, String, String) onFiltersChanged;
  final Function(String) onSearchChanged;
  final String initialGender;
  final String initialClassification;
  final String initialStatus;
  // NEW: Initial breed and group name properties
  final String initialBreed;
  final String initialGroupName;
  // NEW: Lists for breed and group options (dynamic from cattle data)
  final List<String> breedOptions;
  final List<String> groupNameOptions;

  const CattleSearchFilterWidget({
    super.key,
    required this.onSearchChanged,
    required this.onFiltersChanged,
    required this.breedOptions, // Now required - should be generated from actual cattle data
    required this.groupNameOptions, // Now required - should be generated from actual cattle data
    this.initialGender = 'All',
    this.initialClassification = 'All',
    this.initialStatus = 'All',
    // NEW: Initial breed and group name parameters
    this.initialBreed = 'All',
    this.initialGroupName = 'All',
  });

  @override
  State<CattleSearchFilterWidget> createState() =>
      _CattleSearchFilterWidgetState();
}

class _CattleSearchFilterWidgetState extends State<CattleSearchFilterWidget> {
  late String _selectedGender;
  late String _selectedClassification;
  late String _selectedStatus;
  // NEW: State for selected breed and group name
  late String _selectedBreed;
  late String _selectedGroupName;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _genderOptions = ['All', 'Male', 'Female', 'Other'];

  final List<String> _allClassificationOptions = [
    'All',
    'Heifer',
    'Cow',
    'Bull',
    'Steer',
    'Calf',
    'Growers'
  ];

  final List<String> _allStatusOptions = [
    'All',
    'Active',
    'Lactating',
    'Pregnant',
    'Lactating & Pregnant',
    'Sold',
    'Deceased'
  ];

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialGender;
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
    switch (_selectedGender) {
      case 'Male':
        return ['All', 'Bull', 'Steer', 'Calf', 'Growers'];
      case 'Female':
        return ['All', 'Heifer', 'Cow', 'Calf', 'Growers'];
      default:
        return _allClassificationOptions;
    }
  }

  // Helper method for status options
  List<String> _getFilteredStatusOptions() {
    switch (_selectedGender) {
      case 'Male':
      // Removes female-specific statuses
        return ['All', 'Active', 'Sold', 'Deceased'];
      default: // 'Female', 'All', 'Other'
        return _allStatusOptions;
    }
  }

  // MODIFIED: Pass all filters to the callback
  void _updateFilters() {
    widget.onFiltersChanged(
        _selectedGender, _selectedClassification, _selectedStatus, _selectedBreed, _selectedGroupName);
  }

  // MODIFIED: Logic to reset dependent filters when gender changes
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
                    color: AppColors.primary.withOpacity(0.1),
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
                    children: _genderOptions.map((gender) {
                      bool isSelected = _selectedGender == gender;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedGender = gender;

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
                                    gender,
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
                          _selectedGender = 'All';
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
                    color: AppColors.primary.withOpacity(0.1),
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
                    color: AppColors.primary.withOpacity(0.1),
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
                    color: AppColors.primary.withOpacity(0.1),
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
                      Icon(FontAwesomeIcons.cow, color: AppColors.primary, size: 24),
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
                    color: AppColors.primary.withOpacity(0.1),
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
                    color: AppColors.primary.withOpacity(0.1),
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
                                    color: AppColors.primary.withOpacity(0.1),
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
                                        'Current: $_selectedGender',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _selectedGender != 'All'
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                          fontWeight: _selectedGender != 'All'
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
                                    color: AppColors.accent.withOpacity(0.1),
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
                                    color: Colors.orange.withOpacity(0.1),
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
                                    color: Colors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(FontAwesomeIcons.cow,
                                      color: Colors.purple, size: 20),
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
                                    color: Colors.teal.withOpacity(0.1),
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
                if (_selectedGender != 'All' ||
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
                            _selectedGender = 'All';
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
    bool hasActiveFilters = _selectedGender != 'All' ||
        _selectedClassification != 'All' ||
        _selectedStatus != 'All' ||
        _selectedBreed != 'All' ||
        _selectedGroupName != 'All';

    int activeFilterCount = 0;
    if (_selectedGender != 'All') activeFilterCount++;
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
                Border.all(color: AppColors.lightGreen.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: widget.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by tag, name, breed, group, or status...',
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
                      : AppColors.lightGreen.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
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
        ],
      ),
    );
  }

  // MODIFIED: Public methods to access current filter values
  String get selectedGender => _selectedGender;
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
      _selectedGender = 'All';
      _selectedClassification = 'All';
      _selectedStatus = 'All';
      _selectedBreed = 'All';
      _selectedGroupName = 'All';
    });
    _updateFilters();
    clearSearch();
  }
}