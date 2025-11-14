import 'dart:developer';
import 'package:goat_tracer_app/screens/nav/goat/widgets/details/section_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/utils/goat_detail_utils.dart';
import 'package:goat_tracer_app/screens/nav/goat/goat_detail_screen.dart';
import 'package:goat_tracer_app/services/goat/goat_service.dart';

class goatLineageCard extends StatelessWidget {
  final goat goat;

  const goatLineageCard({super.key, required this.goat});

  Future<List<String>> _getValidOffspringTags() async {
    if (goat.offspring == null || goat.offspring!.isEmpty) {
      return [];
    }
    List<String> offspringTags = goat.offspring!
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    List<String> validTags = [];
    for (String tag in offspringTags) {
      final offspringgoat = await GoatService.getGoatByTag(tag);
      if (offspringgoat != null) {
        validTags.add(tag);
      }
    }
    return validTags;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.darkGreen.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeaderWidget(
            icon: Icons.account_tree,
            title: 'Parental Line',
            color: AppColors.darkGreen,
          ),
          const SizedBox(height: 24),
          _buildParentInfoGrid(context, [
            _ParentInfoItemData(
              icon: Icons.female,
              title: 'Dam (Mother)',
              value: goatDetailUtils.getParentDisplay(goat.motherTag),
              tag: goat.motherTag,
            ),
            _ParentInfoItemData(
              icon: Icons.male,
              title: 'Sire (Father)',
              value: goatDetailUtils.getParentDisplay(goat.fatherTag),
              tag: goat.fatherTag,
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.darkGreen.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FontAwesomeIcons.sitemap, color: AppColors.darkGreen, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Offspring',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildOffspringTags(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffspringTags(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _getValidOffspringTags(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          log('Error fetching offspring: ${snapshot.error}');
          return const Center(
            child: Text(
              'Error loading offspring data.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        } else if (snapshot.data == null || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No offspring recorded',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        } else {
          List<String> offspringTags = snapshot.data!;
          return Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: offspringTags.map((tag) => _buildOffspringTag(context, tag)).toList(),
            ),
          );
        }
      },
    );
  }

  Widget _buildOffspringTag(BuildContext context, String tag) {
    return GestureDetector(
      onTap: () => _navigateTogoatDetail(context, tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.darkGreen.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.darkGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.search,
                color: AppColors.darkGreen,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentInfoGrid(BuildContext context, List<_ParentInfoItemData> items) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(child: _buildParentInfoItem(context, items[i])),
          if (i < items.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _buildParentInfoItem(BuildContext context, _ParentInfoItemData item) {
    final hasParent = item.tag != null && item.tag!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.darkGreen.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, color: AppColors.darkGreen, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: hasParent ? AppColors.textPrimary : AppColors.textSecondary,
                    fontStyle: hasParent ? FontStyle.normal : FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasParent) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _navigateTogoatDetail(context, item.tag!),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.darkGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.search,
                      color: AppColors.darkGreen,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _navigateTogoatDetail(BuildContext context, String tag) async {
    log('Navigating to goat detail for tag: $tag');
    if (tag.trim().isEmpty) {
      _showInvalidTag(context, tag);
      return;
    }
    try {
      final navigator = Navigator.of(context);
      final goat = await GoatService.getGoatByTag(tag);
      if (!context.mounted) return;
      if (goat != null) {
        // TODO: Update this to a proper navigation solution if needed, e.g. Navigator.pushNamed
        navigator.push(
          MaterialPageRoute(
            builder: (context) => goatDetailScreen(goat: goat),
          ),
        );
      } else {
        _showgoatNotFound(context, tag);
      }
    } catch (e) {
      log('Named route navigation failed: $e');
      _navigateDirectly(context, tag);
    }
  }

  void _showInvalidTag(BuildContext context, String tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid Tag'),
        content: const Text('Cannot navigate to goat with empty or invalid tag.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateDirectly(BuildContext context, String tag) async {
    final navigator = Navigator.of(context);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      final goat = await GoatService.getGoatByTag(tag);
      if (!context.mounted) return;
      navigator.pop();
      if (goat != null) {
        navigator.push(
          MaterialPageRoute(
            builder: (context) => goatDetailScreen(goat: goat),
          ),
        );
      } else {
        _showgoatNotFound(context, tag);
      }
    } catch (fallbackError) {
      if (context.mounted && navigator.canPop()) {
        navigator.pop();
      }
      log('Direct navigation also failed: $fallbackError');
      if (context.mounted) {
        _showNavigationError(context, tag, fallbackError.toString());
      }
    }
  }

  void _showgoatNotFound(BuildContext context, String tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('goat Not Found'),
        content: Text('No goat found with tag: $tag\n\nThe goat may have been removed or the tag may be incorrect.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNavigationError(BuildContext context, String tag, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Navigation Error'),
        content: Text('Unable to navigate to goat with tag: $tag\n\nError: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ParentInfoItemData {
  final IconData icon;
  final String title;
  final String value;
  final String? tag;
  const _ParentInfoItemData({
    required this.icon,
    required this.title,
    required this.value,
    this.tag,
  });
}

