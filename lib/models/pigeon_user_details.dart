import 'package:cloud_firestore/cloud_firestore.dart';

class PigeonUserDetails {
  final String uid;
  final String email;
  final String displayName;
  final int age;
  final String gender;
  final double height; // in cm
  final double weight; // in kg
  final double idealWeight; // in kg
  final int dailyGoal; // in kcal
  final String units; // 'Metric (kg, cm)' or 'Imperial (lb, in)'
  final bool notificationsEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PigeonUserDetails({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.age = 0,
    this.gender = 'Male',
    this.height = 0.0,
    this.weight = 0.0,
    this.idealWeight = 0.0,
    this.dailyGoal = 0,
    this.units = 'Metric (kg, cm)',
    this.notificationsEnabled = true,
    this.createdAt,
    this.updatedAt,
  });

  // Convert PigeonUserDetails to Map for Firestore
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
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  // Create PigeonUserDetails from Firestore Map
  factory PigeonUserDetails.fromMap(Map<String, dynamic> map) {
    try {
      return PigeonUserDetails(
        uid: map['uid']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        displayName: map['displayName']?.toString() ?? '',
        age: _safeToInt(map['age']) ?? 0,
        gender: map['gender']?.toString() ?? 'Male',
        height: _safeToDouble(map['height']) ?? 0.0,
        weight: _safeToDouble(map['weight']) ?? 0.0,
        idealWeight: _safeToDouble(map['idealWeight']) ?? 0.0,
        dailyGoal: _safeToInt(map['dailyGoal']) ?? 0,
        units: map['units']?.toString() ?? 'Metric (kg, cm)',
        notificationsEnabled: _safeToBool(map['notificationsEnabled']) ?? true,
        createdAt: _safeToDateTime(map['createdAt']),
        updatedAt: _safeToDateTime(map['updatedAt']),
      );
    } catch (e) {
      throw FormatException('Error creating PigeonUserDetails from map: $e');
    }
  }
  
  // Helper methods for safe type conversion
  static int? _safeToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
  
  static double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  static bool? _safeToBool(dynamic value) {
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
  
  static DateTime? _safeToDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // Create PigeonUserDetails from Firestore DocumentSnapshot
  factory PigeonUserDetails.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    return PigeonUserDetails.fromMap({
      'uid': snapshot.id,
      ...data,
    });
  }

  // Copy with method for updating user data
  PigeonUserDetails copyWith({
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
    return PigeonUserDetails(
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
}
