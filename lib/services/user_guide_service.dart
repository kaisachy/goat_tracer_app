import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage user guide state and completion status
class UserGuideService {
  static const String _guideCompletedKey = 'user_guide_completed_';
  
  /// Check if the guide for a specific screen has been completed
  static Future<bool> isGuideCompleted(String screenName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_guideCompletedKey$screenName') ?? false;
    } catch (e) {
      return false;
    }
  }
  
  /// Mark the guide for a specific screen as completed
  static Future<void> markGuideCompleted(String screenName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_guideCompletedKey$screenName', true);
    } catch (e) {
      // Handle error silently
    }
  }
  
  /// Reset the guide completion status for a specific screen
  static Future<void> resetGuide(String screenName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_guideCompletedKey$screenName');
    } catch (e) {
      // Handle error silently
    }
  }
  
  /// Reset all guides (useful for testing or user preference)
  static Future<void> resetAllGuides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_guideCompletedKey)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }
}

