// lib/screens/nav/goat/widgets/history/history-fields/base_history_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/models/user.dart';

import '../../../../../../services/goat/goat_service.dart';
import '../../../../../../services/user_service.dart';
import '../history_styled_text_field.dart';

abstract class BaseEventFields extends StatefulWidget {
  final Map<String, TextEditingController> controllers;

  const BaseEventFields({
    super.key,
    required this.controllers,
  });
}

abstract class BaseEventFieldsState<T extends BaseEventFields> extends State<T> {
  List<goat> Bucks = [];
  List<User> technicians = [];
  List<User> farmers = [];
  bool loadingBucks = false;
  bool loadingTechnicians = false;
  bool loadingFarmers = false;
  bool _useTechnicianTextInput = false; // Toggle between dropdown and text input

  static const int goatGestationPeriodDays = 283;
  static const int returnToHeatDays = 21;

  @override
  void initState() {
    super.initState();
    if (needsBucks()) {
      fetchBucks();
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
  bool needsBucks() => false;
  bool needsTechnicians() => false;
  bool needsFarmers() => false;
  void setupEventDateListeners() {}
  void removeEventDateListeners() {}
  // Optional hooks for subclasses
  void onBucksLoaded() {}

  Future<void> fetchBucks() async {
        debugPrint('DEBUG: fetchBucks started');
    setState(() => loadingBucks = true);
    try {
      final allgoat = await GoatService.getAllGoats();
      debugPrint('DEBUG: fetchBucks - loaded ${allgoat.length} total goat');
      
      final BucksList = allgoat.where((goat) =>
      goat.classification.toLowerCase() == 'Buck' &&
          goat.status.toLowerCase() == 'healthy'
      ).toList();
      
      debugPrint('DEBUG: fetchBucks - found ${BucksList.length} healthy Bucks');
      for (final Buck in BucksList) {
        debugPrint('DEBUG: fetchBucks - Buck: ${Buck.tagNo} (${Buck.classification}, ${Buck.status})');
      }

      setState(() {
        Bucks = BucksList;
        loadingBucks = false;
      });
      
      debugPrint('DEBUG: fetchBucks - Bucks list updated, calling onBucksLoaded');

      // Notify subclasses that Bucks have been loaded
      onBucksLoaded();
    } catch (e) {
      debugPrint('DEBUG: fetchBucks - error: $e');
      setState(() => loadingBucks = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load Bucks: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> fetchTechnicians() async {
        debugPrint('🔍 DEBUG: Starting fetchTechnicians...');
    setState(() => loadingTechnicians = true);

    try {
      debugPrint('🔍 DEBUG: About to call UserService().getUsersByRoles...');

      // Try multiple approaches to debug the issue

      // APPROACH 1: Try without any roles first to see if we get any users
      debugPrint('🔍 DEBUG: Trying to fetch ALL users first...');
      try {
        final allUsers = await UserService().getUsersByRoles();
        debugPrint('🔍 DEBUG: All users count: ${allUsers.length}');
        for (var user in allUsers) {
          debugPrint('🔍 DEBUG: User: ${user.firstName} ${user.lastName} - Role: "${user.role}"');
        }
      } catch (e) {
        debugPrint('🔍 DEBUG: Error fetching all users: $e');
      }

      // APPROACH 2: Try the dedicated getTechnicians method
      debugPrint('🔍 DEBUG: Trying getTechnicians method...');
      try {
        final directTechnicians = await UserService().getTechnicians();
        debugPrint('🔍 DEBUG: Direct technicians count: ${directTechnicians.length}');
        for (var tech in directTechnicians) {
          debugPrint('🔍 DEBUG: Direct technician: ${tech.firstName} ${tech.lastName} - Role: "${tech.role}"');
        }
      } catch (e) {
        debugPrint('🔍 DEBUG: Error with getTechnicians: $e');
      }

      // APPROACH 3: Try with the specific roles you want
      debugPrint('🔍 DEBUG: Trying with roles [pvo, lgu]...');
      final techniciansList = await UserService().getUsersByRoles(roles: ['pvo', 'lgu']);
      debugPrint('🔍 DEBUG: PVO/LGU users count: ${techniciansList.length}');

      // APPROACH 4: Try with uppercase roles
      debugPrint('🔍 DEBUG: Trying with roles [PVO, LGU]...');
      try {
        final upperCaseTechs = await UserService().getUsersByRoles(roles: ['PVO', 'LGU']);
        debugPrint('🔍 DEBUG: Uppercase PVO/LGU users count: ${upperCaseTechs.length}');
      } catch (e) {
        debugPrint('🔍 DEBUG: Error with uppercase roles: $e');
      }

      if (mounted) {
        setState(() {
          // For now, use whichever method returns results
          technicians = techniciansList;
          loadingTechnicians = false;
        });

        debugPrint('🔍 DEBUG: Final technicians assigned: ${technicians.length}');
        _validateCurrentTechnicianSelection();
      }
    } catch (e, stackTrace) {
      debugPrint('🔍 DEBUG: Exception in fetchTechnicians: $e');
      debugPrint('🔍 DEBUG: Stack trace: $stackTrace');

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

        debugPrint('🔍 DEBUG: fetchTechnicians completed');
  }

  Future<void> fetchFarmers() async {
        debugPrint('🔍 DEBUG: Starting fetchFarmers...');
    setState(() => loadingFarmers = true);

    try {
      debugPrint('🔍 DEBUG: About to call UserService().getUsersByRoles for farmers...');

      // Fetch users with farmer role
      final farmersList = await UserService().getUsersByRoles(roles: ['farmer']);
      debugPrint('🔍 DEBUG: Farmers count: ${farmersList.length}');

      if (mounted) {
        setState(() {
          farmers = farmersList;
          loadingFarmers = false;
        });

        debugPrint('🔍 DEBUG: Final farmers assigned: ${farmers.length}');
        _validateCurrentFarmerSelection();
      }
    } catch (e, stackTrace) {
      debugPrint('🔍 DEBUG: Exception in fetchFarmers: $e');
      debugPrint('🔍 DEBUG: Stack trace: $stackTrace');

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

        debugPrint('🔍 DEBUG: fetchFarmers completed');
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
      final expectedDeliveryDate = breedingDate.add(Duration(days: goatGestationPeriodDays));
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
          contentPadding: const EdgeInsets.only(left: 12, right: 12, top: 14, bottom: 14),
          isDense: true,
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

  Widget buildBuckDropdown() {
    final currentRaw = widget.controllers['Buck_tag']?.text ?? '';
    final current = currentRaw.trim();
    final isAutoFilled = current.isNotEmpty && !Bucks.any((Buck) => Buck.tagNo.toLowerCase() == current.toLowerCase());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      child: DropdownButtonFormField<String>(
        value: () {
          debugPrint('DEBUG: buildBuckDropdown - current controller value: "$current"');
          debugPrint('DEBUG: buildBuckDropdown - Bucks list length: ${Bucks.length}');
          debugPrint('DEBUG: buildBuckDropdown - Bucks tags: ${Bucks.map((b) => b.tagNo).join(', ')}');
          debugPrint('DEBUG: buildBuckDropdown - isAutoFilled: $isAutoFilled');
          
          if (current.isEmpty) {
            debugPrint('DEBUG: buildBuckDropdown - current is empty, returning null');
            return null;
          }
          
          final options = Bucks.map((b) => b.tagNo.trim()).toList();
          final lowerToOriginal = { for (final o in options) o.toLowerCase(): o };
          
          // If the current value is not in the Bucks list, add it as a temporary option
          if (!lowerToOriginal.containsKey(current.toLowerCase())) {
            debugPrint('DEBUG: buildBuckDropdown - current value "$current" not found in Bucks list, adding as temporary option');
            options.add(current);
            lowerToOriginal[current.toLowerCase()] = current;
          }
          
          final result = lowerToOriginal[current.toLowerCase()] ?? current;
          debugPrint('DEBUG: buildBuckDropdown - calculated value: "$result"');
          return result;
        }(),
        decoration: InputDecoration(
          labelText: 'Buck Tag (Father)',
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
          fillColor: isAutoFilled ? Colors.grey.shade100 : Colors.white, // Slightly grayed background when read-only
          contentPadding: const EdgeInsets.only(left: 12, right: 12, top: 14, bottom: 14),
          isDense: true,
          suffixIcon: loadingBucks
              ? Container(
            width: 20,
            height: 20,
            padding: const EdgeInsets.all(12),
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
              : isAutoFilled
                  ? Container(
                      width: 20,
                      height: 20,
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.lock,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    )
                  : null,
        ),
        hint: Text(
          loadingBucks ? 'Loading Bucks...' : 'Select Buck',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        isExpanded: true,
        items: () {
          final items = Bucks.map((Buck) {
            return DropdownMenuItem<String>(
              value: Buck.tagNo,
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  Buck.tagNo,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            );
          }).toList();
          
          // If current value is not in Bucks list, add it as a temporary option
          if (isAutoFilled) {
            debugPrint('DEBUG: buildBuckDropdown - adding temporary item for "$current"');
            items.insert(0, DropdownMenuItem<String>(
              value: current,
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  current, // Show only the Buck tag, no "(Auto-filled)" text
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  // Use normal text color, no special styling
                ),
              ),
            ));
          }
          
          return items;
        }(),
        onChanged: (loadingBucks || isAutoFilled) ? null : (value) {
          widget.controllers['Buck_tag']?.text = value ?? '';
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a Buck';
          }
          return null;
        },
      ),
    );
  }

  // Custom Buck dropdown for natural breeding (simpler label)
  Widget buildBuckDropdownForNaturalBreeding() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      child: DropdownButtonFormField<String>(
        value: () {
          final currentRaw = widget.controllers['Buck_tag']?.text ?? '';
          final current = currentRaw.trim();
          if (current.isEmpty) return null;
          List<String> options = Bucks.map((b) => b.tagNo.trim()).toList();
          if (!options.map((o) => o.toLowerCase()).contains(current.toLowerCase())) {
            options = [current, ...options];
          }
          final lowerToOriginal = { for (final o in options) o.toLowerCase(): o };
          final match = lowerToOriginal[current.toLowerCase()];
          // Debug
          // ignore: avoid_print
          debugPrint('Buck dropdown - current: "$current", options: ${options.join(', ')}');
          return match ?? current;
        }(),
        decoration: InputDecoration(
          labelText: 'Buck', // Simplified label for natural breeding
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
          contentPadding: const EdgeInsets.only(left: 12, right: 12, top: 14, bottom: 14),
          isDense: true,
          suffixIcon: loadingBucks
              ? Container(
            width: 20,
            height: 20,
            padding: const EdgeInsets.all(12),
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
              : null,
        ),
        hint: Text(
          loadingBucks ? 'Loading Bucks...' : 'Select Buck',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        isExpanded: true,
        items: () {
          final current = (widget.controllers['Buck_tag']?.text ?? '').trim();
          List<String> options = Bucks.map((b) => b.tagNo.trim()).toList();
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
        onChanged: loadingBucks ? null : (value) {
          final val = (value ?? '').trim();
          widget.controllers['Buck_tag']?.text = val;
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a Buck';
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

    // Auto-detect if we should use text input mode
    // If current value is not empty and not in the dropdown list, use text input
    if (currentValue != null && currentValue.isNotEmpty && technicians.isNotEmpty && !loadingTechnicians) {
      final valueExists = technicians.any((technician) {
        final displayName = '${technician.firstName} ${technician.lastName}'.trim();
        return displayName.toLowerCase() == currentValue!.toLowerCase();
      });
      if (!valueExists && !_useTechnicianTextInput) {
        // If value doesn't exist in dropdown and we haven't manually set text input mode,
        // automatically switch to text input mode
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _useTechnicianTextInput = true;
            });
          }
        });
      }
    }

        debugPrint('=== Technician Dropdown Debug ===');
        debugPrint('Controller value: "$currentValue"');
        debugPrint('Loading technicians: $loadingTechnicians');
        debugPrint('Technicians count: ${technicians.length}');
        debugPrint('Use text input: $_useTechnicianTextInput');
        debugPrint('Technicians: ${technicians.map((t) => '${t.firstName} ${t.lastName} (ID: ${t.id})').join(', ')}');

    // If still loading technicians, show loading state
    if (loadingTechnicians) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Technician/Veterinarian',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                value: null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Technician',
                  prefixIcon: const Icon(FontAwesomeIcons.userDoctor, color: AppColors.primary, size: 18),
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
                  contentPadding: const EdgeInsets.only(left: 10, right: 36, top: 16, bottom: 16),
                  isDense: true,
                  suffixIcon: Container(
                    width: 16,
                    height: 16,
                    padding: const EdgeInsets.all(6),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                hint: const Text(
                  'Loading technicians...',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
                selectedItemBuilder: (context) => [
                  const SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Loading technicians...',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ],
                items: const [],
                onChanged: null,
              ),
            ),
          ),
        ],
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
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
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

        debugPrint('Dropdown items: ${dropdownItems.map((item) => item.value).join(', ')}');

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
      debugPrint('Checking if "$currentValue" exists in dropdown items: $valueExists');
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
      debugPrint('Using existing value: "$dropdownValue"');
    } else {
      dropdownValue = null;
      if (currentValue != null && !valueExists) {
        debugPrint('Current value "$currentValue" not found in technicians, clearing...');
        // Clear the controller if the value doesn't exist
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.controllers['technician']?.clear();
          }
        });
      }
    }

        debugPrint('Final dropdown value: "$dropdownValue"');
        debugPrint('=== End Debug ===');

    // Return text input or dropdown based on mode
    if (_useTechnicianTextInput) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Technician/Veterinarian',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _useTechnicianTextInput = false;
                    // Clear controller when switching to dropdown
                    widget.controllers['technician']?.clear();
                  });
                },
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text(
                  'Use Dropdown',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          HistoryStyledTextField(
            label: 'Technician/Veterinarian Name',
            controller: widget.controllers['technician']!,
            hint: 'Enter technician or veterinarian name',
            icon: FontAwesomeIcons.userDoctor,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter technician/veterinarian name';
              }
              return null;
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Technician/Veterinarian',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _useTechnicianTextInput = true;
                });
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text(
                'Enter Name',
                style: TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        Container(
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
          contentPadding: const EdgeInsets.only(left: 12, right: 12, top: 18, bottom: 18),
          isDense: true,
        ),
        hint: const Text(
          'Select technician',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        isExpanded: true,
        itemHeight: 70, // Set explicit item height to prevent overflow
        menuMaxHeight: 300, // Limit dropdown menu height for better UX
        items: dropdownItems,
        onChanged: (value) {
          debugPrint('Technician dropdown changed to: "$value"');
          // Extract display name from unique value (remove ID part)
          String displayName = value ?? '';
          if (displayName.contains(' (ID: ')) {
            displayName = displayName.split(' (ID: ')[0];
          }
          // Update the controller with the display name
          widget.controllers['technician']?.text = displayName;
          debugPrint('Controller updated to: "${widget.controllers['technician']?.text}"');

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
        ),
      ],
    );
  }

  Widget buildSemenDropdown() {
    List<String> allSemenOptions = [];

    for (var Buck in Bucks) {
      // Use pure tag only
      allSemenOptions.add(Buck.tagNo.trim());
    }

    final currentValueRaw = widget.controllers['semen_used']?.text ?? '';
    final currentValue = currentValueRaw.trim();
    // If the current stored value isn't present in options (e.g., Bucks filtered or not healthy), include it so it can preselect
    if (currentValue.isNotEmpty && !allSemenOptions.contains(currentValue)) {
      allSemenOptions = [currentValue, ...allSemenOptions];
    }
    final exists = allSemenOptions.contains(currentValue);
    final dropdownValue = currentValue.isNotEmpty && exists ? currentValue : null;
    // Debug
    // ignore: avoid_print
        debugPrint('Semen dropdown - current: "$currentValue", exists: $exists, options: ${allSemenOptions.join(', ')}');

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
          contentPadding: const EdgeInsets.only(left: 12, right: 12, top: 14, bottom: 14),
          isDense: true,
          suffixIcon: loadingBucks
              ? Container(
            width: 20,
            height: 20,
            padding: const EdgeInsets.all(12),
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
              : null,
        ),
        hint: Text(
          loadingBucks ? 'Loading options...' : 'Select semen used',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
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
        onChanged: loadingBucks ? null : (value) {
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

        debugPrint('=== Farmer Dropdown Debug ===');
        debugPrint('Controller value: "$currentValue"');
        debugPrint('Loading farmers: $loadingFarmers');
        debugPrint('Farmers count: ${farmers.length}');

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
            contentPadding: const EdgeInsets.only(left: 12, right: 12, top: 16, bottom: 16),
          isDense: true,
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
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
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

        debugPrint('Dropdown items: ${dropdownItems.map((item) => item.value).join(', ')}');

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
      debugPrint('Checking if "$currentValue" exists in dropdown items: $valueExists');
    }

    // Determine the dropdown value to use
    String? dropdownValue;
    if (currentValue != null && valueExists) {
      dropdownValue = currentValue.trim();
      debugPrint('Using existing value: "$dropdownValue"');
    } else {
      dropdownValue = null;
      if (currentValue != null && !valueExists) {
        debugPrint('Current value "$currentValue" not found in farmers, clearing...');
        // Clear the controller if the value doesn't exist
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.controllers['farmer']?.clear();
          }
        });
      }
    }

        debugPrint('Final dropdown value: "$dropdownValue"');
        debugPrint('=== End Debug ===');

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
          contentPadding: const EdgeInsets.only(left: 12, right: 12, top: 18, bottom: 18),
          isDense: true,
        ),
        hint: const Text(
          'Select farmer',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        isExpanded: true,
        itemHeight: 70,
        menuMaxHeight: 300,
        items: dropdownItems,
        onChanged: (value) {
          debugPrint('Farmer dropdown changed to: "$value"');
          // Update the controller with the display name
          widget.controllers['farmer']?.text = value ?? '';
          debugPrint('Controller updated to: "${widget.controllers['farmer']?.text}"');

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
