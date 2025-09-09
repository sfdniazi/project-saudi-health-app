import 'package:flutter/foundation.dart';
import '../../../services/gemini_ai_service.dart';

/// Enumeration for different states of AI recommendations
enum AIRecommendationStatus {
  initial,
  loading,
  loaded,
  error,
  chatting,
}

/// Enumeration for different types of interactions
enum AIInteractionType {
  recommendations,
  chat,
}

/// Model representing a chat message in the AI conversation
@immutable
class ChatMessage {
  final String id;
  final String content;
  final bool isFromUser;
  final DateTime timestamp;
  final AIInteractionType type;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isFromUser,
    required this.timestamp,
    this.type = AIInteractionType.chat,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isFromUser,
    DateTime? timestamp,
    AIInteractionType? type,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isFromUser: isFromUser ?? this.isFromUser,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'isFromUser': isFromUser,
    'timestamp': timestamp.toIso8601String(),
    'type': type.toString(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    content: json['content'],
    isFromUser: json['isFromUser'],
    timestamp: DateTime.parse(json['timestamp']),
    type: AIInteractionType.values.firstWhere(
      (e) => e.toString() == json['type'],
      orElse: () => AIInteractionType.chat,
    ),
  );
}

/// Immutable state model for AI recommendations screen
@immutable
class AIRecommendationsStateModel {
  final AIRecommendationStatus status;
  final AIRecommendationResponse? recommendations;
  final List<ChatMessage> chatHistory;
  final String? errorMessage;
  final bool isLoadingRecommendations;
  final bool isLoadingChat;
  final bool hasShownWelcome;
  final DateTime? lastUpdated;
  final DateTime? lastRecommendationUpdate;

  const AIRecommendationsStateModel({
    this.status = AIRecommendationStatus.initial,
    this.recommendations,
    this.chatHistory = const [],
    this.errorMessage,
    this.isLoadingRecommendations = false,
    this.isLoadingChat = false,
    this.hasShownWelcome = false,
    this.lastUpdated,
    this.lastRecommendationUpdate,
  });

  // Computed properties
  bool get isLoading => status == AIRecommendationStatus.loading;
  bool get hasError => status == AIRecommendationStatus.error;
  bool get hasRecommendations => recommendations != null;
  bool get hasChatHistory => chatHistory.isNotEmpty;
  bool get canShowRecommendations => hasRecommendations && !isLoadingRecommendations;
  bool get isInitial => status == AIRecommendationStatus.initial;
  
  // Get conversation history as strings for AI context
  List<String> get conversationHistory {
    return chatHistory
        .where((message) => message.type == AIInteractionType.chat)
        .map((message) => message.content)
        .toList();
  }

  // Get recent food and exercise related messages
  List<ChatMessage> get foodRelatedMessages {
    return chatHistory.where((message) {
      final content = message.content.toLowerCase();
      return content.contains('food') || 
             content.contains('meal') || 
             content.contains('eat') ||
             content.contains('nutrition') ||
             content.contains('diet');
    }).toList();
  }

  List<ChatMessage> get exerciseRelatedMessages {
    return chatHistory.where((message) {
      final content = message.content.toLowerCase();
      return content.contains('exercise') || 
             content.contains('workout') || 
             content.contains('activity') ||
             content.contains('fitness') ||
             content.contains('training');
    }).toList();
  }

  // Check if recommendations are stale (older than 2 hours)
  bool get areRecommendationsStale {
    if (lastRecommendationUpdate == null) return true;
    return DateTime.now().difference(lastRecommendationUpdate!) > 
           const Duration(hours: 2);
  }

  // Get total number of recommendations
  int get totalRecommendationsCount {
    if (!hasRecommendations) return 0;
    return recommendations!.foodRecommendations.length + 
           recommendations!.exerciseRecommendations.length;
  }

  /// Create a copy of this state with updated values
  AIRecommendationsStateModel copyWith({
    AIRecommendationStatus? status,
    AIRecommendationResponse? recommendations,
    List<ChatMessage>? chatHistory,
    String? errorMessage,
    bool? isLoadingRecommendations,
    bool? isLoadingChat,
    bool? hasShownWelcome,
    DateTime? lastUpdated,
    DateTime? lastRecommendationUpdate,
    bool clearError = false,
    bool clearRecommendations = false,
  }) {
    return AIRecommendationsStateModel(
      status: status ?? this.status,
      recommendations: clearRecommendations ? null : (recommendations ?? this.recommendations),
      chatHistory: chatHistory ?? this.chatHistory,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoadingRecommendations: isLoadingRecommendations ?? this.isLoadingRecommendations,
      isLoadingChat: isLoadingChat ?? this.isLoadingChat,
      hasShownWelcome: hasShownWelcome ?? this.hasShownWelcome,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastRecommendationUpdate: lastRecommendationUpdate ?? this.lastRecommendationUpdate,
    );
  }

  /// Add a new message to the chat history
  AIRecommendationsStateModel addChatMessage(ChatMessage message) {
    final updatedHistory = List<ChatMessage>.from(chatHistory)..add(message);
    return copyWith(
      chatHistory: updatedHistory,
      lastUpdated: DateTime.now(),
    );
  }

  /// Clear all chat history
  AIRecommendationsStateModel clearChatHistory() {
    return copyWith(
      chatHistory: const [],
      lastUpdated: DateTime.now(),
    );
  }

  /// Mark welcome as shown
  AIRecommendationsStateModel markWelcomeShown() {
    return copyWith(hasShownWelcome: true);
  }

  /// Set loading state for recommendations
  AIRecommendationsStateModel setLoadingRecommendations(bool loading) {
    return copyWith(
      isLoadingRecommendations: loading,
      status: loading ? AIRecommendationStatus.loading : status,
      clearError: loading,
    );
  }

  /// Set loading state for chat
  AIRecommendationsStateModel setLoadingChat(bool loading) {
    return copyWith(
      isLoadingChat: loading,
      status: loading ? AIRecommendationStatus.chatting : status,
    );
  }

  /// Set error state
  AIRecommendationsStateModel setError(String error) {
    return copyWith(
      status: AIRecommendationStatus.error,
      errorMessage: error,
      isLoadingRecommendations: false,
      isLoadingChat: false,
    );
  }

  /// Set loaded state with recommendations
  AIRecommendationsStateModel setLoaded(AIRecommendationResponse recommendations) {
    return copyWith(
      status: AIRecommendationStatus.loaded,
      recommendations: recommendations,
      isLoadingRecommendations: false,
      lastUpdated: DateTime.now(),
      lastRecommendationUpdate: DateTime.now(),
      clearError: true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIRecommendationsStateModel &&
        other.status == status &&
        other.recommendations == recommendations &&
        listEquals(other.chatHistory, chatHistory) &&
        other.errorMessage == errorMessage &&
        other.isLoadingRecommendations == isLoadingRecommendations &&
        other.isLoadingChat == isLoadingChat &&
        other.hasShownWelcome == hasShownWelcome &&
        other.lastUpdated == lastUpdated &&
        other.lastRecommendationUpdate == lastRecommendationUpdate;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      recommendations,
      chatHistory,
      errorMessage,
      isLoadingRecommendations,
      isLoadingChat,
      hasShownWelcome,
      lastUpdated,
      lastRecommendationUpdate,
    );
  }

  @override
  String toString() {
    return 'AIRecommendationsStateModel('
        'status: $status, '
        'hasRecommendations: $hasRecommendations, '
        'chatHistoryLength: ${chatHistory.length}, '
        'hasError: $hasError, '
        'isLoadingRecommendations: $isLoadingRecommendations, '
        'isLoadingChat: $isLoadingChat'
        ')';
  }
}
