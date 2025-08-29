import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/app_theme.dart';

class FoodLoggingShimmerWidgets {
  /// Creates shimmer effect for a container
  static Widget _createShimmerContainer({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Date header shimmer
  static Widget dateHeaderShimmer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          _createShimmerContainer(width: 20, height: 20),
          const SizedBox(width: 12),
          _createShimmerContainer(width: 200, height: 16),
        ],
      ),
    );
  }

  /// Daily summary card shimmer
  static Widget dailySummaryCardShimmer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _createShimmerContainer(width: 24, height: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _createShimmerContainer(width: 150, height: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _createShimmerContainer(width: 30, height: 18),
                    const SizedBox(height: 4),
                    _createShimmerContainer(width: 25, height: 12),
                    const SizedBox(height: 4),
                    _createShimmerContainer(width: 40, height: 12),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    _createShimmerContainer(width: 20, height: 18),
                    const SizedBox(height: 4),
                    _createShimmerContainer(width: 15, height: 12),
                    const SizedBox(height: 4),
                    _createShimmerContainer(width: 35, height: 12),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    _createShimmerContainer(width: 25, height: 18),
                    const SizedBox(height: 4),
                    _createShimmerContainer(width: 15, height: 12),
                    const SizedBox(height: 4),
                    _createShimmerContainer(width: 30, height: 12),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    _createShimmerContainer(width: 15, height: 18),
                    const SizedBox(height: 4),
                    _createShimmerContainer(width: 10, height: 12),
                    const SizedBox(height: 4),
                    _createShimmerContainer(width: 25, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Add food section shimmer
  static Widget addFoodSectionShimmer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _createShimmerContainer(width: 80, height: 18),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _createShimmerContainer(
                  width: double.infinity,
                  height: 48,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _createShimmerContainer(
                  width: double.infinity,
                  height: 48,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Today's meals header shimmer
  static Widget todaysMealsHeaderShimmer() {
    return _createShimmerContainer(width: 120, height: 18);
  }

  /// Empty meals card shimmer
  static Widget emptyMealsCardShimmer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          _createShimmerContainer(width: 48, height: 48),
          const SizedBox(height: 16),
          _createShimmerContainer(width: 150, height: 16),
          const SizedBox(height: 8),
          _createShimmerContainer(width: 200, height: 14),
        ],
      ),
    );
  }

  /// Meal card shimmer
  static Widget mealCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _createShimmerContainer(width: 24, height: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _createShimmerContainer(width: 80, height: 16),
                    const SizedBox(height: 4),
                    _createShimmerContainer(width: 60, height: 12),
                  ],
                ),
              ),
              _createShimmerContainer(width: 60, height: 14),
            ],
          ),
          const SizedBox(height: 12),
          _createShimmerContainer(width: 180, height: 14),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: _createShimmerContainer(width: 120, height: 14),
              ),
              _createShimmerContainer(width: 50, height: 12),
            ],
          ),
        ],
      ),
    );
  }

  /// Multiple meal cards shimmer
  static Widget multipleMealCardsShimmer({int count = 3}) {
    return Column(
      children: List.generate(count, (index) => mealCardShimmer()),
    );
  }

  /// Scan history header shimmer
  static Widget scanHistoryHeaderShimmer() {
    return Row(
      children: [
        _createShimmerContainer(width: 20, height: 20),
        const SizedBox(width: 8),
        _createShimmerContainer(width: 100, height: 18),
      ],
    );
  }

  /// Scan history item shimmer
  static Widget scanHistoryItemShimmer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _createShimmerContainer(width: 24, height: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _createShimmerContainer(width: 140, height: 16),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _createShimmerContainer(width: 14, height: 14),
                    const SizedBox(width: 4),
                    _createShimmerContainer(width: 60, height: 12),
                    const SizedBox(width: 12),
                    _createShimmerContainer(width: 14, height: 14),
                    const SizedBox(width: 4),
                    _createShimmerContainer(width: 50, height: 12),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                _createShimmerContainer(width: 25, height: 14),
                _createShimmerContainer(width: 20, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Multiple scan history items shimmer
  static Widget multipleScanHistoryItemsShimmer({int count = 5}) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => scanHistoryItemShimmer(),
    );
  }

  /// Full page loading shimmer
  static Widget fullPageLoadingShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header Shimmer
          dateHeaderShimmer(),
          const SizedBox(height: 20),
          
          // Daily Summary Card Shimmer
          dailySummaryCardShimmer(),
          const SizedBox(height: 20),
          
          // Add Food Section Shimmer
          addFoodSectionShimmer(),
          const SizedBox(height: 20),
          
          // Today's Meals Header Shimmer
          todaysMealsHeaderShimmer(),
          const SizedBox(height: 16),
          
          // Multiple Meal Cards Shimmer
          multipleMealCardsShimmer(count: 2),
          const SizedBox(height: 20),
          
          // Scan History Header Shimmer
          scanHistoryHeaderShimmer(),
          const SizedBox(height: 12),
          
          // Multiple Scan History Items Shimmer
          multipleScanHistoryItemsShimmer(count: 3),
        ],
      ),
    );
  }

  /// Build full page shimmer (for compatibility with old screen)
  static Widget buildFullPageShimmer(BuildContext context) {
    return fullPageLoadingShimmer();
  }

  /// Build error state (for compatibility with old screen)
  static Widget buildErrorState(BuildContext context, String errorMessage, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build stats card shimmer (for compatibility with old screen)
  static Widget buildStatsCardShimmer(BuildContext context) {
    return dailySummaryCardShimmer();
  }

  /// Build meals list shimmer (for compatibility with old screen)
  static Widget buildMealsListShimmer(BuildContext context) {
    return multipleMealCardsShimmer(count: 2);
  }

  /// Build scan history shimmer (for compatibility with old screen)
  static Widget buildScanHistoryShimmer(BuildContext context) {
    return multipleScanHistoryItemsShimmer(count: 3);
  }

  /// Error state shimmer (subtle animation)
  static Widget errorStateShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.red.shade100,
      highlightColor: Colors.red.shade50,
      period: const Duration(milliseconds: 1500),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade400,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _createShimmerContainer(width: 120, height: 16),
                  const SizedBox(height: 4),
                  _createShimmerContainer(width: 200, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
