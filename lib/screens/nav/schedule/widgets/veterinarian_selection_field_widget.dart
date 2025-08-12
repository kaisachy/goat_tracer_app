import 'package:flutter/material.dart';
import '../../../../models/user.dart';

class VeterinarianSelectionField extends StatelessWidget {
  final String? selectedVeterinarianId;
  final bool useCustomVeterinarian;
  final TextEditingController veterinarianController;
  final List<User> veterinarianList;
  final bool isLoadingVeterinarians;
  final Function(String?) onVeterinarianIdChanged;
  final Function(bool) onUseCustomChanged;
  final VoidCallback onRefreshVeterinarians;

  const VeterinarianSelectionField({
    super.key,
    required this.selectedVeterinarianId,
    required this.useCustomVeterinarian,
    required this.veterinarianController,
    required this.veterinarianList,
    required this.isLoadingVeterinarians,
    required this.onVeterinarianIdChanged,
    required this.onUseCustomChanged,
    required this.onRefreshVeterinarians,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        _buildRadioButtons(),
        const SizedBox(height: 8),
        _buildInputField(),
        if (veterinarianList.isEmpty && !isLoadingVeterinarians) 
          _buildInfoMessage(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          'Veterinarian',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        if (isLoadingVeterinarians)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildRadioButtons() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Radio<bool>(
                value: false,
                groupValue: useCustomVeterinarian,
                onChanged: veterinarianList.isNotEmpty ? (value) {
                  onUseCustomChanged(value!);
                } : null,
              ),
              const Text('Select from list'),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: useCustomVeterinarian,
                onChanged: (value) {
                  onUseCustomChanged(value!);
                },
              ),
              const Text('Enter manually'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField() {
    if (!useCustomVeterinarian) {
      return _buildDropdownField();
    } else {
      return _buildTextFormField();
    }
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: selectedVeterinarianId,
      decoration: InputDecoration(
        hintText: isLoadingVeterinarians
            ? 'Loading veterinarians...'
            : veterinarianList.isEmpty
            ? 'No veterinarians available'
            : 'Select a veterinarian',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.person),
        suffixIcon: veterinarianList.isNotEmpty ? IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefreshVeterinarians,
          tooltip: 'Refresh veterinarians',
        ) : null,
      ),
      selectedItemBuilder: (BuildContext context) {
        return veterinarianList.map((vet) {
          return Text('${vet.firstName} ${vet.lastName}');
        }).toList();
      },
      items: veterinarianList.map((vet) {
        return DropdownMenuItem(
          value: vet.id.toString(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${vet.firstName} ${vet.lastName}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                vet.role.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: veterinarianList.isNotEmpty ? (value) {
        onVeterinarianIdChanged(value);
      } : null,
    );
  }

  Widget _buildTextFormField() {
    return TextFormField(
      controller: veterinarianController,
      decoration: InputDecoration(
        hintText: 'Enter veterinarian name',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.person),
      ),
    );
  }

  Widget _buildInfoMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'No PVO/LGU veterinarians found. You can enter manually or refresh the list.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}