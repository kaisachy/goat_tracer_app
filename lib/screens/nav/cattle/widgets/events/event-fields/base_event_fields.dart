// lib/screens/nav/cattle/widgets/event_fields/base_event_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/models/user.dart';

import '../../../../../../services/cattle/cattle_service.dart';
import '../../../../../../services/user_service.dart';

abstract class BaseEventFields extends StatefulWidget {
  final Map<String, TextEditingController> controllers;

  const BaseEventFields({
    super.key,
    required this.controllers,
  });
}

abstract class BaseEventFieldsState<T extends BaseEventFields> extends State<T> {
  List<Cattle> bulls = [];
  List<User> technicians = [];
  bool loadingBulls = false;
  bool loadingTechnicians = false;

  static const int cattleGestationPeriodDays = 283;
  static const int returnToHeatDays = 21;

  @override
  void initState() {
    super.initState();
    if (needsBulls()) {
      fetchBulls();
    }
    if (needsTechnicians()) {
      fetchTechnicians();
    }
    setupEventDateListeners();
  }

  @override
  void dispose() {
    removeEventDateListeners();
    super.dispose();
  }

  // Abstract methods to be implemented by subclasses
  bool needsBulls() => false;
  bool needsTechnicians() => false;
  void setupEventDateListeners() {}
  void removeEventDateListeners() {}

  Future<void> fetchBulls() async {
    setState(() => loadingBulls = true);
    try {
      final allCattle = await CattleService.getAllCattle();
      final bullsList = allCattle.where((cattle) =>
      cattle.classification.toLowerCase() == 'bull' &&
          cattle.status.toLowerCase() == 'active'
      ).toList();

      setState(() {
        bulls = bullsList;
        loadingBulls = false;
      });
    } catch (e) {
      setState(() => loadingBulls = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load bulls: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> fetchTechnicians() async {
    setState(() => loadingTechnicians = true);
    try {
      final techniciansList = await UserService().getTechnicians();

      if (mounted) {
        setState(() {
          technicians = techniciansList;
          loadingTechnicians = false;
        });

        // After loading technicians, check if we need to validate the current selection
        _validateCurrentTechnicianSelection();
      }
    } catch (e) {
      if (mounted) {
        setState(() => loadingTechnicians = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load technicians: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // Helper method to validate current technician selection after loading
  void _validateCurrentTechnicianSelection() {
    final currentValue = widget.controllers['technician']?.text;
    if (currentValue != null && currentValue.isNotEmpty) {
      // Check if the current value exists in the loaded technicians
      final exists = technicians.any((technician) {
        final displayName = '${technician.firstName} ${technician.lastName}';
        return displayName == currentValue;
      });

      // If it doesn't exist, clear the field
      if (!exists) {
        widget.controllers['technician']?.clear();
      }
    }
  }

  Future<void> selectDate(BuildContext context, TextEditingController controller, {Function(DateTime)? onDateSelected}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
      controller.text = formattedDate;

      if (onDateSelected != null) {
        onDateSelected(picked);
      }
    }
  }

  void calculateAndDisplayDeliveryDate(DateTime breedingDate) {
    try {
      final expectedDeliveryDate = breedingDate.add(Duration(days: cattleGestationPeriodDays));
      final formattedDate = '${expectedDeliveryDate.year.toString().padLeft(4, '0')}-'
          '${expectedDeliveryDate.month.toString().padLeft(2, '0')}-'
          '${expectedDeliveryDate.day.toString().padLeft(2, '0')}';

      if (widget.controllers['expected_delivery_date'] != null) {
        widget.controllers['expected_delivery_date']!.text = formattedDate;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      if (widget.controllers['expected_delivery_date'] != null) {
        widget.controllers['expected_delivery_date']!.clear();
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  void calculateAndDisplayReturnToHeatDate(DateTime eventDate) {
    try {
      final estimatedReturnDate = eventDate.add(Duration(days: returnToHeatDays));
      final formattedDate = '${estimatedReturnDate.year.toString().padLeft(4, '0')}-'
          '${estimatedReturnDate.month.toString().padLeft(2, '0')}-'
          '${estimatedReturnDate.day.toString().padLeft(2, '0')}';

      if (widget.controllers['estimated_return_date'] != null) {
        widget.controllers['estimated_return_date']!.text = formattedDate;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      if (widget.controllers['estimated_return_date'] != null) {
        widget.controllers['estimated_return_date']!.clear();
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  // Common UI Builders
  Widget buildDateField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
    bool showCalendarIcon = true,
    Function(DateTime)? onDateSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          suffixIcon: (readOnly || !showCalendarIcon) ? null : IconButton(
            icon: const Icon(Icons.calendar_today, color: AppColors.primary),
            onPressed: () => selectDate(context, controller, onDateSelected: onDateSelected),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.lightGreen),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        onTap: readOnly ? null : () => selectDate(context, controller, onDateSelected: onDateSelected),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a date';
          }
          return null;
        },
      ),
    );
  }

  Widget buildBullDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      child: DropdownButtonFormField<String>(
        value: widget.controllers['bull_tag']?.text.isEmpty == true
            ? null
            : widget.controllers['bull_tag']?.text,
        decoration: InputDecoration(
          labelText: 'Bull Tag (Father)',
          prefixIcon: const Icon(FontAwesomeIcons.mars, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.lightGreen),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          suffixIcon: loadingBulls
              ? Container(
            width: 20,
            height: 20,
            padding: const EdgeInsets.all(12),
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
              : null,
        ),
        hint: Text(loadingBulls ? 'Loading bulls...' : 'Select bull'),
        isExpanded: true,
        items: bulls.map((bull) {
          return DropdownMenuItem<String>(
            value: bull.tagNo,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                '${bull.tagNo} ${bull.name != null ? '(${bull.name})' : ''}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          );
        }).toList(),
        onChanged: loadingBulls ? null : (value) {
          widget.controllers['bull_tag']?.text = value ?? '';
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a bull';
          }
          return null;
        },
      ),
    );
  }

  // Enhanced buildTechnicianDropdown method for base_event_fields.dart

  Widget buildTechnicianDropdown() {
    // Get current value from controller
    String? currentValue = widget.controllers['technician']?.text;

    // Handle empty or null current value
    if (currentValue?.isEmpty == true) {
      currentValue = null;
    }

    print('=== Technician Dropdown Debug ===');
    print('Controller value: "$currentValue"');
    print('Loading technicians: $loadingTechnicians');
    print('Technicians count: ${technicians.length}');

    // If still loading technicians, show loading state
    if (loadingTechnicians) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: double.infinity,
        child: DropdownButtonFormField<String>(
          value: null,
          decoration: InputDecoration(
            labelText: 'Technician',
            prefixIcon: const Icon(FontAwesomeIcons.userDoctor, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.lightGreen),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Increased padding
            suffixIcon: Container(
              width: 20,
              height: 20,
              padding: const EdgeInsets.all(12),
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          hint: const Text('Loading technicians...'),
          items: const [],
          onChanged: null,
        ),
      );
    }

    // Create dropdown items with enhanced styling
    List<DropdownMenuItem<String>> dropdownItems = technicians.map((technician) {
      final displayName = '${technician.firstName} ${technician.lastName}'.trim();
      return DropdownMenuItem<String>(
        value: displayName,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4), // Increased vertical padding
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 60), // Minimum height constraint
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  height: 1.2, // Line height adjustment
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Text(
                technician.role.toUpperCase(),
                style: TextStyle(
                  fontSize: 13, // Slightly smaller font for role
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontWeight: FontWeight.w400,
                  height: 1.1, // Tighter line height for subtitle
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      );
    }).toList();

    // Check if the current value exists in the available options
    bool valueExists = false;
    if (currentValue != null) {
      valueExists = dropdownItems.any((item) {
        // Trim and compare both values
        final itemValue = item.value?.trim() ?? '';
        final currentVal = currentValue?.trim() ?? '';
        return itemValue == currentVal;
      });
      print('Checking if "$currentValue" exists in dropdown items: $valueExists');
    }

    // Determine the dropdown value to use
    String? dropdownValue;
    if (currentValue != null && valueExists) {
      dropdownValue = currentValue.trim();
      print('Using existing value: "$dropdownValue"');
    } else {
      dropdownValue = null;
      if (currentValue != null && !valueExists) {
        print('Current value "$currentValue" not found in technicians, clearing...');
        // Clear the controller if the value doesn't exist
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.controllers['technician']?.clear();
          }
        });
      }
    }

    print('Final dropdown value: "$dropdownValue"');
    print('=== End Debug ===');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      child: DropdownButtonFormField<String>(
        value: dropdownValue,
        decoration: InputDecoration(
          labelText: 'Technician',
          prefixIcon: const Icon(FontAwesomeIcons.userDoctor, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.lightGreen),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18), // Increased padding
        ),
        hint: const Text('Select technician'),
        isExpanded: true,
        itemHeight: 70, // Set explicit item height to prevent overflow
        menuMaxHeight: 300, // Limit dropdown menu height for better UX
        items: dropdownItems,
        onChanged: (value) {
          print('Technician dropdown changed to: "$value"');
          // Update the controller with the display name
          widget.controllers['technician']?.text = value ?? '';
          print('Controller updated to: "${widget.controllers['technician']?.text}"');

          // Force a rebuild to ensure the UI reflects the change
          if (mounted) {
            setState(() {});
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a technician';
          }
          return null;
        },
        // Custom dropdown button builder for better selected value display
        selectedItemBuilder: (BuildContext context) {
          return technicians.map<Widget>((technician) {
            final displayName = '${technician.firstName} ${technician.lastName}'.trim();
            return Container(
              alignment: Alignment.centerLeft,
              constraints: const BoxConstraints(minHeight: 50),
              child: Text(
                displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList();
        },
      ),
    );
  }

  Widget buildSemenDropdown() {
    List<String> allSemenOptions = [];

    for (var bull in bulls) {
      String bullSemenOption = '${bull.tagNo} Semen';
      if (bull.name != null && bull.name!.isNotEmpty) {
        bullSemenOption = '${bull.tagNo} (${bull.name}) Semen';
      }
      allSemenOptions.add(bullSemenOption);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      child: DropdownButtonFormField<String>(
        value: widget.controllers['semen_used']?.text.isEmpty == true
            ? null
            : widget.controllers['semen_used']?.text,
        decoration: InputDecoration(
          labelText: 'Semen Used',
          prefixIcon: const Icon(FontAwesomeIcons.dna, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.lightGreen),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          suffixIcon: loadingBulls
              ? Container(
            width: 20,
            height: 20,
            padding: const EdgeInsets.all(12),
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
              : null,
        ),
        hint: Text(loadingBulls ? 'Loading options...' : 'Select semen used'),
        isExpanded: true,
        items: allSemenOptions.map((semenOption) {
          return DropdownMenuItem<String>(
            value: semenOption,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                semenOption,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          );
        }).toList(),
        onChanged: loadingBulls ? null : (value) {
          widget.controllers['semen_used']?.text = value ?? '';
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select semen type';
          }
          return null;
        },
      ),
    );
  }
}