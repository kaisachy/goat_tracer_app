// lib/screens/nav/profile/modals/farm_details_modal.dart
import 'package:flutter/material.dart';
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Farm Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (widget.isEditingMode)
                    TextButton(
                      onPressed: _saveFarmDetails,
                      child: const Text('Save'),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (widget.isEditingMode) ...[
                TextFormField(
                  controller: farmNameController,
                  decoration: const InputDecoration(labelText: 'Farm Name'),
                ),
                TextFormField(
                  controller: farmTypeController,
                  decoration: const InputDecoration(labelText: 'Farm Type'),
                ),
                TextFormField(
                  controller: farmClassificationController,
                  decoration: const InputDecoration(labelText: 'Farm Classification'),
                ),
                TextFormField(
                  controller: farmAreaController,
                  decoration: const InputDecoration(labelText: 'Farm Land Area (hectares)'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: coopController,
                  decoration: const InputDecoration(labelText: 'Cooperative Affiliation'),
                ),
                const SizedBox(height: 20),
              ] else ...[
                _buildInfoTile('Farm Name', widget.farmDetails?['farm_name'] ?? 'N/A'),
                _buildInfoTile('Farm Type', widget.farmDetails?['farm_type'] ?? 'N/A'),
                _buildInfoTile('Farm Classification', widget.farmDetails?['farm_classification'] ?? 'N/A'),
                _buildInfoTile('Farm Land Area', '${widget.farmDetails?['farm_land_area'] ?? 'N/A'} hectares'),
                _buildInfoTile('Cooperative Affiliation', widget.farmDetails?['cooperative_affiliation'] ?? 'N/A'),
              ],
            ],
          ),
        ),
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
            width: 140,
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

  Future<void> _saveFarmDetails() async {
    if (formKey.currentState!.validate()) {
      final Map<String, dynamic> updateData = {
        'farm_name': farmNameController.text,
        'farm_type': farmTypeController.text,
        'farm_classification': farmClassificationController.text,
        'farm_land_area': farmAreaController.text,
        'cooperative_affiliation': coopController.text,
      };

      bool success = false;
      if (widget.farmDetails?['id'] == null) {
        success = await FarmDetailsService.storeFarmDetails(updateData);
      } else {
        success = await FarmDetailsService.updateFarmDetails(updateData);
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Farm details saved successfully!'
                : 'Save failed. Please try again.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) widget.onSaveSuccess();
      }
    }
  }
}