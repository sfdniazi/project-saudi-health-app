import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../services/firebase_service.dart';
import '../../../services/gemini_ai_service.dart';
import '../../../models/user_model.dart';
import '../../../models/food_model.dart';
import '../../../models/activity_model.dart';
import '../models/ai_recommendations_state_model.dart';

/// Provider for managing AI recommendations state and interactions
/// Follows the same pattern as other providers in the app
class AIRecommendationsProvider with ChangeNotifier {
  // Private state
  AIRecommendationsStateModel _state = const AIRecommendationsStateModel();
  
  // Stream subscriptions
  final Map<String, StreamSubscription> _streamSubscriptions = {};
  
  // Timer for periodic data refresh
  Timer? _refreshTimer;
  
  // User and connectivity
  User? _currentUser;
  UserModel? _userProfile;
  bool _hasInternetConnection = true;
  
  // Cached data for recommendations
  List<FoodLogModel>? _recentFoodLogs;
  List<ActivityModel>? _recentActivities;

  // Public getters
  AIRecommendationsStateModel get state => _state;
  AIRecommendationStatus get status => _state.status;
  AIRecommendationResponse? get recommendations => _state.recommendations;
  List<ChatMessage> get chatHistory => _state.chatHistory;
  String? get errorMessage => _state.errorMessage;
  
  bool get isLoading => _state.isLoading;
  bool get hasError => _state.hasError;
  bool get hasRecommendations => _state.hasRecommendations;
  bool get hasChatHistory => _state.hasChatHistory;
  bool get canShowRecommendations => _state.canShowRecommendations;
  bool get isLoadingRecommendations => _state.isLoadingRecommendations;
  bool get isLoadingChat => _state.isLoadingChat;
  bool get hasShownWelcome => _state.hasShownWelcome;
  
  // Data getters
  UserModel? get userProfile => _userProfile;
  bool get hasInternetConnection => _hasInternetConnection;
  int get totalRecommendationsCount => _state.totalRecommendationsCount;
  List<String> get conversationHistory => _state.conversationHistory;

  /// Initialize the provider
  Future<void> initialize() async {
    developer.log('AIRecommendationsProvider: Initializing...', name: 'AIRecommendationsProvider');
    
    try {
      // Get current user
      _currentUser = FirebaseAuth.instance.currentUser;
      
      if (_currentUser == null) {
        developer.log('AIRecommendationsProvider: No authenticated user found', name: 'AIRecommendationsProvider');
        _setState(_state.setError('User not authenticated'));
        return;
      }

      // Check connectivity
      await _checkConnectivity();
      
      // Set up connectivity listener
      _setupConnectivityListener();
      
      // Load initial data
      await _loadInitialData();
      
      // Show welcome message if first time
      if (!_state.hasShownWelcome) {
        await _showWelcomeMessage();
      }
      
      // Set up periodic refresh
      _startPeriodicRefresh();
      
      developer.log('AIRecommendationsProvider: Initialization complete', name: 'AIRecommendationsProvider');
    } catch (e) {
      developer.log('AIRecommendationsProvider: Initialization failed: $e', name: 'AIRecommendationsProvider');
      _setState(_state.setError('Failed to initialize: ${e.toString()}'));
    }
  }

  /// Update the state and notify listeners
  void _setState(AIRecommendationsStateModel newState) {
    _state = newState;
    notifyListeners();
  }

  /// Check internet connectivity
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _hasInternetConnection = connectivityResult != ConnectivityResult.none;
      developer.log('AIRecommendationsProvider: Connectivity status: $_hasInternetConnection', name: 'AIRecommendationsProvider');
    } catch (e) {
      developer.log('AIRecommendationsProvider: Connectivity check failed: $e', name: 'AIRecommendationsProvider');
      _hasInternetConnection = false;
    }
  }

  /// Set up connectivity listener
  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final wasConnected = _hasInternetConnection;
      _hasInternetConnection = result != ConnectivityResult.none;
      
      if (!wasConnected && _hasInternetConnection) {
        developer.log('AIRecommendationsProvider: Connection restored, refreshing recommendations', name: 'AIRecommendationsProvider');
        refreshRecommendations();
      }
    });
  }

  /// Load initial data required for recommendations
  Future<void> _loadInitialData() async {
    if (_currentUser == null) return;

    developer.log('AIRecommendationsProvider: Loading initial data...', name: 'AIRecommendationsProvider');
    
    try {
      // Load user profile
      _userProfile = await FirebaseService.getUserProfile(_currentUser!.uid);
      
      if (_userProfile == null) {
        throw Exception('User profile not found');
      }

      // Load recent food logs (last 7 days)
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      _recentFoodLogs = await _loadRecentFoodLogs(weekAgo, now);
      
      // Load recent activities (last 7 days)
      _recentActivities = await _loadRecentActivities(weekAgo, now);
      
      // Load initial recommendations if we have internet
      if (_hasInternetConnection) {
        await _loadRecommendations();
      }
      
      developer.log('AIRecommendationsProvider: Initial data loaded successfully', name: 'AIRecommendationsProvider');
    } catch (e) {
      developer.log('AIRecommendationsProvider: Failed to load initial data: $e', name: 'AIRecommendationsProvider');
      _setState(_state.setError('Failed to load data: ${e.toString()}'));
    }
  }

  /// Load recent food logs
  Future<List<FoodLogModel>> _loadRecentFoodLogs(DateTime startDate, DateTime endDate) async {
    if (_currentUser == null) return [];
    
    try {
      final foodLogs = <FoodLogModel>[];
      final currentDate = DateTime.now();
      
      // Load food logs for each day in the range
      for (int i = 0; i < 7; i++) {
        final date = currentDate.subtract(Duration(days: i));
        final foodLog = await FirebaseService.getFoodLogData(_currentUser!.uid, date);
        if (foodLog != null) {
          foodLogs.add(foodLog);
        }
      }
      
      developer.log('AIRecommendationsProvider: Loaded ${foodLogs.length} food logs', name: 'AIRecommendationsProvider');
      return foodLogs;
    } catch (e) {
      developer.log('AIRecommendationsProvider: Failed to load food logs: $e', name: 'AIRecommendationsProvider');
      return [];
    }
  }

  /// Load recent activities
  Future<List<ActivityModel>> _loadRecentActivities(DateTime startDate, DateTime endDate) async {
    if (_currentUser == null) return [];
    
    try {
      final activities = <ActivityModel>[];
      final currentDate = DateTime.now();
      
      // Load activities for each day in the range
      for (int i = 0; i < 7; i++) {
        final date = currentDate.subtract(Duration(days: i));
        final activity = await FirebaseService.getActivityData(_currentUser!.uid, date);
        if (activity != null) {
          activities.add(activity);
        }
      }
      
      developer.log('AIRecommendationsProvider: Loaded ${activities.length} activity records', name: 'AIRecommendationsProvider');
      return activities;
    } catch (e) {
      developer.log('AIRecommendationsProvider: Failed to load activities: $e', name: 'AIRecommendationsProvider');
      return [];
    }
  }

  /// Load AI recommendations
  Future<void> _loadRecommendations() async {
    if (_userProfile == null || !_hasInternetConnection) return;

    _setState(_state.setLoadingRecommendations(true));
    
    try {
      developer.log('AIRecommendationsProvider: Generating AI recommendations...', name: 'AIRecommendationsProvider');
      
      final response = await GeminiAIService.generateRecommendations(
        userProfile: _userProfile!,
        recentFoodLogs: _recentFoodLogs,
        recentActivities: _recentActivities,
        useCache: true,
      );
      
      _setState(_state.setLoaded(response));
      developer.log('AIRecommendationsProvider: AI recommendations loaded successfully', name: 'AIRecommendationsProvider');
    } catch (e) {
      developer.log('AIRecommendationsProvider: Failed to load AI recommendations: $e', name: 'AIRecommendationsProvider');
      _setState(_state.setError('Failed to load recommendations: ${e.toString()}'));
    }
  }

  /// Show welcome message
  Future<void> _showWelcomeMessage() async {
    if (_userProfile == null) return;
    
    final welcomeMessage = ChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      content: 'Hi ${_userProfile!.displayName}! 👋 I\'m your AI nutrition and fitness assistant. I can help you with personalized food recommendations, exercise suggestions, and answer any health-related questions. What would you like to know?',
      isFromUser: false,
      timestamp: DateTime.now(),
      type: AIInteractionType.chat,
    );
    
    _setState(_state.addChatMessage(welcomeMessage).markWelcomeShown());
  }

  /// Start periodic refresh timer
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(hours: 2), (timer) {
      if (_hasInternetConnection && _state.areRecommendationsStale) {
        developer.log('AIRecommendationsProvider: Refreshing stale recommendations', name: 'AIRecommendationsProvider');
        refreshRecommendations();
      }
    });
  }

  /// Refresh recommendations
  Future<void> refreshRecommendations() async {
    if (!_hasInternetConnection) {
      _setState(_state.setError('No internet connection'));
      return;
    }

    await _loadRecommendations();
  }

  /// Send a chat message and get AI response
  Future<void> sendChatMessage(String message) async {
    if (message.trim().isEmpty || _userProfile == null) return;

    // Add user message to chat
    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: message.trim(),
      isFromUser: true,
      timestamp: DateTime.now(),
      type: AIInteractionType.chat,
    );
    
    _setState(_state.addChatMessage(userMessage).setLoadingChat(true));

    try {
      if (!_hasInternetConnection) {
        throw Exception('No internet connection');
      }

      developer.log('AIRecommendationsProvider: Sending chat message: $message', name: 'AIRecommendationsProvider');
      
      // Generate AI response
      final response = await GeminiAIService.generateChatResponse(
        userQuery: message,
        userProfile: _userProfile!,
        conversationHistory: _state.conversationHistory.take(10).toList(), // Last 5 exchanges
      );
      
      // Add AI response to chat
      final aiMessage = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        content: response,
        isFromUser: false,
        timestamp: DateTime.now(),
        type: AIInteractionType.chat,
      );
      
      _setState(_state.addChatMessage(aiMessage).setLoadingChat(false));
      developer.log('AIRecommendationsProvider: Chat response generated successfully', name: 'AIRecommendationsProvider');
    } catch (e) {
      developer.log('AIRecommendationsProvider: Failed to generate chat response: $e', name: 'AIRecommendationsProvider');
      
      // Add error message
      final errorMessage = ChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        content: 'Sorry, I encountered an error processing your message. Please try again or check your internet connection.',
        isFromUser: false,
        timestamp: DateTime.now(),
        type: AIInteractionType.chat,
      );
      
      _setState(_state.addChatMessage(errorMessage).setLoadingChat(false));
    }
  }

  /// Clear chat history
  void clearChatHistory() {
    _setState(_state.clearChatHistory());
    developer.log('AIRecommendationsProvider: Chat history cleared', name: 'AIRecommendationsProvider');
  }

  /// Clear error state
  void clearError() {
    _setState(_state.copyWith(clearError: true));
  }

  /// Get personalized recommendations based on specific query
  Future<void> getPersonalizedRecommendations(String query) async {
    if (_userProfile == null || !_hasInternetConnection) return;

    _setState(_state.setLoadingRecommendations(true));
    
    try {
      developer.log('AIRecommendationsProvider: Getting personalized recommendations for: $query', name: 'AIRecommendationsProvider');
      
      final response = await GeminiAIService.generateRecommendations(
        userProfile: _userProfile!,
        recentFoodLogs: _recentFoodLogs,
        recentActivities: _recentActivities,
        userQuery: query,
        useCache: false, // Don't cache personalized queries
      );
      
      _setState(_state.setLoaded(response));
      developer.log('AIRecommendationsProvider: Personalized recommendations loaded successfully', name: 'AIRecommendationsProvider');
    } catch (e) {
      developer.log('AIRecommendationsProvider: Failed to get personalized recommendations: $e', name: 'AIRecommendationsProvider');
      _setState(_state.setError('Failed to get recommendations: ${e.toString()}'));
    }
  }

  /// Refresh user data and recommendations
  Future<void> refreshUserData() async {
    if (_currentUser == null) return;

    try {
      // Reload user profile
      _userProfile = await FirebaseService.getUserProfile(_currentUser!.uid);
      
      // Reload recent data
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      _recentFoodLogs = await _loadRecentFoodLogs(weekAgo, now);
      _recentActivities = await _loadRecentActivities(weekAgo, now);
      
      // Refresh recommendations with new data
      if (_hasInternetConnection) {
        await _loadRecommendations();
      }
    } catch (e) {
      developer.log('AIRecommendationsProvider: Failed to refresh user data: $e', name: 'AIRecommendationsProvider');
      _setState(_state.setError('Failed to refresh data: ${e.toString()}'));
    }
  }

  @override
  void dispose() {
    developer.log('AIRecommendationsProvider: Disposing...', name: 'AIRecommendationsProvider');
    
    // Cancel all stream subscriptions
    for (final subscription in _streamSubscriptions.values) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
    
    // Cancel refresh timer
    _refreshTimer?.cancel();
    
    super.dispose();
  }
}
