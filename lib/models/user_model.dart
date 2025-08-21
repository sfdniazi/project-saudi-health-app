import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
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

  UserModel({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.age = 0,
    this.gender = 'Male',
    this.height = 0.0,
    this.weight = 0.0,
    this.idealWeight = 0.0,
    this.dailyGoal = 2000,
    this.units = 'Metric (kg, cm)',
    this.notificationsEnabled = true,
    this.createdAt,
    this.updatedAt,
  });

  // Convert UserModel to Map for Firestore
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

  // Create UserModel from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      age: map['age']?.toInt() ?? 0,
      gender: map['gender'] ?? 'Male',
      height: map['height']?.toDouble() ?? 0.0,
      weight: map['weight']?.toDouble() ?? 0.0,
      idealWeight: map['idealWeight']?.toDouble() ?? 0.0,
      dailyGoal: map['dailyGoal']?.toInt() ?? 2000,
      units: map['units'] ?? 'Metric (kg, cm)',
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Create UserModel from Firestore DocumentSnapshot
  factory UserModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap({
      'uid': snapshot.id,
      ...data,
    });
  }

  // Calculate BMI
  double get bmi {
    if (height <= 0 || weight <= 0) return 0.0;
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // Get BMI status
  String get bmiStatus {
    final bmiValue = bmi;
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  // Copy with method for updating user data
  UserModel copyWith({
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
    return UserModel(
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
