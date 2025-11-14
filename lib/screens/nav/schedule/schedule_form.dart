import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/schedule/schedule_service.dart';
import '../../../services/goat/goat_service.dart';
import '../../../services/goat/goat_history_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/schedule.dart';
import '../../../models/goat.dart';
import '../../../models/vaccination_schedule.dart';
import '../../../services/vaccination_service.dart';
import 'widgets/goat_tag_multi_select_field_widget.dart';


class ScheduleForm extends StatefulWidget {
  final Function() onScheduleAdded;
  final Schedule? scheduleToEdit;
  final String? preSelectedVaccineType;

  const ScheduleForm({
    super.key,
    required this.onScheduleAdded,
    this.scheduleToEdit,
    this.preSelectedVaccineType,
  });

  @override
  State<ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<ScheduleForm> {
  final _formKey = GlobalKey<FormState>();

  final _durationController = TextEditingController();
  final _reminderController = TextEditingController();
  final _scheduledByController = TextEditingController();
  final _detailsController = TextEditingController();

  String _selectedType = ScheduleType.vaccination;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<String> _selectedgoatTags = [];

  List<goat> _goatList = [];
  bool _isLoadinggoat = false;
  bool _isLoading = false;
  bool get _isEditing => widget.scheduleToEdit != null;


  // Vaccination-specific
  String? _selectedVaccineName;
  bool _isLoadingVaccineCandidates = false;
  List<Map<String, dynamic>> _allEvents = [];
  // Prevent duplicate schedules cache for current vaccine selection
  final Set<String> _scheduledTagsForSelectedVaccine = {};

  @override
  void initState() {
    super.initState();
    // Set to vaccination type since this form is vaccination-only
    _selectedType = ScheduleType.vaccination;
    // Set pre-selected vaccine type if provided
    if (widget.preSelectedVaccineType != null) {
      _selectedVaccineName = widget.preSelectedVaccineType;
    }
    _loadgoatList();
    _loadEvents();
    // Note: _populateFieldsForEditing() will be called after data is loaded
  }

  @override
  void dispose() {
    _durationController.dispose();
    _reminderController.dispose();
    _scheduledByController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _loadgoatList() async {
    if (mounted) {
      setState(() => _isLoadinggoat = true);
    }

    try {
      final goat = await GoatService.getAllGoats();
      if (mounted) {
        setState(() {
          _goatList = goat;
          _isLoadinggoat = false;
        });
      }
      
      // Populate fields for editing after goat list is loaded
      if (_isEditing) {
        _populateFieldsForEditing();
      }
      
      // If we have a pre-selected vaccine type, populate goat needing that vaccine
      if (widget.preSelectedVaccineType != null && !_isEditing) {
        _populategoatNeedingSelectedVaccine();
      }
    } catch (e) {
      // print('Error loading goat list: $e');
      if (mounted) setState(() => _isLoadinggoat = false);

      if (mounted) {
        _showError('Failed to load goat list: ${e.toString()}');
      }
    }
  }

  Future<void> _loadEvents() async {
    try {
      final events = await GoatHistoryService.getgoatHistory();
      if (mounted) {
        setState(() {
          _allEvents = events;
        });
      }
    } catch (e) {
      // Non-fatal
      debugPrint('Error loading history: $e');
    }
  }

  void _populateFieldsForEditing() {
    final schedule = widget.scheduleToEdit!;
    // Set vaccine type from schedule
    _selectedVaccineName = schedule.vaccineType;

    if (schedule.goatTag != null && schedule.goatTag!.isNotEmpty) {
      _selectedgoatTags = schedule.goatTag!
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    }

    _durationController.text = schedule.duration ?? '';
    _reminderController.text = schedule.reminder ?? '';
    _scheduledByController.text = schedule.scheduledBy ?? '';
    _detailsController.text = schedule.details ?? '';
    _selectedType = schedule.type;
    _selectedDate = DateTime(
      schedule.scheduleDateTime.year,
      schedule.scheduleDateTime.month,
      schedule.scheduleDateTime.day,
    );
    _selectedTime = TimeOfDay.fromDateTime(schedule.scheduleDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVaccineDropdown(),
              const SizedBox(height: 16),
              goatTagMultiSelectField(
                selectedgoatTags: _selectedgoatTags,
                goatList: _filteredgoatForSelectedVaccine(),
                isLoadinggoat: _isLoadinggoat,
                ongoatTagsChanged: (tags) {
                  if (mounted) {
                    setState(() {
                      _selectedgoatTags = tags;
                    });
                  }
                },
                onRefreshgoat: _loadgoatList,
                scheduledTagsForVaccine: _scheduledTagsForSelectedVaccine,
              ),
              const SizedBox(height: 16),
              _buildDurationField(),
              const SizedBox(height: 16),
              _buildReminderField(),
              const SizedBox(height: 16),
              _buildDateTimeSelectors(),
              const SizedBox(height: 16),
              _buildScheduledByField(),
              const SizedBox(height: 16),
              _buildDetailsField(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _isEditing ? 'Edit Schedule' : 'Add New Schedule',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }



  Widget _buildDateTimeSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date & Time *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Text(_formatDate(_selectedDate)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time),
                      const SizedBox(width: 8),
                      Text(_selectedTime.format(context)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveSchedule,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Text(
              _isEditing ? 'UPDATE SCHEDULE' : 'CREATE SCHEDULE',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      if (mounted) setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      if (mounted) setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Require vaccine selection for vaccination schedules
    if (_selectedVaccineName == null) {
      _showError('Please select a vaccine type');
      return;
    }

    // Final validation: prevent duplicates on selected tags for this vaccine
    try {
      await _loadExistingScheduledForSelectedVaccine();
      final conflicted = _selectedgoatTags
          .map((t) => t.trim().toUpperCase())
          .where((t) => _scheduledTagsForSelectedVaccine.contains(t))
          .toList();
      if (conflicted.isNotEmpty) {
        _showError('Some goat already have a scheduled "${_selectedVaccineName!}": ${conflicted.join(', ')}');
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = true);

    try {
      final DateTime scheduleDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      int userId = 1;
      try {
        final currentUserIdString = await AuthService.getCurrentUserId();
        if (currentUserIdString != null) {
          userId = int.tryParse(currentUserIdString) ?? 1;
        }
      } catch (e) {
        // print('Error getting user ID: $e');
      }

      String? goatTagsString;
      if (_selectedgoatTags.isNotEmpty) {
        // If multiple goat selected, we'll create one schedule per goat below
        goatTagsString = _selectedgoatTags.length == 1 ? _selectedgoatTags.first : null;
      }


      if (_isEditing) {
        // Generate title from vaccine type for vaccination schedules
        final computedTitleEdit = _selectedVaccineName ?? 'Vaccination';

        final updatedSchedule = widget.scheduleToEdit!.copyWith(
          title: computedTitleEdit,
          goatTag: goatTagsString,
          type: ScheduleType.vaccination,
          scheduleDateTime: scheduleDateTime,
          duration: _durationController.text.trim().isEmpty
              ? null
              : _durationController.text.trim(),
          reminder: _reminderController.text.trim().isEmpty
              ? null
              : _reminderController.text.trim(),
          scheduledBy: _scheduledByController.text.trim().isEmpty
              ? null
              : _scheduledByController.text.trim(),
          details: _detailsController.text.trim().isEmpty
              ? null
              : _detailsController.text.trim(),
          vaccineType: _selectedType == ScheduleType.vaccination ? _selectedVaccineName : null,
        );

        await ScheduleService.updateSchedule(updatedSchedule);
        _showSuccess('Schedule updated successfully');
      } else {
        // Generate title from vaccine type for vaccination schedules
        final computedTitleCreate = _selectedVaccineName != null
            ? 'Vaccination: ${_selectedVaccineName!}'
            : 'Vaccination';

        if (_selectedgoatTags.length > 1) {
          int successCount = 0;
          for (final tag in _selectedgoatTags) {
            final perTagSchedule = Schedule(
              userId: userId,
              title: computedTitleCreate,
              goatTag: tag,
              type: ScheduleType.vaccination,
              scheduleDateTime: scheduleDateTime,
              duration: _durationController.text.trim().isEmpty
                  ? null
                  : _durationController.text.trim(),
              reminder: _reminderController.text.trim().isEmpty
                  ? null
                  : _reminderController.text.trim(),
              scheduledBy: _scheduledByController.text.trim().isEmpty
                  ? null
                  : _scheduledByController.text.trim(),
              details: _detailsController.text.trim().isEmpty
                  ? null
                  : _detailsController.text.trim(),
              vaccineType: _selectedVaccineName,
            );
            try {
              await ScheduleService.createSchedule(perTagSchedule);
              successCount++;
            } catch (_) {}
          }
          if (successCount > 0) {
            _showSuccess('Created $successCount schedule(s)');
          } else {
            throw Exception('Failed to create schedules');
          }
        } else {
          final newSchedule = Schedule(
            userId: userId,
            title: computedTitleCreate,
            goatTag: goatTagsString,
            type: ScheduleType.vaccination,
            scheduleDateTime: scheduleDateTime,
            duration: _durationController.text.trim().isEmpty
                ? null
                : _durationController.text.trim(),
            reminder: _reminderController.text.trim().isEmpty
                ? null
                : _reminderController.text.trim(),
            scheduledBy: _scheduledByController.text.trim().isEmpty
                ? null
                : _scheduledByController.text.trim(),
            details: _detailsController.text.trim().isEmpty
                ? null
                : _detailsController.text.trim(),
            vaccineType: _selectedVaccineName,
          );

          await ScheduleService.createSchedule(newSchedule);
          _showSuccess('Schedule created successfully');
        }
      }

      widget.onScheduleAdded();
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      // print('Error saving schedule: $e');
      _showError('Error saving schedule: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Internal state helpers (must live on State to use setState)
  void _setLoadingVaccineCandidates(bool loading) {
    if (mounted) {
      setState(() {
        _isLoadingVaccineCandidates = loading;
      });
    }
  }

  void _setSelectedgoatTags(List<String> tags) {
    if (mounted) {
      setState(() {
        _selectedgoatTags = tags;
      });
    }
  }

  void _updateVaccineSelection(String? value) {
    if (mounted) {
      setState(() {
        _selectedVaccineName = value;
      });
      _populategoatNeedingSelectedVaccine();
    }
  }
}

extension _VaccinationUI on _ScheduleFormState {

  Widget _buildVaccineDropdown() {
    final vaccineTypes = VaccinationProtocol.vaccineTypes;
    // Group vaccines by their first applicable stage
    final Map<String, List<String>> vaccinesByStage = {};
    for (final v in vaccineTypes) {
      final stage = v.applicableStages.isNotEmpty ? v.applicableStages.first : 'Other';
      vaccinesByStage.putIfAbsent(stage, () => []);
      vaccinesByStage[stage]!.add(v.name);
    }
    // Sort stages in a sensible order
    final stageOrder = {
      'Newborn Kid': 0,
      'Pre-weaning Calves': 1,
      'Weaned Calves / Growers / Buckling': 2,
      'Replacement Doelings': 3,
      'Breeding Does & Bucks': 4,
      'Pregnant Doeling & Doe': 5,
      'Other': 99,
    };
    final sortedStages = vaccinesByStage.keys.toList()
      ..sort((a, b) => (stageOrder[a] ?? 100).compareTo(stageOrder[b] ?? 100));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vaccine Type *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.vaccines_rounded, size: 18),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedVaccineName,
              hint: const Text('Select vaccine type'),
              isExpanded: true,
              items: [
                for (final stage in sortedStages) ...[
                  // Stage header (disabled item)
                  DropdownMenuItem<String>(
                    enabled: false,
                    value: '__header__$stage',
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                      ),
                      child: Text(
                        stage,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  // Vaccines under this stage
                  for (final name in vaccinesByStage[stage]!) DropdownMenuItem<String>(
                    value: name,
                    child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
              onChanged: (value) {
                if (value != null && value.startsWith('__header__')) {
                  return; // ignore headers
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _updateVaccineSelection(value);
                  }
                });
              },
            ),
          ),
        ),
        if (_isLoadingVaccineCandidates)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_selectedVaccineName != null && _selectedgoatTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Auto-selected ${_selectedgoatTags.length} goat needing "${_selectedVaccineName!}"',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ),
      ],
    );
  }

  List<goat> _filteredgoatForSelectedVaccine() {
    if (_selectedVaccineName == null) return _goatList;
    if (_selectedgoatTags.isEmpty) return _goatList;
    final tagSet = _selectedgoatTags.toSet();
    return _goatList.where((c) => tagSet.contains(c.tagNo)).toList();
  }

  Future<void> _populategoatNeedingSelectedVaccine() async {
    if (_selectedVaccineName == null || !mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setLoadingVaccineCandidates(true);
      }
    });
    
    try {
      // Refresh existing scheduled cache for this vaccine
      await _loadExistingScheduledForSelectedVaccine();
      // Generate vaccination schedules for all goat
      final schedules = await VaccinationService().generateVaccinationSchedules(
        allgoat: _goatList,
        allEvents: _allEvents,
      );

      if (!mounted) return;

      // Filter schedules for selected vaccine and needing action
      final needing = schedules.where((s) =>
          s.vaccineType == _selectedVaccineName && (s.isPending || s.isOverdue));

      // Exclude goat that already have a Scheduled vaccination of this type
      final tags = needing
          .map((s) => s.goatTag)
          .where((tag) => !_scheduledTagsForSelectedVaccine.contains(tag.toUpperCase()))
          .toSet()
          .toList();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _setSelectedgoatTags(tags);
        }
      });
    } catch (e) {
      if (mounted) {
        _showError('Failed to compute vaccination candidates: ${e.toString()}');
      }
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _setLoadingVaccineCandidates(false);
        }
      });
    }
  }

  Future<void> _loadExistingScheduledForSelectedVaccine() async {
    _scheduledTagsForSelectedVaccine.clear();
    if (_selectedVaccineName == null) return;
    try {
      final existing = await ScheduleService.getSchedules(
        type: ScheduleType.vaccination,
        status: ScheduleStatus.scheduled,
      );
      for (final s in existing) {
        if ((s.vaccineType ?? '').toLowerCase() == _selectedVaccineName!.toLowerCase()) {
          for (final tag in s.goatTagsList) {
            _scheduledTagsForSelectedVaccine.add(tag.toUpperCase());
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading existing scheduled for vaccine: $e');
    }
  }

  Widget _buildDurationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _durationController,
          decoration: InputDecoration(
            hintText: 'e.g., 30 minutes, 1 hour',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value != null && value.length > 50) {
              return 'Duration cannot exceed 50 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildReminderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _reminderController,
          decoration: InputDecoration(
            hintText: 'e.g., 1 day before, 2 hours before',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value != null && value.length > 50) {
              return 'Reminder cannot exceed 50 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildScheduledByField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scheduled By',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _scheduledByController,
          decoration: InputDecoration(
            hintText: 'Name of person who scheduled this',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value != null && value.length > 100) {
              return 'Scheduled by cannot exceed 100 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDetailsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _detailsController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Additional details or notes about this schedule',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  
}
