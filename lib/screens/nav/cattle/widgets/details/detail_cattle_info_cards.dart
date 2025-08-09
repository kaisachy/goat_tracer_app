// lib/screens/nav/cattle/widgets/detail_cattle_info_cards.dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/utils/cattle_detail_utils.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/cattle_detail_screen.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_service.dart';

class CattleBasicInfoCard extends StatelessWidget {
  final Cattle cattle;

  const CattleBasicInfoCard({super.key, required this.cattle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.info_outline,
            title: 'Basic Information',
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          _buildInfoGrid([
            _InfoItemData(
              icon: Icons.cake,
              title: 'Age',
              value: CattleDetailUtils.getAgeFromDob(cattle.dateOfBirth),
            ),
            _InfoItemData(
              icon: Icons.event,
              title: 'Date of Birth',
              value: CattleDetailUtils.formatDate(cattle.dateOfBirth),
            ),
            _InfoItemData(
              icon: CattleDetailUtils.getGenderIcon(cattle.gender),
              title: 'Gender',
              value: cattle.gender,
            ),
            _InfoItemData(
              icon: Icons.category,
              title: 'Classification',
              value: CattleDetailUtils.getClassificationDisplay(cattle.classification),
            ),
            _InfoItemData(
              icon: FontAwesomeIcons.cow,
              title: 'Breed',
              value: CattleDetailUtils.getBreedDisplay(cattle.breed),
            ),
            _InfoItemData(
              icon: Icons.monitor_weight,
              title: 'Weight',
              value: CattleDetailUtils.formatWeight(cattle.weight),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(List<_InfoItemData> items) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < items.length ? 16 : 0),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoItem(items[i]),
                ),
                if (i + 1 < items.length) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoItem(items[i + 1]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoItem(_InfoItemData item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, color: AppColors.primary, size: 16),
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
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class CattleLineageCard extends StatelessWidget {
  final Cattle cattle;

  const CattleLineageCard({super.key, required this.cattle});

  // New method to asynchronously get a list of valid offspring tags
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
      // Assuming getCattleByTag returns null if not found
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
          _buildSectionHeader(
            icon: Icons.family_restroom,
            title: 'Lineage Information',
            color: AppColors.darkGreen,
          ),
          const SizedBox(height: 24),
          _buildParentInfoGrid(context, [
            _ParentInfoItemData(
              icon: Icons.woman,
              title: 'Mother',
              value: CattleDetailUtils.getParentDisplay(cattle.motherTag),
              tag: cattle.motherTag,
            ),
            _ParentInfoItemData(
              icon: Icons.man,
              title: 'Father',
              value: CattleDetailUtils.getParentDisplay(cattle.fatherTag),
              tag: cattle.fatherTag,
            ),
          ]),
          const SizedBox(height: 16),
          // Offspring section - full width with navigatable tags
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
          return const Text(
            'Error loading offspring data.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          );
        } else if (snapshot.data == null || snapshot.data!.isEmpty) {
          return const Text(
            'No offspring recorded',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          );
        } else {
          List<String> offspringTags = snapshot.data!;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: offspringTags.map((tag) => _buildOffspringTag(context, tag)).toList(),
          );
        }
      },
    );
  }

  Widget _buildOffspringTag(BuildContext context, String tag) {
    return Container(
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
          GestureDetector(
            onTap: () => _navigateToCattleDetail(context, tag),
            child: Container(
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
          ),
        ],
      ),
    );
  }

  void _navigateToCattleDetail(BuildContext context, String tag) async {
    log('Navigating to cattle detail for tag: $tag');

    // Check if tag is valid
    if (tag.trim().isEmpty) {
      _showInvalidTag(context, tag);
      return;
    }

    try {
      // Method 1: Using named routes (recommended)
      final cattle = await CattleService.getCattleByTag(tag);
      if (cattle != null) {
        Navigator.pushNamed(
          context,
          '/cattle-detail',
          arguments: {'tag': tag},
        );
      } else {
        _showCattleNotFound(context, tag);
      }
    } catch (e) {
      log('Named route navigation failed: $e');

      // Method 2: Direct navigation with cattle fetching
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
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Fetch cattle data using static method
      final cattle = await CattleService.getCattleByTag(tag);

      // Hide loading indicator
      Navigator.pop(context);

      if (cattle != null) {
        // Navigate to cattle detail screen
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
      // Hide loading indicator if still showing
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

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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
              // Add search icon for parents if they exist
              if (hasParent) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _navigateToCattleDetail(context, item.tag!),
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
}

class CattleManagementCard extends StatelessWidget {
  final Cattle cattle;

  const CattleManagementCard({super.key, required this.cattle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.lightGreen.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightGreen.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.manage_accounts,
            title: 'Management Information',
            color: AppColors.lightGreen,
          ),
          const SizedBox(height: 24),
          _buildInfoGrid([
            _InfoItemData(
              icon: Icons.home,
              title: 'Source',
              value: CattleDetailUtils.getSourceDisplay(cattle.source),
            ),
            _InfoItemData(
              icon: Icons.groups,
              title: 'Group',
              value: CattleDetailUtils.getGroupDisplay(cattle.groupName),
            ),
          ]),
          const SizedBox(height: 16),
          // Joined date - full width
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.lightGreen.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.lightGreen, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Joined Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  CattleDetailUtils.formatDate(cattle.joinedDate),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(List<_InfoItemData> items) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(child: _buildInfoItem(items[i])),
          if (i < items.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _buildInfoItem(_InfoItemData item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.lightGreen.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, color: AppColors.lightGreen, size: 16),
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
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class CattleNotesSection extends StatelessWidget {
  final Cattle cattle;

  const CattleNotesSection({super.key, required this.cattle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
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
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.note_alt,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Additional Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Text(
              CattleDetailUtils.getNotesDisplay(cattle.notes),
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: CattleDetailUtils.hasNotes(cattle.notes)
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontStyle: CattleDetailUtils.hasNotes(cattle.notes)
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for parent info item data with navigation support
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

// Helper class for info item data
class _InfoItemData {
  final IconData icon;
  final String title;
  final String value;

  const _InfoItemData({
    required this.icon,
    required this.title,
    required this.value,
  });
}