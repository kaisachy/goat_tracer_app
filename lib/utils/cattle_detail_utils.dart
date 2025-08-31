  // lib/utils/cattle_detail_utils.dart
  import 'package:flutter/material.dart';
  import 'package:cattle_tracer_app/constants/app_colors.dart';
  
  class CattleDetailUtils {
    /// Calculates age from date of birth string
    static String getAgeFromDob(String? dobString) {
      if (dobString == null || dobString.isEmpty) return 'Unknown';
  
      try {
        final dob = DateTime.parse(dobString);
        final now = DateTime.now();
        final difference = now.difference(dob);
  
        if (difference.inDays < 30) {
          return '${difference.inDays}d';
        } else if (difference.inDays < 365) {
          final months = (difference.inDays / 30).floor();
          return '${months}mo';
        } else {
          final years = (difference.inDays / 365).floor();
          return '${years}y';
        }
      } catch (e) {
        return 'Invalid';
      }
    }
  
    /// Gets color based on cattle status
    static Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'active':
          return AppColors.vibrantGreen;
        case 'inactive':
          return Colors.grey[600]!;
        case 'sold':
          return AppColors.gold;
        case 'deceased':
          return Colors.red[600]!;
        default:
          return AppColors.lightGreen;
      }
    }
  
    /// Formats date string for display
    static String formatDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) return 'Unknown';
  
      try {
        final date = DateTime.parse(dateString);
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return dateString; // Return original if parsing fails
      }
    }
  
    /// Validates if a string is a valid date
    static bool isValidDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) return false;
  
      try {
        DateTime.parse(dateString);
        return true;
      } catch (e) {
        return false;
      }
    }
  
    /// Gets gender icon based on gender string
    static IconData getGenderIcon(String gender) {
      switch (gender.toLowerCase()) {
        case 'male':
          return Icons.male;
        case 'female':
          return Icons.female;
        default:
          return Icons.help_outline;
      }
    }
  
    /// Gets gender color based on gender string
    static Color getGenderColor(String? gender) {
      switch (gender?.toLowerCase()) {
        case 'male':
          return Colors.blue;
        case 'female':
          return Colors.pink;
        default:
          return AppColors.textSecondary;
      }
    }
  
    /// Gets gender symbol based on gender string
    static String getGenderSymbol(String? gender) {
      switch (gender?.toLowerCase()) {
        case 'male':
          return '♂';
        case 'female':
          return '♀';
        default:
          return '?';
      }
    }
  
    /// Formats weight for display
    static String formatWeight(dynamic weight) {
      if (weight == null) return 'N/A kg';
      if (weight is String && weight.isEmpty) return 'N/A kg';
  
      return '$weight kg';
    }
  
    /// Gets classification display text
    static String getClassificationDisplay(String classification) {
      // You can add any formatting logic here
      return classification.isNotEmpty ? classification : 'Unknown';
    }
  
    /// Gets breed display text
    static String getBreedDisplay(String? breed) {
      return breed?.isNotEmpty == true ? breed! : 'Unknown';
    }
  
    /// Gets source display text
    static String getSourceDisplay(String source, [String? sourceDetails]) {
      if (source.isEmpty) return 'Unknown';
      
      // If source is "Purchased" or "Other" and we have details, show them
      if ((source == 'Purchased' || source == 'Other') && sourceDetails?.isNotEmpty == true) {
        return '$source - $sourceDetails';
      }
      
      return source;
    }
  
    /// Gets group display text
    static String getGroupDisplay(String? groupName) {
      return groupName?.isNotEmpty == true ? groupName! : 'No Group';
    }
  
    /// Gets parent tag display text
    static String getParentDisplay(String? parentTag) {
      return parentTag?.isNotEmpty == true ? parentTag! : 'Unknown';
    }
  
    /// Gets offspring display text
    static String getOffspringDisplay(String? offspring) {
      if (offspring?.isNotEmpty == true) {
        // If offspring contains multiple tags (comma-separated), format them nicely
        final offspringList = offspring!.split(',').map((tag) => tag.trim()).toList();
        if (offspringList.length == 1) {
          return offspringList.first;
        } else if (offspringList.length <= 3) {
          return offspringList.join(', ');
        } else {
          return '${offspringList.take(3).join(', ')}\n+ ${offspringList.length - 3} more';
        }
      }
      return 'No offspring recorded';
    }
  
    /// Gets notes display text
    static String getNotesDisplay(String? notes) {
      if (notes?.isNotEmpty == true) {
        return notes!;
      }
      return 'No notes available for this cattle yet.\nTap the edit button to add some notes.';
    }
  
    /// Checks if notes are empty
    static bool hasNotes(String? notes) {
      return notes?.isNotEmpty == true;
    }
  }