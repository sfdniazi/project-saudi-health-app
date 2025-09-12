import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';

/// 🎴 Beautiful Nabd Al-Hayah card component matching the reference design
/// 
/// Creates clean white cards with subtle shadows, perfect borders, and consistent spacing
/// exactly like the reference app interface.
class NabdCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool hasBorder;
  final VoidCallback? onTap;
  final String? heroTag;

  const NabdCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.hasBorder = true,
    this.onTap,
    this.heroTag,
  });

  /// Factory constructor for stat cards (like water level, sleep score)
  factory NabdCard.stat({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    String? heroTag,
  }) {
    return NabdCard(
      key: key,
      padding: const EdgeInsets.all(AppTheme.spaceXl),
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceSm,
      ),
      onTap: onTap,
      heroTag: heroTag,
      child: child,
    );
  }

  /// Factory constructor for section cards (like daily tasks, mood tracking)
  factory NabdCard.section({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
  }) {
    return NabdCard(
      key: key,
      padding: const EdgeInsets.all(AppTheme.spaceXxl),
      margin: margin ?? const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceMd,
      ),
      onTap: onTap,
      child: child,
    );
  }

  /// Factory constructor for compact info cards
  factory NabdCard.compact({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return NabdCard(
      key: key,
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      margin: const EdgeInsets.all(AppTheme.spaceSm),
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.cardBackground,
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusLg),
        border: hasBorder
            ? Border.all(
                color: AppTheme.borderColor,
                width: 0.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: elevation ?? AppTheme.elevationMd,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppTheme.spaceXl),
          child: child,
        ),
      ),
    );

    // Add hero animation if heroTag is provided
    if (heroTag != null) {
      cardContent = Hero(
        tag: heroTag!,
        child: cardContent,
      );
    }

    // Add tap functionality if onTap is provided
    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusLg),
          child: cardContent,
        ),
      );
    }

    return Container(
      margin: margin,
      child: cardContent,
    );
  }
}

/// 📊 Stat card component for displaying metrics (water level, steps, etc.)
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Widget? icon;
  final Color? valueColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.valueColor,
    this.backgroundColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return NabdCard.stat(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title and optional icon/trailing
          Row(
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: AppTheme.spaceMd),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          
          // Main value
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: valueColor ?? AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: AppTheme.fontSizeXxxl,
            ),
          ),
          
          // Optional subtitle
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
