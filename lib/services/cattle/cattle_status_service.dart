import 'dart:developer';
import '../auth_service.dart';
import 'cattle_service.dart';
import 'cattle_history_service.dart';

class CattleStatusService {
  /// Check and update cattle status based on breeding history and return to heat dates
  static Future<List<String>> checkAndUpdateBreedingStatus() async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('CattleStatusService: No token found');
      return [];
    }

    List<String> updatedCattle = [];

    try {
      // Get all cattle
      final cattleData = await CattleService.getCattleInformation();
      if (cattleData.isEmpty) {
        log('CattleStatusService: No cattle data found');
        return [];
      }

      // Get all cattle history
      final eventsData = await CattleHistoryService.getCattleHistory();
      if (eventsData.isEmpty) {
        log('CattleStatusService: No history data found');
        return [];
      }

      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Filter female cattle with "Breeding" status
      final breedingCattle = cattleData.where((cattle) {
        final cattleMap = cattle;
        return cattleMap['sex'] == 'Female' && cattleMap['status'] == 'Breeding';
      }).toList();

      log('CattleStatusService: Found ${breedingCattle.length} female cattle with Breeding status');

      for (final cattle in breedingCattle) {
        final cattleMap = cattle;
        final cattleId = cattleMap['id'];

        // Find the most recent breeding event for this cattle
        final breedingEvents = eventsData.where((event) {
          final eventMap = event;
          return eventMap['cattle_id'] == cattleId && 
                 eventMap['event_type'] == 'Breeding';
        }).toList();

        if (breedingEvents.isNotEmpty) {
          // Sort by date to get the most recent
          breedingEvents.sort((a, b) {
            final aDate = DateTime.tryParse(a['event_date'] ?? '');
            final bDate = DateTime.tryParse(b['event_date'] ?? '');
            if (aDate == null || bDate == null) return 0;
            return bDate.compareTo(aDate); // Most recent first
          });

          final mostRecentBreeding = breedingEvents.first;
          final estimatedReturnDate = mostRecentBreeding['estimated_return_date'];

          if (estimatedReturnDate != null && estimatedReturnDate.isNotEmpty) {
            // Check if today is the estimated return date
            if (estimatedReturnDate == todayString) {
              log('CattleStatusService: Updating status for cattle $cattleId from Breeding to Healthy');
              
              // Update cattle status to Healthy
              final updateData = Map<String, dynamic>.from(cattleMap);
              updateData['status'] = 'Healthy';
              
              final success = await CattleService.updateCattleInformation(updateData);
              if (success) {
                updatedCattle.add(cattleMap['tag_number'] ?? 'Unknown');
                log('CattleStatusService: Successfully updated cattle $cattleId status to Healthy');
              } else {
                log('CattleStatusService: Failed to update cattle $cattleId status');
              }
            }
          }
        }
      }

      log('CattleStatusService: Updated ${updatedCattle.length} cattle statuses');
      return updatedCattle;

    } catch (e, stackTrace) {
      log('CattleStatusService: Error checking breeding status: $e', stackTrace: stackTrace);
      return [];
    }
  }

  /// Check for cattle that need status updates based on breeding history
  static Future<List<Map<String, dynamic>>> getCattleNeedingStatusUpdate() async {
    final token = await AuthService.getToken();
    if (token == null) {
      log('CattleStatusService: No token found');
      return [];
    }

    try {
      // Get all cattle
      final cattleData = await CattleService.getCattleInformation();
      if (cattleData.isEmpty) {
        return [];
      }

      // Get all cattle history
      final eventsData = await CattleHistoryService.getCattleHistory();
      if (eventsData.isEmpty) {
        return [];
      }

      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      List<Map<String, dynamic>> cattleNeedingUpdate = [];

      // Filter female cattle with "Breeding" status
      final breedingCattle = cattleData.where((cattle) {
        final cattleMap = cattle;
        return cattleMap['sex'] == 'Female' && cattleMap['status'] == 'Breeding';
      }).toList();

      for (final cattle in breedingCattle) {
        final cattleMap = cattle;
        final cattleId = cattleMap['id'];

        // Find the most recent breeding event for this cattle
        final breedingEvents = eventsData.where((event) {
          final eventMap = event;
          return eventMap['cattle_id'] == cattleId && 
                 eventMap['event_type'] == 'Breeding';
        }).toList();

        if (breedingEvents.isNotEmpty) {
          // Sort by date to get the most recent
          breedingEvents.sort((a, b) {
            final aDate = DateTime.tryParse(a['event_date'] ?? '');
            final bDate = DateTime.tryParse(b['event_date'] ?? '');
            if (aDate == null || bDate == null) return 0;
            return bDate.compareTo(aDate); // Most recent first
          });

          final mostRecentBreeding = breedingEvents.first;
          final estimatedReturnDate = mostRecentBreeding['estimated_return_date'];

          if (estimatedReturnDate != null && estimatedReturnDate.isNotEmpty) {
            // Check if today is the estimated return date
            if (estimatedReturnDate == todayString) {
              cattleNeedingUpdate.add({
                'cattle': cattleMap,
                'breeding_event': mostRecentBreeding,
                'estimated_return_date': estimatedReturnDate,
              });
            }
          }
        }
      }

      return cattleNeedingUpdate;

    } catch (e, stackTrace) {
      log('CattleStatusService: Error getting cattle needing status update: $e', stackTrace: stackTrace);
      return [];
    }
  }
}
