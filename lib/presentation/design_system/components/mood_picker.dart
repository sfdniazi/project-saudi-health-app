import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';

/// 😊 Beautiful mood picker matching the reference design
/// 
/// Displays 5 mood states with emoji and colored backgrounds:
/// Terrible, Bad, Neutral, Good, Awesome
class MoodPicker extends StatelessWidget {
  final MoodState? selectedMood;
  final ValueChanged<MoodState>? onMoodSelected;
  final String title;
  final bool compact;

  const MoodPicker({
    super.key,
    this.selectedMood,
    this.onMoodSelected,
    this.title = 'How do you feel today?',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: AppTheme.fontSizeXl,
          ),
        ),
        SizedBox(height: compact ? AppTheme.spaceMd : AppTheme.spaceXl),
        
        // Mood options row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: MoodState.values.map((mood) {
            final isSelected = mood == selectedMood;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 2.0 : 4.0),
                child: _MoodOption(
                  mood: mood,
                  isSelected: isSelected,
                  onTap: () => onMoodSelected?.call(mood),
                  compact: compact,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Individual mood option widget
class _MoodOption extends StatelessWidget {
  final MoodState mood;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool compact;

  const _MoodOption({
    required this.mood,
    required this.isSelected,
    this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 48.0 : 64.0;
    final emojiSize = compact ? 20.0 : 28.0;
    final labelSize = compact ? AppTheme.fontSizeXs : AppTheme.fontSizeSm;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Emoji circle
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isSelected 
                  ? mood.color.withOpacity(0.2)
                  : mood.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(
                color: isSelected ? mood.color : mood.color.withOpacity(0.3),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected 
                  ? [
                      BoxShadow(
                        color: mood.color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                mood.emoji,
                style: TextStyle(fontSize: emojiSize),
              ),
            ),
          ),
        ),
        
        SizedBox(height: compact ? AppTheme.spaceSm : AppTheme.spaceMd),
        
        // Label
        Text(
          mood.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected ? mood.color : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: labelSize,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Mood states enum matching the reference design
enum MoodState {
  terrible,
  bad, 
  neutral,
  good,
  awesome,
}

extension MoodStateExtension on MoodState {
  /// Emoji for each mood
  String get emoji {
    switch (this) {
      case MoodState.terrible:
        return '😢';
      case MoodState.bad:
        return '😕';
      case MoodState.neutral:
        return '😐';
      case MoodState.good:
        return '🙂';
      case MoodState.awesome:
        return '😊';
    }
  }
  
  /// Label text for each mood
  String get label {
    switch (this) {
      case MoodState.terrible:
        return 'Terrible';
      case MoodState.bad:
        return 'Bad';
      case MoodState.neutral:
        return 'Neutral';
      case MoodState.good:
        return 'Good';
      case MoodState.awesome:
        return 'Awesome';
    }
  }
  
  /// Color for each mood matching the reference design
  Color get color {
    switch (this) {
      case MoodState.terrible:
        return AppTheme.moodTerrible;  // Red
      case MoodState.bad:
        return AppTheme.moodBad;       // Orange
      case MoodState.neutral:
        return AppTheme.moodNeutral;   // Gray
      case MoodState.good:
        return AppTheme.moodGood;      // Yellow
      case MoodState.awesome:
        return AppTheme.moodAwesome;   // Green
    }
  }
  
  /// Numeric value for data storage (1-5)
  int get value {
    switch (this) {
      case MoodState.terrible:
        return 1;
      case MoodState.bad:
        return 2;
      case MoodState.neutral:
        return 3;
      case MoodState.good:
        return 4;
      case MoodState.awesome:
        return 5;
    }
  }
  
  /// Create mood state from numeric value
  static MoodState fromValue(int value) {
    switch (value) {
      case 1:
        return MoodState.terrible;
      case 2:
        return MoodState.bad;
      case 3:
        return MoodState.neutral;
      case 4:
        return MoodState.good;
      case 5:
        return MoodState.awesome;
      default:
        return MoodState.neutral;
    }
  }
}

/// 💭 Compact mood display for showing selected mood
class MoodDisplay extends StatelessWidget {
  final MoodState mood;
  final bool showLabel;
  final double size;

  const MoodDisplay({
    super.key,
    required this.mood,
    this.showLabel = true,
    this.size = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: mood.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(
              color: mood.color.withOpacity(0.3),
              width: 1.0,
            ),
          ),
          child: Center(
            child: Text(
              mood.emoji,
              style: TextStyle(fontSize: size * 0.5),
            ),
          ),
        ),
        
        if (showLabel) ...[
          const SizedBox(width: AppTheme.spaceSm),
          Text(
            mood.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: mood.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
