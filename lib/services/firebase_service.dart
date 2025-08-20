import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

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
}
