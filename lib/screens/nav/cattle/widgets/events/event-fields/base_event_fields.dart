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
  List<User> farmers = [];
  bool loadingBulls = false;
  bool loadingTechnicians = false;
  bool loadingFarmers = false;

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
    if (needsFarmers()) {
      fetchFarmers();
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
  bool needsFarmers() => false;
  void setupEventDateListeners() {}
  void removeEventDateListeners() {}
  // Optional hooks for subclasses
  void onBullsLoaded() {}

  Future<void> fetchBulls() async {
    setState(() => loadingBulls = true);
    try {
      final allCattle = await CattleService.getAllCattle();
      final bullsList = allCattle.where((cattle) =>
      cattle.classification.toLowerCase() == 'bull' &&
          cattle.status.toLowerCase() == 'healthy'
      ).toList();

      setState(() {
        bulls = bullsList;
        loadingBulls = false;
      });

      // Notify subclasses that bulls have been loaded
      onBullsLoaded();
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
    print('🔍 DEBUG: Starting fetchTechnicians...');
    setState(() => loadingTechnicians = true);

    try {
      print('🔍 DEBUG: About to call UserService().getUsersByRoles...');

      // Try multiple approaches to debug the issue

      // APPROACH 1: Try without any roles first to see if we get any users
      print('🔍 DEBUG: Trying to fetch ALL users first...');
      try {
        final allUsers = await UserService().getUsersByRoles();
        print('🔍 DEBUG: All users count: ${allUsers.length}');
        for (var user in allUsers) {
          print('🔍 DEBUG: User: ${user.firstName} ${user.lastName} - Role: "${user.role}"');
        }
      } catch (e) {
        print('🔍 DEBUG: Error fetching all users: $e');
      }

      // APPROACH 2: Try the dedicated getTechnicians method
      print('🔍 DEBUG: Trying getTechnicians method...');
      try {
        final directTechnicians = await UserService().getTechnicians();
        print('🔍 DEBUG: Direct technicians count: ${directTechnicians.length}');
        for (var tech in directTechnicians) {
          print('🔍 DEBUG: Direct technician: ${tech.firstName} ${tech.lastName} - Role: "${tech.role}"');
        }
      } catch (e) {
        print('🔍 DEBUG: Error with getTechnicians: $e');
      }

      // APPROACH 3: Try with the specific roles you want
      print('🔍 DEBUG: Trying with roles [pvo, lgu]...');
      final techniciansList = await UserService().getUsersByRoles(roles: ['pvo', 'lgu']);
      print('🔍 DEBUG: PVO/LGU users count: ${techniciansList.length}');

      // APPROACH 4: Try with uppercase roles
      print('🔍 DEBUG: Trying with roles [PVO, LGU]...');
      try {
        final upperCaseTechs = await UserService().getUsersByRoles(roles: ['PVO', 'LGU']);
        print('🔍 DEBUG: Uppercase PVO/LGU users count: ${upperCaseTechs.length}');
      } catch (e) {
        print('🔍 DEBUG: Error with uppercase roles: $e');
      }

      if (mounted) {
        setState(() {
          // For now, use whichever method returns results
          technicians = techniciansList;
          loadingTechnicians = false;
        });

        print('🔍 DEBUG: Final technicians assigned: ${technicians.length}');
        _validateCurrentTechnicianSelection();
      }
    } catch (e, stackTrace) {
      print('🔍 DEBUG: Exception in fetchTechnicians: $e');
      print('🔍 DEBUG: Stack trace: $stackTrace');

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

    print('🔍 DEBUG: fetchTechnicians completed');
  }

  Future<void> fetchFarmers() async {
    print('🔍 DEBUG: Starting fetchFarmers...');
    setState(() => loadingFarmers = true);

    try {
      print('🔍 DEBUG: About to call UserService().getUsersByRoles for farmers...');

      // Fetch users with farmer role
      final farmersList = await UserService().getUsersByRoles(roles: ['farmer']);
      print('🔍 DEBUG: Farmers count: ${farmersList.length}');

      if (mounted) {
        setState(() {
          farmers = farmersList;
          loadingFarmers = false;
        });

        print('🔍 DEBUG: Final farmers assigned: ${farmers.length}');
        _validateCurrentFarmerSelection();
      }
    } catch (e, stackTrace) {
      print('🔍 DEBUG: Exception in fetchFarmers: $e');
      print('🔍 DEBUG: Stack trace: $stackTrace');

      if (mounted) {
        setState(() => loadingFarmers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load farmers: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }

    print('🔍 DEBUG: fetchFarmers completed');
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

  // Helper method to validate current farmer selection after loading
  void _validateCurrentFarmerSelection() {
    final currentValue = widget.controllers['farmer']?.text;
    if (currentValue != null && currentValue.isNotEmpty) {
      // Check if the current value exists in the loaded farmers
      final exists = farmers.any((farmer) {
        final displayName = '${farmer.firstName} ${farmer.lastName}';
        return displayName == currentValue;
      });

      // If it doesn't exist, clear the field
      if (!exists) {
        widget.controllers['farmer']?.clear();
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
        value: () {
          final currentRaw = widget.controllers['bull_tag']?.text ?? '';
          final current = currentRaw.trim();
          if (current.isEmpty) return null;
          final options = bulls.map((b) => b.tagNo.trim()).toList();
          final lowerToOriginal = { for (final o in options) o.toLowerCase(): o };
          return lowerToOriginal[current.toLowerCase()] ?? current;
        }(),
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
                bull.tagNo,
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

  // Custom bull dropdown for natural breeding (simpler label)
  Widget buildBullDropdownForNaturalBreeding() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      child: DropdownButtonFormField<String>(
        value: () {
          final currentRaw = widget.controllers['bull_tag']?.text ?? '';
          final current = currentRaw.trim();
          if (current.isEmpty) return null;
          List<String> options = bulls.map((b) => b.tagNo.trim()).toList();
          if (!options.map((o) => o.toLowerCase()).contains(current.toLowerCase())) {
            options = [current, ...options];
          }
          final lowerToOriginal = { for (final o in options) o.toLowerCase(): o };
          final match = lowerToOriginal[current.toLowerCase()];
          // Debug
          // ignore: avoid_print
          print('Bull dropdown - current: "$current", options: ${options.join(', ')}');
          return match ?? current;
        }(),
        decoration: InputDecoration(
          labelText: 'Bull', // Simplified label for natural breeding
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
        items: () {
          final current = (widget.controllers['bull_tag']?.text ?? '').trim();
          List<String> options = bulls.map((b) => b.tagNo.trim()).toList();
          if (current.isNotEmpty && !options.map((o) => o.toLowerCase()).contains(current.toLowerCase())) {
            options = [current, ...options];
          }
          return options.map((tag) => DropdownMenuItem<String>(
            value: tag,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                tag,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )).toList();
        }(),
        onChanged: loadingBulls ? null : (value) {
          final val = (value ?? '').trim();
          widget.controllers['bull_tag']?.text = val;
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
    print('Technicians: ${technicians.map((t) => '${t.firstName} ${t.lastName} (ID: ${t.id})').join(', ')}');

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
      // Create unique value by combining name and ID to avoid duplicates
      final uniqueValue = '$displayName (ID: ${technician.id})';
      return DropdownMenuItem<String>(
        value: uniqueValue,
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

    print('Dropdown items: ${dropdownItems.map((item) => item.value).join(', ')}');

    // Check if the current value exists in the available options
    bool valueExists = false;
    if (currentValue != null) {
      valueExists = dropdownItems.any((item) {
        // Trim and compare both values
        final itemValue = item.value?.trim() ?? '';
        final currentVal = currentValue?.trim() ?? '';
        // Check if the current value matches either the full unique value or just the display name
        return itemValue == currentVal || itemValue.startsWith('$currentVal (ID: ');
      });
      print('Checking if "$currentValue" exists in dropdown items: $valueExists');
    }

    // Determine the dropdown value to use
    String? dropdownValue;
    if (currentValue != null && valueExists) {
      // Find the matching unique value from dropdown items
      final matchingItem = dropdownItems.firstWhere(
        (item) {
          final itemValue = item.value?.trim() ?? '';
          final currentVal = currentValue?.trim() ?? '';
          return itemValue == currentVal || itemValue.startsWith('$currentVal (ID: ');
        },
        orElse: () => dropdownItems.first, // Fallback, shouldn't happen
      );
      dropdownValue = matchingItem.value;
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
          // Extract display name from unique value (remove ID part)
          String displayName = value ?? '';
          if (displayName.contains(' (ID: ')) {
            displayName = displayName.split(' (ID: ')[0];
          }
          // Update the controller with the display name
          widget.controllers['technician']?.text = displayName;
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
      // Use pure tag only
      allSemenOptions.add(bull.tagNo.trim());
    }

    final currentValueRaw = widget.controllers['semen_used']?.text ?? '';
    final currentValue = currentValueRaw.trim();
    // If the current stored value isn't present in options (e.g., bulls filtered or not healthy), include it so it can preselect
    if (currentValue.isNotEmpty && !allSemenOptions.contains(currentValue)) {
      allSemenOptions = [currentValue, ...allSemenOptions];
    }
    final exists = allSemenOptions.contains(currentValue);
    final dropdownValue = currentValue.isNotEmpty && exists ? currentValue : null;
    // Debug
    // ignore: avoid_print
    print('Semen dropdown - current: "$currentValue", exists: $exists, options: ${allSemenOptions.join(', ')}');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      child: DropdownButtonFormField<String>(
        value: dropdownValue,
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
          final val = (value ?? '').trim();
          widget.controllers['semen_used']?.text = val;
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

  // Enhanced buildFarmerDropdown method for base_event_fields.dart
  Widget buildFarmerDropdown() {
    // Get current value from controller
    String? currentValue = widget.controllers['farmer']?.text;

    // Handle empty or null current value
    if (currentValue?.isEmpty == true) {
      currentValue = null;
    }

    print('=== Farmer Dropdown Debug ===');
    print('Controller value: "$currentValue"');
    print('Loading farmers: $loadingFarmers');
    print('Farmers count: ${farmers.length}');

    // If still loading farmers, show loading state
    if (loadingFarmers) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: double.infinity,
        child: DropdownButtonFormField<String>(
          value: null,
          decoration: InputDecoration(
            labelText: 'Farmer',
            prefixIcon: const Icon(FontAwesomeIcons.user, color: AppColors.primary),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            suffixIcon: Container(
              width: 20,
              height: 20,
              padding: const EdgeInsets.all(12),
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          hint: const Text('Loading farmers...'),
          items: const [],
          onChanged: null,
        ),
      );
    }

    // Create dropdown items with enhanced styling
    List<DropdownMenuItem<String>> dropdownItems = farmers.map((farmer) {
      final displayName = '${farmer.firstName} ${farmer.lastName}'.trim();
      return DropdownMenuItem<String>(
        value: displayName,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Text(
                farmer.role.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      );
    }).toList();

    print('Dropdown items: ${dropdownItems.map((item) => item.value).join(', ')}');

    // Check if the current value exists in the available options
    bool valueExists = false;
    if (currentValue != null) {
      valueExists = dropdownItems.any((item) {
        // Trim and compare both values
        final itemValue = item.value?.trim() ?? '';
        final currentVal = currentValue?.trim() ?? '';
        // Check if the current value matches either the full unique value or just the display name
        return itemValue == currentVal || itemValue.startsWith('$currentVal (ID: ');
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
        print('Current value "$currentValue" not found in farmers, clearing...');
        // Clear the controller if the value doesn't exist
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.controllers['farmer']?.clear();
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
          labelText: 'Farmer',
          prefixIcon: const Icon(FontAwesomeIcons.user, color: AppColors.primary),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        ),
        hint: const Text('Select farmer'),
        isExpanded: true,
        itemHeight: 70,
        menuMaxHeight: 300,
        items: dropdownItems,
        onChanged: (value) {
          print('Farmer dropdown changed to: "$value"');
          // Update the controller with the display name
          widget.controllers['farmer']?.text = value ?? '';
          print('Controller updated to: "${widget.controllers['farmer']?.text}"');

          // Force a rebuild to ensure the UI reflects the change
          if (mounted) {
            setState(() {});
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a farmer';
          }
          return null;
        },
        // Custom dropdown button builder for better selected value display
        selectedItemBuilder: (BuildContext context) {
          return farmers.map<Widget>((farmer) {
            final displayName = '${farmer.firstName} ${farmer.lastName}'.trim();
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
}