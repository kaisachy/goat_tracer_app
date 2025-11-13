import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
import 'dart:math';
import '../../../constants/app_colors.dart';
import '../../../models/cattle.dart';
import '../../../services/cattle/cattle_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/cattle_age_classification.dart';

class CattleFormScreen extends StatefulWidget {
  final Cattle? cattle;
  final String? preSelectedClassification;
  final String? preSelectedSex; // New: allow preselecting sex for Growers/Calf

  const CattleFormScreen({
    super.key,
    this.cattle,
    this.preSelectedClassification,
    this.preSelectedSex,
  });

  @override
  State<CattleFormScreen> createState() => _CattleFormScreenState();
}

class _CattleFormScreenState extends State<CattleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for all form fields
  final _tagNoController = TextEditingController();
  final _weightController = TextEditingController();
  // final _notesController = TextEditingController(); // Commented out: Notes field removed

  bool get _isEditing => widget.cattle != null;


  // State variables for dates and dropdowns
  String? _dateOfBirth;
  String? _sex;
  String? _classification;
  String? _source;
  String? _sourceDetails; // For storing additional source information
  String? _motherTag;
  String? _fatherTag;
  String? _breed;
  // String? _groupName; // Commented out: Group Name field removed
  String? _ageClassificationWarning;

  // Breed specific controls
  final List<String> defaultBreedOptions = [
    'Native',
    'Brahman',
    'Upgraded Brahman',
    'Angus',
    'Upgraded Angus',
    'Holstein Friesian',
    'Upgraded Holstein Friesian',
    'Sahiwal',
    'Upgraded Sahiwal',
    'Other',
  ];
  final TextEditingController _otherBreedController = TextEditingController();

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
  List<String> _recentlyGeneratedTags = []; // Track tags generated in current session

  // NEW: Dynamic options from user preferences
  List<String> _breedOptions = [];
  // List<String> _groupNameOptions = []; // Commented out: Group Name options removed

  // Options for dropdowns
  final List<String> sexOptions = ['Male', 'Female'];
  final List<String> maleClassificationOptions = ['Calf', 'Steer', 'Growers', 'Bull'];
  final List<String> femaleClassificationOptions = ['Calf', 'Growers', 'Heifer', 'Cow'];
  final List<String> sourceOptions = ['Born on farm', 'Purchased', 'Other'];

  // Helper to get correct classification options based on selected sex
  List<String> get classificationOptions {
    // If we have a pre-selected classification, include it in options
    if (widget.preSelectedClassification != null) {
      if (_sex == 'Male') return maleClassificationOptions;
      if (_sex == 'Female') return femaleClassificationOptions;
      // If sex is not selected yet, return all options for pre-selected classification
      return ['Cow', 'Bull', 'Heifer', 'Steer', 'Growers', 'Calf'];
    }
    
    if (_sex == 'Male') return maleClassificationOptions;
    if (_sex == 'Female') return femaleClassificationOptions;
    return ['Cow', 'Bull', 'Heifer', 'Steer', 'Growers', 'Calf']; // Return all options when no sex selected
  }

  @override
  void initState() {
    super.initState();
    // Initialize breed options with defaults immediately
    _breedOptions = List<String>.from(defaultBreedOptions);
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
        // For web admin compatibility, store tags as-is (6-digit numbers)
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

      String newTag;
      if (_classification != null) {
        // Generate based on classification
        newTag = _generateTagForClassificationType(_classification!);
      } else {
        // Fallback to old method
        newTag = _generateRandomTag();
      }

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

  /// Generate different tag number options (fallback when no classification is selected)
  String _generateRandomTag() {
    // Use web admin logic: generate random 6-digit numbers (100000 to 999999)
    const int maxAttempts = 1000;
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      // Generate a random 6-digit number (100000 to 999999)
      final random = Random();
      final randomNumber = random.nextInt(900000) + 100000; // 100000 to 999999
      
      // Format as 6-digit string with leading zeros
      final tagNumber = randomNumber.toString().padLeft(6, '0');
      
      // Check if this random number is unique
      if (_isTagNumberUnique(tagNumber)) {
        // Add to recently generated tags
        _recentlyGeneratedTags.add(tagNumber.toLowerCase());
        return tagNumber;
      }
      
      attempts++;
    }
    
    // If we can't find a random unique number after many attempts,
    // fall back to sequential approach starting from a random point
    final random = Random();
    final randomStart = random.nextInt(999999) + 1;
    int nextNumber = randomStart;
    
    for (int i = 0; i < 999999; i++) {
      final tagNumber = nextNumber.toString().padLeft(6, '0');
      
      if (_isTagNumberUnique(tagNumber)) {
        // Add to recently generated tags
        _recentlyGeneratedTags.add(tagNumber.toLowerCase());
        return tagNumber;
      }
      
      nextNumber++;
      if (nextNumber > 999999) {
        nextNumber = 1;
      }
    }
    
    // Final fallback - use timestamp-based number
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fallbackTag = (timestamp % 900000 + 100000).toString().padLeft(6, '0');
    
    // Add to recently generated tags
    _recentlyGeneratedTags.add(fallbackTag.toLowerCase());
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
        // _groupNameOptions = []; // Commented out: Group Name options removed
      });
      return;
    }

    // final prefs = await SharedPreferences.getInstance(); // unused now
    // final groupJson = prefs.getString('group_name_options_$userId') ?? '[]'; // Commented out: Group Name prefs

    setState(() {
      // Enforce fixed breed options with "Other"
      _breedOptions = List<String>.from(defaultBreedOptions);
      // _groupNameOptions = List<String>.from(jsonDecode(groupJson)); // Commented out: Group Name options
    });
  }


  // /// Save group name options to SharedPreferences for the current user
  // Future<void> _saveGroupNamesToPreferences() async {
  //   final userId = await _currentUserId;
  //   if (userId == null) {
  //     print('Warning: User not logged in, cannot save preferences');
  //     return;
  //   }
  //
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('group_name_options_$userId', jsonEncode(_groupNameOptions));
  // }


  // /// Add new group name option for the current user
  // Future<void> _addNewGroupName(String groupName) async {
  //   final userId = await _currentUserId;
  //   if (userId == null) {
  //     _showErrorSnackBar('Please log in to save preferences');
  //     return;
  //   }
  //
  //   if (groupName.isNotEmpty && !_groupNameOptions.contains(groupName)) {
  //     setState(() {
  //       _groupNameOptions.add(groupName);
  //       _groupNameOptions.sort();
  //     });
  //     await _saveGroupNamesToPreferences();
  //     _showSuccessSnackBar('Group name added successfully');
  //   } else if (_groupNameOptions.contains(groupName)) {
  //     _showErrorSnackBar('Group name already exists');
  //   }
  // }

  /// Edit existing breed option for the current user

  // /// Edit existing group name option for the current user
  // Future<void> _editGroupName(String oldGroupName, String newGroupName) async {
  //   final userId = await _currentUserId;
  //   if (userId == null) {
  //     _showErrorSnackBar('Please log in to save preferences');
  //     return;
  //   }
  //
  //   if (newGroupName.isNotEmpty && newGroupName != oldGroupName) {
  //     if (_groupNameOptions.contains(newGroupName)) {
  //       _showErrorSnackBar('Group name already exists');
  //       return;
  //     }
  //
  //     setState(() {
  //       final index = _groupNameOptions.indexOf(oldGroupName);
  //       if (index != -1) {
  //         _groupNameOptions[index] = newGroupName;
  //         _groupNameOptions.sort();
  //         if (_groupName == oldGroupName) {
  //           _groupName = newGroupName;
  //         }
  //       }
  //     });
  //     await _saveGroupNamesToPreferences();
  //     _showSuccessSnackBar('Group name updated successfully');
  //   }
  // }

  /// Delete breed option for the current user

  // /// Delete group name option for the current user
  // Future<void> _deleteGroupName(String groupName) async {
  //   final userId = await _currentUserId;
  //   if (userId == null) {
  //     _showErrorSnackBar('Please log in to save preferences');
  //     return;
  //   }
  //
  //   setState(() {
  //     _groupNameOptions.remove(groupName);
  //     if (_groupName == groupName) {
  //       _groupName = null;
  //     }
  //   });
  //   await _saveGroupNamesToPreferences();
  //   _showSuccessSnackBar('Group name deleted successfully');
  // }

  /// Show success snack bar
  // ignore: unused_element
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
  // ignore: unused_element
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
      _tagNoController.text = c.tagNo; // Use tag as-is for web admin compatibility
      _weightController.text = c.weight?.toString() ?? '';
      // _notesController.text = c.notes ?? ''; // Commented out: Notes field removed

      // Set breed and group name
      _breed = c.breed;
      // If existing breed isn't in fixed options, map to Other and prefill
      if (_breed != null && _breed!.isNotEmpty && !_breedOptions.contains(_breed)) {
        _otherBreedController.text = _breed!;
        _breed = 'Other';
      }
      // _groupName = c.groupName; // Commented out: Group Name field removed

      // Set initial parent tags
      _motherTag = c.motherTag;
      _fatherTag = c.fatherTag;

      // NEW: Store original parent tags for the update request
      _originalMotherTag = c.motherTag;
      _originalFatherTag = c.fatherTag;

      _dateOfBirth = c.dateOfBirth;

      // Set dropdown values, ensuring they exist in the options list
      _sex = sexOptions.contains(c.sex) ? c.sex : null;
      if (_sex != null) {
        final currentClassificationOptions = classificationOptions;
        _classification = currentClassificationOptions.contains(c.classification)
            ? c.classification
            : null;
      }
      // Handle source and source details (kept separate; no combined string)
      _source = sourceOptions.contains(c.source) ? c.source : null;
      _sourceDetails = (c.sourceDetails != null && c.sourceDetails!.isNotEmpty)
          ? c.sourceDetails
          : null;
    } else if (widget.preSelectedClassification != null) {
      // If we have a pre-selected classification for new cattle
      _classification = widget.preSelectedClassification;
      _handleClassificationSelection(widget.preSelectedClassification!);
      // If a pre-selected sex was provided (e.g., Male Growers), prefill it
      if (widget.preSelectedSex != null && (widget.preSelectedClassification == 'Growers' || widget.preSelectedClassification == 'Calf')) {
        _sex = widget.preSelectedSex;
      }
    }
  }

  /// Handle classification selection and auto-fill related fields
  void _handleClassificationSelection(String classification) {
    setState(() {
      _classification = classification;
      
      // Auto-fill sex based on classification (only for new cattle with pre-selected classification)
      if (widget.preSelectedClassification != null && widget.cattle == null) {
        if (classification == 'Cow' || classification == 'Heifer') {
          _sex = 'Female';
        } else if (classification == 'Bull' || classification == 'Steer') {
          _sex = 'Male';
        }
        // For Growers and Calf, sex remains null for user selection
      }
      
      // Generate tag based on classification (only for new cattle)
      if (widget.cattle == null) {
        _generateTagForClassification(classification);
      }
    });
    _validateAgeClassificationMatch();
  }

  /// Generate tag number based on classification
  Future<void> _generateTagForClassification(String classification) async {
    setState(() => _isGeneratingTag = true);

    try {
      // Reload existing tags to ensure we have the latest data
      await _loadExistingTags();

      String newTag = _generateTagForClassificationType(classification);

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

  /// Generate tag number using web admin logic (random 6-digit numbers)
  String _generateTagForClassificationType(String classification) {
    // Use web admin logic: generate random 6-digit numbers (100000 to 999999)
    const int maxAttempts = 1000;
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      // Generate a random 6-digit number (100000 to 999999)
      final random = Random();
      final randomNumber = random.nextInt(900000) + 100000; // 100000 to 999999
      
      // Format as 6-digit string with leading zeros
      final tagNumber = randomNumber.toString().padLeft(6, '0');
      
      // Check if this random number is unique
      if (_isTagNumberUnique(tagNumber)) {
        // Add to recently generated tags
        _recentlyGeneratedTags.add(tagNumber.toLowerCase());
        return tagNumber;
      }
      
      attempts++;
    }
    
    // If we can't find a random unique number after many attempts,
    // fall back to sequential approach starting from a random point
    final random = Random();
    final randomStart = random.nextInt(999999) + 1;
    int nextNumber = randomStart;
    
    for (int i = 0; i < 999999; i++) {
      final tagNumber = nextNumber.toString().padLeft(6, '0');
      
      if (_isTagNumberUnique(tagNumber)) {
        // Add to recently generated tags
        _recentlyGeneratedTags.add(tagNumber.toLowerCase());
        return tagNumber;
      }
      
      nextNumber++;
      if (nextNumber > 999999) {
        nextNumber = 1;
      }
    }
    
    // Final fallback - use timestamp-based number
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fallbackTag = (timestamp % 900000 + 100000).toString().padLeft(6, '0');
    
    // Add to recently generated tags
    _recentlyGeneratedTags.add(fallbackTag.toLowerCase());
    return fallbackTag;
  }
  
  /// Check if tag number is unique (not in existing tags or recently generated)
  bool _isTagNumberUnique(String tagNumber) {
    final lowerTag = tagNumber.toLowerCase();
    return !_existingTags.contains(lowerTag) && 
           !_recentlyGeneratedTags.contains(lowerTag);
  }

  /// Fetches all cattle from the service and filters them by gender for parent selection
  Future<void> _fetchParentData() async {
    setState(() => _isLoadingParents = true);

    final allCattle = await CattleService.getAllCattle();
    // Exclude the current cattle being edited from the list of potential parents
    final potentialParents = allCattle.where((c) => c.id != widget.cattle?.id).toList();

    if (mounted) {
      setState(() {
        _femaleCattle = potentialParents.where((c) => c.sex == 'Female').toList();
        _maleCattle = potentialParents.where((c) => c.sex == 'Male').toList();

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
  Future<void> _selectDate(BuildContext context) async {
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
        _dateOfBirth = formatted;
      });
      _validateAgeClassificationMatch();
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

    // Resolve breed value (handle Other)
    String? resolvedBreed;
    if (_breed == 'Other') {
      final other = _otherBreedController.text.trim();
      if (other.isEmpty) {
        _showErrorSnackBar('Please enter the other breed');
        return;
      }
      resolvedBreed = other;
    } else {
      resolvedBreed = _breed;
    }

    // Common data for both create and update
    final Map<String, dynamic> data = {
      'tag_no': tagToCheck,
      'date_of_birth': _dateOfBirth,
      'sex': _sex,
      'weight': double.tryParse(_weightController.text),
      'classification': _classification,
      'breed': textOrNull(resolvedBreed),
      // 'group_name': textOrNull(_groupName), // Commented out: Group Name removed from payload
      'source': _source,
      'source_details': _sourceDetails,
      'mother_tag': _motherTag,
      'father_tag': _fatherTag,
      // 'notes': textOrNull(_notesController.text), // Commented out: Notes removed from payload
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
        if (widget.cattle == null) {
          // Show "Add Another" dialog for new cattle
          _showAddAnotherDialog();
        } else {
          // For updates, just show success message and close
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cattle updated successfully!'),
              backgroundColor: AppColors.vibrantGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // If success is false but no exception was thrown, show generic error
        _showErrorSnackBar('Failed to save cattle information. Please try again.');
      }
    }
  }

  /// Show dialog asking if user wants to add another cattle of the same classification
  void _showAddAnotherDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.vibrantGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_getClassificationLabel()} added successfully.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.vibrantGreen,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Add another ${_classification?.toLowerCase() ?? 'cattle'}?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Close form and return to cattle list
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _resetFormForNewCattle(); // Reset form for new cattle of same classification
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  /// Reset form for adding another cattle of the same classification
  void _resetFormForNewCattle() {
    setState(() {
      // Reset all form fields
      _tagNoController.clear();
      _weightController.clear();
      // _notesController.clear(); // Commented out: Notes field removed
      _otherBreedController.clear();
      
      // Reset dropdown values
      _breed = null;
      // _groupName = null; // Commented out: Group Name field removed
      _motherTag = null;
      _fatherTag = null;
      _dateOfBirth = null;
      _source = null;
      _sourceDetails = null;
      
      // Clear recently generated tags for new cattle
      _recentlyGeneratedTags.clear();
      
      // Keep the same classification and pre-fill sex if applicable
      if (widget.preSelectedClassification != null) {
        _handleClassificationSelection(widget.preSelectedClassification!);
      } else {
        _sex = null;
        _classification = null;
      }
    });
  }

  String _getClassificationLabel() {
    final classification = _classification?.trim();
    if (classification == null || classification.isEmpty) {
      return 'Cattle';
    }
    if (classification.length == 1) {
      return classification.toUpperCase();
    }
    return classification[0].toUpperCase() + classification.substring(1).toLowerCase();
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
  // ignore: unused_element
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
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => _selectDate(context),
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

  // Builds a small warning below fields when age and classification mismatch
  Widget _buildAgeWarning() {
    if (_ageClassificationWarning == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.gold, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _ageClassificationWarning!,
              style: TextStyle(color: AppColors.gold, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  // Validate selected classification vs age inferred from DOB
  void _validateAgeClassificationMatch() {
    if (_dateOfBirth == null || _classification == null || _sex == null) {
      setState(() => _ageClassificationWarning = null);
      return;
    }

    try {
      final dob = DateTime.parse(_dateOfBirth!);
      final now = DateTime.now();
      int months = (now.year - dob.year) * 12 + (now.month - dob.month);
      if (now.day < dob.day) {
        months = months - 1;
      }
      if (months < 0) months = 0;

      final expected = CattleAgeClassification.getExpectedClassification(months, _sex!);
      if (expected != _classification) {
        final diffDays = now.difference(dob).inDays;
        String ageDisplay;
        if (diffDays < 30) {
          ageDisplay = diffDays == 1 ? '1 day' : '$diffDays days';
        } else if (months < 12) {
          ageDisplay = months == 1 ? '1 month' : '$months months';
        } else {
          final years = months ~/ 12;
          final remMonths = months % 12;
          ageDisplay = remMonths == 0
              ? (years == 1 ? '1 year' : '$years years')
              : (years == 1
                  ? '1 year, $remMonths ${remMonths == 1 ? 'month' : 'months'}'
                  : '$years years, $remMonths ${remMonths == 1 ? 'month' : 'months'}');
        }

        setState(() {
          _ageClassificationWarning = 'Age of $ageDisplay suggests "$expected"';
        });
      } else {
        setState(() => _ageClassificationWarning = null);
      }
    } catch (_) {
      setState(() => _ageClassificationWarning = null);
    }
  }

  /// Build fixed Breed dropdown with Other text field
  Widget _buildBreedField() {
    final List<String> options = List<String>.from(_breedOptions);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: options.contains(_breed) ? _breed : null,
          isExpanded: true,
          autovalidateMode: AutovalidateMode.always,
          validator: (value) => (value == null || value.isEmpty)
              ? 'Breed is required'
              : null,
          hint: const Text('Select Breed (Required)'),
          decoration: InputDecoration(
            labelText: 'Breed (Required)',
            prefixIcon: Icon(FontAwesomeIcons.cow, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            fillColor: AppColors.cardBackground,
            filled: true,
            // helperText removed; labeled as (Required)
          ),
          // hint moved above with required text
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('None'),
            ),
            ...options.map((option) => DropdownMenuItem<String>(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _breed = value;
              if (value != 'Other') {
                _otherBreedController.clear();
              }
            });
          },
          menuMaxHeight: MediaQuery.of(context).size.height * 0.3,
        ),
        if (_breed == 'Other') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _otherBreedController,
            decoration: InputDecoration(
              labelText: 'Specify Breed (Required)',
              hintText: 'Enter breed (Required)',
              prefixIcon: Icon(Icons.edit, color: AppColors.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              fillColor: AppColors.cardBackground,
              filled: true,
              // helperText removed; labeled as (Required)
            ),
            validator: (value) {
              if (_breed == 'Other' && (value == null || value.trim().isEmpty)) {
                return 'Please specify the breed';
              }
              return null;
            },
          ),
        ],
      ],
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

  /// Build classification field (read-only if pre-selected)
  Widget _buildClassificationField() {
    final isPreSelected = widget.preSelectedClassification != null;
    final isEditing = widget.cattle != null;

    // Lock classification for pre-selected classifications (new cattle from FAB menu)
    // For editing existing cattle, allow classification changes
    final shouldLockClassification = isPreSelected && !isEditing;
    
    return DropdownButtonFormField<String>(
      value: _classification,
      validator: (value) => value == null ? 'Classification is required' : null,
      isExpanded: true,
      autovalidateMode: AutovalidateMode.always,
      hint: const Text('Select Classification (Required)'),
      decoration: InputDecoration(
        labelText: 'Classification (Required)',
        prefixIcon: Icon(Icons.category, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        fillColor: shouldLockClassification ? Colors.grey[100] : AppColors.cardBackground,
        filled: true,
        suffixIcon: shouldLockClassification 
          ? Icon(Icons.lock, color: Colors.grey[600])
          : null,
        // helperText removed; labeled as (Required)
      ),
      // hint is defined once above; removing duplicate
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('None'),
        ),
        ...((widget.preSelectedClassification != null && !isEditing
            ? ['Cow', 'Bull', 'Heifer', 'Steer', 'Growers', 'Calf']
            : classificationOptions)).map((option) => DropdownMenuItem(
              value: option,
              child: Text(option),
            )),
      ],
      onChanged: shouldLockClassification ? null : (value) {
        if (value != null) {
          _handleClassificationSelection(value);
        }
      },
    );
  }

  /// Build sex field with conditional logic
  Widget _buildSexField() {
    final isEditing = widget.cattle != null;
    final preSelectedClassification = widget.preSelectedClassification;
    final hasPreSelectedSex = widget.preSelectedSex != null;
    
    // For editing existing cattle, always allow sex selection
    // For new cattle with pre-selected classification:
    // - Allow sex selection for Growers and Calf
    // - Auto-fill and lock for Cow, Bull, Heifer, Steer
    final isGrowersOrCalf = preSelectedClassification == 'Growers' || preSelectedClassification == 'Calf';
    final allowSexSelection = isEditing || (!hasPreSelectedSex && (isGrowersOrCalf || preSelectedClassification == null));
    
    return DropdownButtonFormField<String>(
      value: _sex,
      validator: (value) => value == null ? 'Sex is required' : null,
      isExpanded: true,
      autovalidateMode: AutovalidateMode.always,
      hint: const Text('Select Sex (Required)'),
      decoration: InputDecoration(
        labelText: 'Sex (Required)',
        prefixIcon: Icon(Icons.wc, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        fillColor: !allowSexSelection ? Colors.grey[100] : AppColors.cardBackground,
        filled: true,
        suffixIcon: !allowSexSelection 
          ? Icon(Icons.lock, color: Colors.grey[600])
          : null,
        // helperText removed; labeled as (Required)
      ),
      // hint moved above with required text
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('None'),
        ),
        ...sexOptions.map((option) => DropdownMenuItem(
              value: option,
              child: Text(option),
            )),
      ],
      onChanged: allowSexSelection ? (value) {
        setState(() {
          _sex = value;
          // Reset classification if sex changes and no pre-selected classification
          if (widget.preSelectedClassification == null) {
            _classification = null;
          }
        });
        _validateAgeClassificationMatch();
      } : null,
    );
  }

  /// NEW: Build auto-generated tag field with refresh button
  Widget _buildAutoTagField() {
    return TextFormField(
      controller: _tagNoController,
      validator: (value) => value?.isEmpty == true ? 'Tag number is required' : null,
      autovalidateMode: AutovalidateMode.always,
      decoration: InputDecoration(
        labelText: 'Tag Number (Required)',
        hintText: 'Enter tag number (Required)',
        prefixIcon: Icon(Icons.label, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        fillColor: AppColors.cardBackground,
        filled: true,
        // helperText removed; labeled as (Required)
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
                    // Sex field (hidden in add mode for Cow/Bull/Heifer/Steer; visible for Growers/Calf)
                    if (!(
                      widget.cattle == null && (
                        widget.preSelectedClassification == 'Cow' ||
                        widget.preSelectedClassification == 'Bull' ||
                        widget.preSelectedClassification == 'Heifer' ||
                        widget.preSelectedClassification == 'Steer'
                      )
                    ))
                      _buildSexField(),
                    const SizedBox(height: 16),
                    // Classification field (read-only if pre-selected)
                    _buildClassificationField(),
                    _buildAgeWarning(),
                    const SizedBox(height: 16),
                    // Tag number field
                    _buildAutoTagField(),
                    const SizedBox(height: 16),
                    // Date of Birth
                    _buildDateField(
        label: 'Date of Birth (Optional)',
                      value: _dateOfBirth,
                      icon: Icons.cake,
                    ),
                    _buildAgeWarning(),
                    const SizedBox(height: 16),
                    // Moved here: Breed and Weight fields
                    _buildBreedField(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _weightController,
        label: 'Weight (kg) (Optional)',
                      icon: Icons.monitor_weight,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),


              // Source Details Section
              _buildSectionTitle('Source Details', Icons.agriculture),
              _buildCard(
                child: Column(
                  children: [
                    // Custom source dropdown that can show combined information
                    DropdownButtonFormField<String>(
                      value: _source,
                      autovalidateMode: AutovalidateMode.always,
                      validator: (value) => value == null ? 'Source is required' : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Source (Required)',
                        hintText: 'Select Source (Required)',
                        prefixIcon: Icon(Icons.source, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                        fillColor: AppColors.cardBackground,
                        filled: true,
                        // helperText removed; labeled as (Required)
                      ),
                      hint: const Text('Select Source (Required)'),
                      items: const [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text('None'),
                        ),
                      ] + [
                        ...sourceOptions.map((option) => DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _source = value;
                          if (value != 'Purchased' && value != 'Other') {
                            _sourceDetails = null;
                          }
                        });
                      },
                    ),
                    if (_source == 'Purchased' || _source == 'Other') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _sourceDetails ?? '',
                        onChanged: (val) => _sourceDetails = val.trim().isEmpty ? null : val.trim(),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: (_source == 'Purchased' ? 'Purchase Source' : 'Acquisition Details') + ' (Optional)',
                          hintText: _source == 'Purchased'
                              ? 'e.g., John Smith Farm, Market XYZ, Auction House ABC'
                              : 'e.g., Gift from neighbor, Inheritance, Trade, etc.',
                          prefixIcon: Icon(_source == 'Purchased' ? Icons.shopping_cart : Icons.info, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                          fillColor: AppColors.cardBackground,
                          filled: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Parental Line Section
              _buildSectionTitle('Parental Line', Icons.family_restroom),
              _buildCard(
                child: Column(
                  children: [
                    _buildSearchableDropdown(
                      label: 'Dam Tag (Mother) (Optional)',
                      value: _motherTag,
                      options: _femaleCattle,
                      onChanged: (value) => setState(() => _motherTag = value),
                      icon: Icons.female,
                    ),
                    const SizedBox(height: 16),
                    _buildSearchableDropdown(
                      label: 'Sire Tag (Father) (Optional)',
                      value: _fatherTag,
                      options: _maleCattle,
                      onChanged: (value) => setState(() => _fatherTag = value),
                      icon: Icons.male,
                    ),
                  ],
                ),
              ),

              // Additional Notes Section (removed)
              // _buildSectionTitle('Additional Notes', Icons.note),
              // _buildCard(
              //   child: _buildTextField(
              //     controller: _notesController,
              //     label: 'Notes',
              //     icon: Icons.notes,
              //     maxLines: 4,
              //   ),
              // ),

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
                    widget.cattle == null ? 'Submit' : 'Update Cattle',
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
    _weightController.dispose();
    // _notesController.dispose(); // Commented out: Notes field removed
    super.dispose();
  }
}