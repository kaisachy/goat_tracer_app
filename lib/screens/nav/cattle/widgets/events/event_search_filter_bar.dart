import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';

class EventSearchFilterBar extends StatefulWidget {
  final String initialSearchQuery;
  final String initialEventType;
  final List<String> eventTypes;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onClearFilter;

  const EventSearchFilterBar({
    super.key,
    required this.initialSearchQuery,
    required this.initialEventType,
    required this.eventTypes,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onClearFilter,
  });

  @override
  State<EventSearchFilterBar> createState() => _EventSearchFilterBarState();
}

class _EventSearchFilterBarState extends State<EventSearchFilterBar> {
  late TextEditingController _searchController;
  late String selectedEventType;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchQuery);
    selectedEventType = widget.initialEventType;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list_rounded,
                  color: AppColors.vibrantGreen, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Filter Events',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.eventTypes.map((type) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: RadioListTile<String>(
                      // 🔧 MODIFIED: Replaced Text with a Row containing an Icon and Text
                      title: Row(
                        children: [
                          Icon(
                            _getEventIcon(type),
                            color: _getEventColor(type),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              type,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      value: type,
                      groupValue: selectedEventType,
                      activeColor: AppColors.vibrantGreen,
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() => selectedEventType = value);
                          widget.onFilterChanged(value);
                        }
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => selectedEventType = 'All');
                widget.onClearFilter();
                Navigator.of(context).pop();
              },
              child: Text(
                'Clear Filter',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 8),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 400;

        // 🔧 MODIFIED: Removed the main Container and its decorations
        return _buildInlineLayout(isNarrow);
      },
    );
  }

  Widget _buildInlineLayout(bool isNarrow) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Field - Takes most of the space
          Expanded(
            flex: isNarrow ? 3 : 4,
            child: _buildSearchField(isNarrow),
          ),
          SizedBox(width: isNarrow ? 8 : 12),
          // Filter Button - Fixed width
          _buildCompactFilterButton(isNarrow),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isNarrow) {
    return Container(
      constraints: BoxConstraints(minHeight: isNarrow ? 44 : 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          widget.onSearchChanged(value);
          setState(() {}); // Update clear button visibility
        },
        style: TextStyle(fontSize: isNarrow ? 13 : 14),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.lightGreen,
            size: isNarrow ? 18 : 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.clear_rounded,
              color: Colors.grey.shade400,
              size: isNarrow ? 16 : 18,
            ),
            onPressed: () {
              _searchController.clear();
              widget.onSearchChanged('');
              setState(() {});
            },
            constraints: const BoxConstraints(),
            padding: EdgeInsets.all(isNarrow ? 6 : 8),
          )
              : null,
          hintText:
          isNarrow ? 'Search event...' : 'Search event, notes, diagnosis...',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: isNarrow ? 12 : 13,
          ),
          filled: false,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 12 : 16,
            vertical: isNarrow ? 10 : 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.vibrantGreen, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactFilterButton(bool isNarrow) {
    final isFiltered = selectedEventType != 'All';

    return Container(
      constraints: BoxConstraints(
        minHeight: isNarrow ? 44 : 48,
        minWidth: isNarrow ? 44 : 48,
        maxWidth: isNarrow ? 80 : 120,
      ),
      decoration: BoxDecoration(
        color: isFiltered ? AppColors.vibrantGreen : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isFiltered
            ? null
            : Border.all(
          color: AppColors.lightGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _showFilterDialog,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 8 : 12,
              vertical: isNarrow ? 8 : 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  color: isFiltered ? Colors.white : AppColors.lightGreen,
                  size: isNarrow ? 18 : 20,
                ),
                if (!isNarrow && isFiltered) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      selectedEventType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
                if (isFiltered) ...[
                  SizedBox(width: isNarrow ? 2 : 4),
                  Container(
                    width: isNarrow ? 6 : 8,
                    height: isNarrow ? 6 : 8,
                    decoration: BoxDecoration(
                      color: isFiltered
                          ? Colors.white.withOpacity(0.8)
                          : AppColors.vibrantGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper methods for icons, colors, and date formatting
IconData _getEventIcon(String eventType) {
  switch (eventType.toLowerCase()) {
    case 'breeding':
      return Icons.favorite_rounded;
    case 'weighed':
      return Icons.monitor_weight_rounded;
    case 'gives birth':
      return Icons.child_care_rounded;
    case 'vaccinated':
      return Icons.vaccines_rounded;
    case 'pregnant':
      return Icons.pregnant_woman_rounded;
    case 'treated':
      return Icons.medical_services_rounded;
    case 'dry off':
      return Icons.pause_circle_rounded;
    case 'deworming':
      return Icons.pest_control_rounded;
    case 'hoof trimming':
      return Icons.content_cut_rounded;
    case 'castrated':
      return Icons.minor_crash_rounded;
    case 'weaned':
      return Icons.rss_feed_rounded;
    case 'aborted pregnancy':
      return Icons.heart_broken_rounded;
    case 'other':
      return Icons.more_horiz_rounded;
    case 'all':
      return Icons.filter_list_rounded;
    default:
      return Icons.event_note_rounded;
  }
}

Color _getEventColor(String eventType) {
  switch (eventType.toLowerCase()) {
    case 'breeding':
      return Colors.pink.shade400;
    case 'weighed':
      return Colors.orange.shade500;
    case 'gives birth':
      return Colors.blue.shade400;
    case 'vaccinated':
      return Colors.green.shade500;
    case 'pregnant':
      return Colors.purple.shade400;
    case 'treated':
      return Colors.red.shade400;
    case 'dry off':
      return Colors.grey.shade500;
    case 'deworming':
      return Colors.yellow.shade600;
    case 'hoof trimming':
      return Colors.brown.shade400;
    case 'castrated':
      return Colors.indigo.shade400;
    case 'weaned':
      return Colors.teal.shade400;
    case 'aborted pregnancy':
      return Colors.red.shade600;
    case 'other':
      return Colors.blueGrey.shade400;
    case 'all':
      return AppColors.vibrantGreen;
    default:
      return AppColors.lightGreen;
  }
}