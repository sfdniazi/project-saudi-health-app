import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_theme.dart';
import '../../../models/food_model.dart';
import '../providers/food_logging_provider.dart';
import '../models/food_logging_state_model.dart';
import '../widgets/food_logging_shimmer_widgets.dart';

/// Wrapper widget to provide FoodLoggingProvider
class FoodLoggingScreen extends StatelessWidget {
  const FoodLoggingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final provider = FoodLoggingProvider();
        provider.initialize();
        return provider;
      },
      child: const _FoodLoggingScreenContent(),
    );
  }
}

/// Main content widget that consumes the provider
class _FoodLoggingScreenContent extends StatefulWidget {
  const _FoodLoggingScreenContent();

  @override
  State<_FoodLoggingScreenContent> createState() => _FoodLoggingScreenContentState();
}

class _FoodLoggingScreenContentState extends State<_FoodLoggingScreenContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to continue')),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Custom app bar without back button
          _buildCustomAppBar(context),
          
          // Main content
          Expanded(
            child: Consumer<FoodLoggingProvider>(
              builder: (context, provider, child) {
                final state = provider.state;

                // Show loading state
                if (state.isLoading) {
                  return Container(
                    color: AppTheme.getBackgroundColor(context),
                    child: FoodLoggingShimmerWidgets.buildFullPageShimmer(context),
                  );
                }

                // Show error state
                if (state.hasError) {
                  return Container(
                    color: AppTheme.getBackgroundColor(context),
                    child: FoodLoggingShimmerWidgets.buildErrorState(
                      context,
                      state.errorMessage ?? 'Failed to load food logging data',
                      () => provider.refreshData(),
                    ),
                  );
                }

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    color: AppTheme.getBackgroundColor(context),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Header
                          _buildDateHeader(state),
                          const SizedBox(height: 20),
                          
                          // Daily Summary Card
                          _buildDailySummaryCard(state),
                          const SizedBox(height: 20),
                          
                          // Add Food Section
                          _buildAddFoodSection(context, provider),
                          const SizedBox(height: 20),
                          
                          // Today's Meals
                          _buildTodaysMeals(state),
                          const SizedBox(height: 20),
                          
                          // Scan History Section
                          _buildScanHistorySection(state),
                          
                          // Messages
                          if (state.messages.isNotEmpty)
                            _buildMessagesSection(state, provider),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build custom app bar without back button
  Widget _buildCustomAppBar(BuildContext context) {
    // Get safe area padding
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;
    final safeTopPadding = statusBarHeight + 16;
    
    return Container(
      padding: EdgeInsets.fromLTRB(20, safeTopPadding, 20, 20),
      decoration: BoxDecoration(
        gradient: AppTheme.getHeaderGradient(context),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Title only - no back button
            Expanded(
              child: Text(
                'Food Logging',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            
            // Optional notification or settings icon
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // Can add settings or notification functionality here
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(FoodLoggingStateModel state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            DateFormat('EEEE, MMMM d, y').format(state.selectedDate),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummaryCard(FoodLoggingStateModel state) {
    if (state.isSectionLoading(FoodLoggingSection.dailySummary)) {
      return FoodLoggingShimmerWidgets.buildStatsCardShimmer(context);
    }

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
                child: const Icon(
                  Icons.restaurant_menu,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Daily Nutrition Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildNutrientColumn('Calories', '${state.totalCalories.toInt()}', 'kcal'),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildNutrientColumn('Protein', '${state.totalProtein.toInt()}', 'g'),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildNutrientColumn('Carbs', '${state.totalCarbs.toInt()}', 'g'),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildNutrientColumn('Fat', '${state.totalFat.toInt()}', 'g'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientColumn(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAddFoodSection(BuildContext context, FoodLoggingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Food',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showBarcodeScanner(context, provider),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Barcode'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showManualEntry(context, provider),
                  icon: const Icon(Icons.edit),
                  label: const Text('Manual Entry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysMeals(FoodLoggingStateModel state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Meals',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        
        if (state.isSectionLoading(FoodLoggingSection.todaysMeals))
          FoodLoggingShimmerWidgets.buildMealsListShimmer(context)
        else if (!state.hasMeals)
          _buildEmptyMealsCard()
        else
          Column(
            children: state.todaysMeals.map((meal) => _buildMealCard(meal)).toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyMealsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.1),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 48,
              color: AppTheme.textLight.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No meals logged today',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by scanning a barcode or adding food manually',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(FoodEntry meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _getMealIcon(meal.mealType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getMealTypeDisplay(meal.mealType),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      DateFormat('h:mm a').format(meal.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${meal.totalCalories.toInt()} kcal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          if (meal.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...meal.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.name} (${item.quantity} ${item.unit})',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${item.totalCalories.toInt()} kcal',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildScanHistorySection(FoodLoggingStateModel state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.history,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Recent Scans',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (state.isSectionLoading(FoodLoggingSection.scanHistory))
          FoodLoggingShimmerWidgets.buildScanHistoryShimmer(context)
        else if (state.scanHistory.isEmpty)
          _buildEmptyScanHistory()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.scanHistory.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _buildScanHistoryItem(state.scanHistory[index]);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyScanHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.qr_code_scanner_outlined,
            color: AppTheme.textSecondary.withOpacity(0.5),
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'No scans yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Scan your first food barcode to see it here',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScanHistoryItem(Map<String, dynamic> scanData) {
    final mealInfo = scanData['mealInfo'] as Map<String, dynamic>;
    final timestamp = scanData['timestamp'] as Timestamp?;
    
    final timeString = timestamp != null
        ? DateFormat('MMM d, HH:mm').format(timestamp.toDate())
        : 'Recently';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
            child: const Icon(
              Icons.qr_code,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mealInfo['name'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeString,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
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
                Text(
                  '${mealInfo['calories']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const Text(
                  'cal',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesSection(FoodLoggingStateModel state, FoodLoggingProvider provider) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Messages',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: provider.clearAllMessages,
                icon: const Icon(Icons.clear, size: 16),
                color: AppTheme.primaryGreen,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...state.messages.map((message) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $message',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Icon _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icon(Icons.free_breakfast, color: Colors.orange, size: 24);
      case 'lunch':
        return Icon(Icons.lunch_dining, color: Colors.green, size: 24);
      case 'dinner':
        return Icon(Icons.dinner_dining, color: Colors.red, size: 24);
      case 'snack':
        return Icon(Icons.bakery_dining, color: Colors.purple, size: 24);
      default:
        return Icon(Icons.restaurant_menu, color: AppTheme.primaryGreen, size: 24);
    }
  }

  String _getMealTypeDisplay(String mealType) {
    return mealType.substring(0, 1).toUpperCase() + mealType.substring(1).toLowerCase();
  }

  void _showBarcodeScanner(BuildContext context, FoodLoggingProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BarcodeBottomSheet(
        onFoodScanned: (barcode, foodData) async {
          final mealType = await _showMealTypeDialog(context);
          if (mealType != null) {
            await provider.addScannedFood(barcode, foodData, mealType);
          }
        },
      ),
    );
  }

  void _showManualEntry(BuildContext context, FoodLoggingProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManualEntryBottomSheet(
        onFoodAdded: provider.addManualFood,
      ),
    );
  }

  Future<String?> _showMealTypeDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Meal Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMealTypeOption(context, 'breakfast', 'Breakfast', Icons.free_breakfast, Colors.orange),
            _buildMealTypeOption(context, 'lunch', 'Lunch', Icons.lunch_dining, Colors.green),
            _buildMealTypeOption(context, 'dinner', 'Dinner', Icons.dinner_dining, Colors.red),
            _buildMealTypeOption(context, 'snack', 'Snack', Icons.bakery_dining, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeOption(BuildContext context, String value, String label, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () => Navigator.pop(context, value),
    );
  }
}

// Barcode Scanner Bottom Sheet (simplified version)
class _BarcodeBottomSheet extends StatefulWidget {
  final Function(String, Map<String, dynamic>) onFoodScanned;

  const _BarcodeBottomSheet({required this.onFoodScanned});

  @override
  State<_BarcodeBottomSheet> createState() => _BarcodeBottomSheetState();
}

class _BarcodeBottomSheetState extends State<_BarcodeBottomSheet> {

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Scan Food Barcode',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Barcode scanning functionality\nwill be implemented here',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Demo scan result
                  final demoData = {
                    'name': 'Demo Food Item',
                    'calories': 150,
                    'protein': 5.0,
                    'carbs': 20.0,
                    'fat': 3.0,
                    'brand': 'Demo Brand',
                  };
                  widget.onFoodScanned('1234567890', demoData);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Demo Scan'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Manual Entry Bottom Sheet
class _ManualEntryBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onFoodAdded;

  const _ManualEntryBottomSheet({required this.onFoodAdded});

  @override
  State<_ManualEntryBottomSheet> createState() => _ManualEntryBottomSheetState();
}

class _ManualEntryBottomSheetState extends State<_ManualEntryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController(text: '0');
  final _carbsController = TextEditingController(text: '0');
  final _fatController = TextEditingController(text: '0');
  
  String _selectedMealType = 'breakfast';
  String _selectedUnit = 'serving';

  final List<String> _units = ['serving', 'grams', 'cups', 'pieces', 'ml', 'oz'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Add Food Manually',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedMealType,
                      decoration: const InputDecoration(
                        labelText: 'Meal Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'breakfast', child: Text('Breakfast')),
                        DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                        DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                        DropdownMenuItem(value: 'snack', child: Text('Snack')),
                      ],
                      onChanged: (value) => setState(() => _selectedMealType = value!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Food Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter food name' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(),
                            ),
                            items: _units.map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            )).toList(),
                            onChanged: (value) => setState(() => _selectedUnit = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _caloriesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Calories per unit *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter calories' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _proteinController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Protein (g)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _carbsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Carbs (g)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _fatController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Fat (g)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addFood,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Add Food',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addFood() {
    if (_formKey.currentState!.validate()) {
      final foodData = {
        'mealType': _selectedMealType,
        'name': _nameController.text,
        'quantity': double.tryParse(_quantityController.text) ?? 1.0,
        'unit': _selectedUnit,
        'calories': double.tryParse(_caloriesController.text) ?? 0.0,
        'protein': double.tryParse(_proteinController.text) ?? 0.0,
        'carbs': double.tryParse(_carbsController.text) ?? 0.0,
        'fat': double.tryParse(_fatController.text) ?? 0.0,
      };

      widget.onFoodAdded(foodData);
      Navigator.pop(context);
    }
  }
}
