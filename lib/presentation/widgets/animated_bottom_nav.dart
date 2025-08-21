import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class AnimatedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const AnimatedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                active: currentIndex == 0,
                onTap: onTap,
              ),
              _buildItem(
                icon: Icons.directions_run_rounded,
                label: 'Activity',
                index: 1,
                active: currentIndex == 1,
                onTap: onTap,
              ),
              _buildItem(
                icon: Icons.restaurant_rounded,
                label: 'Food',
                index: 2,
                active: currentIndex == 2,
                onTap: onTap,
              ),
              _buildItem(
                icon: Icons.bar_chart_rounded,
                label: 'Stats',
                index: 3,
                active: currentIndex == 3,
                onTap: onTap,
              ),
              _buildItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                index: 4,
                active: currentIndex == 4,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String label,
    required int index,
    required bool active,
    required ValueChanged<int> onTap,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: active ? 20 : 12,
          vertical: active ? 12 : 8,
        ),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryGreen.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: active
              ? Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? AppTheme.primaryGreen : AppTheme.textSecondary,
              size: active ? 24 : 22,
            ),
            if (active) ...[
              const SizedBox(width: 8),
                             Text(
                 label,
                 style: TextStyle(
                   color: AppTheme.primaryGreen,
                   fontWeight: FontWeight.w600,
                   fontSize: 14,
                 ),
               ),
            ],
          ],
        ),
      ),
    );
  }
}
