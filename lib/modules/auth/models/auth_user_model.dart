import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthUserModel {
  final String uid;
  final String email;
  final String displayName;
  final int age;
  final String gender;
  final double height;
  final double weight;
  final double idealWeight;
  final int dailyGoal;
  final String units;
  final bool notificationsEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AuthUserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.age = 25,
    this.gender = 'Male',
    this.height = 170.0,
    this.weight = 70.0,
    this.idealWeight = 65.0,
    this.dailyGoal = 2000,
    this.units = 'Metric (kg, cm)',
    this.notificationsEnabled = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Create AuthUserModel from Firebase User
  factory AuthUserModel.fromFirebaseUser(User user) {
    return AuthUserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 
          (user.email?.contains('@') == true 
              ? user.email!.split('@').first 
              : 'User'),
    );
  }

  /// ✅ Create AuthUserModel from Firestore document with safe type conversion
  factory AuthUserModel.fromMap(Map<String, dynamic> map) {
    try {
      return AuthUserModel(
        uid: _safeString(map['uid']) ?? '',
        email: _safeString(map['email']) ?? '',
        displayName: _safeString(map['displayName']) ?? '',
        age: _safeInt(map['age']) ?? 25,
        gender: _safeString(map['gender']) ?? 'Male',
        height: _safeDouble(map['height']) ?? 170.0,
        weight: _safeDouble(map['weight']) ?? 70.0,
        idealWeight: _safeDouble(map['idealWeight']) ?? 65.0,
        dailyGoal: _safeInt(map['dailyGoal']) ?? 2000,
        units: _safeString(map['units']) ?? 'Metric (kg, cm)',
        notificationsEnabled: _safeBool(map['notificationsEnabled']) ?? true,
        createdAt: _safeDateTime(map['createdAt']),
        updatedAt: _safeDateTime(map['updatedAt']),
      );
    } catch (e) {
      debugPrint('Error creating AuthUserModel from map: $e');
      // Return a basic model with minimal safe data
      return AuthUserModel(
        uid: _safeString(map['uid']) ?? '',
        email: _safeString(map['email']) ?? '',
        displayName: _safeString(map['displayName']) ?? 'User',
      );
    }
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'idealWeight': idealWeight,
      'dailyGoal': dailyGoal,
      'units': units,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  /// Create a copy with updated fields
  AuthUserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    int? age,
    String? gender,
    double? height,
    double? weight,
    double? idealWeight,
    int? dailyGoal,
    String? units,
    bool? notificationsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AuthUserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      idealWeight: idealWeight ?? this.idealWeight,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      units: units ?? this.units,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// ✅ Safe type conversion helpers
  static String? _safeString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }
  
  static int? _safeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
  
  static double? _safeDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  static bool? _safeBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }
    if (value is int) return value != 0;
    return null;
  }
  
  static DateTime? _safeDateTime(dynamic value) {
    if (value == null) return null;
    
    try {
      // Handle Firestore Timestamp
      if (value.runtimeType.toString().contains('Timestamp')) {
        final timestamp = value as dynamic;
        return DateTime.fromMillisecondsSinceEpoch(timestamp.seconds * 1000);
      }
      
      // Handle DateTime
      if (value is DateTime) return value;
      
      // Handle String
      if (value is String) return DateTime.tryParse(value);
      
      // Handle int (milliseconds since epoch)
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      
    } catch (e) {
      debugPrint('Error parsing DateTime: $e');
    }
    
    return null;
  }

  @override
  String toString() {
    return 'AuthUserModel{uid: $uid, email: $email, displayName: $displayName}';
  }
}
