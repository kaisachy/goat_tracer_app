//milk_record_form.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/milk.dart';
import '../../../models/cattle.dart';
import '../../../constants/app_colors.dart';

class MilkRecordFormScreen extends StatefulWidget {
  final MilkProduction? record;
  final List<Cattle> allCattle;
  final bool isEditing;

  const MilkRecordFormScreen({
    super.key,
    this.record,
    required this.allCattle,
    this.isEditing = false,
  });

  @override
  State<MilkRecordFormScreen> createState() => _MilkRecordFormScreenState();
}

class _MilkRecordFormScreenState extends State<MilkRecordFormScreen> {
  late TextEditingController morningController;
  late TextEditingController eveningController;
  late TextEditingController notesController;
  final _formKey = GlobalKey<FormState>();

  String? selectedCattleTag;
  String selectedQuality = 'A';
  String selectedMilkType = 'Individual Cow Milk';
  late DateTime selectedDate;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    morningController = TextEditingController(
      text: widget.record?.morningYield?.toString() ?? '',
    );
    eveningController = TextEditingController(
      text: widget.record?.eveningYield?.toString() ?? '',
    );
    notesController = TextEditingController(
      text: widget.record?.notes ?? '',
    );

    selectedCattleTag = widget.record?.cattleTag;
    selectedQuality = widget.record?.milkQuality ?? 'A';
    selectedMilkType = widget.record?.milkType ?? 'Individual Cow Milk';
    selectedDate = widget.record?.recordDate ?? DateTime.now();
  }

  @override
  void dispose() {
    morningController.dispose();
    eveningController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Milk Record' : 'Add Milk Record',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.trash),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Milk Type Selection
                    _buildSectionTitle('Milk Type', FontAwesomeIcons.droplet),
                    const SizedBox(height: 12),
                    _buildMilkTypeSelector(),
                    const SizedBox(height: 24),

                    // Cattle Selection (only for individual cow milk)
                    if (selectedMilkType == 'Individual Cow Milk') ...[
                      _buildSectionTitle('Select Cow', FontAwesomeIcons.cow),
                      const SizedBox(height: 12),
                      _buildCattleSelector(),
                      const SizedBox(height: 24),
                    ],

                    // Date Selection
                    _buildSectionTitle('Record Date', FontAwesomeIcons.calendar),
                    const SizedBox(height: 12),
                    _buildDateSelector(),
                    const SizedBox(height: 24),

                    // Yield Section
                    _buildSectionTitle('Milk Yield', FontAwesomeIcons.scaleBalanced),
                    const SizedBox(height: 12),
                    _buildYieldSection(),
                    const SizedBox(height: 24),

                    // Quality Section
                    _buildSectionTitle('Quality Grade', FontAwesomeIcons.award),
                    const SizedBox(height: 12),
                    _buildQualityDropdown(),
                    const SizedBox(height: 24),

                    // Notes Section
                    _buildSectionTitle('Notes (Optional)', FontAwesomeIcons.noteSticky),
                    const SizedBox(height: 12),
                    _buildNotesField(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom action buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            widget.isEditing
                                ? FontAwesomeIcons.floppyDisk
                                : FontAwesomeIcons.plus,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.isEditing ? 'Update Record' : 'Save Record',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(
            icon,
            color: AppColors.primary,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMilkTypeSelector() {
    final milkTypes = ['Individual Cow Milk', 'Whole Farm Milk'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: milkTypes.map((type) {
          final isSelected = selectedMilkType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                selectedMilkType = type;
                if (selectedMilkType == 'Whole Farm Milk') {
                  selectedCattleTag = null;
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  type,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCattleSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedCattleTag,
        decoration: InputDecoration(
          labelText: 'Select Cow',
          labelStyle: TextStyle(color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Icon(
            FontAwesomeIcons.cow,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        items: widget.allCattle.isEmpty
            ? [const DropdownMenuItem(
          value: null,
          child: Text('No cows available'),
        )]
            : widget.allCattle.map((cattle) => DropdownMenuItem(
          value: cattle.tagNo,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text('Cattle #${cattle.tagNo}'),
            ],
          ),
        )).toList(),
        onChanged: widget.allCattle.isEmpty
            ? null
            : (value) => setState(() => selectedCattleTag = value),
        validator: (value) {
          if (selectedMilkType == 'Individual Cow Milk' && value == null) {
            return 'Please select a cow';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Icon(
          FontAwesomeIcons.calendar,
          color: AppColors.primary,
          size: 20,
        ),
        title: Text(
          'Record Date',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          _formatDate(selectedDate),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          FontAwesomeIcons.chevronRight,
          color: Colors.grey.shade400,
          size: 16,
        ),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            setState(() => selectedDate = date);
          }
        },
      ),
    );
  }

  Widget _buildYieldSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildYieldField(
                'Morning Yield (L)',
                morningController,
                FontAwesomeIcons.sun,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildYieldField(
                'Evening Yield (L)',
                eveningController,
                FontAwesomeIcons.moon,
                Colors.indigo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                FontAwesomeIcons.calculator,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Total Yield: ${_calculateTotal().toStringAsFixed(1)} L',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYieldField(String label, TextEditingController controller, IconData icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Icon(icon, color: iconColor, size: 20),
          suffixText: 'L',
        ),
        onChanged: (value) => setState(() {}), // Refresh total calculation
        validator: (value) {
          if (value != null && value.isNotEmpty) {
            final doubleValue = double.tryParse(value);
            if (doubleValue == null || doubleValue < 0) {
              return 'Enter valid yield';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildQualityDropdown() {
    final qualities = ['A+', 'A', 'B+', 'B', 'C'];

    Color getQualityColor(String quality) {
      switch (quality) {
        case 'A+': return Colors.green;
        case 'A': return Colors.lightGreen;
        case 'B+': return Colors.orange;
        case 'B': return Colors.deepOrange;
        default: return Colors.grey;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedQuality,
        decoration: InputDecoration(
          labelText: 'Select Quality Grade',
          labelStyle: TextStyle(color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Icon(
            FontAwesomeIcons.award,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        items: qualities.map((quality) => DropdownMenuItem(
          value: quality,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: getQualityColor(quality),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Text('Grade $quality'),
            ],
          ),
        )).toList(),
        onChanged: (value) => setState(() => selectedQuality = value ?? 'A'),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a quality grade';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: notesController,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: 'Add notes about this record...',
          labelStyle: TextStyle(color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(top: 16, left: 16),
            child: Icon(
              FontAwesomeIcons.noteSticky,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  double _calculateTotal() {
    final morning = double.tryParse(morningController.text) ?? 0.0;
    final evening = double.tryParse(eveningController.text) ?? 0.0;
    return morning + evening;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) {
      return 'Today';
    } else if (diff == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation
    if (selectedMilkType == 'Individual Cow Milk' && selectedCattleTag == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a cow for individual cow milk'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final morning = double.tryParse(morningController.text) ?? 0.0;
    final evening = double.tryParse(eveningController.text) ?? 0.0;

    if (morning <= 0 && evening <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one yield value'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Return the form data
    final result = {
      'milkType': selectedMilkType,
      'cattleTag': selectedCattleTag,
      'recordDate': selectedDate,
      'morningYield': morning > 0 ? morning : null,
      'eveningYield': evening > 0 ? evening : null,
      'quality': selectedQuality,
      'notes': notesController.text,
      'isEditing': widget.isEditing,
      'recordId': widget.record?.id,
    };

    Navigator.pop(context, result);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirm Delete'),
          ],
        ),
        content: const Text('Are you sure you want to delete this milk record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, {'delete': true, 'recordId': widget.record?.id}); // Return delete result
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}