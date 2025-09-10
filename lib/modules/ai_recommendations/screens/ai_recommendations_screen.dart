import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../presentation/widgets/custom_appbar.dart';
import '../providers/ai_recommendations_provider.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/recommendation_card_widget.dart';
import '../widgets/typing_indicator_widget.dart';
import '../../activity/screens/activity_screen_with_provider.dart';

/// AI-powered food and exercise recommendations screen with chatbot interface
/// Positioned after the status screen in the app navigation flow
class AIRecommendationsScreen extends StatefulWidget {
  const AIRecommendationsScreen({super.key});

  @override
  State<AIRecommendationsScreen> createState() => _AIRecommendationsScreenState();
}

class _AIRecommendationsScreenState extends State<AIRecommendationsScreen>
    with TickerProviderStateMixin {
  
  late TextEditingController _messageController;
  late ScrollController _chatScrollController;
  late ScrollController _recommendationsScrollController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;
  late FocusNode _messageFocusNode;
  
  bool _showRecommendations = true;
  bool _isMessageInputVisible = false;
  
  // Keys for better widget performance
  final GlobalKey<AnimatedListState> _chatListKey = GlobalKey<AnimatedListState>();
  final ValueNotifier<bool> _isTypingNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    
    _messageController = TextEditingController();
    _chatScrollController = ScrollController();
    _recommendationsScrollController = ScrollController();
    _messageFocusNode = FocusNode();
    
    // Listen to focus changes to manage input visibility
    _messageFocusNode.addListener(_onFocusChange);
    
    // Set up animations
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutCubic),
    );
    
    // Start animations
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
    
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
    
    // Listen for provider changes to auto-scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AIRecommendationsProvider>(context, listen: false);
      provider.addListener(_onProviderChanged);
    });
  }
  
  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isMessageInputVisible = _messageFocusNode.hasFocus || !_showRecommendations;
      });
    }
  }
  
  void _onProviderChanged() {
    if (mounted && !_showRecommendations) {
      // Auto-scroll when new messages are added
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }
  
  bool _shouldShowMessageInput() {
    return !_showRecommendations || _isMessageInputVisible;
  }

  @override
  void dispose() {
    // Remove provider listener if it exists
    try {
      final provider = Provider.of<AIRecommendationsProvider>(context, listen: false);
      provider.removeListener(_onProviderChanged);
    } catch (e) {
      // Provider might not be available anymore
    }
    
    _messageController.dispose();
    _chatScrollController.dispose();
    _recommendationsScrollController.dispose();
    _messageFocusNode.removeListener(_onFocusChange);
    _messageFocusNode.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _isTypingNotifier.dispose();
    super.dispose();
  }

  void _initializeProvider() {
    final provider = Provider.of<AIRecommendationsProvider>(context, listen: false);
    provider.initialize();
  }

  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_chatScrollController.hasClients) {
          _chatScrollController.animateTo(
            _chatScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final provider = Provider.of<AIRecommendationsProvider>(context, listen: false);
    provider.sendChatMessage(message);
    _messageController.clear();
    _isTypingNotifier.value = false;

    // Scroll to bottom after a short delay
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _refreshRecommendations() {
    final provider = Provider.of<AIRecommendationsProvider>(context, listen: false);
    provider.refreshRecommendations();
  }

  void _toggleView() {
    setState(() {
      _showRecommendations = !_showRecommendations;
      _isMessageInputVisible = !_showRecommendations;
    });
    
    // Unfocus when switching to recommendations
    if (_showRecommendations && _messageFocusNode.hasFocus) {
      _messageFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AIRecommendationsProvider>(
      builder: (context, provider, child) {
        // Add error snackbar for transient errors
        if (provider.hasError && provider.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage!),
                  backgroundColor: Colors.red[400],
                  action: SnackBarAction(
                    label: 'Dismiss',
                    textColor: Colors.white,
                    onPressed: () {
                      provider.clearError();
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ),
              );
            }
          });
        }
        
        return Scaffold(
          backgroundColor: AppTheme.background,
          resizeToAvoidBottomInset: true,
          
          // Custom app bar with gradient background
          appBar: CustomAppBar(
            title: 'AI Health Assistant',
            actions: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: IconButton(
                  key: ValueKey(_showRecommendations),
                  icon: Icon(_showRecommendations ? Icons.chat : Icons.lightbulb),
                  onPressed: _toggleView,
                  tooltip: _showRecommendations ? 'Switch to Chat' : 'Switch to Recommendations',
                ),
              ),
              if (provider.hasRecommendations)
                AnimatedOpacity(
                  opacity: provider.isLoadingRecommendations ? 0.5 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: provider.isLoadingRecommendations ? null : _refreshRecommendations,
                    tooltip: 'Refresh Recommendations',
                  ),
                ),
            ],
          ),

          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // View toggle tabs
                    _buildViewToggleTabs(provider),
                    
                    // Main content area with smooth transitions
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.1),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _showRecommendations
                            ? KeyedSubtree(
                                key: const ValueKey('recommendations'),
                                child: _buildRecommendationsView(provider),
                              )
                            : KeyedSubtree(
                                key: const ValueKey('chat'),
                                child: _buildChatView(provider),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Message input as bottom sheet to prevent overflow
          bottomSheet: _shouldShowMessageInput() 
              ? SafeArea(
                  child: _buildMessageInput(provider),
                )
              : null,
        );
      },
    );
  }

  /// Build view toggle tabs
  Widget _buildViewToggleTabs(AIRecommendationsProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'Recommendations',
              Icons.lightbulb_outline,
              _showRecommendations,
              () => setState(() => _showRecommendations = true),
              provider.totalRecommendationsCount,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'Chat',
              Icons.chat_outlined,
              !_showRecommendations,
              () => setState(() => _showRecommendations = false),
              provider.chatHistory.where((m) => m.isFromUser).length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, IconData icon, bool isActive, VoidCallback onTap, int count) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppTheme.primaryGreen : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? AppTheme.primaryGreen : AppTheme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (count > 0 && count < 100) ...[
              const SizedBox(width: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryGreen : AppTheme.textLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build recommendations view
  Widget _buildRecommendationsView(AIRecommendationsProvider provider) {
    if (provider.isLoadingRecommendations) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryGreen),
            const SizedBox(height: 16),
            const Text(
              'Generating personalized recommendations...',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            // Add timeout protection
            ElevatedButton(
              onPressed: () {
                provider.clearError();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.textLight,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }

    if (provider.hasError && !provider.hasRecommendations) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load recommendations',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'Unknown error occurred',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshRecommendations,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (!provider.hasRecommendations) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 16),
            const Text(
              'No recommendations yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete your profile and log some activities to get personalized recommendations',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ActivityScreenWithProvider(),
                  ),
                );
              },
              icon: const Icon(Icons.fitness_center),
              label: const Text('Start Logging Activities'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: _recommendationsScrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Motivational tip
          if (provider.recommendations!.motivationalTip.isNotEmpty)
            _buildMotivationalTip(provider.recommendations!.motivationalTip),
          
          // Food recommendations
          if (provider.recommendations!.foodRecommendations.isNotEmpty) ...[
            _buildSectionHeader('🍎 Food Recommendations'),
            const SizedBox(height: 12),
            ...provider.recommendations!.foodRecommendations.map(
              (recommendation) => RecommendationCardWidget(
                title: recommendation.title,
                description: recommendation.description,
                metadata: '${recommendation.calories} kcal • ${recommendation.type}',
                icon: Icons.restaurant,
                color: AppTheme.primaryGreen,
                onTap: () => _askAboutRecommendation('food', recommendation.title),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Exercise recommendations
          if (provider.recommendations!.exerciseRecommendations.isNotEmpty) ...[
            _buildSectionHeader('🏃‍♂️ Exercise Recommendations'),
            const SizedBox(height: 12),
            ...provider.recommendations!.exerciseRecommendations.map(
              (recommendation) => RecommendationCardWidget(
                title: recommendation.title,
                description: recommendation.description,
                metadata: '${recommendation.duration} min • ${recommendation.calories} kcal',
                icon: Icons.fitness_center,
                color: AppTheme.accentBlue,
                onTap: () => _askAboutRecommendation('exercise', recommendation.title),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Last updated info
          if (provider.state.lastRecommendationUpdate != null)
            _buildLastUpdatedInfo(provider.state.lastRecommendationUpdate!),
        ],
      ),
    );
  }

  /// Build motivational tip card
  Widget _buildMotivationalTip(String tip) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen,
            AppTheme.secondaryGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.psychology,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Motivation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  /// Build last updated info
  Widget _buildLastUpdatedInfo(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    
    String timeAgo;
    if (difference.inMinutes < 1) {
      timeAgo = 'Just now';
    } else if (difference.inHours < 1) {
      timeAgo = '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      timeAgo = '${difference.inHours}h ago';
    } else {
      timeAgo = '${difference.inDays}d ago';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.textLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 14,
            color: AppTheme.textLight,
          ),
          const SizedBox(width: 4),
          Text(
            'Updated $timeAgo',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  /// Build chat view
  Widget _buildChatView(AIRecommendationsProvider provider) {
    return provider.chatHistory.isEmpty
        ? _buildEmptyChatState()
        : ListView.builder(
            key: const PageStorageKey('chat_list'),
            controller: _chatScrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 140), // Further increased bottom padding
            itemCount: provider.chatHistory.length + (provider.isLoadingChat ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.chatHistory.length && provider.isLoadingChat) {
                return const TypingIndicatorWidget(key: ValueKey('typing_indicator'));
              }
              
              final message = provider.chatHistory[index];
              return ChatMessageWidget(
                key: ValueKey(message.id),
                message: message,
                onTap: message.isFromUser ? null : () => _askFollowUpQuestion(message.content),
              );
            },
          );
  }

  /// Build empty chat state
  Widget _buildEmptyChatState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Start a conversation!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask me anything about nutrition, exercise,\nor your health goals.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickQuestionChip('What should I eat for breakfast?'),
              _buildQuickQuestionChip('How can I lose weight?'),
              _buildQuickQuestionChip('Best exercises for beginners?'),
            ],
          ),
        ],
      ),
    );
  }

  /// Build quick question chip
  Widget _buildQuickQuestionChip(String question) {
    return GestureDetector(
      onTap: () {
        _messageController.text = question;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.3),
          ),
        ),
        child: Text(
          question,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryGreen,
          ),
        ),
      ),
    );
  }

  /// Build message input
  Widget _buildMessageInput(AIRecommendationsProvider provider) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom > 0 
          ? MediaQuery.of(context).padding.bottom + 4
          : 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                minHeight: 44,
                maxHeight: MediaQuery.of(context).size.height * 0.15, // Max 15% of screen height
              ),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.textLight.withOpacity(0.2),
                ),
              ),
              child: ValueListenableBuilder<bool>(
                valueListenable: _isTypingNotifier,
                builder: (context, isTyping, child) {
                  return TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    maxLines: null,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Ask me anything about health...',
                      hintStyle: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    textInputAction: TextInputAction.send,
                    onChanged: (text) {
                      _isTypingNotifier.value = text.trim().isNotEmpty;
                    },
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !provider.isLoadingChat,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          ValueListenableBuilder<bool>(
            valueListenable: _isTypingNotifier,
            builder: (context, hasText, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: hasText && !provider.isLoadingChat 
                      ? AppTheme.primaryGradient 
                      : LinearGradient(
                          colors: [AppTheme.textLight, AppTheme.textLight],
                        ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: provider.isLoadingChat || !hasText ? null : _sendMessage,
                  icon: Icon(
                    provider.isLoadingChat 
                        ? Icons.hourglass_empty 
                        : hasText 
                            ? Icons.send 
                            : Icons.send_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Ask about a specific recommendation
  void _askAboutRecommendation(String type, String title) {
    _messageController.text = 'Tell me more about this $type recommendation: $title';
    setState(() {
      _showRecommendations = false;
      _isMessageInputVisible = true;
    });
    _isTypingNotifier.value = true;
    
    // Focus the input and send message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageFocusNode.requestFocus();
      Future.delayed(const Duration(milliseconds: 300), _sendMessage);
    });
  }

  /// Ask follow-up question about a response
  void _askFollowUpQuestion(String context) {
    _messageController.text = 'Can you tell me more about that?';
    Future.delayed(const Duration(milliseconds: 100), _sendMessage);
  }
}
