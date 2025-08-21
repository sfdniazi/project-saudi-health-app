import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../models/hydration_model.dart';
import '../models/food_model.dart';
import '../models/recommendation_model.dart';
import 'package:intl/intl.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference for users
  static CollectionReference get _usersCollection => _firestore.collection('users');

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Create or update user profile in Firestore
  static Future<void> createOrUpdateUserProfile(UserModel userModel) async {
    try {
      await _usersCollection.doc(userModel.uid).set(
        userModel.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  // Get user profile from Firestore
  static Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Get current user profile
  static Future<UserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    return await getUserProfile(user.uid);
  }

  // Stream user profile for real-time updates
  static Stream<UserModel?> streamUserProfile(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromSnapshot(doc);
      }
      return null;
    });
  }

  // Stream current user profile
  static Stream<UserModel?> streamCurrentUserProfile() {
    final user = currentUser;
    if (user == null) {
      return Stream.value(null);
    }
    return streamUserProfile(user.uid);
  }

  // Update specific user data fields
  static Future<void> updateUserData({
    String? displayName,
    int? age,
    double? height,
    double? weight,
    double? idealWeight,
    int? dailyGoal,
    String? units,
    bool? notificationsEnabled,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    final Map<String, dynamic> updates = {};

    if (displayName != null) updates['displayName'] = displayName;
    if (age != null) updates['age'] = age;
    if (height != null) updates['height'] = height;
    if (weight != null) updates['weight'] = weight;
    if (idealWeight != null) updates['idealWeight'] = idealWeight;
    if (dailyGoal != null) updates['dailyGoal'] = dailyGoal;
    if (units != null) updates['units'] = units;
    if (notificationsEnabled != null) updates['notificationsEnabled'] = notificationsEnabled;

    updates['updatedAt'] = FieldValue.serverTimestamp();

    try {
      await _usersCollection.doc(user.uid).update(updates);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Create initial user profile during registration
  static Future<void> createInitialUserProfile({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    try {
      print('Creating initial profile for user: $uid, email: $email');
      
      // Check if profile already exists
      final existingProfile = await getUserProfile(uid);
      if (existingProfile != null) {
        print('Profile already exists for user: $uid');
        return; // Profile already exists, no need to create
      }
      
      final userModel = UserModel(
        uid: uid,
        email: email,
        displayName: displayName ?? 'User',
        age: 0,
        height: 0.0,
        weight: 0.0,
        idealWeight: 0.0,
        dailyGoal: 2000,
        units: 'Metric (kg, cm)',
        notificationsEnabled: true,
        createdAt: DateTime.now(),
      );

      await createOrUpdateUserProfile(userModel);
      print('Successfully created initial profile for user: $uid');
    } catch (e) {
      print('Error creating initial profile for user $uid: $e');
      throw Exception('Failed to create initial user profile: $e');
    }
  }

  // Delete user profile
  static Future<void> deleteUserProfile(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user profile: $e');
    }
  }

  // Check if user profile exists
  static Future<bool> userProfileExists(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // ========== ACTIVITY TRACKING ==========

  static CollectionReference _getActivityCollection(String uid) {
    return _usersCollection.doc(uid).collection('activity');
  }

  // Save or update daily activity data
  static Future<void> saveActivityData(ActivityModel activity) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(activity.date);
      await _getActivityCollection(activity.userId).doc(dateKey).set(
        activity.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to save activity data: $e');
    }
  }

  // Get activity data for a specific date
  static Future<ActivityModel?> getActivityData(String uid, DateTime date) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final doc = await _getActivityCollection(uid).doc(dateKey).get();
      if (doc.exists) {
        return ActivityModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get activity data: $e');
    }
  }

  // Stream activity data for real-time updates
  static Stream<ActivityModel?> streamActivityData(String uid, DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return _getActivityCollection(uid).doc(dateKey).snapshots().map((doc) {
      if (doc.exists) {
        return ActivityModel.fromSnapshot(doc);
      }
      return null;
    });
  }

  // Get activity data for a date range
  static Future<List<ActivityModel>> getActivityRange(String uid, DateTime startDate, DateTime endDate) async {
    try {
      final query = await _getActivityCollection(uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();
      
      return query.docs.map((doc) => ActivityModel.fromSnapshot(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get activity range: $e');
    }
  }

  // ========== HYDRATION TRACKING ==========

  static CollectionReference _getHydrationCollection(String uid) {
    return _usersCollection.doc(uid).collection('hydration');
  }

  // Save or update daily hydration data
  static Future<void> saveHydrationData(HydrationModel hydration) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(hydration.date);
      await _getHydrationCollection(hydration.userId).doc(dateKey).set(
        hydration.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to save hydration data: $e');
    }
  }

  // Get hydration data for a specific date
  static Future<HydrationModel?> getHydrationData(String uid, DateTime date) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final doc = await _getHydrationCollection(uid).doc(dateKey).get();
      if (doc.exists) {
        return HydrationModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get hydration data: $e');
    }
  }

  // Stream hydration data for real-time updates
  static Stream<HydrationModel?> streamHydrationData(String uid, DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return _getHydrationCollection(uid).doc(dateKey).snapshots().map((doc) {
      if (doc.exists) {
        return HydrationModel.fromSnapshot(doc);
      }
      return null;
    });
  }

  // Add water entry to daily hydration
  static Future<void> addWaterEntry(String uid, DateTime date, WaterEntry entry) async {
    try {
      final hydrationData = await getHydrationData(uid, date);
      final List<WaterEntry> entries = hydrationData?.entries.toList() ?? [];
      entries.add(entry);
      
      final totalIntake = entries.fold(0.0, (sum, e) => sum + e.amount);
      
      final updatedHydration = HydrationModel(
        id: hydrationData?.id ?? '',
        userId: uid,
        date: date,
        waterIntake: totalIntake,
        goalAmount: hydrationData?.goalAmount ?? 2.5,
        entries: entries,
        createdAt: hydrationData?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await saveHydrationData(updatedHydration);
    } catch (e) {
      throw Exception('Failed to add water entry: $e');
    }
  }

  // ========== FOOD LOGGING ==========

  static CollectionReference _getFoodLogCollection(String uid) {
    return _usersCollection.doc(uid).collection('food_logs');
  }

  // Save or update daily food log data
  static Future<void> saveFoodLogData(FoodLogModel foodLog) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(foodLog.date);
      final calculatedLog = foodLog.calculateTotals();
      await _getFoodLogCollection(foodLog.userId).doc(dateKey).set(
        calculatedLog.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to save food log data: $e');
    }
  }

  // Get food log data for a specific date
  static Future<FoodLogModel?> getFoodLogData(String uid, DateTime date) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final doc = await _getFoodLogCollection(uid).doc(dateKey).get();
      if (doc.exists) {
        return FoodLogModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get food log data: $e');
    }
  }

  // Stream food log data for real-time updates
  static Stream<FoodLogModel?> streamFoodLogData(String uid, DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return _getFoodLogCollection(uid).doc(dateKey).snapshots().map((doc) {
      if (doc.exists) {
        return FoodLogModel.fromSnapshot(doc);
      }
      return null;
    });
  }

  // Add food entry to daily food log
  static Future<void> addFoodEntry(String uid, DateTime date, FoodEntry entry) async {
    try {
      final foodLogData = await getFoodLogData(uid, date);
      final List<FoodEntry> meals = foodLogData?.meals.toList() ?? [];
      
      // Find existing meal of same type or add new one
      final existingMealIndex = meals.indexWhere((m) => m.mealType == entry.mealType);
      if (existingMealIndex != -1) {
        final existingMeal = meals[existingMealIndex];
        final updatedItems = [...existingMeal.items, ...entry.items];
        meals[existingMealIndex] = existingMeal.copyWith(items: updatedItems).calculateTotals();
      } else {
        meals.add(entry.calculateTotals());
      }
      
      final updatedFoodLog = FoodLogModel(
        id: foodLogData?.id ?? '',
        userId: uid,
        date: date,
        meals: meals,
        createdAt: foodLogData?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await saveFoodLogData(updatedFoodLog);
    } catch (e) {
      throw Exception('Failed to add food entry: $e');
    }
  }

  // ========== RECOMMENDATIONS ==========

  static CollectionReference _getRecommendationsCollection(String uid) {
    return _usersCollection.doc(uid).collection('recommendations');
  }

  // Save recommendation
  static Future<void> saveRecommendation(RecommendationModel recommendation) async {
    try {
      final docRef = _getRecommendationsCollection(recommendation.userId).doc();
      final updatedRecommendation = recommendation.copyWith(id: docRef.id);
      await docRef.set(updatedRecommendation.toMap());
    } catch (e) {
      throw Exception('Failed to save recommendation: $e');
    }
  }

  // Get all recommendations for user
  static Future<List<RecommendationModel>> getRecommendations(String uid) async {
    try {
      final query = await _getRecommendationsCollection(uid)
          .orderBy('priority')
          .orderBy('createdAt', descending: true)
          .get();
      
      return query.docs.map((doc) => RecommendationModel.fromSnapshot(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get recommendations: $e');
    }
  }

  // Stream recommendations for real-time updates
  static Stream<List<RecommendationModel>> streamRecommendations(String uid) {
    return _getRecommendationsCollection(uid)
        .orderBy('priority')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((query) => query.docs.map((doc) => RecommendationModel.fromSnapshot(doc)).toList());
  }

  // Mark recommendation as read
  static Future<void> markRecommendationAsRead(String uid, String recommendationId) async {
    try {
      await _getRecommendationsCollection(uid).doc(recommendationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark recommendation as read: $e');
    }
  }

  // Mark recommendation as completed
  static Future<void> markRecommendationAsCompleted(String uid, String recommendationId) async {
    try {
      await _getRecommendationsCollection(uid).doc(recommendationId).update({
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark recommendation as completed: $e');
    }
  }

  // Generate and save AI recommendations
  static Future<void> generateAndSaveRecommendations(String uid) async {
    try {
      final userProfile = await getUserProfile(uid);
      if (userProfile == null) return;

      // Get recent data for recommendations
      final today = DateTime.now();
      final activityData = await getActivityData(uid, today);
      final hydrationData = await getHydrationData(uid, today);
      final foodLogData = await getFoodLogData(uid, today);

      // Generate recommendations
      final recommendations = RecommendationGenerator.generateRecommendations(
        userId: uid,
        userData: userProfile.toMap(),
        activityData: activityData?.toMap(),
        hydrationData: hydrationData?.toMap(),
        nutritionData: foodLogData?.toMap(),
      );

      // Save recommendations
      for (final recommendation in recommendations) {
        await saveRecommendation(recommendation);
      }
    } catch (e) {
      throw Exception('Failed to generate recommendations: $e');
    }
  }

  // ========== UTILITY METHODS ==========

  // Initialize user collections when they sign up
  static Future<void> initializeUserCollections(String uid) async {
    try {
      final today = DateTime.now();
      final dateKey = DateFormat('yyyy-MM-dd').format(today);

      // Initialize activity tracking
      final initialActivity = ActivityModel(
        id: dateKey,
        userId: uid,
        date: today,
        createdAt: today,
        updatedAt: today,
      );
      await saveActivityData(initialActivity);

      // Initialize hydration tracking
      final initialHydration = HydrationModel(
        id: dateKey,
        userId: uid,
        date: today,
        createdAt: today,
        updatedAt: today,
      );
      await saveHydrationData(initialHydration);

      // Initialize food log
      final initialFoodLog = FoodLogModel(
        id: dateKey,
        userId: uid,
        date: today,
        createdAt: today,
        updatedAt: today,
      );
      await saveFoodLogData(initialFoodLog);

      // Generate initial recommendations
      await generateAndSaveRecommendations(uid);
    } catch (e) {
      print('Warning: Failed to initialize user collections: $e');
    }
  }

  // Get comprehensive health data for today
  static Future<Map<String, dynamic>> getTodayHealthData(String uid) async {
    try {
      final today = DateTime.now();
      
      final results = await Future.wait([
        getUserProfile(uid),
        getActivityData(uid, today),
        getHydrationData(uid, today),
        getFoodLogData(uid, today),
        getRecommendations(uid),
      ]);

      return {
        'userProfile': results[0],
        'activity': results[1],
        'hydration': results[2],
        'foodLog': results[3],
        'recommendations': results[4],
      };
    } catch (e) {
      throw Exception('Failed to get today\'s health data: $e');
    }
  }
}
