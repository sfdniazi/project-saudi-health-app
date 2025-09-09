import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_theme.dart';
import '../../../presentation/widgets/custom_appbar.dart';
import '../../../services/mlkit_service.dart';
import '../../../models/food_model.dart';
import '../providers/food_logging_provider.dart';
import '../models/food_logging_state_model.dart';
import '../widgets/food_logging_shimmer_widgets.dart';

class FoodLoggingScreenWithProvider extends StatefulWidget {
  const FoodLoggingScreenWithProvider({super.key});

  @override
  State<FoodLoggingScreenWithProvider> createState() => _FoodLoggingScreenWithProviderState();
}

class _FoodLoggingScreenWithProviderState extends State<FoodLoggingScreenWithProvider>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Initialize the food logging provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final foodLoggingProvider = context.read<FoodLoggingProvider>();
      // Only initialize if not already initialized
      if (foodLoggingProvider.state.status == FoodLoggingDataStatus.initial) {
        foodLoggingProvider.initialize();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Food Logging',
        showProfile: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<FoodLoggingProvider>().refreshData();
          },
          child: Consumer<FoodLoggingProvider>(
            builder: (context, foodLoggingProvider, child) {
              // Show error state if there's an error
              if (foodLoggingProvider.hasError) {
                return _buildErrorState(foodLoggingProvider);
              }

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16.0,
                        16.0,
                        16.0,
                        MediaQuery.of(context).padding.bottom + 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Header
                          _buildDateHeader(foodLoggingProvider),
                          const SizedBox(height: 16),
                          
                          // Daily Summary Card
                          _buildDailySummaryCard(foodLoggingProvider),
                          const SizedBox(height: 16),
                          
                          // Add Food Section
                          _buildAddFoodSection(foodLoggingProvider),
                          const SizedBox(height: 16),
                          
                          // Today's Meals
                          _buildTodaysMeals(foodLoggingProvider),
                          const SizedBox(height: 16),
                          
                          // Scan History Section
                          _buildScanHistorySection(foodLoggingProvider),
                          
                          // Show success/error messages
                          if (foodLoggingProvider.state.messages.isNotEmpty)
                            ..._buildMessageWidgets(foodLoggingProvider),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(FoodLoggingProvider foodLoggingProvider) {
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              foodLoggingProvider.errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                foodLoggingProvider.clearError();
                foodLoggingProvider.initialize();
              },
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

  Widget _buildDateHeader(FoodLoggingProvider foodLoggingProvider) {
    if (foodLoggingProvider.isSectionLoading(FoodLoggingSection.userProfile)) {
      return FoodLoggingShimmerWidgets.dateHeaderShimmer();
    }

    return GestureDetector(
      onTap: () => _showDatePicker(foodLoggingProvider),
      child: Container(
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
            Icon(
              Icons.calendar_today,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('EEEE, MMMM d, y').format(foodLoggingProvider.selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummaryCard(FoodLoggingProvider foodLoggingProvider) {
    if (foodLoggingProvider.isSectionLoading(FoodLoggingSection.dailySummary)) {
      return FoodLoggingShimmerWidgets.dailySummaryCardShimmer();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Daily Nutrition Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildNutrientColumn(
                    'Calories',
                    '${foodLoggingProvider.totalCalories.toInt()}',
                    'kcal',
                  ),
                ),
                Container(
                  width: 1,
                  height: 35,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildNutrientColumn(
                    'Protein',
                    '${foodLoggingProvider.totalProtein.toInt()}',
                    'g',
                  ),
                ),
                Container(
                  width: 1,
                  height: 35,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildNutrientColumn(
                    'Carbs',
                    '${foodLoggingProvider.totalCarbs.toInt()}',
                    'g',
                  ),
                ),
                Container(
                  width: 1,
                  height: 35,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildNutrientColumn(
                    'Fat',
                    '${foodLoggingProvider.totalFat.toInt()}',
                    'g',
                  ),
                ),
              ],
            ),
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
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
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAddFoodSection(FoodLoggingProvider foodLoggingProvider) {
    if (foodLoggingProvider.isLoading) {
      return FoodLoggingShimmerWidgets.addFoodSectionShimmer();
    }

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
          const Text(
            'Add Food',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showBarcodeScanner(foodLoggingProvider),
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text('Scan Barcode', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showManualEntry(foodLoggingProvider),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Manual Entry', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysMeals(FoodLoggingProvider foodLoggingProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (foodLoggingProvider.isSectionLoading(FoodLoggingSection.todaysMeals))
          FoodLoggingShimmerWidgets.todaysMealsHeaderShimmer()
        else
          const Text(
            'Today\'s Meals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        const SizedBox(height: 16),
        
        if (foodLoggingProvider.isSectionLoading(FoodLoggingSection.todaysMeals))
          FoodLoggingShimmerWidgets.multipleMealCardsShimmer(count: 2)
        else if (!foodLoggingProvider.hasMeals)
          _buildEmptyMealsCard()
        else
          Column(
            children: foodLoggingProvider.todaysMeals.map((meal) => _buildMealCard(meal)).toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyMealsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
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

  Widget _buildScanHistorySection(FoodLoggingProvider foodLoggingProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (foodLoggingProvider.isSectionLoading(FoodLoggingSection.scanHistory))
          FoodLoggingShimmerWidgets.scanHistoryHeaderShimmer()
        else
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
        
        if (foodLoggingProvider.isSectionLoading(FoodLoggingSection.scanHistory))
          FoodLoggingShimmerWidgets.multipleScanHistoryItemsShimmer(count: 3)
        else if (foodLoggingProvider.scanHistory.isEmpty)
          _buildEmptyScanHistoryCard()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: foodLoggingProvider.scanHistory.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _buildScanHistoryItem(foodLoggingProvider.scanHistory[index]);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyScanHistoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
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
    final barcode = scanData['barcode'] as String;
    
    // Format timestamp
    final timeString = timestamp != null
        ? DateFormat('MMM d, HH:mm').format(timestamp.toDate())
        : 'Recently';
    
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
                    const SizedBox(width: 12),
                    Icon(
                      Icons.tag,
                      size: 14,
                      color: AppTheme.textLight,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        barcode.length > 8 
                            ? '${barcode.substring(0, 8)}...'
                            : barcode,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
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

  List<Widget> _buildMessageWidgets(FoodLoggingProvider foodLoggingProvider) {
    return foodLoggingProvider.state.messages.map((message) {
      final isError = message.toLowerCase().contains('error') || 
                     message.toLowerCase().contains('failed');
      
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isError ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isError ? Colors.red.shade200 : Colors.green.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.red : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isError ? Colors.red.shade700 : Colors.green.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => foodLoggingProvider.clearMessage(message),
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: isError ? Colors.red.shade400 : Colors.green.shade400,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
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

  Future<void> _showDatePicker(FoodLoggingProvider foodLoggingProvider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: foodLoggingProvider.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != foodLoggingProvider.selectedDate) {
      await foodLoggingProvider.changeSelectedDate(picked);
    }
  }

  void _showBarcodeScanner(FoodLoggingProvider foodLoggingProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BarcodeBottomSheet(
        onFoodScanned: (barcode, foodData) async {
          final mealType = await _showMealTypeDialog();
          if (mealType != null) {
            await foodLoggingProvider.addScannedFood(barcode, foodData, mealType);
          }
        },
      ),
    );
  }

  void _showManualEntry(FoodLoggingProvider foodLoggingProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManualEntryBottomSheet(
        onFoodAdded: (foodData) async {
          await foodLoggingProvider.addManualFood(foodData);
        },
      ),
    );
  }

  Future<String?> _showMealTypeDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Meal Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMealTypeOption('breakfast', 'Breakfast', Icons.free_breakfast, Colors.orange),
            _buildMealTypeOption('lunch', 'Lunch', Icons.lunch_dining, Colors.green),
            _buildMealTypeOption('dinner', 'Dinner', Icons.dinner_dining, Colors.red),
            _buildMealTypeOption('snack', 'Snack', Icons.bakery_dining, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeOption(String value, String label, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () => Navigator.pop(context, value),
    );
  }
}

// Barcode Scanner Bottom Sheet (simplified version using existing code structure)
class _BarcodeBottomSheet extends StatefulWidget {
  final Function(String, Map<String, dynamic>) onFoodScanned;

  const _BarcodeBottomSheet({required this.onFoodScanned});

  @override
  State<_BarcodeBottomSheet> createState() => _BarcodeBottomSheetState();
}

class _BarcodeBottomSheetState extends State<_BarcodeBottomSheet> 
    with WidgetsBindingObserver {
  final MLKitService _mlKitService = MLKitService.instance;
  
  bool _isInitialized = false;
  bool _isScanning = false;
  bool _isProcessing = false;
  CameraController? _cameraController;
  Map<String, dynamic>? _lastScanResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScanner();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopScanning();
    super.dispose();
  }

  Future<void> _initializeScanner() async {
    try {
      await _mlKitService.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  Future<void> _startScanning() async {
    if (!_isInitialized) return;

    try {
      setState(() {
        _isScanning = true;
        _lastScanResult = null;
      });

      final controller = await _mlKitService.startCamera();
      if (mounted && controller != null) {
        setState(() {
          _cameraController = controller;
        });
        await _cameraController!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || !_isScanning) return;
    
    _isProcessing = true;
    
    try {
      final barcode = await _mlKitService.scanBarcodeFromImage(image);
      
      if (barcode != null && mounted) {
        await _stopScanning();
        await _handleBarcodeResult(barcode);
      }
    } catch (e) {
      // Handle error silently
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _handleBarcodeResult(String barcode) async {
    try {
      final foodData = _mlKitService.getFoodDataForBarcode(barcode);
      
      setState(() {
        _lastScanResult = {
          'barcode': barcode,
          ...foodData,
          'scannedAt': DateTime.now(),
        };
      });

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 1500));
        widget.onFoodScanned(barcode, foodData);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Error handled silently
        });
      }
    }
  }

  Future<void> _stopScanning() async {
    try {
      await _cameraController?.stopImageStream();
      await _mlKitService.stopCamera();
      if (mounted) {
        setState(() {
          _isScanning = false;
          _cameraController = null;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

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
                  'Scan Food Barcode',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    _stopScanning();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: _buildCameraContent(),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? _stopScanning : _startScanning,
                icon: Icon(_isScanning ? Icons.stop : Icons.qr_code_scanner),
                label: Text(_isScanning ? 'Stop Scanning' : 'Start Scanning'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isScanning 
                      ? AppTheme.accentOrange 
                      : AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraContent() {
    if (_lastScanResult != null) {
      final result = _lastScanResult!;
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.primaryGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scanned Successfully!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result['name'] as String,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    if (_isScanning && _cameraController != null && 
        _cameraController!.value.isInitialized) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CameraPreview(_cameraController!),
            ),
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Point camera at barcode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _isInitialized 
                ? 'Tap "Start Scanning" to begin'
                : 'Initializing scanner...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (!_isInitialized) ...[
            const SizedBox(height: 12),
            const CircularProgressIndicator(),
          ],
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
