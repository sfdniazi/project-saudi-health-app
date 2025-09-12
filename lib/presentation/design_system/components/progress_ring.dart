import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/app_theme.dart';

/// 🎯 Beautiful circular progress ring matching the reference design
/// 
/// Perfect for water level, meal completion, step goals, etc.
/// Displays progress as a circular ring with center content.
class ProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;
  final Widget? child;
  final String? centerText;
  final String? centerSubtext;
  final bool showPercentage;
  final VoidCallback? onTap;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 120.0,
    this.strokeWidth = 8.0,
    this.progressColor = AppTheme.nabdBlue,
    this.backgroundColor = AppTheme.borderColor,
    this.child,
    this.centerText,
    this.centerSubtext,
    this.showPercentage = false,
    this.onTap,
  });

  /// Factory constructor for water tracking (like the reference)
  factory ProgressRing.water({
    Key? key,
    required double current,
    required double target,
    VoidCallback? onTap,
  }) {
    final progress = current / target;
    final percentage = (progress * 100).round();
    
    return ProgressRing(
      key: key,
      progress: progress.clamp(0.0, 1.0),
      size: 140.0,
      strokeWidth: 12.0,
      progressColor: AppTheme.nabdBlue,
      centerText: '${current.toInt()}/${target.toInt()}ml',
      centerSubtext: '$percentage%',
      onTap: onTap,
    );
  }

  /// Factory constructor for goal completion (like nutrition goals)
  factory ProgressRing.goal({
    Key? key,
    required double progress,
    required String title,
    Color? color,
    VoidCallback? onTap,
  }) {
    final percentage = (progress * 100).round();
    
    return ProgressRing(
      key: key,
      progress: progress.clamp(0.0, 1.0),
      size: 100.0,
      strokeWidth: 8.0,
      progressColor: color ?? AppTheme.nabdGreen,
      centerText: '$percentage%',
      centerSubtext: title,
      onTap: onTap,
    );
  }

  /// Factory constructor for large display (like sleep assessment)
  factory ProgressRing.assessment({
    Key? key,
    required int score,
    required int maxScore,
    String? subtitle,
    Color? color,
    VoidCallback? onTap,
  }) {
    final progress = score / maxScore;
    
    return ProgressRing(
      key: key,
      progress: progress.clamp(0.0, 1.0),
      size: 160.0,
      strokeWidth: 10.0,
      progressColor: color ?? AppTheme.nabdGreen,
      centerText: score.toString(),
      centerSubtext: subtitle,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget progressWidget = CustomPaint(
      size: Size(size, size),
      painter: _ProgressRingPainter(
        progress: progress,
        strokeWidth: strokeWidth,
        progressColor: progressColor,
        backgroundColor: backgroundColor,
      ),
      child: Container(
        width: size,
        height: size,
        child: Center(
          child: child ?? _buildDefaultCenter(context),
        ),
      ),
    );

    // Add tap functionality if onTap is provided
    if (onTap != null) {
      progressWidget = GestureDetector(
        onTap: onTap,
        child: progressWidget,
      );
    }

    return progressWidget;
  }

  Widget _buildDefaultCenter(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (centerText != null) ...[
          Text(
            centerText!,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: size > 140 ? AppTheme.fontSizeXxxl : AppTheme.fontSizeXl,
            ),
            textAlign: TextAlign.center,
          ),
        ] else if (showPercentage) ...[
          Text(
            '${(progress * 100).round()}%',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: size > 140 ? AppTheme.fontSizeXxxl : AppTheme.fontSizeXl,
            ),
          ),
        ],
        
        if (centerSubtext != null) ...[
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            centerSubtext!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSizeSm,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Custom painter for the circular progress ring
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// 🎯 Combined progress ring with plus button (for water tracking)
class ProgressRingWithButton extends StatelessWidget {
  final double progress;
  final String centerText;
  final String? centerSubtext;
  final Color progressColor;
  final VoidCallback? onAddPressed;
  final VoidCallback? onRingTapped;

  const ProgressRingWithButton({
    super.key,
    required this.progress,
    required this.centerText,
    this.centerSubtext,
    this.progressColor = AppTheme.nabdBlue,
    this.onAddPressed,
    this.onRingTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Main progress ring
        ProgressRing(
          progress: progress,
          progressColor: progressColor,
          centerText: centerText,
          centerSubtext: centerSubtext,
          size: 140.0,
          strokeWidth: 12.0,
          onTap: onRingTapped,
        ),
        
        // Plus button positioned at bottom right
        Positioned(
          right: 0,
          bottom: 8,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.textPrimary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowColor,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onAddPressed,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
