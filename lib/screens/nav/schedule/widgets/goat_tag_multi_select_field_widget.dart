import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../constants/app_colors.dart';
import '../../../../models/goat.dart';
import '../modals/goat_multi_select_dialog.dart';

class goatTagMultiSelectField extends StatelessWidget {
  final List<String> selectedgoatTags;
  final List<goat> goatList;
  final bool isLoadinggoat;
  final Function(List<String>) ongoatTagsChanged;
  final VoidCallback onRefreshgoat;
  final Set<String>? scheduledTagsForVaccine; // uppercase tags that are already scheduled

  const goatTagMultiSelectField({
    super.key,
    required this.selectedgoatTags,
    required this.goatList,
    required this.isLoadinggoat,
    required this.ongoatTagsChanged,
    required this.onRefreshgoat,
    this.scheduledTagsForVaccine,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Goat Tags',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            if (isLoadinggoat)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Enhanced dropdown field with selected goat displayed inside
        InkWell(
          onTap: isLoadinggoat || goatList.isEmpty ? null : () => _showgoatMultiSelectDialog(context),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // <-- This is the corrected line
              children: [
                FaIcon(
                  FontAwesomeIcons.Doe,
                  color: AppColors.darkGreen,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: selectedgoatTags.isEmpty
                      ? Text(
                    isLoadinggoat
                        ? 'Loading goat...'
                        : goatList.isEmpty
                        ? 'No goat available'
                        : 'Select goat',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  )
                      : Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: selectedgoatTags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                final updatedTags = List<String>.from(selectedgoatTags);
                                updatedTags.remove(tag);
                                ongoatTagsChanged(updatedTags);
                              },
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),

        if (goatList.isEmpty && !isLoadinggoat) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'No goat found. Add Goat first or refresh the list.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _showgoatMultiSelectDialog(BuildContext context) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => goatMultiSelectDialog(
        goatList: goatList,
        initialSelectedTags: selectedgoatTags,
        scheduledTagsForVaccine: scheduledTagsForVaccine ?? const {},
      ),
    );

    if (result != null) {
      ongoatTagsChanged(result);
    }
  }
}
