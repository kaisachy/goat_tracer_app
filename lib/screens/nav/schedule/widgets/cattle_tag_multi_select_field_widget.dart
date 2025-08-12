import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../constants/app_colors.dart';
import '../../../../models/cattle.dart';
import '../modals/cattle_multi_select_dialog.dart';

class CattleTagMultiSelectField extends StatelessWidget {
  final List<String> selectedCattleTags;
  final List<Cattle> cattleList;
  final bool isLoadingCattle;
  final Function(List<String>) onCattleTagsChanged;
  final VoidCallback onRefreshCattle;

  const CattleTagMultiSelectField({
    super.key,
    required this.selectedCattleTags,
    required this.cattleList,
    required this.isLoadingCattle,
    required this.onCattleTagsChanged,
    required this.onRefreshCattle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Cattle Tags',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            if (isLoadingCattle)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Enhanced dropdown field with selected cattle displayed inside
        InkWell(
          onTap: isLoadingCattle || cattleList.isEmpty ? null : () => _showCattleMultiSelectDialog(context),
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
                  FontAwesomeIcons.cow,
                  color: AppColors.darkGreen,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: selectedCattleTags.isEmpty
                      ? Text(
                    isLoadingCattle
                        ? 'Loading cattle...'
                        : cattleList.isEmpty
                        ? 'No cattle available'
                        : 'Select cattle',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  )
                      : Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: selectedCattleTags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
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
                                final updatedTags = List<String>.from(selectedCattleTags);
                                updatedTags.remove(tag);
                                onCattleTagsChanged(updatedTags);
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

        if (cattleList.isEmpty && !isLoadingCattle) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'No cattle found. Add cattle first or refresh the list.',
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

  Future<void> _showCattleMultiSelectDialog(BuildContext context) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => CattleMultiSelectDialog(
        cattleList: cattleList,
        initialSelectedTags: selectedCattleTags,
      ),
    );

    if (result != null) {
      onCattleTagsChanged(result);
    }
  }
}