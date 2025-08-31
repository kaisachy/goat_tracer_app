import 'package:flutter/material.dart';
import '../../../../../constants/app_colors.dart';

class ScheduleHeader extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onSearchClear;
  final Widget child;

  const ScheduleHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(context),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 400;

        return Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: isNarrow ? 44 : 48,
            maxHeight: isNarrow ? 44 : 48,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: TextStyle(fontSize: isNarrow ? 13 : 14),
            textAlign: TextAlign.left,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: isNarrow ? 18 : 20,
              ),
              suffixIcon: searchController.text.isNotEmpty == true
                  ? IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  color: Colors.grey.shade400,
                  size: isNarrow ? 16 : 18,
                ),
                onPressed: onSearchClear,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.all(isNarrow ? 6 : 8),
              )
                  : null,
              hintText: isNarrow ? 'Search schedules...' : 'Search schedules, cattle, veterinarian...',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: isNarrow ? 12 : 13,
              ),
              filled: false,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 12 : 16,
                vertical: isNarrow ? 10 : 12,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        );
      },
    );
  }
}