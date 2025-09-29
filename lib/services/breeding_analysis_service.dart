import 'package:cattle_tracer_app/services/cattle/cattle_event_service.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_service.dart';
import 'package:flutter/src/material/date.dart';

class BreedingAnalysisService {
  static Future<Map<String, dynamic>> getBreedingSuccessAnalysis({
    String? selectedCowTag,
    String? selectedBullTag,
    String? selectedBreedingType, String? successStatus, DateTimeRange<DateTime>? dateRange,
  }) async {
    try {
      // Load cattle directory to mirror web JOINs (sex/classification by tag)
      final allCattleModels = await CattleService.getAllCattle();
      final Map<String, Map<String, String>> tagToProfile = {};
      for (final c in allCattleModels) {
        final tag = c.tagNo.toString();
        if (tag.isEmpty) continue;
        tagToProfile[tag] = {
          'sex': c.sex.toString(),
          'classification': c.classification.toString(),
        };
      }
      // Get all breeding events
      final allEvents = await CattleEventService.getCattleEvent();
      final breedingEvents = allEvents.where((event) {
        if (event['event_type']?.toString().toLowerCase() != 'breeding') return false;
        final tag = event['cattle_tag']?.toString() ?? '';
        final prof = tagToProfile[tag];
        if (prof == null) return false;
        final sex = prof['sex']?.toLowerCase();
        final cls = prof['classification']?.toLowerCase();
        return sex == 'female' && (cls == 'cow' || cls == 'heifer');
      }).toList();

      // Get pregnancy events (female cow/heifer only, align with web)
      final pregnancyEvents = allEvents.where((event) {
        if (event['event_type']?.toString().toLowerCase() != 'pregnant') return false;
        final tag = event['cattle_tag']?.toString() ?? '';
        final prof = tagToProfile[tag];
        if (prof == null) return false;
        final sex = prof['sex']?.toLowerCase();
        final cls = prof['classification']?.toLowerCase();
        return sex == 'female' && (cls == 'cow' || cls == 'heifer');
      }).toList();

      // Get birth events (female cow/heifer only, align with web)
      final birthEvents = allEvents.where((event) {
        if (event['event_type']?.toString().toLowerCase() != 'gives birth') return false;
        final tag = event['cattle_tag']?.toString() ?? '';
        final prof = tagToProfile[tag];
        if (prof == null) return false;
        final sex = prof['sex']?.toLowerCase();
        final cls = prof['classification']?.toLowerCase();
        return sex == 'female' && (cls == 'cow' || cls == 'heifer');
      }).toList();

      // Filter by selected parameters
      List<Map<String, dynamic>> filteredBreedingEvents = breedingEvents;
      // Apply date range to breeding events (retain same logic as web)
      if (dateRange != null) {
        final start = dateRange.start;
        final end = dateRange.end;
        filteredBreedingEvents = filteredBreedingEvents.where((event) {
          final dateStr = event['event_date']?.toString();
          if (dateStr == null || dateStr.isEmpty) return false;
          try {
            final date = DateTime.parse(dateStr);
            return !date.isBefore(start) && !date.isAfter(end);
          } catch (_) {
            return false;
          }
        }).toList();
      }
      if (selectedCowTag != null && selectedCowTag.isNotEmpty) {
        filteredBreedingEvents = filteredBreedingEvents.where((event) =>
            event['cattle_tag']?.toString() == selectedCowTag).toList();
      }
      if (selectedBullTag != null && selectedBullTag.isNotEmpty) {
        filteredBreedingEvents = filteredBreedingEvents.where((event) {
          final eventBull = _getResponsibleBull(event);
          return eventBull == selectedBullTag;
        }).toList();
      }
      if (selectedBreedingType != null && selectedBreedingType.isNotEmpty) {
        print('DEBUG: Filtering by breeding type: $selectedBreedingType');
        print('DEBUG: Events before filter: ${filteredBreedingEvents.length}');
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
            } else if (event['bull_tag'] != null && event['bull_tag'].toString().isNotEmpty) {
              eventType = 'natural_breeding';
            } else {
              eventType = 'unknown';
            }
          }
          print('DEBUG: Event breeding_type: $eventType, comparing with: $selectedBreedingType');
          return eventType == selectedBreedingType;
        }).toList();
        print('DEBUG: Events after filter: ${filteredBreedingEvents.length}');
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
          'cow': selectedCowTag,
          'bull': selectedBullTag,
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
    final Map<String, List<Map<String, dynamic>>> cowBreedingHistory = {};
    final Map<String, List<Map<String, dynamic>>> cowPregnancyHistory = {};
    final Map<String, List<Map<String, dynamic>>> cowBirthHistory = {};

    // Group events by cow
    for (final event in breedingEvents) {
      final cowTag = event['cattle_tag']?.toString() ?? '';
      if (cowTag.isNotEmpty) {
        cowBreedingHistory.putIfAbsent(cowTag, () => []);
        cowBreedingHistory[cowTag]!.add(event);
      }
    }

    for (final event in pregnancyEvents) {
      final cowTag = event['cattle_tag']?.toString() ?? '';
      if (cowTag.isNotEmpty) {
        cowPregnancyHistory.putIfAbsent(cowTag, () => []);
        cowPregnancyHistory[cowTag]!.add(event);
      }
    }

    for (final event in birthEvents) {
      final cowTag = event['cattle_tag']?.toString() ?? '';
      if (cowTag.isNotEmpty) {
        cowBirthHistory.putIfAbsent(cowTag, () => []);
        cowBirthHistory[cowTag]!.add(event);
      }
    }

    // Analyze each cow's breeding success
    final List<Map<String, dynamic>> cowAnalysis = [];
    final Map<String, Map<String, dynamic>> bullPerformance = {};
    final Map<String, Map<String, dynamic>> breedingTypePerformance = {};

    for (final cowTag in cowBreedingHistory.keys) {
      final cowBreedings = cowBreedingHistory[cowTag]!;
      final cowPregnancies = cowPregnancyHistory[cowTag] ?? [];

      // Sort events by date
      cowBreedings.sort((a, b) => DateTime.parse(a['event_date'] ?? '1900-01-01')
          .compareTo(DateTime.parse(b['event_date'] ?? '1900-01-01')));

      final List<Map<String, dynamic>> successfulBreedings = [];
      final List<Map<String, dynamic>> failedBreedings = [];
      final List<Map<String, dynamic>> pendingBreedings = [];

      for (int i = 0; i < cowBreedings.length; i++) {
        final breeding = cowBreedings[i];
        final breedingDate = DateTime.parse(breeding['event_date'] ?? '1900-01-01');
        final today = DateTime.now();
        final daysSinceBreeding = today.difference(breedingDate).inDays;
        
        // Look for pregnancy within 25-60 days after breeding
        bool foundPregnancy = false;
        String? responsibleBull = _getResponsibleBull(breeding);
        String breedingType = breeding['breeding_type']?.toString() ?? '';
        // If breeding_type is empty, try to determine from other fields
        if (breedingType.isEmpty) {
          // Check if it's artificial insemination by looking for semen_used
          if (breeding['semen_used'] != null && breeding['semen_used'].toString().isNotEmpty) {
            breedingType = 'artificial_insemination';
          } else if (breeding['bull_tag'] != null && breeding['bull_tag'].toString().isNotEmpty) {
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

        print('DEBUG: Analyzing breeding for cow $cowTag on ${breeding['event_date']} (${daysSinceBreeding} days ago)');
        print('DEBUG: Responsible bull: $responsibleBull');
        print('DEBUG: Breeding type: $breedingType');

        // Check if breeding is too recent to determine success/failure
        if (daysSinceBreeding < 25) {
          print('DEBUG: ⏳ Breeding too recent (${daysSinceBreeding} days) - marking as pending');
          pendingBreedings.add({
            'event_date': breeding['event_date'],
            'breeding_type': breedingType,
            'days_since_breeding': daysSinceBreeding,
            'status': 'pending',
          });
          continue; // Skip to next breeding event
        }

        // Check pregnancy events
        for (final pregnancy in cowPregnancies) {
          final pregnancyDate = DateTime.parse(pregnancy['event_date'] ?? '1900-01-01');
          final daysDifference = pregnancyDate.difference(breedingDate).inDays;
          final pregnancyBull = _getResponsibleBull(pregnancy);
          
          print('DEBUG: Checking pregnancy on ${pregnancy['event_date']} (${daysDifference} days later)');
          print('DEBUG: Pregnancy bull: $pregnancyBull');
          
          if (daysDifference >= 25 && daysDifference <= 60) {
            // Check if the same bull is responsible
            if (_isSameBull(responsibleBull, pregnancyBull)) {
              foundPregnancy = true;
              print('DEBUG: ✅ Pregnancy match found!');
              successfulBreedings.add({
                'event_date': breeding['event_date'],
                'breeding_type': breeding['breeding_type'],
                'pregnancy_date': pregnancy['event_date'],
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
            print('DEBUG: ❌ No pregnancy/birth match found after ${daysSinceBreeding} days - marking as failed');
            failedBreedings.add({
              'event_date': breeding['event_date'],
              'breeding_type': breedingType,
              'days_since_breeding': daysSinceBreeding,
              'status': 'failed',
            });
          } else {
            print('DEBUG: ⏳ No pregnancy/birth match found but only ${daysSinceBreeding} days passed - marking as pending');
            pendingBreedings.add({
              'event_date': breeding['event_date'],
              'breeding_type': breedingType,
              'days_since_breeding': daysSinceBreeding,
              'status': 'pending',
            });
          }
        }

        // Track bull performance
        if (responsibleBull != null) {
          bullPerformance.putIfAbsent(responsibleBull, () => {
            'bull_tag': responsibleBull,
            'total_breedings': 0,
            'successful_breedings': 0,
            'success_rate': 0.0,
            'cows_served': <String>{},
          });
          
          bullPerformance[responsibleBull]!['total_breedings'] = 
              (bullPerformance[responsibleBull]!['total_breedings'] as int) + 1;
          (bullPerformance[responsibleBull]!['cows_served'] as Set<String>).add(cowTag);
          
          if (foundPregnancy) {
            bullPerformance[responsibleBull]!['successful_breedings'] = 
                (bullPerformance[responsibleBull]!['successful_breedings'] as int) + 1;
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

      // Calculate success rate for this cow (only count resolved breedings)
      final totalBreedings = cowBreedings.length;
      final resolvedBreedings = successfulBreedings.length + failedBreedings.length;
      final successfulCount = successfulBreedings.length;
      final pendingCount = pendingBreedings.length;
      final successRate = resolvedBreedings > 0 ? (successfulCount / resolvedBreedings) * 100 : 0.0;

      cowAnalysis.add({
        'cow_tag': cowTag,
        'total_breedings': totalBreedings,
        'successful_breedings': successfulCount,
        'failed_breedings': failedBreedings.length,
        'pending_breedings': pendingCount,
        'resolved_breedings': resolvedBreedings,
        'success_rate': successRate,
        'successful_breedings_details': successfulBreedings,
        'failed_breedings_details': failedBreedings,
        'pending_breedings_details': pendingBreedings,
        'last_breeding_date': cowBreedings.isNotEmpty ? cowBreedings.last['event_date'] : null,
      });
    }

    // Calculate final success rates for bulls and breeding types
    for (final bull in bullPerformance.values) {
      final total = bull['total_breedings'] as int;
      final successful = bull['successful_breedings'] as int;
      bull['success_rate'] = total > 0 ? (successful / total) * 100 : 0.0;
      bull['cows_served'] = (bull['cows_served'] as Set<String>).length;
    }

    for (final type in breedingTypePerformance.values) {
      final total = type['total_breedings'] as int;
      final successful = type['successful_breedings'] as int;
      type['success_rate'] = total > 0 ? (successful / total) * 100 : 0.0;
    }

    // Calculate overall statistics
    final totalBreedings = breedingEvents.length;
    final totalSuccessful = cowAnalysis.fold<int>(0, (sum, cow) => sum + (cow['successful_breedings'] as int));
    final totalFailed = cowAnalysis.fold<int>(0, (sum, cow) => sum + (cow['failed_breedings'] as int));
    final totalPending = cowAnalysis.fold<int>(0, (sum, cow) => sum + (cow['pending_breedings'] as int));
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
      'cow_analysis': cowAnalysis,
      'bull_performance': bullPerformance.values.toList(),
      'breeding_type_performance': breedingTypePerformance.values.toList(),
    };
  }

  static String? _getResponsibleBull(Map<String, dynamic> event) {
    // For natural breeding, use bull_tag
    if (event['breeding_type']?.toString() == 'natural_breeding') {
      return event['bull_tag']?.toString();
    }
    
    // For artificial insemination, extract bull from semen_used
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
    
    // For pregnancy and birth events, use bull_tag
    final bullTag = event['bull_tag']?.toString();
    if (bullTag != null && bullTag.isNotEmpty) {
      return bullTag;
    }
    
    return null;
  }

  static bool _isSameBull(String? bull1, String? bull2) {
    // If both are null, consider them the same (no bull specified)
    if (bull1 == null && bull2 == null) return true;
    
    // If one is null and the other isn't, they're different
    if (bull1 == null || bull2 == null) return false;
    
    // Compare the bull tags (case-insensitive)
    return bull1.toLowerCase().trim() == bull2.toLowerCase().trim();
  }

  // Get available cows for filtering (only actual cows, not bulls)
  static Future<List<String>> getAvailableCows() async {
    try {
      // Get all cattle and filter only cows
      final allCattle = await CattleService.getAllCattle();
      final cows = allCattle.where((cattle) => 
          cattle.classification.toString().toLowerCase() == 'cow').toList();
      
              final List<String> cowTags = [];
        for (final cow in cows) {
          final cowTag = cow.tagNo.toString();
          if (cowTag.isNotEmpty) {
            cowTags.add(cowTag);
          }
        }
      
      return cowTags..sort();
    } catch (e) {
      print('DEBUG: Error getting available cows: $e');
      return [];
    }
  }

  // Get available bulls for filtering
  static Future<List<String>> getAvailableBulls() async {
    try {
      final allEvents = await CattleEventService.getCattleEvent();
      final breedingEvents = allEvents.where((event) =>
          event['event_type']?.toString().toLowerCase() == 'breeding').toList();
      
      final Set<String> bullTags = {};
      for (final event in breedingEvents) {
        final bull = _getResponsibleBull(event);
        if (bull != null && bull.isNotEmpty) {
          bullTags.add(bull);
        }
      }
      
      return bullTags.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  // Get available breeding types for filtering
  static Future<List<Map<String, String>>> getAvailableBreedingTypes() async {
    try {
      final allEvents = await CattleEventService.getCattleEvent();
      final breedingEvents = allEvents.where((event) =>
          event['event_type']?.toString().toLowerCase() == 'breeding').toList();
      
      final Set<String> breedingTypes = {};
      for (final event in breedingEvents) {
        String breedingType = event['breeding_type']?.toString() ?? '';
        // If breeding_type is empty, try to determine from other fields
        if (breedingType.isEmpty) {
          // Check if it's artificial insemination by looking for semen_used
          if (event['semen_used'] != null && event['semen_used'].toString().isNotEmpty) {
            breedingType = 'artificial_insemination';
          } else if (event['bull_tag'] != null && event['bull_tag'].toString().isNotEmpty) {
            breedingType = 'natural_breeding';
          } else {
            breedingType = 'unknown';
          }
        }
        if (breedingType.isNotEmpty) {
          breedingTypes.add(breedingType);
        }
      }
      
      print('DEBUG: Available breeding types found: ${breedingTypes.toList()}');
      print('DEBUG: Total breeding events found: ${breedingEvents.length}');
      for (final event in breedingEvents) {
        print('DEBUG: Event breeding_type: ${event['breeding_type']}');
        print('DEBUG: Event semen_used: ${event['semen_used']}');
        print('DEBUG: Event bull_tag: ${event['bull_tag']}');
        print('DEBUG: ---');
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
      print('DEBUG: Error getting available breeding types: $e');
      return [];
    }
  }
}
