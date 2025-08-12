// lib/screens/nav/profile/modals/farm_details_modal.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/services/profile/farm_details_service.dart';

class FarmDetailsModal extends StatefulWidget {
  final Map<String, dynamic>? farmDetails;
  final bool isEditingMode;
  final VoidCallback onSaveSuccess;

  const FarmDetailsModal({
    super.key,
    required this.farmDetails,
    required this.isEditingMode,
    required this.onSaveSuccess,
  });

  @override
  State<FarmDetailsModal> createState() => _FarmDetailsModalState();
}

class _FarmDetailsModalState extends State<FarmDetailsModal> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController farmNameController;
  late TextEditingController farmTypeController;
  late TextEditingController farmClassificationController;
  late TextEditingController farmAreaController;
  late TextEditingController coopController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final farm = widget.farmDetails;
    farmNameController = TextEditingController(text: farm?['farm_name'] ?? '');
    farmTypeController = TextEditingController(text: farm?['farm_type'] ?? '');
    farmClassificationController = TextEditingController(text: farm?['farm_classification'] ?? '');
    farmAreaController = TextEditingController(text: farm?['farm_land_area']?.toString() ?? '');
    coopController = TextEditingController(text: farm?['cooperative_affiliation'] ?? '');
  }

  @override
  void dispose() {
    farmNameController.dispose();
    farmTypeController.dispose();
    farmClassificationController.dispose();
    farmAreaController.dispose();
    coopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            _buildHeader(),

            const SizedBox(height: 24),

            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: widget.isEditingMode
                      ? _buildEditingForm()
                      : _buildViewContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const FaIcon(
            FontAwesomeIcons.seedling,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Farm Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                widget.isEditingMode
                    ? 'Edit your farm information'
                    : 'View your farm information',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (widget.isEditingMode)
          _buildSaveButton(),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
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
          onTap: _isLoading ? null : _saveFarmDetails,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  FontAwesomeIcons.floppyDisk,
                  size: 16,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  'Save',
                  style: TextStyle(
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

  Widget _buildEditingForm() {
    return Column(
      children: [
        _buildStyledTextField(
          controller: farmNameController,
          label: 'Farm Name',
          icon: FontAwesomeIcons.leaf,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter farm name';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        _buildStyledTextField(
          controller: farmTypeController,
          label: 'Farm Type',
          icon: FontAwesomeIcons.tractor,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter farm type';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        _buildStyledTextField(
          controller: farmClassificationController,
          label: 'Farm Classification',
          icon: FontAwesomeIcons.tags,
        ),
        const SizedBox(height: 20),

        _buildStyledTextField(
          controller: farmAreaController,
          label: 'Farm Land Area (hectares)',
          icon: FontAwesomeIcons.expand,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isNotEmpty == true) {
              final number = double.tryParse(value!);
              if (number == null || number <= 0) {
                return 'Please enter a valid area';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        _buildStyledTextField(
          controller: coopController,
          label: 'Cooperative Affiliation',
          icon: FontAwesomeIcons.handshake,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
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
            child: FaIcon(
              icon,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }

  Widget _buildViewContent() {
    return Column(
      children: [
        _buildInfoCard('Farm Name', widget.farmDetails?['farm_name'] ?? 'N/A', FontAwesomeIcons.leaf),
        const SizedBox(height: 16),

        _buildInfoCard('Farm Type', widget.farmDetails?['farm_type'] ?? 'N/A', FontAwesomeIcons.tractor),
        const SizedBox(height: 16),

        _buildInfoCard('Farm Classification', widget.farmDetails?['farm_classification'] ?? 'N/A', FontAwesomeIcons.shapes),
        const SizedBox(height: 16),

        _buildInfoCard('Farm Land Area', '${widget.farmDetails?['farm_land_area'] ?? 'N/A'} hectares', FontAwesomeIcons.expand),
        const SizedBox(height: 16),

        _buildInfoCard('Cooperative Affiliation', widget.farmDetails?['cooperative_affiliation'] ?? 'N/A', FontAwesomeIcons.handshake),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
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

  Future<void> _saveFarmDetails() async {
    if (formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final Map<String, dynamic> updateData = {
        'farm_name': farmNameController.text,
        'farm_type': farmTypeController.text,
        'farm_classification': farmClassificationController.text,
        'farm_land_area': farmAreaController.text,
        'cooperative_affiliation': coopController.text,
      };

      bool success = false;
      try {
        if (widget.farmDetails?['id'] == null) {
          success = await FarmDetailsService.storeFarmDetails(updateData);
        } else {
          success = await FarmDetailsService.updateFarmDetails(updateData);
        }
      } catch (e) {
        success = false;
      }

      setState(() => _isLoading = false);

      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                FaIcon(
                  success ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.circleXmark,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  success
                      ? 'Farm details saved successfully!'
                      : 'Save failed. Please try again.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: success ? AppColors.vibrantGreen : Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );

        if (success) widget.onSaveSuccess();
      }
    }
  }
}