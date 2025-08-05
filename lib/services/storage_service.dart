import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences_model.dart';
import '../models/recommendation_model.dart';

class StorageService {
  static const String userPreferencesKey = 'user_preferences';
  static const String recommendationsKey = 'recommendations';

  // Save user preferences to local storage
  Future<bool> saveUserPreferences(UserPreferences userPreferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(userPreferences.toJson());
      return await prefs.setString(userPreferencesKey, jsonString);
    } catch (e) {
      print('Error saving user preferences: $e');
      return false;
    }
  }

  // Get user preferences from local storage
  Future<UserPreferences?> getUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(userPreferencesKey);
      
      if (jsonString == null) {
        return null;
      }
      
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      return UserPreferences.fromJson(jsonData);
    } catch (e) {
      print('Error getting user preferences: $e');
      return null;
    }
  }

  // Save recommendations to local storage
  Future<bool> saveRecommendations(List<OutfitRecommendation> recommendations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList = recommendations.map((rec) => rec.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      return await prefs.setString(recommendationsKey, jsonString);
    } catch (e) {
      print('Error saving recommendations: $e');
      return false;
    }
  }

  // Get recommendations from local storage
  Future<List<OutfitRecommendation>?> getRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(recommendationsKey);
      
      if (jsonString == null) {
        return null;
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return OutfitRecommendation.fromJsonList(jsonList);
    } catch (e) {
      print('Error getting recommendations: $e');
      return null;
    }
  }
  // Check if user has previous recommendations
  Future<bool> hasPreviousRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(recommendationsKey);
    } catch (e) {
      print('Error checking previous recommendations: $e');
      return false;
    }
  }
  
  // Clear all stored data (for testing or reset)
  Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(userPreferencesKey);
      await prefs.remove(recommendationsKey);
      return true;
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }
}
