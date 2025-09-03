import 'package:cattle_tracer_app/screens/nav/schedule/widgets/schedule_priority_dropdown_widget.dart';
import 'package:cattle_tracer_app/screens/nav/schedule/widgets/veterinarian_selection_field_widget.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/schedule/schedule_service.dart';
import '../../../services/cattle/cattle_service.dart';
import '../../../services/cattle/cattle_event_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../models/schedule.dart';
import '../../../models/cattle.dart';
import '../../../models/user.dart';
import '../../../models/vaccination_schedule.dart';
import '../../../services/vaccination_service.dart';
import 'widgets/cattle_tag_multi_select_field_widget.dart';


class CattleScheduleForm extends StatefulWidget {
  final Function() onScheduleAdded;
  final Schedule? scheduleToEdit;
  final String? preSelectedVaccineType;

  const CattleScheduleForm({
    super.key,
    required this.onScheduleAdded,
    this.scheduleToEdit,
    this.preSelectedVaccineType,
  });

  @override
  State<CattleScheduleForm> createState() => _CattleScheduleFormState();
}

class _CattleScheduleFormState extends State<CattleScheduleForm> {
  final _formKey = GlobalKey<FormState>();

  final _veterinarianController = TextEditingController();
  final _notesController = TextEditingController();


  String _selectedType = ScheduleType.vaccination;
  String _selectedPriority = SchedulePriority.medium;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<String> _selectedCattleTags = [];

  List<Cattle> _cattleList = [];
  List<User> _veterinarianList = [];
  bool _isLoadingCattle = false;
  bool _isLoadingVeterinarians = false;
  bool _isLoading = false;
  bool get _isEditing => widget.scheduleToEdit != null;

  String? _selectedVeterinarianId;
  bool _useCustomVeterinarian = false;

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
    _loadCattleList();
    _loadVeterinarians();
    _loadEvents();
    // Note: _populateFieldsForEditing() will be called after data is loaded
  }

  @override
  void dispose() {

    _veterinarianController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  Future<void> _loadCattleList() async {
    if (mounted) {
      setState(() => _isLoadingCattle = true);
    }

    try {
      final cattle = await CattleService.getAllCattle();
      if (mounted) {
        setState(() {
          _cattleList = cattle;
          _isLoadingCattle = false;
        });
      }
      
      // Populate fields for editing after cattle list is loaded
      if (_isEditing && _veterinarianList.isNotEmpty) {
        _populateFieldsForEditing();
      }
      
      // If we have a pre-selected vaccine type, populate cattle needing that vaccine
      if (widget.preSelectedVaccineType != null && !_isEditing) {
        _populateCattleNeedingSelectedVaccine();
      }
    } catch (e) {
      // print('Error loading cattle list: $e');
      if (mounted) setState(() => _isLoadingCattle = false);

      if (mounted) {
        _showError('Failed to load cattle list: ${e.toString()}');
      }
    }
  }

  Future<void> _loadEvents() async {
    try {
      final events = await CattleEventService.getCattleEvent();
      if (mounted) {
        setState(() {
          _allEvents = events;
        });
      }
    } catch (e) {
      // Non-fatal
      debugPrint('Error loading events: $e');
    }
  }

  Future<void> _loadVeterinarians() async {
    if (mounted) {
      setState(() => _isLoadingVeterinarians = true);
    }

    try {
      final veterinarians = await UserService().getUsersByRoles(roles: ['pvo', 'lgu']);
      if (mounted) {
        setState(() {
          _veterinarianList = veterinarians;
          _isLoadingVeterinarians = false;
        });
      }
      // print('Loaded ${veterinarians.length} veterinarians');
      
      // Populate fields for editing after veterinarians are loaded
      if (_isEditing && _cattleList.isNotEmpty) {
        _populateFieldsForEditing();
      }
    } catch (e) {
      // print('Error loading veterinarians: $e');
      if (mounted) setState(() => _isLoadingVeterinarians = false);

      if (mounted) {
        _showError('Failed to load veterinarians: ${e.toString()}');
      }
    }
  }

  void _populateFieldsForEditing() {
    final schedule = widget.scheduleToEdit!;
    // Set vaccine type from schedule
    _selectedVaccineName = schedule.vaccineType;

    if (schedule.cattleTag != null && schedule.cattleTag!.isNotEmpty) {
      _selectedCattleTags = schedule.cattleTag!
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    }

    if (schedule.veterinarian != null && schedule.veterinarian!.isNotEmpty) {
      final matchingVet = _veterinarianList.firstWhere(
            (vet) => '${vet.firstName} ${vet.lastName}' == schedule.veterinarian,
        orElse: () => User(
          id: 0,
          firstName: '',
          lastName: '',
          email: '',
          role: '',
          emailVerified: false,
          active: false,
          createdAt: DateTime.now(),
        ),
      );

      if (matchingVet.id != 0) {
        _selectedVeterinarianId = matchingVet.id.toString();
        _useCustomVeterinarian = false;
      } else {
        _veterinarianController.text = schedule.veterinarian!;
        _useCustomVeterinarian = true;
      }
    }

    _notesController.text = schedule.notes ?? '';
    _selectedType = schedule.type;
    _selectedPriority = schedule.priority;
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
              CattleTagMultiSelectField(
                selectedCattleTags: _selectedCattleTags,
                cattleList: _filteredCattleForSelectedVaccine(),
                isLoadingCattle: _isLoadingCattle,
                onCattleTagsChanged: (tags) {
                  if (mounted) {
                    setState(() {
                      _selectedCattleTags = tags;
                    });
                  }
                },
                onRefreshCattle: _loadCattleList,
                scheduledTagsForVaccine: _scheduledTagsForSelectedVaccine,
              ),
              const SizedBox(height: 16),
              SchedulePriorityDropdown(
                selectedPriority: _selectedPriority,
                onChanged: (value) {
                  if (value != null) {
                    if (mounted) {
                      setState(() => _selectedPriority = value);
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildDateTimeSelectors(),
              const SizedBox(height: 16),
              VeterinarianSelectionField(
                selectedVeterinarianId: _selectedVeterinarianId,
                useCustomVeterinarian: _useCustomVeterinarian,
                veterinarianController: _veterinarianController,
                veterinarianList: _veterinarianList,
                isLoadingVeterinarians: _isLoadingVeterinarians,
                onVeterinarianIdChanged: (id) {
                  if (mounted) {
                    setState(() {
                      _selectedVeterinarianId = id;
                    });
                  }
                },
                onUseCustomChanged: (useCustom) {
                  if (mounted) {
                    setState(() {
                      _useCustomVeterinarian = useCustom;
                      if (!_useCustomVeterinarian) {
                        _veterinarianController.clear();
                      } else {
                        _selectedVeterinarianId = null;
                      }
                    });
                  }
                },
                onRefreshVeterinarians: _loadVeterinarians,
              ),
              const SizedBox(height: 16),
              _buildNotesField(),
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

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter additional notes (optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.notes),
            ),
          ),
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
      final conflicted = _selectedCattleTags
          .map((t) => t.trim().toUpperCase())
          .where((t) => _scheduledTagsForSelectedVaccine.contains(t))
          .toList();
      if (conflicted.isNotEmpty) {
        _showError('Some cattle already have a scheduled "${_selectedVaccineName!}": ${conflicted.join(', ')}');
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

      String? cattleTagsString;
      if (_selectedCattleTags.isNotEmpty) {
        // If multiple cattle selected, we'll create one schedule per cattle below
        cattleTagsString = _selectedCattleTags.length == 1 ? _selectedCattleTags.first : null;
      }

      String? veterinarianName;
      if (_useCustomVeterinarian) {
        if (_veterinarianController.text.trim().isNotEmpty) {
          veterinarianName = _veterinarianController.text.trim();
        }
      } else {
        if (_selectedVeterinarianId != null) {
          final selectedVet = _veterinarianList.firstWhere(
                (vet) => vet.id.toString() == _selectedVeterinarianId,
            orElse: () => User(
              id: 0,
              firstName: '',
              lastName: '',
              email: '',
              role: '',
              emailVerified: false,
              active: false,
              createdAt: DateTime.now(),
            ),
          );
          if (selectedVet.id != 0) {
            veterinarianName = '${selectedVet.firstName} ${selectedVet.lastName}';
          }
        }
      }

      if (_isEditing) {
        // Generate title from vaccine type for vaccination schedules
        final computedTitleEdit = _selectedVaccineName ?? 'Vaccination';

        final updatedSchedule = widget.scheduleToEdit!.copyWith(
          title: computedTitleEdit,
          cattleTag: cattleTagsString,
          type: ScheduleType.vaccination,
          priority: _selectedPriority,
          scheduleDateTime: scheduleDateTime,
          veterinarian: veterinarianName,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          vaccineType: _selectedType == ScheduleType.vaccination ? _selectedVaccineName : null,
        );

        await ScheduleService.updateSchedule(updatedSchedule);
        _showSuccess('Schedule updated successfully');
      } else {
        // Generate title from vaccine type for vaccination schedules
        final computedTitleCreate = _selectedVaccineName != null
            ? 'Vaccination: ${_selectedVaccineName!}'
            : 'Vaccination';

        if (_selectedCattleTags.length > 1) {
          int successCount = 0;
          for (final tag in _selectedCattleTags) {
            final perTagSchedule = Schedule(
              userId: userId,
              title: computedTitleCreate,
              cattleTag: tag,
              type: ScheduleType.vaccination,
              priority: _selectedPriority,
              scheduleDateTime: scheduleDateTime,
              veterinarian: veterinarianName,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
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
            cattleTag: cattleTagsString,
            type: ScheduleType.vaccination,
            priority: _selectedPriority,
            scheduleDateTime: scheduleDateTime,
            veterinarian: veterinarianName,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
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

  void _setSelectedCattleTags(List<String> tags) {
    if (mounted) {
      setState(() {
        _selectedCattleTags = tags;
      });
    }
  }

  void _updateVaccineSelection(String? value) {
    if (mounted) {
      setState(() {
        _selectedVaccineName = value;
      });
      _populateCattleNeedingSelectedVaccine();
    }
  }
}

extension _VaccinationUI on _CattleScheduleFormState {

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
      'Newborn Calf': 0,
      'Pre-weaning Calves': 1,
      'Weaned Calves / Growers / Steer': 2,
      'Replacement Heifers': 3,
      'Breeding Cows & Bulls': 4,
      'Pregnant Heifer & Cow': 5,
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
        if (_selectedVaccineName != null && _selectedCattleTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Auto-selected ${_selectedCattleTags.length} cattle needing "${_selectedVaccineName!}"',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ),
      ],
    );
  }

  List<Cattle> _filteredCattleForSelectedVaccine() {
    if (_selectedVaccineName == null) return _cattleList;
    if (_selectedCattleTags.isEmpty) return _cattleList;
    final tagSet = _selectedCattleTags.toSet();
    return _cattleList.where((c) => tagSet.contains(c.tagNo)).toList();
  }

  Future<void> _populateCattleNeedingSelectedVaccine() async {
    if (_selectedVaccineName == null || !mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setLoadingVaccineCandidates(true);
      }
    });
    
    try {
      // Refresh existing scheduled cache for this vaccine
      await _loadExistingScheduledForSelectedVaccine();
      // Generate vaccination schedules for all cattle
      final schedules = await VaccinationService().generateVaccinationSchedules(
        allCattle: _cattleList,
        allEvents: _allEvents,
      );

      if (!mounted) return;

      // Filter schedules for selected vaccine and needing action
      final needing = schedules.where((s) =>
          s.vaccineType == _selectedVaccineName && (s.isPending || s.isOverdue));

      // Exclude cattle that already have a Scheduled vaccination of this type
      final tags = needing
          .map((s) => s.cattleTag)
          .where((tag) => !_scheduledTagsForSelectedVaccine.contains(tag.toUpperCase()))
          .toSet()
          .toList();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _setSelectedCattleTags(tags);
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
          for (final tag in s.cattleTagsList) {
            _scheduledTagsForSelectedVaccine.add(tag.toUpperCase());
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading existing scheduled for vaccine: $e');
    }
  }

  
}
