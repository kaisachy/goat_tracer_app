// lib/screens/nav/profile/modals/personal_information_modal.dart
import 'package:flutter/material.dart';
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

class _PersonalInformationModalState extends State<PersonalInformationModal> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController genderController;
  late final TextEditingController birthdateController;
  late final TextEditingController statusController;
  late final TextEditingController contactController;
  late final TextEditingController provinceController;
  late final TextEditingController muniController;
  late final TextEditingController brgyController;

  bool _isLoading = true;
  Map<String, dynamic>? _personalInformation;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    genderController = TextEditingController();
    birthdateController = TextEditingController();
    statusController = TextEditingController();
    contactController = TextEditingController();
    provinceController = TextEditingController();
    muniController = TextEditingController();
    brgyController = TextEditingController();

    // Fetch data when the modal opens
    _fetchData();
  }

  Future<void> _fetchData() async {
    final data = await PersonalInformationService.getPersonalInformation();
    if (mounted) {
      setState(() {
        _personalInformation = data;
        // Populate controllers with fetched data
        genderController.text = data?['gender'] ?? '';
        birthdateController.text = data?['birthdate'] ?? '';
        statusController.text = data?['marital_status'] ?? '';
        contactController.text = data?['contact_number'] ?? '';
        provinceController.text = data?['province'] ?? '';
        muniController.text = data?['municipality'] ?? '';
        brgyController.text = data?['barangay'] ?? '';

        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // This header is always visible
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // Only show save button if in edit mode AND not loading
                if (widget.isEditingMode && !_isLoading)
                  TextButton(
                    onPressed: _savePersonalInfo,
                    child: const Text('Save'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // The content area is conditional
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              _buildFormContent(),
          ],
        ),
      ),
    );
  }

  /// Builds the main form content after data has loaded
  Widget _buildFormContent() {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (widget.isEditingMode) ...[
            TextFormField(
              controller: genderController,
              decoration: const InputDecoration(labelText: 'Gender'),
            ),
            TextFormField(
              controller: birthdateController,
              decoration: const InputDecoration(labelText: 'Birthdate'),
            ),
            TextFormField(
              controller: statusController,
              decoration: const InputDecoration(labelText: 'Marital Status'),
            ),
            TextFormField(
              controller: contactController,
              decoration: const InputDecoration(labelText: 'Contact Number'),
            ),
          ] else ...[
            _buildInfoTile('Gender', _personalInformation?['gender'] ?? 'N/A'),
            _buildInfoTile('Birthdate', _personalInformation?['birthdate'] ?? 'N/A'),
            _buildInfoTile('Marital Status', _personalInformation?['marital_status'] ?? 'N/A'),
            _buildInfoTile('Contact Number', _personalInformation?['contact_number'] ?? 'N/A'),
          ],
          const SizedBox(height: 16),
          const Text(
            'Address',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (widget.isEditingMode) ...[
            TextFormField(
              controller: provinceController,
              decoration: const InputDecoration(labelText: 'Province'),
            ),
            TextFormField(
              controller: muniController,
              decoration: const InputDecoration(labelText: 'Municipality'),
            ),
            TextFormField(
              controller: brgyController,
              decoration: const InputDecoration(labelText: 'Barangay'),
            ),
            const SizedBox(height: 20),
          ] else ...[
            _buildInfoTile('Province', _personalInformation?['province'] ?? 'N/A'),
            _buildInfoTile('Municipality', _personalInformation?['municipality'] ?? 'N/A'),
            _buildInfoTile('Barangay', _personalInformation?['barangay'] ?? 'N/A'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePersonalInfo() async {
    if (formKey.currentState!.validate()) {
      final Map<String, dynamic> updateData = {
        'gender': genderController.text,
        'birthdate': birthdateController.text,
        'marital_status': statusController.text,
        'contact_number': contactController.text,
        'province': provinceController.text,
        'municipality': muniController.text,
        'barangay': brgyController.text,
      };

      bool success = false;
      if (_personalInformation?['id'] == null) {
        success = await PersonalInformationService.storePersonalInformation(updateData);
      } else {
        success = await PersonalInformationService.updatePersonalInformation(updateData);
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Personal information saved successfully!' : 'Save failed. Please try again.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) widget.onSaveSuccess();
      }
    }
  }
}