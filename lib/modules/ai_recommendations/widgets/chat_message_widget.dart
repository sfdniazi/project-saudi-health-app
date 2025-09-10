import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../models/ai_recommendations_state_model.dart';

/// Widget for displaying chat messages in the AI conversation
class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onTap;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isFromUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!message.isFromUser) ...[
            _buildAvatarWidget(),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: message.isFromUser
                      ? AppTheme.primaryGreen
                      : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: message.isFromUser 
                        ? const Radius.circular(16) 
                        : const Radius.circular(4),
                    bottomRight: message.isFromUser 
                        ? const Radius.circular(4) 
                        : const Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: message.isFromUser
                            ? Colors.white
                            : AppTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: message.isFromUser
                            ? Colors.white.withOpacity(0.7)
                            : AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (message.isFromUser) ...[
            const SizedBox(width: 12),
            _buildUserAvatarWidget(),
          ],
        ],
      ),
      ),
    );
  }

  /// Build AI avatar widget
  Widget _buildAvatarWidget() {
    return const _AIAvatar();
  }

  /// Build user avatar widget
  Widget _buildUserAvatarWidget() {
    return const _UserAvatar();
  }

  /// Format timestamp for display
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

/// Optimized AI avatar widget
class _AIAvatar extends StatelessWidget {
  const _AIAvatar();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
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
      ),
      child: const Icon(
        Icons.psychology,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}

/// Optimized user avatar widget
class _UserAvatar extends StatelessWidget {
  const _UserAvatar();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.accentBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}
