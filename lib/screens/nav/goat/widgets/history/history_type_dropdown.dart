// lib/screens/nav/goat/widgets/history/history_type_dropdown.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../../constants/app_colors.dart';
import '../../../../../models/goat.dart';
import '../../../../../utils/history_type_utils.dart';
import '../../../../../services/goat/goat_history_service.dart';


class HistoryTypeDropdown extends StatefulWidget {
  final Goat? goatDetails;
  final String selectedHistoryType;
  final Map<String, TextEditingController> controllers;
  final ValueChanged<String?> onHistoryTypeChanged;
  final Function(DateTime)? onHistoryDateSelected; // Add callback for date selection
  final bool locked;

  const HistoryTypeDropdown({
    super.key,
    required this.goatDetails,
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
    // Re-filter if goatDetails changed
    if (oldWidget.goatDetails?.tagNo != widget.goatDetails?.tagNo) {
      _filterDropdownTypes();
    }
  }

  Future<void> _filterDropdownTypes() async {
    final allTypes = HistoryTypeUtils.getHistoryTypesForSex(
      widget.goatDetails?.sex,
      classification: widget.goatDetails?.classification,
    );
    List<String> filtered = List<String>.from(allTypes);
    if (widget.goatDetails != null) {
      final eventsForTag = await GoatHistoryService.getgoatHistoryByTag(widget.goatDetails!.tagNo);
      final hasSick = eventsForTag.any((e) => (e['history_type']?.toString().toLowerCase() ?? '') == 'sick');
      DateTime? latestClosureDate;
      for (final event in eventsForTag) {
        final type = (event['history_type']?.toString().toLowerCase() ?? '');
        if (type != 'gives birth' && type != 'aborted pregnancy') continue;
        final rawDate = event['history_date']?.toString();
        final parsedDate = DateTime.tryParse(rawDate ?? '');
        if (parsedDate == null) continue;
        if (latestClosureDate == null || parsedDate.isAfter(latestClosureDate)) {
          latestClosureDate = parsedDate;
        }
      }
      bool hasBreedingAfterClosure = false;
      bool hasPregnantAfterClosure = false;
      for (final event in eventsForTag) {
        final type = (event['history_type']?.toString().toLowerCase() ?? '');
        final rawDate = event['history_date']?.toString();
        final parsedDate = DateTime.tryParse(rawDate ?? '');
        if (parsedDate == null) continue;
        final isAfterClosure = latestClosureDate == null || parsedDate.isAfter(latestClosureDate);
        if (!isAfterClosure) continue;
        if (!hasBreedingAfterClosure && type == 'breeding') {
          hasBreedingAfterClosure = true;
        }
        if (!hasPregnantAfterClosure && type == 'pregnant') {
          hasPregnantAfterClosure = true;
        }
        if (hasBreedingAfterClosure && hasPregnantAfterClosure) {
          break;
        }
      }
      if (filtered.contains('Treated') && !hasSick) {
        filtered = filtered.where((type) => type != 'Treated').toList();
      }
      if (filtered.contains('Pregnant') && !hasBreedingAfterClosure) {
        filtered = filtered.where((type) => type != 'Pregnant').toList();
      }
      if (filtered.contains('Gives Birth') && !hasPregnantAfterClosure) {
        filtered = filtered.where((type) => type != 'Gives Birth').toList();
      }
      if (filtered.contains('Aborted Pregnancy')) {
        final classification = widget.goatDetails!.classification.toLowerCase();
        final isEligibleClass = classification == 'doe' || classification == 'doeling';
        if (!isEligibleClass || !hasPregnantAfterClosure) {
          filtered = filtered.where((type) => type != 'Aborted Pregnancy').toList();
        }
      }
    }
    final currentType = widget.selectedHistoryType.trim();
    final currentLower = currentType.toLowerCase();
    if (currentType.isNotEmpty &&
        !filtered.contains(currentType) &&
        !currentLower.startsWith('select type') &&
        !currentLower.startsWith('loading')) {
      filtered = [currentType, ...filtered];
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

      debugPrint('Date selected in dropdown: $formattedDate'); // Debug print

      // FIXED: Trigger the callback to notify parent widget about date selection
      if (widget.onHistoryDateSelected != null) {
        debugPrint('Calling onHistoryDateSelected callback with date: $picked'); // Debug print
        widget.onHistoryDateSelected!(picked);
      } else {
        debugPrint('onHistoryDateSelected callback is null!'); // Debug print
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

  Widget _buildHistoryIcon(String historyType, Color color, {double size = 16}) {
    final imagePath = HistoryTypeUtils.getHistoryImagePath(historyType);
    if (imagePath != null) {
      // Make images slightly smaller than icons
      final imageSize = size * 0.85;
      return Image.asset(
        imagePath,
        width: imageSize,
        height: imageSize,
        fit: BoxFit.contain,
        color: color,
        colorBlendMode: BlendMode.srcIn,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails to load
          return Icon(HistoryTypeUtils.getHistoryIcon(historyType), color: color, size: size);
        },
      );
    } else {
      return Icon(HistoryTypeUtils.getHistoryIcon(historyType), color: color, size: size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.08),
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
                  color: AppColors.primary.withValues(alpha: 0.15),
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
              final isLoading = type == 'Loading goat information...';

              return DropdownMenuItem(
                value: type,
                enabled: !isLoading,
                child: isPlaceholder || isLoading
                    ? Text(
                  type,
                  style: TextStyle(
                    color: isLoading
                        ? Colors.grey
                        : AppColors.textSecondary.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                )
                    : Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: HistoryTypeUtils.getHistoryColor(type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: _buildHistoryIcon(
                          type,
                          HistoryTypeUtils.getHistoryColor(type),
                          size: 16,
                        ),
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
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }

                if (value == 'Loading goat information...') {
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
            onChanged: (widget.goatDetails == null || widget.locked)
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
                    color: widget.selectedHistoryType == 'Select type of history record'
                        ? AppColors.textSecondary.withValues(alpha: 0.1)
                        : HistoryTypeUtils.getHistoryColor(widget.selectedHistoryType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: widget.selectedHistoryType == 'Select type of history record'
                        ? Icon(
                            Icons.history,
                            color: AppColors.textSecondary,
                            size: 16,
                          )
                        : _buildHistoryIcon(
                            widget.selectedHistoryType,
                            HistoryTypeUtils.getHistoryColor(widget.selectedHistoryType),
                            size: 16,
                          ),
                  ),
                ),
              ),
              labelStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: widget.locked ? Colors.grey.shade100 : AppColors.lightGreen.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: widget.locked ? Colors.grey.shade300 : AppColors.lightGreen.withValues(alpha: 0.2),
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
              if (value == 'Loading goat information...') {
                return 'Please wait for goat information to load';
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
