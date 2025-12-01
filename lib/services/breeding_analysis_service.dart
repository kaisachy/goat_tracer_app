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
        return sex == 'female' && (cls == 'doe' || cls == 'Doeling');
      }).toList();

      // Get pregnancy events (female doe/Doeling only, align with web)
      final pregnancyEvents = allEvents.where((event) {
        if (event['history_type']?.toString().toLowerCase() != 'pregnant') return false;
        final tag = event['goat_tag']?.toString() ?? '';
        final prof = tagToProfile[tag];
        if (prof == null) return false;
        final sex = prof['sex']?.toLowerCase();
        final cls = prof['classification']?.toLowerCase();
        return sex == 'female' && (cls == 'doe' || cls == 'Doeling');
      }).toList();

      // Get birth events (female doe/Doeling only, align with web)
      final birthEvents = allEvents.where((event) {
        if (event['history_type']?.toString().toLowerCase() != 'kidding') return false;
        final tag = event['goat_tag']?.toString() ?? '';
        final prof = tagToProfile[tag];
        if (prof == null) return false;
        final sex = prof['sex']?.toLowerCase();
        final cls = prof['classification']?.toLowerCase();
        return sex == 'female' && (cls == 'doe' || cls == 'Doeling');
      }).toList();

      // Get abortion events (female doe/Doeling only)
      final abortionEvents = allEvents.where((event) {
        if (event['history_type']?.toString().toLowerCase() != 'aborted') return false;
        final tag = event['goat_tag']?.toString() ?? '';
        final prof = tagToProfile[tag];
        if (prof == null) return false;
        final sex = prof['sex']?.toLowerCase();
        final cls = prof['classification']?.toLowerCase();
        return sex == 'female' && (cls == 'doe' || cls == 'Doeling');
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

      // Analyze breeding success (shared logic with web: kidding/abortion based)
      final analysis = await _analyzeBreedingSuccess(
        filteredBreedingEvents,
        pregnancyEvents,
        birthEvents,
        abortionEvents,
      );

      return {
        'success': true,
        'data': analysis,
        'totalBreedingEvents': filteredBreedingEvents.length,
        'filteredBy': {
          'doe': selectedDoeTag,
          'buck': selectedBuckTag,
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
    List<Map<String, dynamic>> abortionEvents,
  ) async {
    final Map<String, List<Map<String, dynamic>>> doeBreedingHistory = {};
    final Map<String, List<Map<String, dynamic>>> doePregnancyHistory = {};
    final Map<String, List<Map<String, dynamic>>> doeBirthHistory = {};
    final Map<String, List<Map<String, dynamic>>> doeAbortionHistory = {};

    // Group events by doe
    for (final event in breedingEvents) {
      final doeTag = event['goat_tag']?.toString() ?? '';
      if (doeTag.isNotEmpty) {
        doeBreedingHistory.putIfAbsent(doeTag, () => []);
        doeBreedingHistory[doeTag]!.add(event);
      }
    }

    for (final event in pregnancyEvents) {
      final doeTag = event['goat_tag']?.toString() ?? '';
      if (doeTag.isNotEmpty) {
        doePregnancyHistory.putIfAbsent(doeTag, () => []);
        doePregnancyHistory[doeTag]!.add(event);
      }
    }

    for (final event in birthEvents) {
      final doeTag = event['goat_tag']?.toString() ?? '';
      if (doeTag.isNotEmpty) {
        doeBirthHistory.putIfAbsent(doeTag, () => []);
        doeBirthHistory[doeTag]!.add(event);
      }
    }

    for (final event in abortionEvents) {
      final doeTag = event['goat_tag']?.toString() ?? '';
      if (doeTag.isNotEmpty) {
        doeAbortionHistory.putIfAbsent(doeTag, () => []);
        doeAbortionHistory[doeTag]!.add(event);
      }
    }

    // Analyze each doe's breeding success
    final List<Map<String, dynamic>> doeAnalysis = [];
    final Map<String, Map<String, dynamic>> buckPerformance = {};
    final Map<String, Map<String, dynamic>> breedingTypePerformance = {};

    for (final doeTag in doeBreedingHistory.keys) {
      final doeBreedings = doeBreedingHistory[doeTag]!;
      final doePregnancies = doePregnancyHistory[doeTag] ?? [];
      final doeBirths = doeBirthHistory[doeTag] ?? [];
      final doeAbortions = doeAbortionHistory[doeTag] ?? [];

      // Sort events by date for deterministic evaluation
      DateTime? parseDateForDoe(Map<String, dynamic> e) {
        final raw = e['history_date']?.toString();
        if (raw == null || raw.isEmpty) return null;
        return DateTime.tryParse(raw);
      }

      int compareEventsForDoe(Map<String, dynamic> a, Map<String, dynamic> b) {
        final ad = parseDateForDoe(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = parseDateForDoe(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ad.compareTo(bd);
      }

      doeBreedings.sort(compareEventsForDoe);
      doePregnancies.sort(compareEventsForDoe);
      doeBirths.sort(compareEventsForDoe);
      doeAbortions.sort(compareEventsForDoe);

      final List<Map<String, dynamic>> successfulBreedings = [];
      final List<Map<String, dynamic>> failedBreedings = [];
      final List<Map<String, dynamic>> pendingBreedings = [];

      Map<String, dynamic>? firstEventMapAfterForDoe(List<Map<String, dynamic>> events, DateTime breedingDate) {
        for (final e in events) {
          final d = parseDateForDoe(e);
          if (d != null && d.isAfter(breedingDate)) return e;
        }
        return null;
      }

      Map<String, dynamic>? firstEventMapBetweenForDoe(
        List<Map<String, dynamic>> events,
        DateTime breedingDate,
        DateTime? before,
      ) {
        for (final e in events) {
          final d = parseDateForDoe(e);
          if (d == null) continue;
          if (!d.isAfter(breedingDate)) continue;
          if (before != null && !d.isBefore(before)) continue;
          return e;
        }
        return null;
      }

      for (final breeding in doeBreedings) {
        final breedingDate = parseDateForDoe(breeding) ?? DateTime.fromMillisecondsSinceEpoch(0);

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

        debugPrint('DEBUG: Analyzing breeding for doe $doeTag on ${breeding['history_date']}');
        debugPrint('DEBUG: Responsible buck: $responsibleBuck');
        debugPrint('DEBUG: Breeding type: $breedingType');

        // Find first kidding (birth) and abortion after this breeding
        final kiddingEvent = firstEventMapAfterForDoe(doeBirths, breedingDate);
        final abortionEvent = firstEventMapAfterForDoe(doeAbortions, breedingDate);

        // Optional pregnancy context (first pregnancy after breeding, before kidding if exists)
        Map<String, dynamic>? pregnancyEvent;
        if (kiddingEvent != null) {
          final kiddingDate = parseDateForDoe(kiddingEvent);
          pregnancyEvent = firstEventMapBetweenForDoe(doePregnancies, breedingDate, kiddingDate);
        } else {
          pregnancyEvent = firstEventMapAfterForDoe(doePregnancies, breedingDate);
        }

        // Rule:
        // - Success  => any kidding after breeding (even if abortions exist).
        // - Failed   => no kidding, but at least one abortion after breeding.
        // - Pending  => neither kidding nor abortion yet.
        bool isSuccess = false;

        if (kiddingEvent != null) {
          isSuccess = true;
          successfulBreedings.add({
            'history_date': breeding['history_date'],
            'breeding_type': breedingType,
            'kidding_date': kiddingEvent['history_date'],
            'pregnancy_date': pregnancyEvent?['history_date'],
            'status': 'successful',
          });
        } else if (abortionEvent != null) {
          failedBreedings.add({
            'history_date': breeding['history_date'],
            'breeding_type': breedingType,
            'abortion_date': abortionEvent['history_date'],
            'pregnancy_date': pregnancyEvent?['history_date'],
            'status': 'failed',
          });
        } else {
          pendingBreedings.add({
            'history_date': breeding['history_date'],
            'breeding_type': breedingType,
            'pregnancy_date': pregnancyEvent?['history_date'],
            'status': 'pending',
          });
        }

        // Track buck performance
        if (responsibleBuck != null) {
          buckPerformance.putIfAbsent(responsibleBuck, () => {
            'Buck_tag': responsibleBuck,
            'total_breedings': 0,
            'successful_breedings': 0,
            'success_rate': 0.0,
            'Does_served': <String>{},
          });
          
          buckPerformance[responsibleBuck]!['total_breedings'] = 
              (buckPerformance[responsibleBuck]!['total_breedings'] as int) + 1;
          (buckPerformance[responsibleBuck]!['Does_served'] as Set<String>).add(doeTag);
          
          if (isSuccess) {
            buckPerformance[responsibleBuck]!['successful_breedings'] = 
                (buckPerformance[responsibleBuck]!['successful_breedings'] as int) + 1;
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
        
        if (isSuccess) {
          breedingTypePerformance[breedingType]!['successful_breedings'] = 
              (breedingTypePerformance[breedingType]!['successful_breedings'] as int) + 1;
        }
      }

      // Calculate success rate for this doe (only count resolved breedings)
      final totalBreedings = doeBreedings.length;
      final resolvedBreedings = successfulBreedings.length + failedBreedings.length;
      final successfulCount = successfulBreedings.length;
      final pendingCount = pendingBreedings.length;
      final successRate = resolvedBreedings > 0 ? (successfulCount / resolvedBreedings) * 100 : 0.0;

      doeAnalysis.add({
        'Doe_tag': doeTag,
        'total_breedings': totalBreedings,
        'successful_breedings': successfulCount,
        'failed_breedings': failedBreedings.length,
        'pending_breedings': pendingCount,
        'resolved_breedings': resolvedBreedings,
        'success_rate': successRate,
        'successful_breedings_details': successfulBreedings,
        'failed_breedings_details': failedBreedings,
        'pending_breedings_details': pendingBreedings,
        'last_breeding_date': doeBreedings.isNotEmpty ? doeBreedings.last['history_date'] : null,
      });
    }

    // Calculate final success rates for Bucks and breeding types
    for (final buck in buckPerformance.values) {
      final total = buck['total_breedings'] as int;
      final successful = buck['successful_breedings'] as int;
      buck['success_rate'] = total > 0 ? (successful / total) * 100 : 0.0;
      buck['Does_served'] = (buck['Does_served'] as Set<String>).length;
    }

    for (final type in breedingTypePerformance.values) {
      final total = type['total_breedings'] as int;
      final successful = type['successful_breedings'] as int;
      type['success_rate'] = total > 0 ? (successful / total) * 100 : 0.0;
    }

    // Calculate overall statistics
    final totalBreedings = breedingEvents.length;
    final totalSuccessful = doeAnalysis.fold<int>(0, (sum, doe) => sum + (doe['successful_breedings'] as int));
    final totalFailed = doeAnalysis.fold<int>(0, (sum, doe) => sum + (doe['failed_breedings'] as int));
    final totalPending = doeAnalysis.fold<int>(0, (sum, doe) => sum + (doe['pending_breedings'] as int));
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
      'Doe_analysis': doeAnalysis,
      'Buck_performance': buckPerformance.values.toList(),
      'breeding_type_performance': breedingTypePerformance.values.toList(),
    };
  }

  static String? _getResponsibleBuck(Map<String, dynamic> event) {
    // For natural breeding, use Buck_tag
    if (event['breeding_type']?.toString() == 'natural_breeding') {
      return event['Buck_tag']?.toString();
    }
    
    // For artificial insemination, extract buck from semen_used
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
    final buckTag = event['Buck_tag']?.toString();
    if (buckTag != null && buckTag.isNotEmpty) {
      return buckTag;
    }
    
    return null;
  }


  // Get available does for filtering (only actual does, not Bucks)
  static Future<List<String>> getAvailableDoes() async {
    try {
      // Get all goat and filter only does
      final allGoats = await GoatService.getAllGoats();
      final does = allGoats.where((goat) => 
          goat.classification.toString().toLowerCase() == 'doe').toList();
      
              final List<String> doeTags = [];
        for (final doe in does) {
          final doeTag = doe.tagNo.toString();
          if (doeTag.isNotEmpty) {
            doeTags.add(doeTag);
          }
        }
      
      return doeTags..sort();
    } catch (e) {
      debugPrint('DEBUG: Error getting available does: $e');
      return [];
    }
  }

  // Get available Bucks for filtering
  static Future<List<String>> getAvailableBucks() async {
    try {
      final allEvents = await GoatHistoryService.getgoatHistory();
      final breedingEvents = allEvents.where((event) =>
          event['history_type']?.toString().toLowerCase() == 'breeding').toList();
      
      final Set<String> buckTags = {};
      for (final event in breedingEvents) {
        final buck = _getResponsibleBuck(event);
        if (buck != null && buck.isNotEmpty) {
          buckTags.add(buck);
        }
      }
      
      return buckTags.toList()..sort();
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


