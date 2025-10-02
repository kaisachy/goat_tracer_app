import 'dart:developer';
import 'cattle/cattle_status_service.dart';
import 'profile/personal_information_service.dart';
import 'cattle/cattle_service.dart';
import 'milk/milk_production_service.dart';
import 'schedule/schedule_service.dart';

class RefreshService {
  /// Comprehensive refresh for all app data
  static Future<Map<String, dynamic>> refreshAllData() async {
    Map<String, dynamic> results = {
      'cattleStatusUpdates': [],
      'profileRefreshed': false,
      'cattleDataRefreshed': false,
      'milkDataRefreshed': false,
      'scheduleDataRefreshed': false,
      'errors': [],
    };

    try {
      // 1. Check and update cattle breeding status
      try {
        final updatedCattle = await CattleStatusService.checkAndUpdateBreedingStatus();
        results['cattleStatusUpdates'] = updatedCattle;
        log('RefreshService: Cattle status updates completed');
      } catch (e) {
        results['errors'].add('Cattle status update failed: $e');
        log('RefreshService: Error updating cattle status: $e');
      }

      // 2. Refresh profile data
      try {
        await PersonalInformationService.getPersonalInformation();
        results['profileRefreshed'] = true;
        log('RefreshService: Profile data refreshed');
      } catch (e) {
        results['errors'].add('Profile refresh failed: $e');
        log('RefreshService: Error refreshing profile: $e');
      }

      // 3. Refresh cattle data
      try {
        await CattleService.getCattleInformation();
        results['cattleDataRefreshed'] = true;
        log('RefreshService: Cattle data refreshed');
      } catch (e) {
        results['errors'].add('Cattle data refresh failed: $e');
        log('RefreshService: Error refreshing cattle data: $e');
      }

      // 4. Refresh milk data
      try {
        await MilkProductionService.getMilkProductions();
        results['milkDataRefreshed'] = true;
        log('RefreshService: Milk data refreshed');
      } catch (e) {
        results['errors'].add('Milk data refresh failed: $e');
        log('RefreshService: Error refreshing milk data: $e');
      }

      // 5. Refresh schedule data
      try {
        await ScheduleService.getSchedules();
        results['scheduleDataRefreshed'] = true;
        log('RefreshService: Schedule data refreshed');
      } catch (e) {
        results['errors'].add('Schedule data refresh failed: $e');
        log('RefreshService: Error refreshing schedule data: $e');
      }

    } catch (e) {
      results['errors'].add('General refresh error: $e');
      log('RefreshService: General error during refresh: $e');
    }

    return results;
  }

  /// Refresh data for a specific page
  static Future<Map<String, dynamic>> refreshPageData(int pageIndex) async {
    Map<String, dynamic> results = {
      'success': false,
      'message': '',
      'data': null,
      'errors': [],
    };

    try {
      switch (pageIndex) {
        case 0: // Profile
          try {
            await PersonalInformationService.getPersonalInformation();
            results['success'] = true;
            results['message'] = 'Profile data refreshed';
          } catch (e) {
            results['errors'].add('Profile refresh failed: $e');
          }
          break;
          
        case 1: // Production Record (Cattle)
          try {
            await CattleService.getCattleInformation();
            final updatedCattle = await CattleStatusService.checkAndUpdateBreedingStatus();
            results['success'] = true;
            results['message'] = 'Cattle data refreshed';
            results['data'] = updatedCattle;
          } catch (e) {
            results['errors'].add('Cattle refresh failed: $e');
          }
          break;
          
        case 2: // Dashboard
          // Refresh dashboard data (cattle, milk, schedule summaries)
          try {
            await CattleService.getCattleInformation();
            await MilkProductionService.getMilkProductions();
            await ScheduleService.getSchedules();
            results['success'] = true;
            results['message'] = 'Dashboard data refreshed';
          } catch (e) {
            results['errors'].add('Dashboard refresh failed: $e');
          }
          break;
          
        case 3: // Events
          try {
            // Events don't have a specific service refresh, but we can refresh cattle data
            // since events are related to cattle
            await CattleService.getCattleInformation();
            results['success'] = true;
            results['message'] = 'Events data refreshed';
          } catch (e) {
            results['errors'].add('Events refresh failed: $e');
          }
          break;
          
        case 4: // Schedule
          try {
            await ScheduleService.getSchedules();
            results['success'] = true;
            results['message'] = 'Schedule data refreshed';
          } catch (e) {
            results['errors'].add('Schedule refresh failed: $e');
          }
          break;
          
        case 5: // Milk Production
          try {
            await MilkProductionService.getMilkProductions();
            results['success'] = true;
            results['message'] = 'Milk data refreshed';
          } catch (e) {
            results['errors'].add('Milk refresh failed: $e');
          }
          break;
          
        case 6: // Settings
          results['success'] = true;
          results['message'] = 'Settings refreshed';
          break;
          
        default:
          results['errors'].add('Unknown page index: $pageIndex');
      }
    } catch (e) {
      results['errors'].add('Page refresh error: $e');
    }

    return results;
  }

  /// Get a user-friendly message based on refresh results
  static String getRefreshMessage(Map<String, dynamic> results) {
    if (results['errors'].isNotEmpty) {
      return 'Refresh completed with some errors';
    }
    
    if (results['cattleStatusUpdates'].isNotEmpty) {
      return 'Data refreshed! ${results['cattleStatusUpdates'].length} cow(s) status updated';
    }
    
    return 'Data refreshed successfully!';
  }
}
