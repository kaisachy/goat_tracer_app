import 'dart:developer';
import 'package:cattle_tracer_app/screens/nav/cattle/widgets/details/section_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/utils/cattle_detail_utils.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/cattle_detail_screen.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_service.dart';

class CattleLineageCard extends StatelessWidget {
  final Cattle cattle;

  const CattleLineageCard({super.key, required this.cattle});

  Future<List<String>> _getValidOffspringTags() async {
    if (cattle.offspring == null || cattle.offspring!.isEmpty) {
      return [];
    }
    List<String> offspringTags = cattle.offspring!
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    List<String> validTags = [];
    for (String tag in offspringTags) {
      final offspringCattle = await CattleService.getCattleByTag(tag);
      if (offspringCattle != null) {
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
          color: AppColors.darkGreen.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withOpacity(0.08),
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
            icon: Icons.family_restroom,
            title: 'Genealogy',
            color: AppColors.darkGreen,
          ),
          const SizedBox(height: 24),
          _buildParentInfoGrid(context, [
            _ParentInfoItemData(
              icon: Icons.woman,
              title: 'Dam (Mother)',
              value: CattleDetailUtils.getParentDisplay(cattle.motherTag),
              tag: cattle.motherTag,
            ),
            _ParentInfoItemData(
              icon: Icons.man,
              title: 'Sire (Father)',
              value: CattleDetailUtils.getParentDisplay(cattle.fatherTag),
              tag: cattle.fatherTag,
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.darkGreen.withOpacity(0.15),
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
      onTap: () => _navigateToCattleDetail(context, tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.darkGreen.withOpacity(0.3),
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
                color: AppColors.darkGreen.withOpacity(0.1),
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
        color: AppColors.darkGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.darkGreen.withOpacity(0.15),
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
                  onTap: () => _navigateToCattleDetail(context, item.tag!),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.darkGreen.withOpacity(0.1),
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

  void _navigateToCattleDetail(BuildContext context, String tag) async {
    log('Navigating to cattle detail for tag: $tag');
    if (tag.trim().isEmpty) {
      _showInvalidTag(context, tag);
      return;
    }
    try {
      final cattle = await CattleService.getCattleByTag(tag);
      if (cattle != null) {
        // TODO: Update this to a proper navigation solution if needed, e.g. Navigator.pushNamed
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CattleDetailScreen(cattle: cattle),
          ),
        );
      } else {
        _showCattleNotFound(context, tag);
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
        content: const Text('Cannot navigate to cattle with empty or invalid tag.'),
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
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      final cattle = await CattleService.getCattleByTag(tag);
      Navigator.pop(context);
      if (cattle != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CattleDetailScreen(cattle: cattle),
          ),
        );
      } else {
        _showCattleNotFound(context, tag);
      }
    } catch (fallbackError) {
      Navigator.pop(context);
      log('Direct navigation also failed: $fallbackError');
      _showNavigationError(context, tag, fallbackError.toString());
    }
  }

  void _showCattleNotFound(BuildContext context, String tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cattle Not Found'),
        content: Text('No cattle found with tag: $tag\n\nThe cattle may have been removed or the tag may be incorrect.'),
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
        content: Text('Unable to navigate to cattle with tag: $tag\n\nError: $error'),
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
