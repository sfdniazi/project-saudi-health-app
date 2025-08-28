import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import '../../core/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../services/mlkit_service.dart'; // 🎯 Import ML Kit service
import '../../models/food_model.dart';
import '../../presentation/widgets/custom_appbar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OldFoodLoggingScreen extends StatefulWidget {
  const OldFoodLoggingScreen({super.key});

  @override
  State<OldFoodLoggingScreen> createState() => _OldFoodLoggingScreenState();
}

class _OldFoodLoggingScreenState extends State<OldFoodLoggingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final user = FirebaseAuth.instance.currentUser;
  final today = DateTime.now();

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
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to continue')),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Food Logging',
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              _buildDateHeader(),
              const SizedBox(height: 20),
              
              // Daily Summary Card
              _buildDailySummaryCard(),
              const SizedBox(height: 20),
              
              // Add Food Section
              _buildAddFoodSection(),
              const SizedBox(height: 20),
              
              // Today's Meals
              _buildTodaysMeals(),
              
              const SizedBox(height: 20),
              
              // 🎯 Scan History Section
              _buildScanHistorySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
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
          Icon(
            Icons.calendar_today,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            DateFormat('EEEE, MMMM d, y').format(today),
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

  Widget _buildDailySummaryCard() {
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
      child: StreamBuilder<FoodLogModel?>(
        stream: FirebaseService.streamFoodLogData(user!.uid, today),
        builder: (context, snapshot) {
          final foodLog = snapshot.data;
          final calories = foodLog?.totalCalories ?? 0.0;
          final protein = foodLog?.totalProtein ?? 0.0;
          final carbs = foodLog?.totalCarbs ?? 0.0;
          final fat = foodLog?.totalFat ?? 0.0;

          return Column(
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
                    child: _buildNutrientColumn('Calories', '${calories.toInt()}', 'kcal'),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildNutrientColumn('Protein', '${protein.toInt()}', 'g'),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildNutrientColumn('Carbs', '${carbs.toInt()}', 'g'),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildNutrientColumn('Fat', '${fat.toInt()}', 'g'),
                  ),
                ],
              ),
            ],
          );
        },
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

  Widget _buildAddFoodSection() {
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showBarcodeScanner,
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
                  onPressed: _showManualEntry,
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

  Widget _buildTodaysMeals() {
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
        StreamBuilder<FoodLogModel?>(
          stream: FirebaseService.streamFoodLogData(user!.uid, today),
          builder: (context, snapshot) {
            final foodLog = snapshot.data;
            
            if (foodLog == null || foodLog.meals.isEmpty) {
              return _buildEmptyMealsCard();
            }

            return Column(
              children: foodLog.meals.map((meal) => _buildMealCard(meal)).toList(),
            );
          },
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

  void _showBarcodeScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BarcodeBottomSheet(
        onFoodScanned: _addScannedFood,
      ),
    );
  }

  void _showManualEntry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManualEntryBottomSheet(
        onFoodAdded: _addManualFood,
      ),
    );
  }

  Future<void> _addScannedFood(String barcode, Map<String, dynamic> foodData) async {
    try {
      final mealType = await _showMealTypeDialog();
      if (mealType == null) return;

      final foodItem = FoodItem(
        name: foodData['name'] ?? 'Scanned Food',
        barcode: barcode,
        caloriesPerUnit: foodData['calories']?.toDouble() ?? 100.0,
        proteinPerUnit: foodData['protein']?.toDouble() ?? 0.0,
        carbsPerUnit: foodData['carbs']?.toDouble() ?? 0.0,
        fatPerUnit: foodData['fat']?.toDouble() ?? 0.0,
        brand: foodData['brand'],
        imageUrl: foodData['imageUrl'],
      );

      final foodEntry = FoodEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        mealType: mealType,
        items: [foodItem],
        timestamp: DateTime.now(),
      );

      await FirebaseService.addFoodEntry(user!.uid, today, foodEntry);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${foodItem.name} to $mealType'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding food: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addManualFood(Map<String, dynamic> foodData) async {
    try {
      final mealType = foodData['mealType'] as String;
      
      final foodItem = FoodItem(
        name: foodData['name'],
        quantity: foodData['quantity']?.toDouble() ?? 1.0,
        unit: foodData['unit'] ?? 'serving',
        caloriesPerUnit: foodData['calories']?.toDouble() ?? 0.0,
        proteinPerUnit: foodData['protein']?.toDouble() ?? 0.0,
        carbsPerUnit: foodData['carbs']?.toDouble() ?? 0.0,
        fatPerUnit: foodData['fat']?.toDouble() ?? 0.0,
      );

      final foodEntry = FoodEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        mealType: mealType,
        items: [foodItem],
        timestamp: DateTime.now(),
      );

      await FirebaseService.addFoodEntry(user!.uid, today, foodEntry);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${foodItem.name} to $mealType'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding food: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  /// 🎯 Build scan history section with inline history display
  Widget _buildScanHistorySection() {
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
            const Spacer(),
// 🧺 Removed "View All" button as full scan history is not implemented yet
          ],
        ),
        
        const SizedBox(height: 12),
        
        // 🎯 Stream scan history from Firestore
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirebaseService.streamScanHistory(user!.uid, limit: 10),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 120,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: AppTheme.primaryGreen),
              );
            }
            
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentOrange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.accentOrange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Error loading scan history: ${snapshot.error}',
                        style: const TextStyle(
                          color: AppTheme.accentOrange,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            final scanHistory = snapshot.data ?? [];
            
            if (scanHistory.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.textLight.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_scanner_outlined,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
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
            
            // Show scan history list
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: scanHistory.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _buildScanHistoryItem(scanHistory[index]);
              },
            );
          },
        ),
      ],
    );
  }

  /// 🎯 Build individual scan history item
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
          color: AppTheme.textLight.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 🎯 Food icon with background
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.qr_code,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 🎯 Food info
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
                    Text(
                      barcode.length > 8 
                          ? '${barcode.substring(0, 8)}...'
                          : barcode,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 🎯 Nutrition info badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
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
}

// 🎯 Enhanced Barcode Scanner with real ML Kit integration
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
  String? _errorMessage;
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  /// 🎯 Initialize ML Kit scanner
  Future<void> _initializeScanner() async {
    try {
      await _mlKitService.initialize();
      setState(() {
        _isInitialized = true;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize scanner: $e';
        _isInitialized = false;
      });
    }
  }

  /// 🎯 Initialize camera for scanning
  Future<void> _initializeCamera() async {
    try {
      final controller = await _mlKitService.startCamera();
      if (mounted && controller != null) {
        setState(() {
          _cameraController = controller;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera failed: $e';
        });
      }
    }
  }

  /// 🎯 Start scanning process
  Future<void> _startScanning() async {
    if (!_isInitialized) {
      _showErrorMessage('Scanner not initialized');
      return;
    }

    try {
      setState(() {
        _isScanning = true;
        _errorMessage = null;
        _lastScanResult = null;
      });

      await _initializeCamera();
      if (_cameraController == null) {
        throw Exception('Camera initialization failed');
      }

      // Start image stream processing
      await _cameraController!.startImageStream(_processCameraImage);

    } catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'Failed to start scanning: $e';
      });
    }
  }

  /// 🎯 Process camera image for barcode detection
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
      debugPrint('Error processing camera image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// 🎯 Handle scanned barcode result
  Future<void> _handleBarcodeResult(String barcode) async {
    try {
      // Get food data from ML Kit service
      final foodData = _mlKitService.getFoodDataForBarcode(barcode);
      
      // Save scan result to Firestore for history
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseService.saveScanResult(
          uid: user.uid,
          barcode: barcode,
          mealInfo: foodData,
        );
      }

      setState(() {
        _lastScanResult = {
          'barcode': barcode,
          ...foodData,
          'scannedAt': DateTime.now(),
        };
      });

      // Show success and pass result to parent
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Scanned: ${foodData['name']}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Add delay to show result, then proceed
        await Future.delayed(const Duration(milliseconds: 1500));
        widget.onFoodScanned(barcode, foodData);
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process scan: $e';
      });
    }
  }

  /// 🎯 Stop scanning and cleanup
  Future<void> _stopScanning() async {
    try {
      await _cameraController?.stopImageStream();
      await _mlKitService.stopCamera();
      setState(() {
        _isScanning = false;
        _cameraController = null;
      });
    } catch (e) {
      debugPrint('Error stopping scanning: $e');
    }
  }

  /// 🎯 Show error message
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppTheme.accentOrange,
        ),
      );
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
          // 🎯 Header
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
          
          // 🎯 Camera Preview or Status
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: _buildCameraContent(),
            ),
          ),
          
          // 🎯 Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.accentOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, 
                          color: AppTheme.accentOrange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.accentOrange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? _stopScanning : _startScanning,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isScanning
                          ? const Icon(Icons.stop, key: ValueKey('stop'))
                          : const Icon(Icons.qr_code_scanner, key: ValueKey('start')),
                    ),
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
                
// 🧹 Removed demo scan button as requested
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Build camera content based on current state
  Widget _buildCameraContent() {
    if (_lastScanResult != null) {
      // Show scan result
      final result = _lastScanResult!;
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.primaryGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scanned Successfully!',
              style: const TextStyle(
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
            const SizedBox(height: 12),
            Text(
              '${result['calories']} calories',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_isScanning && _cameraController != null && 
        _cameraController!.value.isInitialized) {
      // Show camera preview
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CameraPreview(_cameraController!),
            ),
            // Scanning overlay
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
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
    
    // Default state
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
                    // Meal Type Dropdown
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
                    
                    // Food Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Food Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter food name' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Quantity and Unit
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
                    
                    // Calories
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
                    
                    // Macros Row
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
                    
                    // Add Button
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
