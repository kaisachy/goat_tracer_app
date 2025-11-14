import 'dart:developer';
import '../auth_service.dart';
import 'goat_service.dart';
import 'goat_history_service.dart';

class GoatStatusService {
  /// Check and update goat status based on breeding history and return to heat dates
  static Future<List<String>> checkAndUpdateBreedingStatus() async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('GoatStatusService: No token found');
      return [];
    }

    List<String> updatedgoat = [];

    try {
      // Get all goat
      final goatData = await GoatService.getGoatInformation();
      if (goatData.isEmpty) {
        log('GoatStatusService: No goat data found');
        return [];
      }

      // Get all Goat History
      final eventsData = await GoatHistoryService.getgoatHistory();
      if (eventsData.isEmpty) {
        log('GoatStatusService: No history data found');
        return [];
      }

      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Filter female goat with "Breeding" status
      final breedinggoat = goatData.where((goat) {
        final goatMap = goat;
        return goatMap['sex'] == 'Female' && goatMap['status'] == 'Breeding';
      }).toList();

      log('GoatStatusService: Found ${breedinggoat.length} female goat with Breeding status');

      for (final goat in breedinggoat) {
        final goatMap = goat;
        final goatId = goatMap['id'];

        // Find the most recent breeding event for this goat
        final breedingEvents = eventsData.where((event) {
          final eventMap = event;
          return eventMap['goat_id'] == goatId && 
                 eventMap['history_type'] == 'Breeding';
        }).toList();

        if (breedingEvents.isNotEmpty) {
          // Sort by date to get the most recent
          breedingEvents.sort((a, b) {
            final aDate = DateTime.tryParse(a['history_date'] ?? '');
            final bDate = DateTime.tryParse(b['history_date'] ?? '');
            if (aDate == null || bDate == null) return 0;
            return bDate.compareTo(aDate); // Most recent first
          });

          final mostRecentBreeding = breedingEvents.first;
          final estimatedReturnDate = mostRecentBreeding['estimated_return_date'];

          if (estimatedReturnDate != null && estimatedReturnDate.isNotEmpty) {
            // Check if today is the estimated return date
            if (estimatedReturnDate == todayString) {
              log('GoatStatusService: Updating status for goat $goatId from Breeding to Healthy');
              
              // Update goat status to Healthy
              final updateData = Map<String, dynamic>.from(goatMap);
              updateData['status'] = 'Healthy';
              
              final success = await GoatService.updategoatInformation(updateData);
              if (success) {
                updatedgoat.add(goatMap['tag_number'] ?? 'Unknown');
                log('GoatStatusService: Successfully updated goat $goatId status to Healthy');
              } else {
                log('GoatStatusService: Failed to update goat $goatId status');
              }
            }
          }
        }
      }

      log('GoatStatusService: Updated ${updatedgoat.length} goat statuses');
      return updatedgoat;

    } catch (e, stackTrace) {
      log('GoatStatusService: Error checking breeding status: $e', stackTrace: stackTrace);
      return [];
    }
  }

  /// Check for goat that need status updates based on breeding history
  static Future<List<Map<String, dynamic>>> getgoatNeedingStatusUpdate() async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('GoatStatusService: No token found');
      return [];
    }

    try {
      // Get all goat
      final goatData = await GoatService.getGoatInformation();
      if (goatData.isEmpty) {
        return [];
      }

      // Get all Goat History
      final eventsData = await GoatHistoryService.getgoatHistory();
      if (eventsData.isEmpty) {
        return [];
      }

      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      List<Map<String, dynamic>> goatNeedingUpdate = [];

      // Filter female goat with "Breeding" status
      final breedinggoat = goatData.where((goat) {
        final goatMap = goat;
        return goatMap['sex'] == 'Female' && goatMap['status'] == 'Breeding';
      }).toList();

      for (final goat in breedinggoat) {
        final goatMap = goat;
        final goatId = goatMap['id'];

        // Find the most recent breeding event for this goat
        final breedingEvents = eventsData.where((event) {
          final eventMap = event;
          return eventMap['goat_id'] == goatId && 
                 eventMap['history_type'] == 'Breeding';
        }).toList();

        if (breedingEvents.isNotEmpty) {
          // Sort by date to get the most recent
          breedingEvents.sort((a, b) {
            final aDate = DateTime.tryParse(a['history_date'] ?? '');
            final bDate = DateTime.tryParse(b['history_date'] ?? '');
            if (aDate == null || bDate == null) return 0;
            return bDate.compareTo(aDate); // Most recent first
          });

          final mostRecentBreeding = breedingEvents.first;
          final estimatedReturnDate = mostRecentBreeding['estimated_return_date'];

          if (estimatedReturnDate != null && estimatedReturnDate.isNotEmpty) {
            // Check if today is the estimated return date
            if (estimatedReturnDate == todayString) {
              goatNeedingUpdate.add({
                'goat': goatMap,
                'breeding_event': mostRecentBreeding,
                'estimated_return_date': estimatedReturnDate,
              });
            }
          }
        }
      }

      return goatNeedingUpdate;

    } catch (e, stackTrace) {
      log('GoatStatusService: Error getting goat needing status update: $e', stackTrace: stackTrace);
      return [];
    }
  }
}
