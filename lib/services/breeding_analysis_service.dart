import 'package:goat_tracer_app/services/goat/goat_history_service.dart';
import 'package:goat_tracer_app/services/goat/goat_service.dart';
import 'package:flutter/material.dart';

class BreedingAnalysisService {
  static Future<Map<String, dynamic>> getBreedingSuccessAnalysis({
    String? selectedDoeTag,
    String? selectedBuckTag,
    String? selectedBreedingType, String? successStatus, DateTimeRange<DateTime>? dateRange,
  }) async {
    try {
      // Load goat directory to mirror web JOINs (sex/classification by tag)
      final allgoatModels = await GoatService.getAllGoats();
      final Map<String, Map<String, String>> tagToProfile = {};
      for (final c in allgoatModels) {
        final tag = c.tagNo.toString();
        if (tag.isEmpty) continue;
        tagToProfile[tag] = {
          'sex': c.sex.toString(),
          'classification': c.classification.toString(),
        };
      }
      // Get all breeding events
      final allEvents = await GoatHistoryService.getgoatHistory();
      final breedingEvents = allEvents.where((event) {
        if (event['history_type']?.toString().toLowerCase() != 'breeding') return false;
        final tag = event['goat_tag']?.toString() ?? '';
        final prof = tagToProfile[tag];
        if (prof == null) return false;
        final sex = prof['sex']?.toLowerCase();
        final cls = prof['classification']?.toLowerCase();
        return sex == 'female' && (cls == 'Doe' || cls == 'Doeling');
      }).toList();

      // Get pregnancy events (female Doe/Doeling only, align with web)
      final pregnancyEvents = allEvents.where((event) {
        if (event['history_type']?.toString().toLowerCase() != 'pregnant') return false;
        final tag = event['goat_tag']?.toString() ?? '';
        final prof = tagToProfile[tag];
        if (prof == null) return false;
        final sex = prof['sex']?.toLowerCase();
        final cls = prof['classification']?.toLowerCase();
        return sex == 'female' && (cls == 'Doe' || cls == 'Doeling');
      }).toList();

      // Get birth events (female Doe/Doeling only, align with web)
      final birthEvents = allEvents.where((event) {
        if (event['history_type']?.toString().toLowerCase() != 'gives birth') return false;
        final tag = event['goat_tag']?.toString() ?? '';
        final prof = tagToProfile[tag];
        if (prof == null) return false;
        final sex = prof['sex']?.toLowerCase();
        final cls = prof['classification']?.toLowerCase();
        return sex == 'female' && (cls == 'Doe' || cls == 'Doeling');
      }).toList();

      // Filter by selected parameters
      List<Map<String, dynamic>> filteredBreedingEvents = breedingEvents;
      // Apply date range to breeding events (retain same logic as web)
      if (dateRange != null) {
        final start = dateRange.start;
        final end = dateRange.end;
        filteredBreedingEvents = filteredBreedingEvents.where((event) {
          final dateStr = event['history_date']?.toString();
          if (dateStr == null || dateStr.isEmpty) return false;
          try {
            final date = DateTime.parse(dateStr);
            return !date.isBefore(start) && !date.isAfter(end);
          } catch (_) {
            return false;
          }
        }).toList();
      }
      if (selectedDoeTag != null && selectedDoeTag.isNotEmpty) {
        filteredBreedingEvents = filteredBreedingEvents.where((event) =>
            event['goat_tag']?.toString() == selectedDoeTag).toList();
      }
      if (selectedBuckTag != null && selectedBuckTag.isNotEmpty) {
        filteredBreedingEvents = filteredBreedingEvents.where((event) {
          final eventBuck = _getResponsibleBuck(event);
          return eventBuck == selectedBuckTag;
        }).toList();
      }
      if (selectedBreedingType != null && selectedBreedingType.isNotEmpty) {
        debugPrint('DEBUG: Filtering by breeding type: $selectedBreedingType');
        debugPrint('DEBUG: Events before filter: ${filteredBreedingEvents.length}');
        filteredBreedingEvents = filteredBreedingEvents.where((event) {
          String eventType = event['breeding_type']?.toString() ?? '';
          // Normalize human-readable types to snake_case for comparison
          if (eventType.isNotEmpty) {
            final lower = eventType.toLowerCase();
            if (lower == 'artificial insemination' || lower == 'artificial_insemination') {
              eventType = 'artificial_insemination';
            } else if (lower == 'natural breeding' || lower == 'natural_breeding') {
              eventType = 'natural_breeding';
            } else {
              eventType = lower.replaceAll(' ', '_');
            }
          }
          // Apply the same fallback logic for filtering
          if (eventType.isEmpty) {
            if (event['semen_used'] != null && event['semen_used'].toString().isNotEmpty) {
              eventType = 'artificial_insemination';
            } else if (event['Buck_tag'] != null && event['Buck_tag'].toString().isNotEmpty) {
              eventType = 'natural_breeding';
            } else {
              eventType = 'unknown';
            }
          }
          debugPrint('DEBUG: Event breeding_type: $eventType, comparing with: $selectedBreedingType');
          return eventType == selectedBreedingType;
        }).toList();
        debugPrint('DEBUG: Events after filter: ${filteredBreedingEvents.length}');
      }

      // Analyze breeding success
      final analysis = await _analyzeBreedingSuccess(
        filteredBreedingEvents,
        pregnancyEvents,
        birthEvents,
      );

      return {
        'success': true,
        'data': analysis,
        'totalBreedingEvents': filteredBreedingEvents.length,
        'filteredBy': {
          'Doe': selectedDoeTag,
          'Buck': selectedBuckTag,
          'breedingType': selectedBreedingType,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to analyze breeding success: $e',
        'data': null,
      };
    }
  }

  static Future<Map<String, dynamic>> _analyzeBreedingSuccess(
    List<Map<String, dynamic>> breedingEvents,
    List<Map<String, dynamic>> pregnancyEvents,
    List<Map<String, dynamic>> birthEvents,
  ) async {
    final Map<String, List<Map<String, dynamic>>> DoeBreedingHistory = {};
    final Map<String, List<Map<String, dynamic>>> DoePregnancyHistory = {};
    final Map<String, List<Map<String, dynamic>>> DoeBirthHistory = {};

    // Group events by Doe
    for (final event in breedingEvents) {
      final DoeTag = event['goat_tag']?.toString() ?? '';
      if (DoeTag.isNotEmpty) {
        DoeBreedingHistory.putIfAbsent(DoeTag, () => []);
        DoeBreedingHistory[DoeTag]!.add(event);
      }
    }

    for (final event in pregnancyEvents) {
      final DoeTag = event['goat_tag']?.toString() ?? '';
      if (DoeTag.isNotEmpty) {
        DoePregnancyHistory.putIfAbsent(DoeTag, () => []);
        DoePregnancyHistory[DoeTag]!.add(event);
      }
    }

    for (final event in birthEvents) {
      final DoeTag = event['goat_tag']?.toString() ?? '';
      if (DoeTag.isNotEmpty) {
        DoeBirthHistory.putIfAbsent(DoeTag, () => []);
        DoeBirthHistory[DoeTag]!.add(event);
      }
    }

    // Analyze each Doe's breeding success
    final List<Map<String, dynamic>> DoeAnalysis = [];
    final Map<String, Map<String, dynamic>> BuckPerformance = {};
    final Map<String, Map<String, dynamic>> breedingTypePerformance = {};

    for (final DoeTag in DoeBreedingHistory.keys) {
      final DoeBreedings = DoeBreedingHistory[DoeTag]!;
      final DoePregnancies = DoePregnancyHistory[DoeTag] ?? [];

      // Sort events by date
      DoeBreedings.sort((a, b) => DateTime.parse(a['history_date'] ?? '1900-01-01')
          .compareTo(DateTime.parse(b['history_date'] ?? '1900-01-01')));

      final List<Map<String, dynamic>> successfulBreedings = [];
      final List<Map<String, dynamic>> failedBreedings = [];
      final List<Map<String, dynamic>> pendingBreedings = [];

      for (int i = 0; i < DoeBreedings.length; i++) {
        final breeding = DoeBreedings[i];
        final breedingDate = DateTime.parse(breeding['history_date'] ?? '1900-01-01');
        final today = DateTime.now();
        final daysSinceBreeding = today.difference(breedingDate).inDays;
        
        // Look for pregnancy within 25-60 days after breeding
        bool foundPregnancy = false;
        String? responsibleBuck = _getResponsibleBuck(breeding);
        String breedingType = breeding['breeding_type']?.toString() ?? '';
        // If breeding_type is empty, try to determine from other fields
        if (breedingType.isEmpty) {
          // Check if it's artificial insemination by looking for semen_used
          if (breeding['semen_used'] != null && breeding['semen_used'].toString().isNotEmpty) {
            breedingType = 'artificial_insemination';
          } else if (breeding['Buck_tag'] != null && breeding['Buck_tag'].toString().isNotEmpty) {
            breedingType = 'natural_breeding';
          } else {
            breedingType = 'unknown';
          }
        } else {
          // Normalize to snake_case for consistency with web
          final lower = breedingType.toLowerCase();
          if (lower == 'artificial insemination' || lower == 'artificial_insemination') {
            breedingType = 'artificial_insemination';
          } else if (lower == 'natural breeding' || lower == 'natural_breeding') {
            breedingType = 'natural_breeding';
          } else {
            breedingType = lower.replaceAll(' ', '_');
          }
        }

        debugPrint('DEBUG: Analyzing breeding for Doe $DoeTag on ${breeding['history_date']} ($daysSinceBreeding days ago)');
        debugPrint('DEBUG: Responsible Buck: $responsibleBuck');
        debugPrint('DEBUG: Breeding type: $breedingType');

        // Check if breeding is too recent to determine success/failure
        if (daysSinceBreeding < 25) {
          debugPrint('DEBUG: ⏳ Breeding too recent ($daysSinceBreeding days) - marking as pending');
          pendingBreedings.add({
            'history_date': breeding['history_date'],
            'breeding_type': breedingType,
            'days_since_breeding': daysSinceBreeding,
            'status': 'pending',
          });
          continue; // Skip to next breeding event
        }

        // Check pregnancy events
        for (final pregnancy in DoePregnancies) {
          final pregnancyDate = DateTime.parse(pregnancy['history_date'] ?? '1900-01-01');
          final daysDifference = pregnancyDate.difference(breedingDate).inDays;
          final pregnancyBuck = _getResponsibleBuck(pregnancy);
          
          debugPrint('DEBUG: Checking pregnancy on ${pregnancy['history_date']} ($daysDifference days later)');
          debugPrint('DEBUG: Pregnancy Buck: $pregnancyBuck');
          
          if (daysDifference >= 25 && daysDifference <= 60) {
            // Check if the same Buck is responsible
            if (_isSameBuck(responsibleBuck, pregnancyBuck)) {
              foundPregnancy = true;
              debugPrint('DEBUG: ✅ Pregnancy match found!');
              successfulBreedings.add({
                'history_date': breeding['history_date'],
                'breeding_type': breeding['breeding_type'],
                'pregnancy_date': pregnancy['history_date'],
                'days_to_pregnancy': daysDifference,
              });
              break;
            }
          }
        }

        // Success is determined by pregnancy only; do not use birth events to mark success

        if (!foundPregnancy) {
          // Only mark as failed if enough time has passed (more than 60 days)
          if (daysSinceBreeding > 60) {
            debugPrint('DEBUG: ❌ No pregnancy/birth match found after $daysSinceBreeding days - marking as failed');
            failedBreedings.add({
              'history_date': breeding['history_date'],
              'breeding_type': breedingType,
              'days_since_breeding': daysSinceBreeding,
              'status': 'failed',
            });
          } else {
            debugPrint('DEBUG: ⏳ No pregnancy/birth match found but only $daysSinceBreeding days passed - marking as pending');
            pendingBreedings.add({
              'history_date': breeding['history_date'],
              'breeding_type': breedingType,
              'days_since_breeding': daysSinceBreeding,
              'status': 'pending',
            });
          }
        }

        // Track Buck performance
        if (responsibleBuck != null) {
          BuckPerformance.putIfAbsent(responsibleBuck, () => {
            'Buck_tag': responsibleBuck,
            'total_breedings': 0,
            'successful_breedings': 0,
            'success_rate': 0.0,
            'Does_served': <String>{},
          });
          
          BuckPerformance[responsibleBuck]!['total_breedings'] = 
              (BuckPerformance[responsibleBuck]!['total_breedings'] as int) + 1;
          (BuckPerformance[responsibleBuck]!['Does_served'] as Set<String>).add(DoeTag);
          
          if (foundPregnancy) {
            BuckPerformance[responsibleBuck]!['successful_breedings'] = 
                (BuckPerformance[responsibleBuck]!['successful_breedings'] as int) + 1;
          }
        }

        // Track breeding type performance
        breedingTypePerformance.putIfAbsent(breedingType, () => {
          'type': breedingType,
          'total_breedings': 0,
          'successful_breedings': 0,
          'success_rate': 0.0,
        });
        
        breedingTypePerformance[breedingType]!['total_breedings'] = 
            (breedingTypePerformance[breedingType]!['total_breedings'] as int) + 1;
        
        if (foundPregnancy) {
          breedingTypePerformance[breedingType]!['successful_breedings'] = 
              (breedingTypePerformance[breedingType]!['successful_breedings'] as int) + 1;
        }
      }

      // Calculate success rate for this Doe (only count resolved breedings)
      final totalBreedings = DoeBreedings.length;
      final resolvedBreedings = successfulBreedings.length + failedBreedings.length;
      final successfulCount = successfulBreedings.length;
      final pendingCount = pendingBreedings.length;
      final successRate = resolvedBreedings > 0 ? (successfulCount / resolvedBreedings) * 100 : 0.0;

      DoeAnalysis.add({
        'Doe_tag': DoeTag,
        'total_breedings': totalBreedings,
        'successful_breedings': successfulCount,
        'failed_breedings': failedBreedings.length,
        'pending_breedings': pendingCount,
        'resolved_breedings': resolvedBreedings,
        'success_rate': successRate,
        'successful_breedings_details': successfulBreedings,
        'failed_breedings_details': failedBreedings,
        'pending_breedings_details': pendingBreedings,
        'last_breeding_date': DoeBreedings.isNotEmpty ? DoeBreedings.last['history_date'] : null,
      });
    }

    // Calculate final success rates for Bucks and breeding types
    for (final Buck in BuckPerformance.values) {
      final total = Buck['total_breedings'] as int;
      final successful = Buck['successful_breedings'] as int;
      Buck['success_rate'] = total > 0 ? (successful / total) * 100 : 0.0;
      Buck['Does_served'] = (Buck['Does_served'] as Set<String>).length;
    }

    for (final type in breedingTypePerformance.values) {
      final total = type['total_breedings'] as int;
      final successful = type['successful_breedings'] as int;
      type['success_rate'] = total > 0 ? (successful / total) * 100 : 0.0;
    }

    // Calculate overall statistics
    final totalBreedings = breedingEvents.length;
    final totalSuccessful = DoeAnalysis.fold<int>(0, (sum, Doe) => sum + (Doe['successful_breedings'] as int));
    final totalFailed = DoeAnalysis.fold<int>(0, (sum, Doe) => sum + (Doe['failed_breedings'] as int));
    final totalPending = DoeAnalysis.fold<int>(0, (sum, Doe) => sum + (Doe['pending_breedings'] as int));
    final totalResolved = totalSuccessful + totalFailed;
    final overallSuccessRate = totalResolved > 0 ? (totalSuccessful / totalResolved) * 100 : 0.0;

    return {
      'overall_statistics': {
        'total_breedings': totalBreedings,
        'total_successful': totalSuccessful,
        'total_failed': totalFailed,
        'total_pending': totalPending,
        'total_resolved': totalResolved,
        'overall_success_rate': overallSuccessRate,
      },
      'Doe_analysis': DoeAnalysis,
      'Buck_performance': BuckPerformance.values.toList(),
      'breeding_type_performance': breedingTypePerformance.values.toList(),
    };
  }

  static String? _getResponsibleBuck(Map<String, dynamic> event) {
    // For natural breeding, use Buck_tag
    if (event['breeding_type']?.toString() == 'natural_breeding') {
      return event['Buck_tag']?.toString();
    }
    
    // For artificial insemination, extract Buck from semen_used
    final semenUsed = event['semen_used']?.toString() ?? '';
    if (semenUsed.isNotEmpty) {
      if (semenUsed.contains(' Semen')) {
        String tagPart = semenUsed.replaceAll(' Semen', '');
        if (tagPart.contains(' (') && tagPart.contains(')')) {
          return tagPart.split(' (')[0];
        } else {
          return tagPart;
        }
      }
      // If semen_used provided without label, treat it as already-clean tag
      return semenUsed;
    }
    
    // For pregnancy and birth events, use Buck_tag
    final BuckTag = event['Buck_tag']?.toString();
    if (BuckTag != null && BuckTag.isNotEmpty) {
      return BuckTag;
    }
    
    return null;
  }

  static bool _isSameBuck(String? Buck1, String? Buck2) {
    // If both are null, consider them the same (no Buck specified)
    if (Buck1 == null && Buck2 == null) return true;
    
    // If one is null and the other isn't, they're different
    if (Buck1 == null || Buck2 == null) return false;
    
    // Compare the Buck tags (case-insensitive)
    return Buck1.toLowerCase().trim() == Buck2.toLowerCase().trim();
  }

  // Get available Does for filtering (only actual Does, not Bucks)
  static Future<List<String>> getAvailableDoes() async {
    try {
      // Get all goat and filter only Does
      final allgoat = await GoatService.getAllGoats();
      final Does = allgoat.where((goat) => 
          goat.classification.toString().toLowerCase() == 'Doe').toList();
      
              final List<String> DoeTags = [];
        for (final Doe in Does) {
          final DoeTag = Doe.tagNo.toString();
          if (DoeTag.isNotEmpty) {
            DoeTags.add(DoeTag);
          }
        }
      
      return DoeTags..sort();
    } catch (e) {
      debugPrint('DEBUG: Error getting available Does: $e');
      return [];
    }
  }

  // Get available Bucks for filtering
  static Future<List<String>> getAvailableBucks() async {
    try {
      final allEvents = await GoatHistoryService.getgoatHistory();
      final breedingEvents = allEvents.where((event) =>
          event['history_type']?.toString().toLowerCase() == 'breeding').toList();
      
      final Set<String> BuckTags = {};
      for (final event in breedingEvents) {
        final Buck = _getResponsibleBuck(event);
        if (Buck != null && Buck.isNotEmpty) {
          BuckTags.add(Buck);
        }
      }
      
      return BuckTags.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  // Get available breeding types for filtering
  static Future<List<Map<String, String>>> getAvailableBreedingTypes() async {
    try {
      final allEvents = await GoatHistoryService.getgoatHistory();
      final breedingEvents = allEvents.where((event) =>
          event['history_type']?.toString().toLowerCase() == 'breeding').toList();
      
      final Set<String> breedingTypes = {};
      for (final event in breedingEvents) {
        String breedingType = event['breeding_type']?.toString() ?? '';
        // If breeding_type is empty, try to determine from other fields
        if (breedingType.isEmpty) {
          // Check if it's artificial insemination by looking for semen_used
          if (event['semen_used'] != null && event['semen_used'].toString().isNotEmpty) {
            breedingType = 'artificial_insemination';
          } else if (event['Buck_tag'] != null && event['Buck_tag'].toString().isNotEmpty) {
            breedingType = 'natural_breeding';
          } else {
            breedingType = 'unknown';
          }
        }
        if (breedingType.isNotEmpty) {
          breedingTypes.add(breedingType);
        }
      }
      
      debugPrint('DEBUG: Available breeding types found: ${breedingTypes.toList()}');
      debugPrint('DEBUG: Total breeding events found: ${breedingEvents.length}');
      for (final event in breedingEvents) {
        debugPrint('DEBUG: Event breeding_type: ${event['breeding_type']}');
        debugPrint('DEBUG: Event semen_used: ${event['semen_used']}');
        debugPrint('DEBUG: Event Buck_tag: ${event['Buck_tag']}');
        debugPrint('DEBUG: ---');
      }
      
      // Map raw values to user-friendly labels
      final List<Map<String, String>> breedingTypeOptions = [];
      for (final type in breedingTypes) {
        String label = type;
        switch (type.toLowerCase()) {
          case 'artificial_insemination':
            label = 'Artificial Insemination';
            break;
          case 'natural_breeding':
            label = 'Natural Breeding';
            break;
          case 'unknown':
            label = 'Unknown';
            break;
        }
        breedingTypeOptions.add({
          'value': type,
          'label': label,
        });
      }
      
      return breedingTypeOptions;
    } catch (e) {
      debugPrint('DEBUG: Error getting available breeding types: $e');
      return [];
    }
  }
}


