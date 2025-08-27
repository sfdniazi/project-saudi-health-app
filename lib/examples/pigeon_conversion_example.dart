import '../models/pigeon_user_details.dart';
import '../services/auth_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Example showing how to safely convert various types to PigeonUserDetails
/// This file demonstrates the correct way to handle the type conversion error:
/// "type 'List<Object?>' is not a subtype of type 'PigeonUserDetails?'"
class PigeonConversionExample {
  
  /// ❌ WRONG: This will cause the error
  /// PigeonUserDetails? user = someListResult; // This causes the error!
  
  /// ✅ CORRECT: Use the safe conversion function
  static PigeonUserDetails? handleQueryResult(List<Object?> queryResult) {
    // Use the safe conversion function
    return safeToPigeonUserDetails(queryResult);
  }
  
  /// ✅ CORRECT: Handle method channel results safely
  static Future<PigeonUserDetails?> handleMethodChannelResult(dynamic result) async {
    // If you're getting data from a method channel that returns List<Object?>
    return safeToPigeonUserDetails(result);
  }
  
  /// ✅ CORRECT: Handle Firestore query results
  static Future<PigeonUserDetails?> getUserFromQuery(Query query) async {
    try {
      final querySnapshot = await query.get();
      if (querySnapshot.docs.isEmpty) return null;
      
      // Convert the first document to PigeonUserDetails
      return PigeonUserDetails.fromSnapshot(querySnapshot.docs.first);
    } catch (e) {
      print('Error getting user from query: $e');
      return null;
    }
  }
  
  /// ✅ CORRECT: Handle various input types
  static PigeonUserDetails? convertAnyTypeSafely(dynamic input) {
    return safeToPigeonUserDetails(input);
  }
  
  /// Example usage scenarios
  static void exampleUsages() {
    // Example 1: Converting a List<Object?> result
    List<Object?> someQueryResult = []; // This might come from a method channel
    PigeonUserDetails? user1 = safeToPigeonUserDetails(someQueryResult);
    
    // Example 2: Converting a Map
    Map<String, dynamic> userData = {
      'uid': '123',
      'email': 'test@example.com',
      'displayName': 'Test User',
    };
    PigeonUserDetails? user2 = safeToPigeonUserDetails(userData);
    
    // Example 3: Handle null input safely
    dynamic nullInput = null;
    PigeonUserDetails? user3 = safeToPigeonUserDetails(nullInput); // Returns null safely
    
    print('Converted users: $user1, $user2, $user3');
  }
}

/// Common patterns where the error occurs and how to fix them:
class CommonErrorPatterns {
  
  /// ❌ WRONG: Direct assignment
  static void wrongWay(List<Object?> result) {
    // PigeonUserDetails? user = result; // ❌ This causes the error!
  }
  
  /// ✅ CORRECT: Use safe conversion
  static void correctWay(List<Object?> result) {
    PigeonUserDetails? user = safeToPigeonUserDetails(result); // ✅ This works!
  }
  
  /// ❌ WRONG: Direct casting
  static void wrongCasting(dynamic result) {
    // PigeonUserDetails? user = result as PigeonUserDetails?; // ❌ Unsafe!
  }
  
  /// ✅ CORRECT: Safe casting with type checking
  static void correctCasting(dynamic result) {
    PigeonUserDetails? user = safeToPigeonUserDetails(result); // ✅ Safe!
  }
}
