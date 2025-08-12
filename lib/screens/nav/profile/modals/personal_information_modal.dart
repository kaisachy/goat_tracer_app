// lib/screens/nav/profile/modals/personal_information_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/services/profile/personal_information_service.dart';

class PersonalInformationModal extends StatefulWidget {
  final bool isEditingMode;
  final VoidCallback onSaveSuccess;

  const PersonalInformationModal({
    super.key,
    required this.isEditingMode,
    required this.onSaveSuccess,
  });

  @override
  State<PersonalInformationModal> createState() => _PersonalInformationModalState();
}

class _PersonalInformationModalState extends State<PersonalInformationModal> with TickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController genderController;
  late final TextEditingController birthdateController;
  late final TextEditingController statusController;
  late final TextEditingController contactController;
  late final TextEditingController provinceController;
  late final TextEditingController muniController;
  late final TextEditingController brgyController;

  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _personalInformation;
  String? _selectedGender;
  String? _selectedStatus;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _statusOptions = ['Single', 'Married', 'Divorced', 'Widowed'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _fetchData();
  }

  void _initializeControllers() {
    genderController = TextEditingController();
    birthdateController = TextEditingController();
    statusController = TextEditingController();
    contactController = TextEditingController();
    provinceController = TextEditingController();
    muniController = TextEditingController();
    brgyController = TextEditingController();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    _slideController.forward();
  }

  Future<void> _fetchData() async {
    try {
      final data = await PersonalInformationService.getPersonalInformation();
      if (mounted) {
        setState(() {
          _personalInformation = data;
          _populateControllers(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load data: $e');
      }
    }
  }

  void _populateControllers(Map<String, dynamic>? data) {
    genderController.text = data?['gender'] ?? '';
    birthdateController.text = data?['birthdate'] ?? '';
    statusController.text = data?['marital_status'] ?? '';
    contactController.text = data?['contact_number'] ?? '';
    _selectedGender = data?['gender'];
    _selectedStatus = data?['marital_status'];
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    genderController.dispose();
    birthdateController.dispose();
    statusController.dispose();
    contactController.dispose();
    provinceController.dispose();
    muniController.dispose();
    brgyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 24,
                  right: 24,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    Flexible(
                      child: _isLoading ? _buildLoadingState() : _buildContent(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Drag handle
        Container(
          height: 4,
          width: 50,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isEditingMode ? 'Edit your details' : 'View your information',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isEditingMode && !_isLoading)
              _buildSaveButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.vibrantGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isSaving ? null : _savePersonalInfo,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _isSaving
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  _isSaving ? 'Saving...' : 'Save',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightGreen.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading your information...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: 'Personal Details',
                icon: Icons.account_circle_outlined,
                children: [
                  if (widget.isEditingMode) ...[
                    _buildGenderDropdown(),
                    const SizedBox(height: 16),
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildStatusDropdown(),
                    const SizedBox(height: 16),
                    _buildContactField(),
                  ] else ...[
                    _buildModernInfoTile('Gender', _personalInformation?['gender'] ?? 'N/A', Icons.wc_rounded),
                    _buildModernInfoTile('Birthdate', _personalInformation?['birthdate'] ?? 'N/A', Icons.cake_rounded),
                    _buildModernInfoTile('Status', _personalInformation?['marital_status'] ?? 'N/A', Icons.favorite_rounded),
                    _buildModernInfoTile('Contact', _personalInformation?['contact_number'] ?? 'N/A', Icons.phone_rounded),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: _getInputDecoration('Gender', Icons.wc_rounded),
      items: _genderOptions.map((gender) => DropdownMenuItem(
        value: gender,
        child: Text(gender),
      )).toList(),
      onChanged: (value) {
        setState(() {
          _selectedGender = value;
          genderController.text = value ?? '';
        });
      },
      validator: (value) => value?.isEmpty == true ? 'Gender is required' : null,
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: _getInputDecoration('Marital Status', Icons.favorite_rounded),
      items: _statusOptions.map((status) => DropdownMenuItem(
        value: status,
        child: Text(status),
      )).toList(),
      onChanged: (value) {
        setState(() {
          _selectedStatus = value;
          statusController.text = value ?? '';
        });
      },
      validator: (value) => value?.isEmpty == true ? 'Marital status is required' : null,
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: birthdateController,
      decoration: _getInputDecoration('Birthdate', Icons.cake_rounded),
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          birthdateController.text = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        }
      },
      validator: (value) => value?.isEmpty == true ? 'Birthdate is required' : null,
    );
  }

  Widget _buildContactField() {
    return TextFormField(
      controller: contactController,
      decoration: _getInputDecoration('Contact Number', Icons.phone_rounded),
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
      ],
      validator: (value) {
        if (value?.isEmpty == true) return 'Contact number is required';
        if (value!.length < 10) return 'Contact number must be at least 10 digits';
        return null;
      },
    );
  }

  InputDecoration _getInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.lightGreen.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 18,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: AppColors.cardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildModernInfoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.vibrantGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _savePersonalInfo() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final Map<String, dynamic> updateData = {
        'gender': genderController.text.trim(),
        'birthdate': birthdateController.text.trim(),
        'marital_status': statusController.text.trim(),
        'contact_number': contactController.text.trim(),
      };

      bool success;
      if (_personalInformation?['id'] == null) {
        success = await PersonalInformationService.storePersonalInformation(updateData);
      } else {
        success = await PersonalInformationService.updatePersonalInformation(updateData);
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        if (success) {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
          _showSuccessSnackBar('Personal information saved successfully!');
          widget.onSaveSuccess();
        } else {
          _showErrorSnackBar('Failed to save. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _showErrorSnackBar('An error occurred: $e');
      }
    }
  }
}