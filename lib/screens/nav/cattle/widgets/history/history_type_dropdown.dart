// lib/screens/nav/cattle/widgets/history/history_type_dropdown.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../../constants/app_colors.dart';
import '../../../../../models/cattle.dart';
import '../../../../../utils/history_type_utils.dart';
import '../../../../../services/cattle/cattle_history_service.dart';


class HistoryTypeDropdown extends StatefulWidget {
  final Cattle? cattleDetails;
  final String selectedHistoryType;
  final Map<String, TextEditingController> controllers;
  final ValueChanged<String?> onHistoryTypeChanged;
  final Function(DateTime)? onHistoryDateSelected; // Add callback for date selection
  final bool locked;

  const HistoryTypeDropdown({
    super.key,
    required this.cattleDetails,
    required this.selectedHistoryType,
    required this.controllers,
    required this.onHistoryTypeChanged,
    this.onHistoryDateSelected, // Add this parameter
    this.locked = false,
  });

  @override
  HistoryTypeDropdownState createState() => HistoryTypeDropdownState();
}

class HistoryTypeDropdownState extends State<HistoryTypeDropdown> {
  late List<String> filteredHistoryTypes = const [];

  @override
  void initState() {
    super.initState();
    _filterDropdownTypes();
  }

  @override
  void didUpdateWidget(covariant HistoryTypeDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-filter if cattleDetails changed
    if (oldWidget.cattleDetails?.tagNo != widget.cattleDetails?.tagNo) {
      _filterDropdownTypes();
    }
  }

  Future<void> _filterDropdownTypes() async {
    final allTypes = HistoryTypeUtils.getHistoryTypesForSex(
      widget.cattleDetails?.sex,
      classification: widget.cattleDetails?.classification,
    );
    List<String> filtered = List<String>.from(allTypes);
    if (widget.cattleDetails != null) {
      final eventsForTag = await CattleHistoryService.getCattleHistoryByTag(widget.cattleDetails!.tagNo);
      final hasSick = eventsForTag.any((e) => (e['history_type']?.toString().toLowerCase() ?? '') == 'sick');
      final hasBreeding = eventsForTag.any((e) => (e['history_type']?.toString().toLowerCase() ?? '') == 'breeding');
      final hasPregnant = eventsForTag.any((e) => (e['history_type']?.toString().toLowerCase() ?? '') == 'pregnant');
      if (filtered.contains('Treated') && !hasSick) {
        filtered = filtered.where((type) => type != 'Treated').toList();
      }
      if (filtered.contains('Pregnant') && !hasBreeding) {
        filtered = filtered.where((type) => type != 'Pregnant').toList();
      }
      if (filtered.contains('Gives Birth') && !hasPregnant) {
        filtered = filtered.where((type) => type != 'Gives Birth').toList();
      }
      if (filtered.contains('Aborted Pregnancy')) {
        final classification = widget.cattleDetails!.classification.toLowerCase();
        bool isEligibleClass = classification == 'cow' || classification == 'heifer';
        // Find the latest Pregnant history record
        final pregnantEvents = eventsForTag.where((e) => (e['history_type']?.toString().toLowerCase() ?? '') == 'pregnant').toList();
        if (pregnantEvents.isNotEmpty && isEligibleClass) {
          // Get the latest Pregnant record by date
          pregnantEvents.sort((a, b) {
            try {
              final da = DateTime.parse(a['history_date']);
              final db = DateTime.parse(b['history_date']);
              return db.compareTo(da);
            } catch (_) {
              return 0;
            }
          });
          final latestPregnant = pregnantEvents.first;
          final latestPregnantDate = latestPregnant['history_date'];
          // Look for any Gives Birth history after this date
          final givesBirthAfterPregnant = eventsForTag.any((e) {
            if ((e['history_type']?.toString().toLowerCase() ?? '') != 'gives birth') return false;
            try {
              final givesBirthDate = DateTime.parse(e['history_date']);
              final pregnantDate = DateTime.parse(latestPregnantDate);
              return givesBirthDate.isAfter(pregnantDate) || givesBirthDate.isAtSameMomentAs(pregnantDate);
            } catch (_) {
              return false;
            }
          });
          if (givesBirthAfterPregnant) {
            filtered = filtered.where((type) => type != 'Aborted Pregnancy').toList();
          }
        } else {
          filtered = filtered.where((type) => type != 'Aborted Pregnancy').toList();
        }
      }
    }
    filteredHistoryTypes = filtered;
    setState(() {});
  }

  List<String> get historyTypes => filteredHistoryTypes;

  // Helper method to show date picker and update controller
  Future<void> _selectHistoryDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
      controller.text = formattedDate;

      print('Date selected in dropdown: $formattedDate'); // Debug print

      // FIXED: Trigger the callback to notify parent widget about date selection
      if (widget.onHistoryDateSelected != null) {
        print('Calling onHistoryDateSelected callback with date: $picked'); // Debug print
        widget.onHistoryDateSelected!(picked);
      } else {
        print('onHistoryDateSelected callback is null!'); // Debug print
      }

      // Force a rebuild to ensure UI updates
      if (mounted) {
        setState(() {});
      }
    }
  }

  Widget _buildHistoryDateField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary),
          // Removed suffixIcon
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.lightGreen),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () => _selectHistoryDate(context, controller),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Date is required';
          }
          return null;
        },
      ),
    );
  }

  bool _attemptedValidation = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history, color: AppColors.primary, size: 20),
                    if (widget.locked) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.lock, color: AppColors.primary, size: 16),
                    ]
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'History Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // History Type Dropdown
          SizedBox(
            width: double.infinity,
            child: DropdownButtonFormField<String>(
              autovalidateMode: _attemptedValidation ? AutovalidateMode.always : AutovalidateMode.disabled,
              value: historyTypes.contains(widget.selectedHistoryType) ? widget.selectedHistoryType : 'Select type of history record',
            items: historyTypes.map((type) {
              final isPlaceholder = type == 'Select type of history record';
              final isLoading = type == 'Loading cattle information...';

              return DropdownMenuItem(
                value: type,
                enabled: !isLoading,
                child: isPlaceholder || isLoading
                    ? Text(
                  type,
                  style: TextStyle(
                    color: isLoading
                        ? Colors.grey
                        : AppColors.textSecondary.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                )
                    : Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: HistoryTypeUtils.getHistoryColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        HistoryTypeUtils.getHistoryIcon(type),
                        size: 16,
                        color: HistoryTypeUtils.getHistoryColor(type),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        type,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            selectedItemBuilder: (BuildContext context) {
              return historyTypes.map<Widget>((String value) {
                if (value == 'Select type of history record') {
                  return Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }

                if (value == 'Loading cattle information...') {
                  return Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }

                return Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList();
            },
            onChanged: (widget.cattleDetails == null || widget.locked)
                ? null
                : (val) {
                    widget.onHistoryTypeChanged(val);
                    setState(() => _attemptedValidation = true);
                  },
            decoration: InputDecoration(
              labelText: 'History Type',
              prefixIcon: Container(
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(5),
                child: Container(
                  decoration: BoxDecoration(
                    color: HistoryTypeUtils.getHistoryColor(widget.selectedHistoryType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    widget.selectedHistoryType == 'Select type of history record'
                        ? Icons.history
                        : HistoryTypeUtils.getHistoryIcon(widget.selectedHistoryType),
                    color: widget.selectedHistoryType == 'Select type of history record'
                        ? AppColors.textSecondary
                        : HistoryTypeUtils.getHistoryColor(widget.selectedHistoryType),
                    size: 16,
                  ),
                ),
              ),
              labelStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: widget.locked ? Colors.grey.shade100 : AppColors.lightGreen.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: widget.locked ? Colors.grey.shade300 : AppColors.lightGreen.withOpacity(0.2),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: AppColors.vibrantGreen,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 16,
                bottom: 16,
              ),
              isDense: true,
            ),
            validator: (value) {
              if (!_attemptedValidation) return null;
              if (value == null || value == 'Select type of history record') {
                return 'Please select a history type';
              }
              if (value == 'Loading cattle information...') {
                return 'Please wait for cattle information to load';
              }
              return null;
            },
            ),
          ),
          const SizedBox(height: 20),

          // Date with Calendar Picker
          _buildHistoryDateField(
            label: 'Date',
            controller: widget.controllers['history_date']!,
            hint: 'Select date',
            icon: FontAwesomeIcons.calendarDays,
          ),
        ],
      ),
    );
  }
}