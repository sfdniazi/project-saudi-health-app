import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

/// ✅ Animated user avatar widget that shows age/gender-appropriate avatars
/// instead of displaying email addresses
class AnimatedUserAvatar extends StatefulWidget {
  final String displayName;
  final String email;
  final int age;
  final String gender;
  final double size;
  final bool showPulse; // Animation effect

  const AnimatedUserAvatar({
    super.key,
    required this.displayName,
    required this.email,
    this.age = 25,
    this.gender = 'Male',
    this.size = 40,
    this.showPulse = false,
  });

  @override
  State<AnimatedUserAvatar> createState() => _AnimatedUserAvatarState();
}

class _AnimatedUserAvatarState extends State<AnimatedUserAvatar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start pulse animation if enabled
    if (widget.showPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedUserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update pulse animation based on showPulse property
    if (widget.showPulse && !oldWidget.showPulse) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.showPulse && oldWidget.showPulse) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  /// Get avatar color based on age and gender
  Color _getAvatarColor() {
    final bool isYoung = widget.age < 30;
    final bool isMale = widget.gender.toLowerCase() == 'male';
    
    if (isYoung && isMale) {
      return AppTheme.accentBlue.withValues(alpha: 0.8);
    } else if (isYoung && !isMale) {
      return Colors.pink.withValues(alpha: 0.8);
    } else if (!isYoung && isMale) {
      return AppTheme.primaryGreen.withValues(alpha: 0.8);
    } else {
      return Colors.purple.withValues(alpha: 0.8);
    }
  }

  /// Get avatar icon based on age and gender
  IconData _getAvatarIcon() {
    final bool isYoung = widget.age < 30;
    final bool isMale = widget.gender.toLowerCase() == 'male';
    
    if (isYoung && isMale) {
      return Icons.person; // Young male
    } else if (isYoung && !isMale) {
      return Icons.person_2; // Young female
    } else if (!isYoung && isMale) {
      return Icons.person_3; // Older male
    } else {
      return Icons.person_4; // Older female
    }
  }

  /// Get initials from display name or email
  String _getInitials() {
    String name = widget.displayName.trim();
    
    // If no display name, derive from email
    if (name.isEmpty) {
      name = widget.email.contains('@') 
          ? widget.email.split('@').first 
          : 'User';
    }
    
    // Get first letter of first and last name
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0].substring(0, 1).toUpperCase();
    }
    
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.showPulse ? _pulseAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _getAvatarColor(),
                  _getAvatarColor().withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getAvatarColor().withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Main avatar content
                Center(
                  child: widget.displayName.isNotEmpty || widget.email.isNotEmpty
                      ? Text(
                          _getInitials(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.size * 0.35,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        )
                      : Icon(
                          _getAvatarIcon(),
                          color: Colors.white,
                          size: widget.size * 0.5,
                        ),
                ),
                
                // Age/gender indicator (small icon in bottom right)
                if (widget.size >= 50) // Only show for larger avatars
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: widget.size * 0.25,
                      height: widget.size * 0.25,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: _getAvatarColor(),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        widget.gender.toLowerCase() == 'male' 
                            ? Icons.male 
                            : Icons.female,
                        color: _getAvatarColor(),
                        size: widget.size * 0.15,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ✅ Extension to create animated avatar easily
extension UserAvatarExtension on Widget {
  Widget withAnimatedAvatar({
    required String displayName,
    required String email,
    int age = 25,
    String gender = 'Male',
    double size = 40,
    bool showPulse = false,
  }) {
    return AnimatedUserAvatar(
      displayName: displayName,
      email: email,
      age: age,
      gender: gender,
      size: size,
      showPulse: showPulse,
    );
  }
}
