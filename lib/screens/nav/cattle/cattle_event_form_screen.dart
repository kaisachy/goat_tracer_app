// lib/screens/nav/cattle/cattle_event_form_screen.dart

import 'package:cattle_tracer_app/screens/nav/cattle/widgets/events/event_specific_fields.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/widgets/events/event_type_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/cattle.dart';
import '../../../services/cattle/cattle_event_service.dart';
import '../../../services/cattle/cattle_service.dart';
import '../../../constants/app_colors.dart';
import 'modals/calf_registration_dialog.dart';
import 'widgets/events/event_cattle_info_card.dart';
import 'widgets/events/event_notes_section.dart';
import 'modals/event_success_dialog.dart';
import 'modals/event_delete_confirmation_dialog.dart';

class CattleEventFormScreen extends StatefulWidget {
  final CattleEvent? event;
  final String? cattleTag;

  const CattleEventFormScreen({
    super.key,
    this.event,
    this.cattleTag,
  });

  @override
  State<CattleEventFormScreen> createState() => _CattleEventFormScreenState();
}

class _CattleEventFormScreenState extends State<CattleEventFormScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final GlobalKey<EventSpecificFieldsState> _eventSpecificFieldsKey =
  GlobalKey<EventSpecificFieldsState>();
  late bool isEditing;
  bool _isLoading = false;

  // Cattle details
  Cattle? _cattleDetails;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String selectedEventType = 'Select type of event';

  // New state for temporary calf data
  Map<String, dynamic>? _temporaryCalfData;

  @override
  void initState() {
    super.initState();
    isEditing = widget.event != null;
    _initializeAnimations();
    _initializeControllers();
    _loadCattleDetails();

    // Load existing calf data if editing birth event
    if (isEditing && widget.event != null && widget.event!.eventType == 'Gives Birth') {
      _loadExistingCalfData();
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
  }

  void _initializeControllers() {
    final fields = [
      'bull_tag', 'calf_tag', 'event_date', 'sickness_symptoms',
      'diagnosis', 'technician', 'medicine_given', 'semen_used',
      'estimated_return_date', 'weighed_result', 'breeding_date',
      'expected_delivery_date', 'notes'
    ];

    for (var field in fields) {
      _controllers[field] = TextEditingController(
        text: isEditing ? widget.event!.toJson()[field]?.toString() ?? '' : '',
      );
    }
  }

  // Load existing calf data for editing
  Future<void> _loadExistingCalfData() async {
    if (widget.event == null || widget.event!.calfTag == null) return;

    try {
      final calf = await CattleService.getCattleByTag(widget.event!.calfTag!);
      if (calf != null && mounted) {
        setState(() {
          _temporaryCalfData = {
            'tag_no': calf.tagNo,
            'name': calf.name,
            'gender': calf.gender,
            'registered': true, // Mark as already registered since it exists
            'isEditMode': true,
            'calfId': calf.id,
            'pendingOperation': 'update',
            'fullCalfData': {
              'id': calf.id,
              'tag_no': calf.tagNo,
              'name': calf.name,
              'gender': calf.gender,
              'date_of_birth': calf.dateOfBirth,
              'classification': calf.classification,
              'status': calf.status,
              'breed': calf.breed,
              'source': calf.source,
              'mother_tag': calf.motherTag,
              'father_tag': calf.fatherTag,
              'weight': calf.weight,
              'group_name': calf.groupName,
              'joined_date': calf.joinedDate,
              'notes': calf.notes,
            },
          };
          _controllers['calf_tag']?.text = calf.tagNo;
        });
        print('Loaded existing calf data: ${calf.tagNo} with ID: ${calf.id}');
      }
    } catch (e) {
      print('Error loading calf data: $e');
      // If we can't load the calf, clear the temporary data
      if (mounted) {
        setState(() {
          _temporaryCalfData = null;
          _controllers['calf_tag']?.text = '';
        });
      }
    }
  }

  void _handleEventDateSelected(DateTime selectedDate) {
    if (selectedEventType.toLowerCase() == 'breeding') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _eventSpecificFieldsKey.currentState
            ?.calculateAndDisplayReturnToHeatDate(selectedDate);
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCattleDetails() async {
    if (widget.cattleTag == null || widget.cattleTag!.isEmpty) {
      _showErrorMessage('Invalid cattle tag provided');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cattle = await CattleService.getCattleByTag(widget.cattleTag!);

      // Animations are played only after the initial data is fetched.
      _fadeController.forward();
      _slideController.forward();

      if (cattle != null && mounted) {
        setState(() {
          _cattleDetails = cattle;
        });

        if (isEditing && widget.event != null) {
          await _setEditEventType(cattle);
        }
      } else {
        if (mounted) {
          _showErrorMessage(
              'Cattle with tag "${widget.cattleTag}" not found in the database');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error loading cattle details: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setEditEventType(Cattle cattle) async {
    final editEventType = widget.event!.eventType;
    await Future.delayed(Duration.zero);

    final eventTypes = _getEventTypesForGender(cattle.gender);

    if (eventTypes.contains(editEventType)) {
      setState(() {
        selectedEventType = editEventType;
      });
    } else {
      setState(() {
        selectedEventType = 'Select type of event';
      });

      if (mounted) {
        _showWarningMessage(
            'Event type "$editEventType" is not valid for ${cattle.gender.toLowerCase()} cattle. Please select a valid event type.');
      }
    }
  }

  List<String> _getEventTypesForGender(String gender) {
    final baseTypes = ['Select type of event'];

    if (gender.toLowerCase() == 'female') {
      return [
        ...baseTypes, 'Dry off', 'Treated', 'Breeding', 'Weighed',
        'Gives Birth', 'Vaccinated', 'Pregnant', 'Aborted Pregnancy',
        'Deworming', 'Hoof Trimming', 'Other',
      ];
    } else if (gender.toLowerCase() == 'male') {
      return [
        ...baseTypes, 'Treated', 'Weighed', 'Vaccinated', 'Deworming',
        'Hoof Trimming', 'Castrated', 'Weaned', 'Other'
      ];
    } else {
      return [
        ...baseTypes, 'Treated', 'Weighed', 'Vaccinated', 'Deworming',
        'Hoof Trimming', 'Other'
      ];
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          overflow: TextOverflow.visible, softWrap: true),
      backgroundColor: Colors.red[600],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      duration: const Duration(seconds: 5),
    ));
  }

  void _showWarningMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          overflow: TextOverflow.visible, softWrap: true),
      backgroundColor: Colors.orange[600],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      duration: const Duration(seconds: 4),
    ));
  }


  // Execute calf operations only after successful event save
  Future<bool> _executeCalfOperations() async {
    if (_temporaryCalfData == null || _temporaryCalfData!['fullCalfData'] == null) {
      print('No calf operations to execute');
      return true; // No operations needed
    }

    try {
      final pendingOperation = _temporaryCalfData!['pendingOperation'];
      final calfData = _temporaryCalfData!['fullCalfData'] as Map<String, dynamic>;
      final calfTag = _safeParseString(calfData['tag_no']) ?? '';

      print('Executing calf $pendingOperation for: $calfTag');

      bool success;
      if (pendingOperation == 'update') {
        // Ensure we have the ID for update
        int? calfId = _safeParseInt(calfData['id']) ?? _safeParseInt(_temporaryCalfData!['calfId']);

        if (calfId == null) {
          print('No calf ID found for update, trying to find by tag');
          final existingCalf = await CattleService.getCattleByTag(calfTag);
          if (existingCalf != null) {
            calfId = existingCalf.id;
            calfData['id'] = calfId;
          } else {
            throw Exception('Could not find existing calf with tag: $calfTag');
          }
        }

        success = await CattleService.updateCattleInformation(calfData);
        print('Calf update result: $success for ID: $calfId');
      } else {
        // Create new calf - remove ID if present
        final newCalfData = Map<String, dynamic>.from(calfData);
        newCalfData.remove('id');

        success = await CattleService.storeCattleInformation(newCalfData);
        print('Calf registration result: $success');
      }

      if (success) {
        // Update temporary data to reflect successful operation
        setState(() {
          _temporaryCalfData!['registered'] = true;
        });
      }

      return success;
    } catch (e) {
      print('Error executing calf operations: $e');
      return false;
    }
  }

  Future<bool> _updateMotherStatus() async {
    try {
      if (_cattleDetails != null) {
        final updateData = Map<String, dynamic>.from(_cattleDetails!.toJson());
        updateData['status'] = 'Lactating';
        return await CattleService.updateCattleInformation(updateData);
      }
      return false;
    } catch (e) {
      print('Error updating mother status: $e');
      return false;
    }
  }

  Future<void> _handleGivesBirthEvent() async {
    try {
      bool calfHandled = false;
      bool motherStatusUpdated = false;
      String calfStatus = '';

      // Execute calf operations
      calfHandled = await _executeCalfOperations();

      if (_temporaryCalfData != null) {
        final calfTag = _temporaryCalfData!['tag_no'] ?? 'unknown';
        final isEditMode = _temporaryCalfData!['isEditMode'] == true;
        calfStatus = calfHandled
            ? (isEditMode ? 'Calf $calfTag updated successfully' : 'Calf $calfTag registered successfully')
            : (isEditMode ? 'Failed to update calf $calfTag' : 'Failed to register calf $calfTag');
      } else {
        calfStatus = 'No calf data to process';
        calfHandled = true; // No calf to handle
      }

      // Update mother status
      motherStatusUpdated = await _updateMotherStatus();
      final motherStatus = motherStatusUpdated
          ? 'Mother status updated to Lactating'
          : 'Failed to update mother status';

      // Log the results for debugging
      print('Birth event results - Calf: $calfStatus, Mother: $motherStatus');

    } catch (e) {
      // Log any errors that occur during the process
      print('Error in _handleGivesBirthEvent: $e');
    }
  }

  Future<void> _openCalfRegistrationDialog() async {
    final motherTag = widget.cattleTag ?? '';
    final fatherTag = _controllers['bull_tag']?.text ?? '';

    // Prepare existing calf data for the dialog with safe type conversion
    Map<String, dynamic>? existingCalfData;
    if (_temporaryCalfData != null) {
      try {
        existingCalfData = <String, dynamic>{};

        // Copy basic fields with safe conversion
        existingCalfData['tag_no'] = _safeParseString(_temporaryCalfData!['tag_no']);
        existingCalfData['name'] = _safeParseString(_temporaryCalfData!['name']);
        existingCalfData['gender'] = _safeParseString(_temporaryCalfData!['gender']);
        existingCalfData['registered'] = _temporaryCalfData!['registered'] ?? false;
        existingCalfData['isEditMode'] = _temporaryCalfData!['isEditMode'] ?? false;

        // Safely get the calf ID
        int? calfId = _safeParseInt(_temporaryCalfData!['calfId']);
        if (calfId != null) {
          existingCalfData['calfId'] = calfId;
        }

        // Copy fullCalfData if it exists
        if (_temporaryCalfData!['fullCalfData'] != null) {
          final originalFullData = _temporaryCalfData!['fullCalfData'] as Map<String, dynamic>;
          existingCalfData['fullCalfData'] = <String, dynamic>{};

          // Copy each field with safe type conversion
          final fullData = existingCalfData['fullCalfData'] as Map<String, dynamic>;
          fullData['tag_no'] = _safeParseString(originalFullData['tag_no']);
          fullData['name'] = _safeParseString(originalFullData['name']);
          fullData['gender'] = _safeParseString(originalFullData['gender']);
          fullData['date_of_birth'] = _safeParseString(originalFullData['date_of_birth']);
          fullData['classification'] = _safeParseString(originalFullData['classification']);
          fullData['status'] = _safeParseString(originalFullData['status']);
          fullData['breed'] = _safeParseString(originalFullData['breed']);
          fullData['source'] = _safeParseString(originalFullData['source']);
          fullData['mother_tag'] = _safeParseString(originalFullData['mother_tag']);
          fullData['father_tag'] = _safeParseString(originalFullData['father_tag']);
          fullData['weight'] = _safeParseDouble(originalFullData['weight']);
          fullData['group_name'] = _safeParseString(originalFullData['group_name']);
          fullData['joined_date'] = _safeParseString(originalFullData['joined_date']);
          fullData['notes'] = _safeParseString(originalFullData['notes']);

          // Include ID if available
          if (calfId != null) {
            fullData['id'] = calfId;
          } else if (originalFullData['id'] != null) {
            final id = _safeParseInt(originalFullData['id']);
            if (id != null) {
              fullData['id'] = id;
            }
          }
        }

        print('Prepared calf data for dialog: calfId=$calfId, isEditMode=${existingCalfData['isEditMode']}');
      } catch (e) {
        print('Error preparing calf data for dialog: $e');
        existingCalfData = null;
      }
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CalfRegistrationDialog(
        motherTag: motherTag,
        fatherTag: fatherTag,
        existingCalfData: existingCalfData,
        isEditMode: _temporaryCalfData != null,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _temporaryCalfData = result;
        // Update the calf_tag controller
        _controllers['calf_tag']?.text = _safeParseString(result['tag_no']) ?? '';
      });
      print('Calf dialog result: ${result['pendingOperation']} operation prepared for ${result['tag_no']}');
    }
  }

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

  double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedEventType == 'Select type of event') {
      _showErrorMessage('Please select an event type.');
      return;
    }
    if (_cattleDetails == null) {
      _showErrorMessage('Cattle information not loaded. Please try again.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final data = {
        'cattle_tag': widget.cattleTag,
        'bull_tag': _controllers['bull_tag']!.text.isEmpty
            ? null
            : _controllers['bull_tag']!.text,
        'calf_tag': _controllers['calf_tag']!.text.isEmpty
            ? null
            : _controllers['calf_tag']!.text,
        'event_type': selectedEventType,
        'event_date': _controllers['event_date']!.text,
        'sickness_symptoms': _controllers['sickness_symptoms']!.text,
        'diagnosis': _controllers['diagnosis']!.text,
        'technician': _controllers['technician']!.text,
        'medicine_given': _controllers['medicine_given']!.text,
        'semen_used': _controllers['semen_used']!.text,
        'estimated_return_date': _controllers['estimated_return_date']!.text,
        'weighed_result': _controllers['weighed_result']!.text.isEmpty
            ? null
            : double.tryParse(_controllers['weighed_result']!.text),
        'breeding_date': _controllers['breeding_date']!.text,
        'expected_delivery_date':
        _controllers['expected_delivery_date']!.text,
        'notes': _controllers['notes']!.text,
      };

      // First, try to save the event
      bool eventSuccess;
      if (isEditing) {
        data['id'] = widget.event!.id;
        eventSuccess = await CattleEventService.updateCattleEvent(data);
      } else {
        eventSuccess = await CattleEventService.storeCattleEvent(data);
      }

      if (eventSuccess) {
        // Event saved successfully, now handle specific event types
        if (selectedEventType.toLowerCase() == 'gives birth') {
          await _handleGivesBirthEvent();
        } else if (selectedEventType.toLowerCase() == 'breeding') {
          await _handleBreedingEvent();
        }else if (selectedEventType.toLowerCase() == 'pregnant') {
          await _handlePregnantEvent();
        }

        if (context.mounted) {
          SuccessDialog.show(
            context: context,
            isEditing: isEditing,
            onContinue: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
          );
        }
      } else {
        _showErrorMessage('Failed to save cattle event. Please try again.');
      }
    } catch (e) {
      _showErrorMessage('Error saving event: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _shouldShowReturnToHeatField() {
    return _cattleDetails?.gender.toLowerCase() == 'female' &&
        selectedEventType.toLowerCase() == 'breeding';
  }

  Future<void> _handleBreedingEvent() async {
    try {
      bool cowStatusUpdated = false;
      bool bullStatusUpdated = false;
      bool bullEventCreated = false;
      String cowStatus = '';
      String bullStatus = '';
      String bullEventStatus = '';

      // Update cow (mother) status to Breeding
      if (_cattleDetails != null) {
        final cowUpdateData = Map<String, dynamic>.from(_cattleDetails!.toJson());
        cowUpdateData['status'] = 'Breeding';
        cowStatusUpdated = await CattleService.updateCattleInformation(cowUpdateData);
        cowStatus = cowStatusUpdated
            ? 'Cow ${_cattleDetails!.tagNo} status updated to Breeding'
            : 'Failed to update cow ${_cattleDetails!.tagNo} status';
      }

      // Get bull information and create corresponding event
      final bullTag = _controllers['bull_tag']?.text ?? '';
      if (bullTag.isNotEmpty) {
        try {
          final bull = await CattleService.getCattleByTag(bullTag);
          if (bull != null) {
            // Update bull status to Breeding
            final bullUpdateData = Map<String, dynamic>.from(bull.toJson());
            bullUpdateData['status'] = 'Breeding';
            bullStatusUpdated = await CattleService.updateCattleInformation(bullUpdateData);
            bullStatus = bullStatusUpdated
                ? 'Bull $bullTag status updated to Breeding'
                : 'Failed to update bull $bullTag status';

            // Create breeding event for the bull
            final bullEventData = {
              'cattle_tag': bullTag,
              'bull_tag': null, // Bull doesn't need its own bull_tag
              'calf_tag': null, // No calf tag for bull's breeding event
              'event_type': 'Breeding',
              'event_date': _controllers['event_date']!.text,
              'sickness_symptoms': '',
              'diagnosis': '',
              'technician': _controllers['technician']!.text,
              'medicine_given': '',
              'weighed_result': null,
              'breeding_date': _controllers['event_date']!.text, // Same as event_date for consistency
              'notes': 'Breeding with cow ${_cattleDetails?.tagNo ?? 'Unknown'}${_controllers['notes']!.text.isNotEmpty ? '. Additional notes: ${_controllers['notes']!.text}' : ''}',
            };

            bullEventCreated = await CattleEventService.storeCattleEvent(bullEventData);
            bullEventStatus = bullEventCreated
                ? 'Breeding event created for bull $bullTag'
                : 'Failed to create breeding event for bull $bullTag';
          } else {
            bullStatus = 'Bull $bullTag not found in database';
            bullEventStatus = 'Cannot create event for non-existent bull';
          }
        } catch (e) {
          bullStatus = 'Error updating bull $bullTag status: $e';
          bullEventStatus = 'Error creating bull breeding event: $e';
        }
      } else {
        bullStatus = 'No bull tag found for breeding event';
        bullEventStatus = 'No bull tag available for event creation';
      }

      // Log the results for debugging
      print('Breeding event results:');
      print('- Cow: $cowStatus');
      print('- Bull Status: $bullStatus');
      print('- Bull Event: $bullEventStatus');

      // Optional: Show a snackbar with summary if needed
      if (mounted && (cowStatusUpdated || bullStatusUpdated || bullEventCreated)) {
        if (bullEventCreated) {
        }

        // You can uncomment this if you want to show success feedback
        /*
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          duration: const Duration(seconds: 3),
        ),
      );
      */
      }

    } catch (e) {
      // Log any errors that occur during the process
      print('Error in _handleBreedingEvent: $e');

      // Optional: Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Some breeding event operations may have failed'),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }


  Future<void> _handlePregnantEvent() async {
    try {
      bool cowStatusUpdated = false;
      String cowStatus = '';

      // Update cow (mother) status to Pregnant
      if (_cattleDetails != null) {
        final cowUpdateData = Map<String, dynamic>.from(_cattleDetails!.toJson());
        cowUpdateData['status'] = 'Pregnant';
        cowStatusUpdated = await CattleService.updateCattleInformation(cowUpdateData);
        cowStatus = cowStatusUpdated
            ? 'Cow ${_cattleDetails!.tagNo} status updated to Pregnant'
            : 'Failed to update cow ${_cattleDetails!.tagNo} status to Pregnant';
      }

      // Log the result for debugging
      print('Pregnant event result: $cowStatus');

      // Optional: Show success feedback to user
      if (mounted && cowStatusUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cattle status updated to Pregnant'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      // Log any errors that occur during the process
      print('Error in _handlePregnantEvent: $e');

      // Optional: Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Failed to update cattle status to Pregnant'),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await DeleteConfirmationDialog.show(context);
    if (confirmed == true) {
      setState(() => _isLoading = true);
      final success =
      await CattleEventService.deleteCattleEvent(widget.event!.id);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Cattle Event' : 'Add Cattle Event',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
        actions: isEditing
            ? [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _deleteEvent,
            tooltip: 'Delete Event',
          )
        ]
            : null,
      ),
      body: SafeArea(
        child: _isLoading && _cattleDetails == null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: AppColors.vibrantGreen,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading cattle information...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        )
            : FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40,
                    ),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cattle Info Card
                            EventCattleInfoEventCard(
                              cattleDetails: _cattleDetails,
                              cattleTag: widget.cattleTag,
                            ),
                            const SizedBox(height: 30),

                            // Event Type Section
                            EventTypeDropdown(
                              cattleDetails: _cattleDetails,
                              selectedEventType: selectedEventType,
                              controllers: _controllers,
                              onEventTypeChanged: (value) {
                                if (value != null) {
                                  setState(() => selectedEventType = value);
                                }
                              },
                              onEventDateSelected: _handleEventDateSelected,
                            ),
                            const SizedBox(height: 30),

                            // Event-specific fields
                            EventSpecificFields(
                              key: _eventSpecificFieldsKey,
                              selectedEventType: selectedEventType,
                              controllers: _controllers,
                              cattleTag: widget.cattleTag,
                              temporaryCalfData: _temporaryCalfData,
                              onEditCalfPressed: _openCalfRegistrationDialog,
                              showReturnToHeat: _shouldShowReturnToHeatField(),
                            ),

                            // Notes Section
                            EventNotesSection(
                              controller: _controllers['notes']!,
                            ),
                            const SizedBox(height: 40),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading || _cattleDetails == null
                                    ? null
                                    : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.vibrantGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  shadowColor:
                                  AppColors.vibrantGreen.withOpacity(0.3),
                                ),
                                icon: _isLoading
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : Icon(
                                  isEditing
                                      ? FontAwesomeIcons.penToSquare
                                      : FontAwesomeIcons.plus,
                                  size: 18,
                                ),
                                label: Text(
                                  _isLoading
                                      ? 'Saving...'
                                      : (isEditing ? 'Update Event' : 'Create Event'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}