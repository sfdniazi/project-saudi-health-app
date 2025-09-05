import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/food_model.dart';
import '../models/activity_model.dart';

/// Service for integrating with Google Gemini AI to provide personalized 
/// food and exercise recommendations based on user data
class GeminiAIService {
  static const String _apiKey = 'AIzaSyCyZtA-QogjpHQhW6Eo6-iJEshfqpu_QRg';
  static const String _modelName = 'gemini-1.5-flash';
  static const String _cacheKey = 'ai_recommendations_cache';
  static const Duration _cacheExpiry = Duration(hours: 2);
  
  static GenerativeModel? _model;
  static GenerativeModel get _geminiModel {
    _model ??= GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1000,
      ),
      safetySettings: [
        SafetySetting(
          HarmCategory.harassment,
          HarmBlockThreshold.medium,
        ),
        SafetySetting(
          HarmCategory.hateSpeech,
          HarmBlockThreshold.medium,
        ),
        SafetySetting(
          HarmCategory.sexuallyExplicit,
          HarmBlockThreshold.medium,
        ),
        SafetySetting(
          HarmCategory.dangerousContent,
          HarmBlockThreshold.medium,
        ),
      ],
    );
    return _model!;
  }

  /// Generate personalized food and exercise recommendations using Gemini AI
  static Future<AIRecommendationResponse> generateRecommendations({
    required UserModel userProfile,
    List<FoodLogModel>? recentFoodLogs,
    List<ActivityModel>? recentActivities,
    String? userQuery,
    bool useCache = true,
  }) async {
    try {
      // Check cache first
      if (useCache && userQuery == null) {
        final cachedResponse = await _getCachedRecommendations(userProfile.uid);
        if (cachedResponse != null) {
          debugPrint('✅ Using cached AI recommendations');
          return cachedResponse;
        }
      }

      debugPrint('🤖 Generating new AI recommendations...');

      // Prepare context for AI
      final context = _buildUserContext(
        userProfile: userProfile,
        recentFoodLogs: recentFoodLogs,
        recentActivities: recentActivities,
        userQuery: userQuery,
      );

      // Generate AI response
      final content = [Content.text(context)];
      final response = await _geminiModel.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw AIException('Empty response from AI service');
      }

      // Parse and validate response
      final aiResponse = _parseAIResponse(response.text!);
      
      // Cache the response if it's a general recommendation
      if (userQuery == null) {
        await _cacheRecommendations(userProfile.uid, aiResponse);
      }

      debugPrint('✅ AI recommendations generated successfully');
      return aiResponse;

    } catch (e) {
      debugPrint('❌ AI recommendation error: $e');
      
      if (e is AIException) {
        rethrow;
      }
      
      // Return fallback recommendations on error
      return _getFallbackRecommendations(userProfile);
    }
  }

  /// Generate interactive chat response for user queries
  static Future<String> generateChatResponse({
    required String userQuery,
    required UserModel userProfile,
    List<String>? conversationHistory,
  }) async {
    try {
      debugPrint('🤖 Generating chat response for: $userQuery');

      // Build chat context
      final context = _buildChatContext(
        userQuery: userQuery,
        userProfile: userProfile,
        conversationHistory: conversationHistory,
      );

      final content = [Content.text(context)];
      final response = await _geminiModel.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw AIException('Empty response from AI service');
      }

      debugPrint('✅ Chat response generated successfully');
      return response.text!;

    } catch (e) {
      debugPrint('❌ Chat response error: $e');
      return _getFallbackChatResponse(userQuery);
    }
  }

  /// Build comprehensive user context for AI recommendations
  static String _buildUserContext({
    required UserModel userProfile,
    List<FoodLogModel>? recentFoodLogs,
    List<ActivityModel>? recentActivities,
    String? userQuery,
  }) {
    final context = StringBuffer();
    
    context.writeln('You are a professional nutritionist and fitness expert AI assistant.');
    context.writeln('Provide personalized, evidence-based food and exercise recommendations.');
    context.writeln('Keep responses concise, actionable, and motivating.');
    context.writeln();

    // User profile information
    context.writeln('=== USER PROFILE ===');
    context.writeln('Age: ${userProfile.age} years');
    context.writeln('Gender: ${userProfile.gender}');
    context.writeln('Height: ${userProfile.height} cm');
    context.writeln('Weight: ${userProfile.weight} kg');
    context.writeln('BMI: ${userProfile.bmi.toStringAsFixed(1)}');
    context.writeln('Daily Calorie Goal: ${userProfile.dailyGoal} kcal');
    context.writeln();

    // Recent food logs
    if (recentFoodLogs != null && recentFoodLogs.isNotEmpty) {
      context.writeln('=== RECENT NUTRITION (Last 7 days) ===');
      for (final log in recentFoodLogs.take(7)) {
        context.writeln('Date: ${log.date.day}/${log.date.month}');
        context.writeln('Total Calories: ${log.totalCalories.toInt()} kcal');
        context.writeln('Protein: ${log.totalProtein.toInt()}g');
        context.writeln('Carbs: ${log.totalCarbs.toInt()}g');
        context.writeln('Fat: ${log.totalFat.toInt()}g');
        
        if (log.meals.isNotEmpty) {
          context.writeln('Meals: ${log.meals.map((m) => '${m.mealType} (${m.items.length} items)').join(', ')}');
        }
        context.writeln('---');
      }
      context.writeln();
    }

    // Recent activities
    if (recentActivities != null && recentActivities.isNotEmpty) {
      context.writeln('=== RECENT ACTIVITY (Last 7 days) ===');
      for (final activity in recentActivities.take(7)) {
        context.writeln('Date: ${activity.date.day}/${activity.date.month}');
        context.writeln('Steps: ${activity.steps}');
        context.writeln('Distance: ${activity.distance.toStringAsFixed(1)} km');
        context.writeln('Calories Burned: ${activity.calories.toInt()} kcal');
        context.writeln('Active Minutes: ${activity.activeMinutes}');
        context.writeln('---');
      }
      context.writeln();
    }

    // User query or default prompt
    if (userQuery != null && userQuery.isNotEmpty) {
      context.writeln('=== USER QUESTION ===');
      context.writeln(userQuery);
      context.writeln();
      context.writeln('Please provide a helpful, personalized answer based on the user\'s profile and recent data.');
    } else {
      context.writeln('=== TASK ===');
      context.writeln('Based on the user\'s profile and recent data, provide:');
      context.writeln('1. 3 personalized food recommendations with specific meals/foods');
      context.writeln('2. 3 personalized exercise recommendations with specific activities');
      context.writeln('3. 1 motivational tip related to their current progress');
      context.writeln();
      context.writeln('Format as JSON with this structure:');
      context.writeln('{');
      context.writeln('  "foodRecommendations": [');
      context.writeln('    {"title": "...", "description": "...", "calories": 000, "type": "meal/snack"}');
      context.writeln('  ],');
      context.writeln('  "exerciseRecommendations": [');
      context.writeln('    {"title": "...", "description": "...", "duration": 00, "calories": 000}');
      context.writeln('  ],');
      context.writeln('  "motivationalTip": "..."');
      context.writeln('}');
    }

    return context.toString();
  }

  /// Build chat context for conversational responses
  static String _buildChatContext({
    required String userQuery,
    required UserModel userProfile,
    List<String>? conversationHistory,
  }) {
    final context = StringBuffer();
    
    context.writeln('You are a friendly, knowledgeable nutrition and fitness AI assistant.');
    context.writeln('Provide helpful, personalized advice based on the user\'s profile.');
    context.writeln('Keep responses conversational, encouraging, and under 200 words.');
    context.writeln();

    // Basic user info for context
    context.writeln('User: ${userProfile.displayName}, ${userProfile.age}y, BMI: ${userProfile.bmi.toStringAsFixed(1)}');
    context.writeln();

    // Conversation history
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      context.writeln('=== CONVERSATION HISTORY ===');
      for (int i = 0; i < conversationHistory.length && i < 6; i++) {
        final isUser = i % 2 == 0;
        context.writeln('${isUser ? "User" : "Assistant"}: ${conversationHistory[i]}');
      }
      context.writeln();
    }

    context.writeln('User: $userQuery');
    context.writeln();
    context.writeln('Please provide a helpful, personalized response.');

    return context.toString();
  }

  /// Parse AI response and extract structured recommendations
  static AIRecommendationResponse _parseAIResponse(String responseText) {
    try {
      // Try to extract JSON from response
      final jsonStart = responseText.indexOf('{');
      final jsonEnd = responseText.lastIndexOf('}') + 1;
      
      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = responseText.substring(jsonStart, jsonEnd);
        final jsonData = json.decode(jsonStr);
        
        return AIRecommendationResponse(
          foodRecommendations: (jsonData['foodRecommendations'] as List<dynamic>?)
              ?.map((item) => AIFoodRecommendation.fromJson(item))
              .toList() ?? [],
          exerciseRecommendations: (jsonData['exerciseRecommendations'] as List<dynamic>?)
              ?.map((item) => AIExerciseRecommendation.fromJson(item))
              .toList() ?? [],
          motivationalTip: jsonData['motivationalTip'] as String? ?? '',
          rawResponse: responseText,
        );
      }
    } catch (e) {
      debugPrint('Failed to parse JSON response: $e');
    }

    // Fallback: create response from text analysis
    return _parseTextResponse(responseText);
  }

  /// Parse text-based response as fallback
  static AIRecommendationResponse _parseTextResponse(String responseText) {
    final lines = responseText.split('\n');
    final foodRecs = <AIFoodRecommendation>[];
    final exerciseRecs = <AIExerciseRecommendation>[];
    
    // Simple text parsing (basic implementation)
    String motivationalTip = 'Keep up the great work on your health journey!';
    
    // Extract any obvious food or exercise mentions
    for (final line in lines) {
      if (line.toLowerCase().contains('eat') || line.toLowerCase().contains('meal')) {
        foodRecs.add(AIFoodRecommendation(
          title: 'Nutrition Suggestion',
          description: line.trim(),
          calories: 300,
          type: 'meal',
        ));
      }
      if (line.toLowerCase().contains('exercise') || line.toLowerCase().contains('workout')) {
        exerciseRecs.add(AIExerciseRecommendation(
          title: 'Exercise Suggestion',
          description: line.trim(),
          duration: 30,
          calories: 200,
        ));
      }
    }
    
    return AIRecommendationResponse(
      foodRecommendations: foodRecs,
      exerciseRecommendations: exerciseRecs,
      motivationalTip: motivationalTip,
      rawResponse: responseText,
    );
  }

  /// Get cached recommendations if available and valid
  static Future<AIRecommendationResponse?> _getCachedRecommendations(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cacheKey}_$userId';
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final cacheJson = json.decode(cachedData);
        final cacheTime = DateTime.parse(cacheJson['timestamp']);
        
        if (DateTime.now().difference(cacheTime) < _cacheExpiry) {
          return AIRecommendationResponse.fromJson(cacheJson['data']);
        }
      }
    } catch (e) {
      debugPrint('Cache read error: $e');
    }
    return null;
  }

  /// Cache recommendations for future use
  static Future<void> _cacheRecommendations(String userId, AIRecommendationResponse response) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cacheKey}_$userId';
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': response.toJson(),
      };
      await prefs.setString(cacheKey, json.encode(cacheData));
    } catch (e) {
      debugPrint('Cache write error: $e');
    }
  }

  /// Get fallback recommendations when AI is unavailable
  static AIRecommendationResponse _getFallbackRecommendations(UserModel userProfile) {
    final bmi = userProfile.bmi;
    
    return AIRecommendationResponse(
      foodRecommendations: [
        AIFoodRecommendation(
          title: 'Balanced Breakfast',
          description: 'Start your day with oatmeal topped with berries and nuts for sustained energy.',
          calories: 350,
          type: 'meal',
        ),
        AIFoodRecommendation(
          title: 'Protein-Rich Lunch',
          description: 'Grilled chicken salad with mixed vegetables provides lean protein and fiber.',
          calories: 450,
          type: 'meal',
        ),
        AIFoodRecommendation(
          title: 'Healthy Snack',
          description: 'Greek yogurt with almonds offers protein and healthy fats.',
          calories: 180,
          type: 'snack',
        ),
      ],
      exerciseRecommendations: [
        AIExerciseRecommendation(
          title: '30-Minute Walk',
          description: 'A brisk walk is great for cardiovascular health and calorie burning.',
          duration: 30,
          calories: 150,
        ),
        AIExerciseRecommendation(
          title: 'Bodyweight Exercises',
          description: 'Push-ups, squats, and planks can be done anywhere for strength building.',
          duration: 20,
          calories: 120,
        ),
        AIExerciseRecommendation(
          title: 'Stretching Routine',
          description: 'Gentle stretching improves flexibility and helps with recovery.',
          duration: 15,
          calories: 50,
        ),
      ],
      motivationalTip: bmi < 18.5 
          ? 'Focus on nutrient-dense foods to reach a healthy weight!' 
          : bmi > 25 
              ? 'Small, consistent changes lead to lasting results!' 
              : 'Great job maintaining a healthy lifestyle!',
      rawResponse: 'Fallback recommendations due to AI service unavailability.',
    );
  }

  /// Get fallback chat response
  static String _getFallbackChatResponse(String userQuery) {
    if (userQuery.toLowerCase().contains('food') || userQuery.toLowerCase().contains('eat')) {
      return "I'd recommend focusing on whole foods like fruits, vegetables, lean proteins, and whole grains. What specific aspect of nutrition would you like to know more about?";
    }
    
    if (userQuery.toLowerCase().contains('exercise') || userQuery.toLowerCase().contains('workout')) {
      return "Regular physical activity is key to good health! Try to include both cardio and strength training. What type of activities do you enjoy?";
    }
    
    return "I'm here to help with your nutrition and fitness questions! Could you please be more specific about what you'd like to know?";
  }
}

/// Exception class for AI-related errors
class AIException implements Exception {
  final String message;
  AIException(this.message);
  
  @override
  String toString() => 'AIException: $message';
}

/// Response model for AI recommendations
class AIRecommendationResponse {
  final List<AIFoodRecommendation> foodRecommendations;
  final List<AIExerciseRecommendation> exerciseRecommendations;
  final String motivationalTip;
  final String rawResponse;

  AIRecommendationResponse({
    required this.foodRecommendations,
    required this.exerciseRecommendations,
    required this.motivationalTip,
    required this.rawResponse,
  });

  Map<String, dynamic> toJson() => {
    'foodRecommendations': foodRecommendations.map((e) => e.toJson()).toList(),
    'exerciseRecommendations': exerciseRecommendations.map((e) => e.toJson()).toList(),
    'motivationalTip': motivationalTip,
    'rawResponse': rawResponse,
  };

  factory AIRecommendationResponse.fromJson(Map<String, dynamic> json) => 
      AIRecommendationResponse(
        foodRecommendations: (json['foodRecommendations'] as List<dynamic>?)
            ?.map((e) => AIFoodRecommendation.fromJson(e))
            .toList() ?? [],
        exerciseRecommendations: (json['exerciseRecommendations'] as List<dynamic>?)
            ?.map((e) => AIExerciseRecommendation.fromJson(e))
            .toList() ?? [],
        motivationalTip: json['motivationalTip'] as String? ?? '',
        rawResponse: json['rawResponse'] as String? ?? '',
      );
}

/// Model for AI food recommendations
class AIFoodRecommendation {
  final String title;
  final String description;
  final int calories;
  final String type; // meal, snack, etc.

  AIFoodRecommendation({
    required this.title,
    required this.description,
    required this.calories,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'calories': calories,
    'type': type,
  };

  factory AIFoodRecommendation.fromJson(Map<String, dynamic> json) => 
      AIFoodRecommendation(
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        calories: (json['calories'] as num?)?.toInt() ?? 0,
        type: json['type'] as String? ?? 'meal',
      );
}

/// Model for AI exercise recommendations
class AIExerciseRecommendation {
  final String title;
  final String description;
  final int duration; // minutes
  final int calories;

  AIExerciseRecommendation({
    required this.title,
    required this.description,
    required this.duration,
    required this.calories,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'duration': duration,
    'calories': calories,
  };

  factory AIExerciseRecommendation.fromJson(Map<String, dynamic> json) => 
      AIExerciseRecommendation(
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        duration: (json['duration'] as num?)?.toInt() ?? 0,
        calories: (json['calories'] as num?)?.toInt() ?? 0,
      );
}
