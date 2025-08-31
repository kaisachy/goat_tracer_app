import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../../../constants/app_colors.dart';
import '../../../models/cattle.dart';
import '../../../services/cattle/cattle_service.dart';
import '../../../services/auth_service.dart';

class CattleFormScreen extends StatefulWidget {
  final Cattle? cattle;

  const CattleFormScreen({
    super.key,
    this.cattle,
  });

  @override
  State<CattleFormScreen> createState() => _CattleFormScreenState();
}

class _CattleFormScreenState extends State<CattleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for all form fields
  final _tagNoController = TextEditingController();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  bool get _isEditing => widget.cattle != null;

  // State variables for dates and dropdowns
  String? _dateOfBirth;
  String? _joinedDate;
  String? _gender;
  String? _classification;
  String? _source;
  String? _sourceDetails; // For storing additional source information
  String? _motherTag;
  String? _fatherTag;
  String? _breed;
  String? _groupName;

  // NEW: State variables to hold the original parent tags for updates
  String? _originalMotherTag;
  String? _originalFatherTag;

  // State variables for holding parent cattle lists
  List<Cattle> _femaleCattle = [];
  List<Cattle> _maleCattle = [];
  bool _isLoadingParents = true;

  // NEW: For tag generation
  bool _isGeneratingTag = false;
  List<String> _existingTags = [];

  // NEW: Dynamic options from user preferences
  List<String> _breedOptions = [];
  List<String> _groupNameOptions = [];

  // Options for dropdowns
  final List<String> genderOptions = ['Male', 'Female'];
  final List<String> maleClassificationOptions = ['Calf', 'Steer', 'Growers', 'Bull'];
  final List<String> femaleClassificationOptions = ['Calf', 'Growers', 'Heifer', 'Cow'];
  final List<String> sourceOptions = ['Born on farm', 'Purchased', 'Other'];

  // Helper to get correct classification options based on selected gender
  List<String> get classificationOptions {
    if (_gender == 'Male') return maleClassificationOptions;
    if (_gender == 'Female') return femaleClassificationOptions;
    return [];
  }

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _populateFormFields();
    _fetchParentData();
    _loadExistingTags();

    // Auto-generate tag for new cattle
    if (widget.cattle == null) {
      _generateUniqueTag();
    }

    if (!_isEditing) {
      _generateUniqueTag();
    }
  }

  /// Load existing tags from all cattle
  Future<void> _loadExistingTags() async {
    try {
      final allCattle = await CattleService.getAllCattle();
      setState(() {
        _existingTags = allCattle.map((cattle) => cattle.tagNo.toLowerCase()).toList();
      });
    } catch (e) {
      print('Error loading existing tags: $e');
    }
  }

  /// Generate a unique tag number
  Future<void> _generateUniqueTag() async {
    setState(() => _isGeneratingTag = true);

    try {
      // Reload existing tags to ensure we have the latest data
      await _loadExistingTags();

      String newTag = _generateRandomTag();

      setState(() {
        _tagNoController.text = newTag;
        _isGeneratingTag = false;
      });

    } catch (e) {
      print('Error generating tag: $e');
      setState(() => _isGeneratingTag = false);
      _showErrorSnackBar('Failed to generate tag number');
    }
  }

  /// Generate different tag number options
  String _generateRandomTag() {
    // Find the highest existing CT- tag number
    int highestNumber = 0;

    for (String existingTag in _existingTags) {
      final upperTag = existingTag.toUpperCase();
      if (upperTag.startsWith('CT-')) {
        final numberPart = upperTag.substring(3); // Remove 'CT-' prefix
        final number = int.tryParse(numberPart);
        if (number != null && number > highestNumber) {
          highestNumber = number;
        }
      }
    }

    // Generate different options each time refresh is clicked
    final random = Random();
    final currentTag = _tagNoController.text.toUpperCase();

    List<String> possibleTags = [];

    // Option 1: Next sequential number
    final nextSequential = highestNumber + 1;
    possibleTags.add('CT-${nextSequential.toString().padLeft(4, '0')}');

    // Option 2: Skip a few numbers ahead (random jump)
    final jumpAhead = highestNumber + random.nextInt(10) + 2; // Jump 2-11 numbers ahead
    possibleTags.add('CT-${jumpAhead.toString().padLeft(4, '0')}');

    // Option 3: Random number in a higher range
    final randomHigh = highestNumber + random.nextInt(50) + 20; // 20-70 numbers ahead
    possibleTags.add('CT-${randomHigh.toString().padLeft(4, '0')}');

    // Option 4: Round number (next hundred, fifty, etc.)
    int roundNumber;
    if (highestNumber < 50) {
      roundNumber = 50;
    } else if (highestNumber < 100) {
      roundNumber = 100;
    } else {
      roundNumber = ((highestNumber / 100).ceil() + 1) * 100;
    }
    possibleTags.add('CT-${roundNumber.toString().padLeft(4, '0')}');

    // Remove any that might already exist
    possibleTags.removeWhere((tag) => _existingTags.contains(tag.toLowerCase()));

    // Remove the current tag if it's in the list
    possibleTags.removeWhere((tag) => tag == currentTag);

    // If we have options, pick one randomly
    if (possibleTags.isNotEmpty) {
      return possibleTags[random.nextInt(possibleTags.length)];
    }

    // Fallback: just increment from current or highest
    String fallbackTag;
    if (currentTag.startsWith('CT-')) {
      final currentNumber = int.tryParse(currentTag.substring(3)) ?? 0;
      fallbackTag = 'CT-${(currentNumber + 1).toString().padLeft(4, '0')}';
    } else {
      fallbackTag = 'CT-${(highestNumber + 1).toString().padLeft(4, '0')}';
    }

    return fallbackTag;
  }

  /// Get the current logged-in user ID from AuthService
  Future<String?> get _currentUserId async {
    // First try to get user ID from secure storage (faster)
    String? userId = await AuthService.getUserId();

    // If not found, try to extract from token
    userId ??= await AuthService.getCurrentUserId();

    return userId;
  }

  /// Load breed and group name options from SharedPreferences for the current user
  Future<void> _loadUserPreferences() async {
    final userId = await _currentUserId;
    if (userId == null) {
      // Handle case where user is not logged in
      print('Warning: User not logged in, cannot load preferences');
      setState(() {
        _breedOptions = [];
        _groupNameOptions = [];
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final breedJson = prefs.getString('breed_options_$userId') ?? '[]';
    final groupJson = prefs.getString('group_name_options_$userId') ?? '[]';

    setState(() {
      _breedOptions = List<String>.from(jsonDecode(breedJson));
      _groupNameOptions = List<String>.from(jsonDecode(groupJson));
    });
  }

  /// Save breed options to SharedPreferences for the current user
  Future<void> _saveBreedsToPreferences() async {
    final userId = await _currentUserId;
    if (userId == null) {
      print('Warning: User not logged in, cannot save preferences');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('breed_options_$userId', jsonEncode(_breedOptions));
  }

  /// Save group name options to SharedPreferences for the current user
  Future<void> _saveGroupNamesToPreferences() async {
    final userId = await _currentUserId;
    if (userId == null) {
      print('Warning: User not logged in, cannot save preferences');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('group_name_options_$userId', jsonEncode(_groupNameOptions));
  }

  /// Add new breed option for the current user
  Future<void> _addNewBreed(String breed) async {
    final userId = await _currentUserId;
    if (userId == null) {
      _showErrorSnackBar('Please log in to save preferences');
      return;
    }

    if (breed.isNotEmpty && !_breedOptions.contains(breed)) {
      setState(() {
        _breedOptions.add(breed);
        _breedOptions.sort();
      });
      await _saveBreedsToPreferences();
      _showSuccessSnackBar('Breed added successfully');
    } else if (_breedOptions.contains(breed)) {
      _showErrorSnackBar('Breed already exists');
    }
  }

  /// Add new group name option for the current user
  Future<void> _addNewGroupName(String groupName) async {
    final userId = await _currentUserId;
    if (userId == null) {
      _showErrorSnackBar('Please log in to save preferences');
      return;
    }

    if (groupName.isNotEmpty && !_groupNameOptions.contains(groupName)) {
      setState(() {
        _groupNameOptions.add(groupName);
        _groupNameOptions.sort();
      });
      await _saveGroupNamesToPreferences();
      _showSuccessSnackBar('Group name added successfully');
    } else if (_groupNameOptions.contains(groupName)) {
      _showErrorSnackBar('Group name already exists');
    }
  }

  /// Edit existing breed option for the current user
  Future<void> _editBreed(String oldBreed, String newBreed) async {
    final userId = await _currentUserId;
    if (userId == null) {
      _showErrorSnackBar('Please log in to save preferences');
      return;
    }

    if (newBreed.isNotEmpty && newBreed != oldBreed) {
      if (_breedOptions.contains(newBreed)) {
        _showErrorSnackBar('Breed name already exists');
        return;
      }

      setState(() {
        final index = _breedOptions.indexOf(oldBreed);
        if (index != -1) {
          _breedOptions[index] = newBreed;
          _breedOptions.sort();
          if (_breed == oldBreed) {
            _breed = newBreed;
          }
        }
      });
      await _saveBreedsToPreferences();
      _showSuccessSnackBar('Breed updated successfully');
    }
  }

  /// Edit existing group name option for the current user
  Future<void> _editGroupName(String oldGroupName, String newGroupName) async {
    final userId = await _currentUserId;
    if (userId == null) {
      _showErrorSnackBar('Please log in to save preferences');
      return;
    }

    if (newGroupName.isNotEmpty && newGroupName != oldGroupName) {
      if (_groupNameOptions.contains(newGroupName)) {
        _showErrorSnackBar('Group name already exists');
        return;
      }

      setState(() {
        final index = _groupNameOptions.indexOf(oldGroupName);
        if (index != -1) {
          _groupNameOptions[index] = newGroupName;
          _groupNameOptions.sort();
          if (_groupName == oldGroupName) {
            _groupName = newGroupName;
          }
        }
      });
      await _saveGroupNamesToPreferences();
      _showSuccessSnackBar('Group name updated successfully');
    }
  }

  /// Delete breed option for the current user
  Future<void> _deleteBreed(String breed) async {
    final userId = await _currentUserId;
    if (userId == null) {
      _showErrorSnackBar('Please log in to save preferences');
      return;
    }

    setState(() {
      _breedOptions.remove(breed);
      if (_breed == breed) {
        _breed = null;
      }
    });
    await _saveBreedsToPreferences();
    _showSuccessSnackBar('Breed deleted successfully');
  }

  /// Delete group name option for the current user
  Future<void> _deleteGroupName(String groupName) async {
    final userId = await _currentUserId;
    if (userId == null) {
      _showErrorSnackBar('Please log in to save preferences');
      return;
    }

    setState(() {
      _groupNameOptions.remove(groupName);
      if (_groupName == groupName) {
        _groupName = null;
      }
    });
    await _saveGroupNamesToPreferences();
    _showSuccessSnackBar('Group name deleted successfully');
  }

  /// Show success snack bar
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.vibrantGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Show error snack bar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Show dialog to add new option
  Future<void> _showAddOptionDialog(String title, String hintText, Function(String) onAdd) async {
    final controller = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onAdd(controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Show dialog to edit option
  Future<void> _showEditOptionDialog(String title, String currentValue, Function(String, String) onEdit) async {
    final controller = TextEditingController(text: currentValue);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onEdit(currentValue, controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Show dialog to manage options (edit/delete)
  Future<void> _showManageOptionsDialog(String title, List<String> options, Function(String, String) onEdit, Function(String) onDelete) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage $title Options'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: options.isEmpty
              ? const Center(child: Text('No options available'))
              : ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              return ListTile(
                title: Text(option),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditOptionDialog(title, option, onEdit);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteConfirmDialog(title, option, onDelete);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show source details modal for Purchased or Other options
  Future<void> _showSourceDetailsModal() async {
    // Extract existing details if editing
    String? existingDetails;
    String baseSource = _source ?? '';
    
    if (_source != null && _source!.contains(' - ')) {
      final parts = _source!.split(' - ');
      if (parts.length >= 2) {
        baseSource = parts[0];
        existingDetails = parts.sublist(1).join(' - ');
      }
    }
    
    final controller = TextEditingController(text: existingDetails ?? '');
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              baseSource == 'Purchased' ? Icons.shopping_cart : Icons.info,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(baseSource == 'Purchased' ? 'Purchased - Details' : 'Other - Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              baseSource == 'Purchased' 
                ? 'Where/who did you purchase this cattle from?'
                : 'Please provide additional details about how you acquired this cattle (e.g., gift, inheritance, trade).',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: baseSource == 'Purchased' ? 'Purchase Source' : 'Acquisition Details',
                hintText: baseSource == 'Purchased' 
                  ? 'e.g., John Smith Farm, Market XYZ, Auction House ABC'
                  : 'e.g., Gift from neighbor, Inheritance, Trade, etc.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: Icon(Icons.info, color: AppColors.primary),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (existingDetails != null) ...[
            TextButton(
              onPressed: () {
                setState(() {
                  // Clear the source details and revert to base source
                  _source = baseSource;
                  _sourceDetails = null;
                });
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear'),
            ),
          ],
          ElevatedButton(
            onPressed: () {
              final details = controller.text.trim();
              if (details.isNotEmpty) {
                setState(() {
                  // Update the source to show the combined information
                  _source = '$baseSource - $details';
                  // Store the details separately for backend
                  _sourceDetails = details;
                });
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Show delete confirmation dialog
  Future<void> _showDeleteConfirmDialog(String title, String option, Function(String) onDelete) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $title'),
        content: Text('Are you sure you want to delete "$option"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onDelete(option);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Populates form fields if editing an existing cattle
  void _populateFormFields() {
    final c = widget.cattle;
    if (c != null) {
      _tagNoController.text = c.tagNo;
      _nameController.text = c.name ?? '';
      _weightController.text = c.weight?.toString() ?? '';
      _notesController.text = c.notes ?? '';

      // Set breed and group name
      _breed = c.breed;
      _groupName = c.groupName;

      // Set initial parent tags
      _motherTag = c.motherTag;
      _fatherTag = c.fatherTag;

      // NEW: Store original parent tags for the update request
      _originalMotherTag = c.motherTag;
      _originalFatherTag = c.fatherTag;

      _dateOfBirth = c.dateOfBirth;
      _joinedDate = c.joinedDate;

      // Set dropdown values, ensuring they exist in the options list
      _gender = genderOptions.contains(c.gender) ? c.gender : null;
      if (_gender != null) {
        final currentClassificationOptions = classificationOptions;
        _classification = currentClassificationOptions.contains(c.classification)
            ? c.classification
            : null;
      }
      // Handle source and source details
      if (c.sourceDetails != null && c.sourceDetails!.isNotEmpty) {
        // If we have source details, show the combined format
        _source = '${c.source} - ${c.sourceDetails}';
        _sourceDetails = c.sourceDetails;
      } else {
        _source = sourceOptions.contains(c.source) ? c.source : null;
        _sourceDetails = null;
      }
    }
  }

  /// Fetches all cattle from the service and filters them by gender for parent selection
  Future<void> _fetchParentData() async {
    setState(() => _isLoadingParents = true);

    final allCattle = await CattleService.getAllCattle();
    // Exclude the current cattle being edited from the list of potential parents
    final potentialParents = allCattle.where((c) => c.id != widget.cattle?.id).toList();

    if (mounted) {
      setState(() {
        _femaleCattle = potentialParents.where((c) => c.gender == 'Female').toList();
        _maleCattle = potentialParents.where((c) => c.gender == 'Male').toList();

        // Validate parent tags - if they don't exist in the current cattle list, set them to null
        if (_motherTag != null && !_femaleCattle.any((c) => c.tagNo == _motherTag)) {
          _motherTag = null;
        }
        if (_fatherTag != null && !_maleCattle.any((c) => c.tagNo == _fatherTag)) {
          _fatherTag = null;
        }

        _isLoadingParents = false;
      });
    }
  }

  /// Shows a date picker dialog
  Future<void> _selectDate(BuildContext context, bool isDob) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              secondary: AppColors.accent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        if (isDob) {
          _dateOfBirth = formatted;
        } else {
          _joinedDate = formatted;
        }
      });
    }
  }

  /// Validates and submits the form data
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final tagToCheck = _tagNoController.text.trim();
    print('Checking tag: $tagToCheck');

    // Check if tag already exists (only for new cattle or when tag is changed)
    bool shouldCheckTag = !_isEditing || widget.cattle!.tagNo != tagToCheck;

    print('Should check tag: $shouldCheckTag');

    if (shouldCheckTag) {
      // Show loading indicator for tag checking
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final allCattle = await CattleService.getAllCattle();
        final duplicateExists = allCattle.any((cattle) =>
        cattle.tagNo.toLowerCase() == tagToCheck.toLowerCase() &&
            (!_isEditing || cattle.id != widget.cattle!.id));

        if (mounted) Navigator.pop(context);

        if (duplicateExists) {
          _showErrorSnackBar('Cattle tag already exists. Please use a different unique tag.');
          return;
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);
        _showErrorSnackBar('Error validating tag. Please try again.');
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );

    String? textOrNull(String? text) {
      return text != null && text.isNotEmpty ? text : null;
    }

    // Common data for both create and update
    final Map<String, dynamic> data = {
      'tag_no': _tagNoController.text.trim(),
      'name': textOrNull(_nameController.text),
      'date_of_birth': _dateOfBirth,
      'gender': _gender,
      'weight': double.tryParse(_weightController.text),
      'classification': _classification,
      'breed': textOrNull(_breed),
      'group_name': textOrNull(_groupName),
      'joined_date': _joinedDate,
      'source': _source,
      'source_details': _sourceDetails,
      'mother_tag': _motherTag,
      'father_tag': _fatherTag,
      'notes': textOrNull(_notesController.text),
      'status': widget.cattle?.status ?? 'Healthy',
    };

    final bool success;

    try {
      if (widget.cattle != null) {
        // This is an UPDATE
        data['id'] = widget.cattle!.id;

        // Add the original parent tags to the data map for the backend
        data['original_mother_tag'] = _originalMotherTag;
        data['original_father_tag'] = _originalFatherTag;

        // IMPORTANT: Also add the original tag number for backend reference updates
        data['original_tag_no'] = widget.cattle!.tagNo;

        success = await CattleService.updateCattleInformation(data);
      } else {
        // This is a CREATE
        success = await CattleService.storeCattleInformation(data);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        print('Error submitting form: $e');

        // Parse different types of errors
        String errorMessage = 'Failed to save cattle information';

        if (e.toString().contains('Duplicate entry') ||
            e.toString().contains('tag_no') ||
            e.toString().contains('already exists') ||
            e.toString().contains('1062')) {
          errorMessage = 'Cattle tag already exists. Please use a different unique tag.';
        } else if (e.toString().contains('foreign key constraint') ||
            e.toString().contains('Cannot delete or update a parent row')) {
          errorMessage = 'Unable to update. This cattle has offspring that reference it.';
        } else if (e.toString().contains('connection') ||
            e.toString().contains('network') ||
            e.toString().contains('timeout')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        }

        _showErrorSnackBar(errorMessage);
      }
      return;
    }

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.cattle == null
                ? 'Cattle added successfully!'
                : 'Cattle updated successfully!'),
            backgroundColor: AppColors.vibrantGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.pop(context, true);
      } else {
        // If success is false but no exception was thrown, show generic error
        _showErrorSnackBar('Failed to save cattle information. Please try again.');
      }
    }
  }

  /// Builds a searchable dropdown for parent selection
  Widget _buildSearchableDropdown({
    required String label,
    required String? value,
    required List<Cattle> options,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    // Check if the current value exists in the options
    bool valueExists = value == null || options.any((cattle) => cattle.tagNo == value);
    String? safeValue = valueExists ? value : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        fillColor: AppColors.cardBackground,
        filled: true,
        suffixIcon: _isLoadingParents
            ? const Padding(
          padding: EdgeInsets.all(12.0),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
            : null,
      ),
      hint: Text('Select $label'),
      items: [
        // Add a "None" option
        const DropdownMenuItem<String>(
          value: null,
          child: Text('None'),
        ),
        // Add all cattle options, ensuring no duplicates
        ...options.toSet().map((cattle) {
          return DropdownMenuItem<String>(
            value: cattle.tagNo,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    cattle.tagNo,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (cattle.name != null && cattle.name!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      cattle.name!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
      onChanged: _isLoadingParents ? null : (newValue) {
        onChanged(newValue);
      },
      menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
      selectedItemBuilder: (context) {
        return [
          const Text('None'),
          ...options.toSet().map((cattle) {
            return Text(
              cattle.tagNo,
              overflow: TextOverflow.ellipsis,
            );
          }),
        ];
      },
    );
  }

  /// Build dynamic dropdown with CRUD functionality
  Widget _buildDynamicDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required Function(String?) onChanged,
    required IconData icon,
    required Function(String) onAdd,
    required Function(String, String) onEdit,
    required Function(String) onDelete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: options.contains(value) ? value : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  fillColor: AppColors.cardBackground,
                  filled: true,
                ),
                hint: Text('Select $label'),
                items: [
                  // Add a "None" option
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('None'),
                  ),
                  // Add all options
                  ...options.map((option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(option, overflow: TextOverflow.ellipsis),
                  )),
                ],
                onChanged: onChanged,
                menuMaxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AppColors.primary),
              onSelected: (String choice) {
                switch (choice) {
                  case 'add':
                    _showAddOptionDialog(label, 'Enter new $label', onAdd);
                    break;
                  case 'manage':
                    _showManageOptionsDialog(label, options, onEdit, onDelete);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'add',
                  child: Row(
                    children: [
                      Icon(Icons.add, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text('Add New'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'manage',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text('Manage'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // --- UI Helper Widgets ---

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 3,
      shadowColor: AppColors.primary.withOpacity(0.2),
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.lightGreen.withOpacity(0.3), width: 1),
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }

  Widget _buildDateField({
    required String label,
    required String? value,
    required bool isDob,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => _selectDate(context, isDob),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          suffixIcon: const Icon(Icons.calendar_today, color: AppColors.textSecondary),
          fillColor: AppColors.cardBackground,
          filled: true,
        ),
        child: Text(
          value != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(value)) : 'Select date',
          style: TextStyle(
            color: value != null ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required Function(String?) onChanged,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      validator: validator,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        fillColor: AppColors.cardBackground,
        filled: true,
      ),
      hint: Text('Select $label'),
      items: options.map((option) => DropdownMenuItem(
        value: option,
        child: Text(
          option,
          overflow: TextOverflow.ellipsis,
        ),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        fillColor: AppColors.cardBackground,
        filled: true,
      ),
    );
  }

  /// NEW: Build auto-generated tag field with refresh button
  Widget _buildAutoTagField() {
    return TextFormField(
      controller: _tagNoController,
      validator: (value) => value?.isEmpty == true ? 'Tag number is required' : null,
      decoration: InputDecoration(
        labelText: 'Tag Number *',
        prefixIcon: Icon(Icons.label, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        fillColor: AppColors.cardBackground,
        filled: true,
        suffixIcon: _isGeneratingTag
            ? const Padding(
          padding: EdgeInsets.all(12.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
            : IconButton(
          onPressed: _generateUniqueTag,
          icon: Icon(
            Icons.refresh,
            color: AppColors.primary,
          ),
          tooltip: 'Generate new tag number',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50] ?? const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: Text(
          widget.cattle == null ? 'Add New Cattle' : 'Edit Cattle',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.darkGreen],
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSectionTitle('Basic Information', Icons.info_outline),
              _buildCard(
                child: Column(
                  children: [
                    _buildAutoTagField(), // NEW: Use the auto-generated tag field
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Name (Optional)',
                      icon: FontAwesomeIcons.signature,
                    ),
                    const SizedBox(height: 16),
                    // Use Column instead of Row for better responsive design
                    Column(
                      children: [
                        _buildDateField(
                          label: 'Date of Birth',
                          value: _dateOfBirth,
                          isDob: true,
                          icon: Icons.cake,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Gender *',
                          value: _gender,
                          options: genderOptions,
                          validator: (value) => value == null ? 'Gender is required' : null,
                          onChanged: (value) {
                            setState(() {
                              _gender = value;
                              _classification = null;
                            });
                          },
                          icon: Icons.wc,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Physical Characteristics Section
              _buildSectionTitle('Physical Characteristics', Icons.monitor_weight),
              _buildCard(
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _weightController,
                      label: 'Weight (kg)',
                      icon: Icons.monitor_weight,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Classification *',
                      value: _classification,
                      options: classificationOptions,
                      validator: (value) => value == null ? 'Classification is required' : null,
                      onChanged: (value) => setState(() => _classification = value),
                      icon: Icons.category,
                    ),
                    const SizedBox(height: 16),
                    _buildDynamicDropdown(
                      label: 'Breed',
                      value: _breed,
                      options: _breedOptions,
                      onChanged: (value) => setState(() => _breed = value),
                      icon: FontAwesomeIcons.cow,
                      onAdd: _addNewBreed,
                      onEdit: _editBreed,
                      onDelete: _deleteBreed,
                    ),
                    const SizedBox(height: 16),
                    _buildDynamicDropdown(
                      label: 'Group Name',
                      value: _groupName,
                      options: _groupNameOptions,
                      onChanged: (value) => setState(() => _groupName = value),
                      icon: FontAwesomeIcons.groupArrowsRotate,
                      onAdd: _addNewGroupName,
                      onEdit: _editGroupName,
                      onDelete: _deleteGroupName,
                    ),
                  ],
                ),
              ),

              // Farm Information Section
              _buildSectionTitle('Farm Information', Icons.agriculture),
              _buildCard(
                child: Column(
                  children: [
                    _buildDateField(
                      label: 'Joined Date',
                      value: _joinedDate,
                      isDob: false,
                      icon: Icons.event,
                    ),
                    const SizedBox(height: 16),
                    // Custom source dropdown that can show combined information
                    DropdownButtonFormField<String>(
                      value: _source,
                      validator: (value) => value == null ? 'Source is required' : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Source *',
                        prefixIcon: Icon(Icons.source, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                        fillColor: AppColors.cardBackground,
                        filled: true,
                      ),
                      hint: const Text('Select Source'),
                      items: [
                        // Add the base options
                        ...sourceOptions.map((option) => DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        )),
                        // Add any custom combined options that exist
                        if (_source != null && _source!.contains(' - '))
                          DropdownMenuItem<String>(
                            value: _source,
                            child: Text(_source!),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _source = value;
                          // Show modal for Purchased or Other options
                          if (value == 'Purchased' || value == 'Other') {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _showSourceDetailsModal();
                            });
                          }
                        });
                      },
                    ),
                    // Show edit button if we have source details
                    if (_source != null && _source!.contains(' - ')) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _source!.startsWith('Purchased') ? Icons.shopping_cart : Icons.info,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _source!,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _showSourceDetailsModal,
                            icon: Icon(Icons.edit, color: AppColors.primary),
                            tooltip: 'Edit source details',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Lineage Information Section
              _buildSectionTitle('Lineage Information', Icons.family_restroom),
              _buildCard(
                child: Column(
                  children: [
                    _buildSearchableDropdown(
                      label: 'Mother Tag',
                      value: _motherTag,
                      options: _femaleCattle,
                      onChanged: (value) => setState(() => _motherTag = value),
                      icon: Icons.female,
                    ),
                    const SizedBox(height: 16),
                    _buildSearchableDropdown(
                      label: 'Father Tag',
                      value: _fatherTag,
                      options: _maleCattle,
                      onChanged: (value) => setState(() => _fatherTag = value),
                      icon: Icons.male,
                    ),
                  ],
                ),
              ),

              // Additional Notes Section
              _buildSectionTitle('Additional Notes', Icons.note),
              _buildCard(
                child: _buildTextField(
                  controller: _notesController,
                  label: 'Notes',
                  icon: Icons.notes,
                  maxLines: 4,
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: Icon(
                    widget.cattle == null ? Icons.add_circle : Icons.update,
                    color: Colors.white,
                  ),
                  label: Text(
                    widget.cattle == null ? 'Add Cattle' : 'Update Cattle',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tagNoController.dispose();
    _nameController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}