import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';
import '../models/recommendation_model.dart';
import '../models/user_preferences_model.dart';

class ApiService {
  final String baseUrl = 'https://simple-walrus-initially.ngrok-free.app';
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // Get all questions from the API
  Future<List<Question>> getQuestions() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/questions'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return Question.fromJsonList(jsonData);
      } else {
        throw Exception('Failed to load questions: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to load questions: $e');
    }
  }

  // Submit user preferences to the API
  Future<Map<String, dynamic>> submitPreferences(Map<String, dynamic> preferences) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/preferences'),
        headers: {
          'Content-Type': 'application/json'
        },
        body: jsonEncode(preferences),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to submit preferences: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to submit preferences: $e');
    }
  }

  // Get outfit recommendations from the API
  Future<List<OutfitRecommendation>> getRecommendations() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/recommendations'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final List<dynamic> outfitsJson = jsonData['outfits'] ?? [];
        return OutfitRecommendation.fromJsonList(outfitsJson);
      } else {
        throw Exception('Failed to load recommendations: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to load recommendations: $e');
    }
  }
}
