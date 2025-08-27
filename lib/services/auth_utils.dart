import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pigeon_user_details.dart';

/// Fetches user details by UID from Firestore, or creates the user document if it doesn't exist.
/// This function handles both first-time sign-ups and normal logins without needing app restart.
/// 
/// Returns null if the user parameter is null or if there's an error creating the user document.
/// The return value is guaranteed to be PigeonUserDetails? and never List<Object?>
Future<PigeonUserDetails?> fetchOrCreateUserDetails(User user) async {
  try {
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await userDocRef.get();

    if (!doc.exists) {
      // Auto-create user document for new sign-ups
      final email = user.email ?? '';
      final derivedName = (user.displayName?.trim().isNotEmpty == true)
          ? user.displayName!.trim()
          : (email.contains('@') ? email.split('@').first : 'User');
      
      final newUserData = {
        'uid': user.uid,
        'email': email,
        'displayName': derivedName,
        'age': 25,            // default, user can edit later
        'gender': 'Male',     // default, user can edit later
        'height': 170.0,      // cm
        'weight': 70.0,       // kg
        'idealWeight': 65.0,  // kg
        'dailyGoal': 2000,    // kcal
        'units': 'Metric (kg, cm)',
        'notificationsEnabled': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      try {
        await userDocRef.set(newUserData);
        // Return the user details with the data we just created
        final result = PigeonUserDetails.fromMap({
          ...newUserData,
          'createdAt': DateTime.now(), // Approximate since server timestamp isn't available yet
          'updatedAt': DateTime.now(),
        });
        return result;
      } catch (e) {
        print('Error creating user document: $e');
        return null;
      }
    }

    // Document exists, get the data and map it
    final data = doc.data();
    if (data == null) {
      print('Document exists but data is null for user: ${user.uid}');
      return null;
    }

    try {
      final result = PigeonUserDetails.fromMap(Map<String, dynamic>.from(data));
      return result;
    } catch (e) {
      print('Error parsing user data: $e');
      print('Data type: ${data.runtimeType}');
      print('Data content: $data');
      return null;
    }
  } catch (e) {
    print('Error in fetchOrCreateUserDetails: $e');
    return null;
  }
}

/// Alternative version that accepts a query result and safely extracts the first document
/// Use this if you have a query result that you need to convert to a single user object
PigeonUserDetails? extractUserFromQueryResult(List<Object?> queryResult) {
  if (queryResult.isEmpty) return null;
  
  final firstDoc = queryResult.first;
  if (firstDoc is QueryDocumentSnapshot) {
    try {
      final data = firstDoc.data() as Map<String, dynamic>?;
      if (data == null) return null;
      
      return PigeonUserDetails.fromMap({
        'uid': firstDoc.id,
        ...data,
      });
    } catch (e) {
      print('Error extracting user from query result: $e');
      return null;
    }
  }
  
  return null;
}

/// Safe conversion function for any type to PigeonUserDetails
/// Handles various input types including Lists, Maps, and QueryResults
PigeonUserDetails? safeToPigeonUserDetails(dynamic input) {
  if (input == null) return null;
  
  try {
    // If it's already a PigeonUserDetails, return it
    if (input is PigeonUserDetails) {
      return input;
    }
    
    // If it's a Map, try to convert it
    if (input is Map<String, dynamic>) {
      return PigeonUserDetails.fromMap(input);
    }
    
    // If it's a List<Object?> (common from method channels or queries)
    if (input is List<Object?>) {
      return extractUserFromQueryResult(input);
    }
    
    // If it's a single QueryDocumentSnapshot
    if (input is QueryDocumentSnapshot) {
      return PigeonUserDetails.fromSnapshot(input);
    }
    
    // If it's a DocumentSnapshot
    if (input is DocumentSnapshot) {
      return PigeonUserDetails.fromSnapshot(input);
    }
    
    print('Unable to convert input of type ${input.runtimeType} to PigeonUserDetails');
    return null;
    
  } catch (e) {
    print('Error converting to PigeonUserDetails: $e');
    return null;
  }
}
