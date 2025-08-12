// lib/screens/nav/cattle/widgets/calf_registration_dialog.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../constants/app_colors.dart';
import '../../../../services/cattle/cattle_service.dart';

class CalfRegistrationDialog extends StatefulWidget {
  final String motherTag;
  final String fatherTag;
  final Map<String, dynamic>? existingCalfData; // For editing mode
  final bool isEditMode; // Flag to determine if we're editing

  const CalfRegistrationDialog({
    super.key,
    required this.motherTag,
    required this.fatherTag,
    this.existingCalfData,
    this.isEditMode = false,
  });

  @override
  State<CalfRegistrationDialog> createState() => _CalfRegistrationDialogState();
}

class _CalfRegistrationDialogState extends State<CalfRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tagController = TextEditingController();
  final _nameController = TextEditingController();

  String _selectedGender = 'Female';
  bool _isLoading = false;
  List<String> _existingTags = [];
  int? _existingCalfId; // Store the calf ID for updates

  final List<String> _genderOptions = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _loadExistingTags();
    _initializeForEditMode();
  }

  void _initializeForEditMode() {
    if (widget.isEditMode && widget.existingCalfData != null) {
      final data = widget.existingCalfData!;

      try {
        // Handle both direct data and nested fullCalfData
        Map<String, dynamic> calfData;
        if (data.containsKey('fullCalfData')) {
          calfData = data['fullCalfData'] as Map<String, dynamic>;
          // Try to get calf ID from multiple possible sources
          _existingCalfId = _safeParseInt(data['calfId']) ?? _safeParseInt(calfData['id']);
        } else {
          calfData = data;
          _existingCalfId = _safeParseInt(data['id']);
        }

        _tagController.text = _safeParseString(calfData['tag_no']) ?? '';
        _nameController.text = _safeParseString(calfData['name']) ?? '';
        _selectedGender = _safeParseString(calfData['gender']) ?? 'Female';

        print('Edit mode initialized with calf ID: $_existingCalfId, tag: ${_tagController.text}');
      } catch (e) {
        print('Error initializing edit mode: $e');
        // Set defaults on error
        _tagController.text = '';
        _nameController.text = '';
        _selectedGender = 'Female';
        _existingCalfId = null;
      }
    }
  }

  // Helper methods for safe type conversion
  int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  String? _safeParseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  Future<void> _loadExistingTags() async {
    try {
      final cattle = await CattleService.getAllCattle();
      setState(() {
        _existingTags = cattle.map((c) => c.tagNo).toList();

        // If editing, remove the current calf's tag from existing tags
        if (widget.isEditMode && widget.existingCalfData != null) {
          final currentTag = _getCurrentTag();
          if (currentTag != null && currentTag.isNotEmpty) {
            _existingTags.remove(currentTag);
          }
        }
      });
    } catch (e) {
      print('Error loading existing tags: $e');
    }
  }

  String? _getCurrentTag() {
    if (widget.existingCalfData == null) return null;

    try {
      final data = widget.existingCalfData!;
      if (data.containsKey('fullCalfData')) {
        return _safeParseString(data['fullCalfData']['tag_no']);
      }
      return _safeParseString(data['tag_no']);
    } catch (e) {
      print('Error getting current tag: $e');
      return null;
    }
  }

  String? _validateTagNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tag number is required';
    }

    final trimmedValue = value.trim();
    if (_existingTags.contains(trimmedValue)) {
      return 'This tag number already exists';
    }

    return null;
  }

  String _getClassification() {
    return 'Calf'; // Both male and female calves start as 'Calf'
  }

  Map<String, dynamic> _prepareCalfData() {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final baseData = <String, dynamic>{
      'tag_no': _tagController.text.trim(),
      'name': _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      'gender': _selectedGender,
      'classification': _getClassification(),
      'status': 'Active',
      'source': 'Born on farm',
      'mother_tag': widget.motherTag,
      'father_tag': widget.fatherTag.isEmpty ? null : widget.fatherTag,
      'notes': 'Born from ${widget.motherTag}${widget.fatherTag.isNotEmpty ? ' and ${widget.fatherTag}' : ''}',
    };

    // Handle dates based on edit mode
    if (widget.isEditMode && widget.existingCalfData != null) {
      try {
        // Preserve existing dates when editing
        final existingData = widget.existingCalfData!.containsKey('fullCalfData')
            ? widget.existingCalfData!['fullCalfData'] as Map<String, dynamic>
            : widget.existingCalfData!;

        baseData['date_of_birth'] = _safeParseString(existingData['date_of_birth']) ?? todayString;
        baseData['joined_date'] = _safeParseString(existingData['joined_date']) ?? todayString;

        // Preserve other existing fields that shouldn't be overwritten
        if (existingData['weight'] != null) {
          baseData['weight'] = existingData['weight'];
        }
        if (existingData['breed'] != null) {
          baseData['breed'] = _safeParseString(existingData['breed']);
        }
        if (existingData['group_name'] != null) {
          baseData['group_name'] = _safeParseString(existingData['group_name']);
        }
      } catch (e) {
        print('Error preserving existing data: $e');
        // Use defaults if error occurs
        baseData['date_of_birth'] = todayString;
        baseData['joined_date'] = todayString;
      }
    } else {
      // New calf - use today's date
      baseData['date_of_birth'] = todayString;
      baseData['joined_date'] = todayString;
    }

    // Add other nullable fields with defaults
    baseData['weight'] = baseData['weight'];
    baseData['breed'] = baseData['breed'];
    baseData['group_name'] = baseData['group_name'];

    // Add ID for updates - ensure it's properly typed
    if (widget.isEditMode && _existingCalfId != null) {
      baseData['id'] = _existingCalfId; // This should be an int
      print('Adding calf ID to update data: $_existingCalfId (${_existingCalfId.runtimeType})');
    }

    print('Prepared calf data: ${baseData.keys.join(', ')}');
    return baseData;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate father tag for new registrations
    if (!widget.isEditMode && widget.fatherTag.isEmpty) {
      _showError('Please select a bull (father) first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final calfData = _prepareCalfData();
      print('Calf data prepared for ${widget.isEditMode ? 'update' : 'registration'}: $calfData');

      // Prepare result data with safe type conversion - DO NOT register yet
      Map<String, dynamic> resultData = {
        'tag_no': _tagController.text.trim(),
        'gender': _selectedGender,
        'name': _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        'registered': false, // Mark as not registered yet - will be done when event is saved
        'isEditMode': widget.isEditMode,
        'fullCalfData': calfData,
        'pendingOperation': widget.isEditMode ? 'update' : 'create', // Track what operation is pending
      };

      // Include the calf ID if we have it
      if (_existingCalfId != null) {
        resultData['calfId'] = _existingCalfId;
      }

      Navigator.of(context).pop(resultData);

      // Show appropriate message
      if (mounted) {
        _showSuccess('Calf information saved. Will be ${widget.isEditMode ? 'updated' : 'registered'} when event is saved.');
      }

    } catch (e) {
      print('Error preparing calf data: $e');
      print('Stack trace: ${StackTrace.current}');
      _showError('Error preparing calf data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.darkGreen,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      FontAwesomeIcons.baby,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isEditMode ? 'Edit Calf Information' : 'Register New Calf',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.isEditMode ? 'Update calf details' : 'Prepare calf for registration',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Parent Information
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.lightGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Parent Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.female, color: AppColors.primary, size: 18),
                                const SizedBox(width: 8),
                                Text('Mother: ${widget.motherTag}',
                                    style: const TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.male, color: AppColors.primary, size: 18),
                                const SizedBox(width: 8),
                                Text('Father: ${widget.fatherTag.isEmpty ? 'Not selected' : widget.fatherTag}',
                                    style: const TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Calf Tag Number
                      TextFormField(
                        controller: _tagController,
                        validator: _validateTagNumber,
                        decoration: InputDecoration(
                          labelText: 'Calf Tag Number *',
                          prefixIcon: const Icon(Icons.label, color: AppColors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.lightGreen),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Calf Name (Optional)
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Calf Name (Optional)',
                          prefixIcon: const Icon(FontAwesomeIcons.signature, color: AppColors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.lightGreen),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Gender Selection
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender *',
                          prefixIcon: Icon(
                            _selectedGender == 'Male' ? Icons.male : Icons.female,
                            color: AppColors.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.lightGreen),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                        ),
                        items: _genderOptions.map((gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedGender = value);
                          }
                        },
                      ),

                      const SizedBox(height: 20),

                      // Status info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 20
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.isEditMode
                                    ? 'Calf will be updated in the database when the event is saved.'
                                    : 'Calf will be registered in the database when the event is saved.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Text(
                        widget.isEditMode ? 'Save Changes' : 'Prepare Calf',
                        style: const TextStyle(fontWeight: FontWeight.w600),
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

  @override
  void dispose() {
    _tagController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}