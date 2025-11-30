// lib/screens/nav/goat/widgets/Kid_registration_dialog.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../constants/app_colors.dart';
import '../../../../services/goat/goat_service.dart';

class KidRegistrationDialog extends StatefulWidget {
  final String motherTag;
  final String fatherTag;
  final Map<String, dynamic>? existingKidData; // For editing mode
  final bool isEditMode; // Flag to determine if we're editing
  final List<String>? reservedTags; // Tags to avoid (e.g., already prepared in-session)

  const KidRegistrationDialog({
    super.key,
    required this.motherTag,
    required this.fatherTag,
    this.existingKidData,
    this.isEditMode = false,
    this.reservedTags,
  });

  @override
  State<KidRegistrationDialog> createState() => _KidRegistrationDialogState();
}

class _KidRegistrationDialogState extends State<KidRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tagController = TextEditingController();

  String _selectedSex = 'Female';
  bool _isLoading = false;
  List<String> _existingTags = [];
  int? _existingKidId; // Store the Kid ID for updates

  final List<String> _sexOptions = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _loadExistingTags();
    _initializeForEditMode();
  }

  void _initializeForEditMode() {
    if (widget.isEditMode && widget.existingKidData != null) {
      final data = widget.existingKidData!;

      try {
        // Handle both direct data and nested fullKidData
        Map<String, dynamic> kidData;
        if (data.containsKey('fullKidData')) {
          kidData = data['fullKidData'] as Map<String, dynamic>;
          // Try to get Kid ID from multiple possible sources
          _existingKidId = _safeParseInt(data['kidId']) ?? _safeParseInt(kidData['id']);
        } else {
          kidData = data;
          _existingKidId = _safeParseInt(data['id']);
        }

        _tagController.text = _safeParseString(kidData['tag_no']) ?? '';
        _selectedSex = _safeParseString(kidData['sex']) ?? 'Female';

        debugPrint('Edit mode initialized with Kid ID: $_existingKidId, tag: ${_tagController.text}');
      } catch (e) {
        debugPrint('Error initializing edit mode: $e');
        // Set defaults on error
        _tagController.text = '';
        _selectedSex = 'Female';
        _existingKidId = null;
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
      final goat = await GoatService.getAllGoats();
      setState(() {
        _existingTags = goat.map((c) => c.tagNo).toList();
        // Include reserved tags from current session to prevent duplicates
        if (widget.reservedTags != null && widget.reservedTags!.isNotEmpty) {
          _existingTags.addAll(widget.reservedTags!);
        }

        // If editing, remove the current Kid's tag from existing tags
        if (widget.isEditMode && widget.existingKidData != null) {
          final currentTag = _getCurrentTag();
          if (currentTag != null && currentTag.isNotEmpty) {
            _existingTags.remove(currentTag);
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading existing tags: $e');
    }
  }
  
  /// Check if tag number is unique (not in existing tags)
  bool _isTagNumberUnique(String tagNumber) {
    final lowerTag = tagNumber.toLowerCase();
    return !_existingTags.contains(lowerTag);
  }

  String? _getCurrentTag() {
    if (widget.existingKidData == null) return null;

    try {
      final data = widget.existingKidData!;
      if (data.containsKey('fullKidData')) {
        return _safeParseString(data['fullKidData']['tag_no']);
      }
      return _safeParseString(data['tag_no']);
    } catch (e) {
      debugPrint('Error getting current tag: $e');
      return null;
    }
  }

  String? _validateTagNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tag number is required';
    }

    final trimmedValue = value.trim();
    
    // Check if tag already exists (case-insensitive)
    final exists = _existingTags.any((tag) => 
        tag.toLowerCase() == trimmedValue.toLowerCase());
    
    if (exists) {
      return 'This tag number already exists';
    }

    // Validate tag format (should be 6-digit number)
    final tagPattern = RegExp(r'^\d{6}$');
    if (!tagPattern.hasMatch(trimmedValue)) {
      return 'Tag must be a 6-digit number (e.g., 123456)';
    }

    return null;
  }

  String _getClassification() {
    return 'Kid'; // Both male and female calves start as 'Kid'
  }

  Map<String, dynamic> _prepareKidData() {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final baseData = <String, dynamic>{
      'tag_no': _tagController.text.trim(),
      'sex': _selectedSex,
      'classification': _getClassification(),
      'status': 'Healthy',
      'source': 'Born on farm',
      'mother_tag': widget.motherTag,
      'father_tag': widget.fatherTag.isEmpty ? null : widget.fatherTag,
      'notes': 'Born from ${widget.motherTag}${widget.fatherTag.isNotEmpty ? ' and ${widget.fatherTag}' : ''}',
    };

    // Handle dates based on edit mode
    if (widget.isEditMode && widget.existingKidData != null) {
      try {
        // Preserve existing dates when editing
        final existingData = widget.existingKidData!.containsKey('fullKidData')
            ? widget.existingKidData!['fullKidData'] as Map<String, dynamic>
            : widget.existingKidData!;

        baseData['date_of_birth'] = _safeParseString(existingData['date_of_birth']) ?? todayString;

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
        debugPrint('Error preserving existing data: $e');
        // Use defaults if error occurs
        baseData['date_of_birth'] = todayString;
      }
    } else {
      // New Kid - use today's date
      baseData['date_of_birth'] = todayString;
    }

    // Add other nullable fields with defaults
    baseData['weight'] = baseData['weight'];
    baseData['breed'] = baseData['breed'];
    baseData['group_name'] = baseData['group_name'];

    // Add ID for updates - ensure it's properly typed
    if (widget.isEditMode && _existingKidId != null) {
      baseData['id'] = _existingKidId; // This should be an int
      debugPrint('Adding Kid ID to update data: $_existingKidId (${_existingKidId.runtimeType})');
    }

        debugPrint('Prepared Kid data: ${baseData.keys.join(', ')}');
    return baseData;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate father tag for new registrations
    if (!widget.isEditMode && widget.fatherTag.isEmpty) {
      _showError('Please select a Buck (father) first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final kidData = _prepareKidData();
      debugPrint('Kid data prepared for ${widget.isEditMode ? 'update' : 'registration'}: $kidData');

      // Prepare result data with safe type conversion - DO NOT register yet
      Map<String, dynamic> resultData = {
        'tag_no': _tagController.text.trim(),
        'sex': _selectedSex,
        'registered': false, // Mark as not registered yet - will be done when event is saved
        'isEditMode': widget.isEditMode,
        'fullKidData': kidData,
        'pendingOperation': widget.isEditMode ? 'update' : 'create', // Track what operation is pending
      };

      // Include the Kid ID if we have it
      if (_existingKidId != null) {
        resultData['kidId'] = _existingKidId;
      }

      Navigator.of(context).pop(resultData);

      // Show appropriate message
      if (mounted) {
        _showSuccess('Kid information saved. Will be ${widget.isEditMode ? 'updated' : 'registered'} when event is saved.');
      }

    } catch (e) {
      debugPrint('Error preparing Kid data: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      _showError('Error preparing Kid data: $e');
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
              color: Colors.black.withValues(alpha: 0.1),
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
                      color: Colors.white.withValues(alpha: 0.2),
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
                          widget.isEditMode ? 'Edit Kid Information' : 'Register New Kid',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.isEditMode ? 'Update Kid details' : 'Prepare Kid for registration',
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
                          color: AppColors.lightGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.lightGreen.withValues(alpha: 0.3),
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

                      // Kid Tag Number
                      TextFormField(
                        controller: _tagController,
                        validator: _validateTagNumber,
                        decoration: InputDecoration(
                          labelText: 'Kid Tag Number *',
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
                          helperText: 'Enter 6-digit tag number',
                          helperStyle: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Gender Selection
                      DropdownButtonFormField<String>(
                        value: _selectedSex,
                        decoration: InputDecoration(
                          labelText: 'Sex *',
                          prefixIcon: Icon(
                            _selectedSex == 'Male' ? Icons.male : Icons.female,
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
                        items: _sexOptions.map((sex) {
                          return DropdownMenuItem<String>(
                            value: sex,
                            child: Text(sex),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedSex = value);
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
                                    ? 'Kid will be updated in the database when the event is saved.'
                                    : 'Kid will be registered in the database when the event is saved.',
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
                        widget.isEditMode ? 'Save Changes' : 'Prepare Kid',
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
    super.dispose();
  }
}
