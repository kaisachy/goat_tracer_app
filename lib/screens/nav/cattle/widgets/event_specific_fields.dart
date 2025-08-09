// lib/screens/nav/cattle/widgets/event_specific_fields.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../constants/app_colors.dart';
import '../../../../utils/event_type_utils.dart';
import '../../../../models/cattle.dart';
import '../../../../models/user.dart';
import '../../../../services/cattle/cattle_service.dart';
import '../../../../services/user_service.dart';
import 'event_styled_text_field.dart';
import '../modals/calf_registration_dialog.dart';

class EventSpecificFields extends StatefulWidget {
  final String selectedEventType;
  final Map<String, TextEditingController> controllers;
  final String? cattleTag;
  final Map<String, dynamic>? temporaryCalfData;
  final VoidCallback? onEditCalfPressed;

  const EventSpecificFields({
    super.key,
    required this.selectedEventType,
    required this.controllers,
    this.cattleTag,
    this.temporaryCalfData,
    this.onEditCalfPressed,
  });

  @override
  EventSpecificFieldsState createState() => EventSpecificFieldsState();
}

class EventSpecificFieldsState extends State<EventSpecificFields> {
  List<Cattle> _bulls = [];
  List<User> _technicians = [];
  bool _loadingBulls = false;
  bool _loadingTechnicians = false;
  Map<String, dynamic>? _newCalfData;
  static const int cattleGestationPeriodDays = 283;
  static const int returnToHeatDays = 21;

  @override
  void initState() {
    super.initState();

    // Initialize calf data from parent if available
    if (widget.temporaryCalfData != null) {
      _newCalfData = widget.temporaryCalfData;
    }

    if (widget.selectedEventType.toLowerCase() == 'gives birth' ||
        widget.selectedEventType.toLowerCase() == 'pregnant' ||
        widget.selectedEventType.toLowerCase() == 'breeding') {
      _fetchBulls();
    }

    if (_needsTechnicianField(widget.selectedEventType)) {
      _fetchTechnicians();
    }

    _setupEventDateListeners();
  }

  @override
  void didUpdateWidget(EventSpecificFields oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update calf data when parent updates it
    if (widget.temporaryCalfData != oldWidget.temporaryCalfData) {
      setState(() {
        _newCalfData = widget.temporaryCalfData;
      });
    }

    if ((widget.selectedEventType.toLowerCase() == 'gives birth' ||
        widget.selectedEventType.toLowerCase() == 'pregnant' ||
        widget.selectedEventType.toLowerCase() == 'breeding') &&
        (oldWidget.selectedEventType.toLowerCase() != 'gives birth' &&
            oldWidget.selectedEventType.toLowerCase() != 'pregnant' &&
            oldWidget.selectedEventType.toLowerCase() != 'breeding')) {
      _fetchBulls();
    }

    if (_needsTechnicianField(widget.selectedEventType) &&
        !_needsTechnicianField(oldWidget.selectedEventType)) {
      _fetchTechnicians();
    }

    if (oldWidget.controllers != widget.controllers) {
      if (oldWidget.controllers['breeding_date'] != null) {
        oldWidget.controllers['breeding_date']!.removeListener(_onBreedingDateChanged);
      }
      if (oldWidget.controllers['event_date'] != null) {
        oldWidget.controllers['event_date']!.removeListener(_onEventDateChanged);
      }
      _setupEventDateListeners();
    }
  }

  bool _needsTechnicianField(String eventType) {
    final techniciansEventTypes = [
      'treated',
      'breeding',
      'vaccinated',
      'castrated',
      'other'
    ];
    return techniciansEventTypes.contains(eventType.toLowerCase());
  }

  void _setupEventDateListeners() {
    // Add listener for breeding date changes in 'pregnant' event type
    if (widget.selectedEventType.toLowerCase() == 'pregnant' &&
        widget.controllers['breeding_date'] != null) {
      widget.controllers['breeding_date']!.removeListener(_onBreedingDateChanged);
      widget.controllers['breeding_date']!.addListener(_onBreedingDateChanged);
    }

    // Add listener for event date changes in 'breeding' event type
    if (widget.selectedEventType.toLowerCase() == 'breeding' &&
        widget.controllers['event_date'] != null) {
      widget.controllers['event_date']!.removeListener(_onEventDateChanged);
      widget.controllers['event_date']!.addListener(_onEventDateChanged);
    }
  }

  void _onBreedingDateChanged() {
    final breedingDateText = widget.controllers['breeding_date']?.text ?? '';

    if (breedingDateText.isNotEmpty) {
      try {
        final breedingDate = DateTime.parse(breedingDateText);
        _calculateAndDisplayDeliveryDate(breedingDate);
      } catch (e) {
        if (widget.controllers['expected_delivery_date'] != null) {
          widget.controllers['expected_delivery_date']!.clear();
          if (mounted) {
            setState(() {});
          }
        }
      }
    } else {
      if (widget.controllers['expected_delivery_date'] != null) {
        widget.controllers['expected_delivery_date']!.clear();
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  void _onEventDateChanged() {
    if (widget.selectedEventType.toLowerCase() != 'breeding') return;

    final eventDateText = widget.controllers['event_date']?.text ?? '';

    if (eventDateText.isNotEmpty) {
      try {
        DateTime eventDate = DateTime.parse(eventDateText);
        calculateAndDisplayReturnToHeatDate(eventDate);
      } catch (e) {
        if (widget.controllers['estimated_return_date'] != null) {
          widget.controllers['estimated_return_date']!.clear();
          if (mounted) {
            setState(() {});
          }
        }
      }
    } else {
      if (widget.controllers['estimated_return_date'] != null) {
        widget.controllers['estimated_return_date']!.clear();
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  @override
  void dispose() {
    // Remove listeners to prevent memory leaks
    if (widget.controllers['breeding_date'] != null) {
      widget.controllers['breeding_date']!.removeListener(_onBreedingDateChanged);
    }
    if (widget.controllers['event_date'] != null) {
      widget.controllers['event_date']!.removeListener(_onEventDateChanged);
    }
    super.dispose();
  }

  Future<void> _fetchBulls() async {
    setState(() => _loadingBulls = true);
    try {
      final allCattle = await CattleService.getAllCattle();
      final bulls = allCattle.where((cattle) =>
      cattle.classification.toLowerCase() == 'bull' &&
          cattle.status.toLowerCase() == 'active'
      ).toList();

      setState(() {
        _bulls = bulls;
        _loadingBulls = false;
      });
    } catch (e) {
      setState(() => _loadingBulls = false);
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

  Future<void> _fetchTechnicians() async {
    setState(() => _loadingTechnicians = true);
    try {
      final technicians = await UserService().getTechnicians();

      setState(() {
        _technicians = technicians;
        _loadingTechnicians = false;
      });
    } catch (e) {
      setState(() => _loadingTechnicians = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load technicians: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _showCalfRegistrationDialog() async {
    // Use the callback from parent if provided (for edit mode)
    if (widget.onEditCalfPressed != null) {
      widget.onEditCalfPressed!();
      return; // Parent will handle opening the dialog
    }

    // Fallback - open dialog directly if no callback provided
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CalfRegistrationDialog(
        motherTag: widget.cattleTag ?? '',
        fatherTag: widget.controllers['bull_tag']?.text ?? '',
        existingCalfData: _newCalfData?['fullCalfData'] ?? _newCalfData,
        isEditMode: _newCalfData != null,
      ),
    );

    if (result != null) {
      setState(() {
        _newCalfData = result;
        widget.controllers['calf_tag']?.text = result['tag_no'] ?? '';
      });
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
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

      // If this is the breeding date controller, trigger calculation immediately
      if (widget.controllers['breeding_date'] == controller &&
          widget.selectedEventType.toLowerCase() == 'pregnant') {
        _calculateAndDisplayDeliveryDate(picked);
      }

      // If this is the event date controller for breeding, trigger return to heat calculation
      if (widget.controllers['event_date'] == controller &&
          widget.selectedEventType.toLowerCase() == 'breeding') {
        calculateAndDisplayReturnToHeatDate(picked);
      }
    }
  }

  void _calculateAndDisplayDeliveryDate(DateTime breedingDate) {
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

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
    bool showCalendarIcon = true,
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
            onPressed: () => _selectDate(context, controller),
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
        onTap: readOnly ? null : () => _selectDate(context, controller),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a date';
          }
          return null;
        },
      ),
    );
  }

  Widget buildAnyDateField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    bool showCalendarIcon = true,
  }) {
    return _buildDateField(
      label: label,
      controller: controller,
      icon: icon,
      readOnly: readOnly,
      showCalendarIcon: showCalendarIcon,
    );
  }

  Widget buildEventDateField({
    required TextEditingController controller,
    String label = 'Event Date',
    String hint = 'Select event date',
  }) {
    return _buildDateField(
      label: label,
      controller: controller,
      icon: FontAwesomeIcons.calendarDays,
      showCalendarIcon: true,
    );
  }

  Widget buildDatePickerField({
    required String label,
    required TextEditingController controller,
    String? hint,
    IconData? icon,
    bool readOnly = false,
  }) {
    return _buildDateField(
      label: label,
      controller: controller,
      icon: icon ?? FontAwesomeIcons.calendar,
      readOnly: readOnly,
      showCalendarIcon: !readOnly,
    );
  }

  Widget _buildBullDropdown() {
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
          suffixIcon: _loadingBulls
              ? Container(
            width: 20,
            height: 20,
            padding: const EdgeInsets.all(12),
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
              : null,
        ),
        hint: Text(_loadingBulls ? 'Loading bulls...' : 'Select bull'),
        isExpanded: true,
        items: _bulls.map((bull) {
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
        onChanged: _loadingBulls ? null : (value) {
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

  Widget _buildTechnicianDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      child: DropdownButtonFormField<String>(
        value: widget.controllers['technician']?.text.isEmpty == true
            ? null
            : widget.controllers['technician']?.text,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          suffixIcon: _loadingTechnicians
              ? Container(
            width: 20,
            height: 20,
            padding: const EdgeInsets.all(12),
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
              : null,
        ),
        hint: Text(_loadingTechnicians ? 'Loading technicians...' : 'Select technician'),
        isExpanded: true,
        items: _technicians.map((technician) {
          final displayName = '${technician.firstName} ${technician.lastName}';

          return DropdownMenuItem<String>(
            value: displayName,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              constraints: BoxConstraints(
                minHeight: 48,
                maxWidth: MediaQuery.of(context).size.width - 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      technician.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        onChanged: _loadingTechnicians ? null : (value) {
          widget.controllers['technician']?.text = value ?? '';
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a technician';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSemenDropdown() {
    List<String> allSemenOptions = [];

    for (var bull in _bulls) {
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
          suffixIcon: _loadingBulls
              ? Container(
            width: 20,
            height: 20,
            padding: const EdgeInsets.all(12),
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
              : null,
        ),
        hint: Text(_loadingBulls ? 'Loading options...' : 'Select semen used'),
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
        onChanged: _loadingBulls ? null : (value) {
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

  Widget _buildCalfRegistrationField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.lightGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.baby, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Calf Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: _showCalfRegistrationDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    _newCalfData == null ? 'Add Calf' : 'Edit Calf',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ),
            ],
          ),
          if (_newCalfData != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.lightGreen.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.label, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tag: ${_newCalfData!['tag_no'] ?? 'Not set'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_newCalfData!['name'] != null && _newCalfData!['name'].toString().isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(FontAwesomeIcons.signature, color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Name: ${_newCalfData!['name']}',
                            style: const TextStyle(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      Icon(
                        _newCalfData!['gender'] == 'Male' ? Icons.male : Icons.female,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Gender: ${_newCalfData!['gender'] ?? 'Not set'}',
                          style: const TextStyle(color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildEventSpecificFields() {
    List<Widget> fields = [];

    switch (widget.selectedEventType.toLowerCase()) {
      case 'dry off':
        break;

      case 'treated':
        fields.addAll([
          EventStyledTextField(
            label: 'Sickness Symptoms',
            controller: widget.controllers['sickness_symptoms']!,
            maxLines: 3,
            hint: 'Describe the symptoms...',
            icon: FontAwesomeIcons.thermometer,
          ),
          EventStyledTextField(
            label: 'Diagnosis',
            controller: widget.controllers['diagnosis']!,
            maxLines: 2,
            hint: 'Medical diagnosis...',
            icon: FontAwesomeIcons.stethoscope,
          ),
          _buildTechnicianDropdown(),
          EventStyledTextField(
            label: 'Medicine Given',
            controller: widget.controllers['medicine_given']!,
            hint: 'Name and dosage of medicine',
            icon: FontAwesomeIcons.pills,
          ),
        ]);
        break;

      case 'breeding':
        fields.addAll([
          _buildSemenDropdown(),
          _buildTechnicianDropdown(),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateField(
                  label: 'Estimated Return to Heat Date',
                  controller: widget.controllers['estimated_return_date']!,
                  icon: FontAwesomeIcons.calendar,
                  readOnly: true,
                  showCalendarIcon: false,
                ),
              ],
            ),
          ),
        ]);
        break;

      case 'weighed':
        fields.add(
          EventStyledTextField(
            label: 'Weight Result (kg)',
            controller: widget.controllers['weighed_result']!,
            isNumber: true,
            hint: 'Enter weight in kg',
            icon: FontAwesomeIcons.weightScale,
          ),
        );
        break;

      case 'gives birth':
        fields.addAll([
          _buildBullDropdown(),
          _buildCalfRegistrationField(),
        ]);
        break;

      case 'vaccinated':
        fields.add(
          EventStyledTextField(
            label: 'Vaccine Given',
            controller: widget.controllers['medicine_given']!,
            hint: 'Name of vaccine',
            icon: FontAwesomeIcons.syringe,
          ),
        );
        break;

      case 'pregnant':
        fields.addAll([
          _buildDateField(
            label: 'Breeding Date',
            controller: widget.controllers['breeding_date']!,
            icon: FontAwesomeIcons.calendar,
            showCalendarIcon: true,
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateField(
                  label: 'Expected Delivery Date',
                  controller: widget.controllers['expected_delivery_date']!,
                  icon: FontAwesomeIcons.calendarDays,
                  readOnly: true,
                  showCalendarIcon: false,
                ),
              ],
            ),
          ),
          _buildBullDropdown(),
        ]);
        break;

      case 'aborted pregnancy':
        break;

      case 'deworming':
        fields.add(
          EventStyledTextField(
            label: 'Deworming Medicine',
            controller: widget.controllers['medicine_given']!,
            hint: 'Name and dosage',
            icon: FontAwesomeIcons.pills,
          ),
        );
        break;

      case 'hoof trimming':
        break;

      case 'castrated':
        fields.add(
          _buildTechnicianDropdown(),
        );
        break;

      case 'weaned':
        break;

      case 'other':
      default:
        fields.addAll([
          EventStyledTextField(
            label: 'Bull Tag',
            controller: widget.controllers['bull_tag']!,
            hint: 'Related bull tag (optional)',
            icon: FontAwesomeIcons.mars,
          ),
          EventStyledTextField(
            label: 'Calf Tag',
            controller: widget.controllers['calf_tag']!,
            hint: 'Related calf tag (optional)',
            icon: FontAwesomeIcons.baby,
          ),
          _buildTechnicianDropdown(),
        ]);
        break;
    }

    return fields;
  }

  Map<String, dynamic>? getNewCalfData() {
    return _newCalfData;
  }

  bool hasCalfData() {
    return _newCalfData != null;
  }

  String? getCalfTag() {
    return _newCalfData?['tag_no'];
  }

  Map<String, dynamic>? getFullCalfData() {
    return _newCalfData?['fullCalfData'];
  }

  bool isCalfReadyForRegistration() {
    return _newCalfData != null &&
        _newCalfData!['fullCalfData'] != null &&
        _newCalfData!['pendingOperation'] != null;
  }

  @override
  Widget build(BuildContext context) {
    final fields = _buildEventSpecificFields();

    if (fields.isEmpty ||
        widget.selectedEventType == 'Select type of event' ||
        widget.selectedEventType == 'Loading cattle information...') {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkGreen.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EventTypeUtils.getEventTypeColor(widget.selectedEventType).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      FontAwesomeIcons.clipboardList,
                      color: EventTypeUtils.getEventTypeColor(widget.selectedEventType),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${widget.selectedEventType} Details',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...fields.map((field) => SizedBox(
                width: double.infinity,
                child: field,
              )),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}