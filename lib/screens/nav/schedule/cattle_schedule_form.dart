import 'package:cattle_tracer_app/screens/nav/schedule/widgets/schedule_priority_dropdown_widget.dart';
import 'package:cattle_tracer_app/screens/nav/schedule/widgets/schedule_type_dropdown_widget.dart';
import 'package:cattle_tracer_app/screens/nav/schedule/widgets/veterinarian_selection_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/app_colors.dart';
import '../../../services/schedule/schedule_service.dart';
import '../../../services/cattle/cattle_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../models/schedule.dart';
import '../../../models/cattle.dart';
import '../../../models/user.dart';
import 'widgets/cattle_tag_multi_select_field_widget.dart';


class CattleScheduleForm extends StatefulWidget {
  final Function() onScheduleAdded;
  final Schedule? scheduleToEdit;

  const CattleScheduleForm({
    super.key,
    required this.onScheduleAdded,
    this.scheduleToEdit,
  });

  @override
  State<CattleScheduleForm> createState() => _CattleScheduleFormState();
}

class _CattleScheduleFormState extends State<CattleScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    _loadCattleList();
    _loadVeterinarians();
    // Note: _populateFieldsForEditing() will be called after data is loaded
  }

  @override
  void dispose() {
    _titleController.dispose();
    _veterinarianController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCattleList() async {
    setState(() => _isLoadingCattle = true);

    try {
      final cattle = await CattleService.getAllCattle();
      setState(() {
        _cattleList = cattle;
        _isLoadingCattle = false;
      });
      
      // Populate fields for editing after cattle list is loaded
      if (_isEditing && _veterinarianList.isNotEmpty) {
        _populateFieldsForEditing();
      }
    } catch (e) {
      print('Error loading cattle list: $e');
      setState(() => _isLoadingCattle = false);

      if (mounted) {
        _showError('Failed to load cattle list: ${e.toString()}');
      }
    }
  }

  Future<void> _loadVeterinarians() async {
    setState(() => _isLoadingVeterinarians = true);

    try {
      final veterinarians = await UserService().getUsersByRoles(roles: ['pvo', 'lgu']);
      setState(() {
        _veterinarianList = veterinarians;
        _isLoadingVeterinarians = false;
      });
      print('Loaded ${veterinarians.length} veterinarians');
      
      // Populate fields for editing after veterinarians are loaded
      if (_isEditing && _cattleList.isNotEmpty) {
        _populateFieldsForEditing();
      }
    } catch (e) {
      print('Error loading veterinarians: $e');
      setState(() => _isLoadingVeterinarians = false);

      if (mounted) {
        _showError('Failed to load veterinarians: ${e.toString()}');
      }
    }
  }

  void _populateFieldsForEditing() {
    final schedule = widget.scheduleToEdit!;
    _titleController.text = schedule.title;

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
              _buildTitleField(),
              const SizedBox(height: 16),
              CattleTagMultiSelectField(
                selectedCattleTags: _selectedCattleTags,
                cattleList: _cattleList,
                isLoadingCattle: _isLoadingCattle,
                onCattleTagsChanged: (tags) {
                  setState(() {
                    _selectedCattleTags = tags;
                  });
                },
                onRefreshCattle: _loadCattleList,
              ),
              const SizedBox(height: 16),
              ScheduleTypeDropdown(
                selectedType: _selectedType,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              SchedulePriorityDropdown(
                selectedPriority: _selectedPriority,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPriority = value);
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
                  setState(() {
                    _selectedVeterinarianId = id;
                  });
                },
                onUseCustomChanged: (useCustom) {
                  setState(() {
                    _useCustomVeterinarian = useCustom;
                    if (!_useCustomVeterinarian) {
                      _veterinarianController.clear();
                    } else {
                      _selectedVeterinarianId = null;
                    }
                  });
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

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Title *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Enter schedule title',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(16.0),
              child: FaIcon(
                FontAwesomeIcons.signature,
                size: 16,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Title is required';
            }
            return null;
          },
        ),
      ],
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

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
        print('Error getting user ID: $e');
      }

      String? cattleTagsString;
      if (_selectedCattleTags.isNotEmpty) {
        cattleTagsString = _selectedCattleTags.join(', ');
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
        final updatedSchedule = widget.scheduleToEdit!.copyWith(
          title: _titleController.text.trim(),
          cattleTag: cattleTagsString,
          type: _selectedType,
          priority: _selectedPriority,
          scheduleDateTime: scheduleDateTime,
          veterinarian: veterinarianName,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        await ScheduleService.updateSchedule(updatedSchedule);
        _showSuccess('Schedule updated successfully');
      } else {
        final newSchedule = Schedule(
          userId: userId,
          title: _titleController.text.trim(),
          cattleTag: cattleTagsString,
          type: _selectedType,
          priority: _selectedPriority,
          scheduleDateTime: scheduleDateTime,
          veterinarian: veterinarianName,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        await ScheduleService.createSchedule(newSchedule);
        _showSuccess(_selectedCattleTags.isEmpty
            ? 'Schedule created successfully'
            : 'Schedule created for ${_selectedCattleTags.length} cattle');
      }

      widget.onScheduleAdded();
      Navigator.pop(context, true);
    } catch (e) {
      print('Error saving schedule: $e');
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
}
