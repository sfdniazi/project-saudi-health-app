import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String id;
  final String userId;
  final DateTime date;
  final int steps;
  final double distance; // in km
  final double calories;
  final int activeMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ActivityModel({
    required this.id,
    required this.userId,
    required this.date,
    this.steps = 0,
    this.distance = 0.0,
    this.calories = 0.0,
    this.activeMinutes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'steps': steps,
      'distance': distance,
      'calories': calories,
      'activeMinutes': activeMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ActivityModel(
      id: documentId,
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      steps: map['steps']?.toInt() ?? 0,
      distance: map['distance']?.toDouble() ?? 0.0,
      calories: map['calories']?.toDouble() ?? 0.0,
      activeMinutes: map['activeMinutes']?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory ActivityModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ActivityModel.fromMap(data, snapshot.id);
  }

  ActivityModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? steps,
    double? distance,
    double? calories,
    int? activeMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      distance: distance ?? this.distance,
      calories: calories ?? this.calories,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calculate calories from steps (rough estimation)
  static double estimateCalories(int steps, double weightKg) {
    // Rough estimation: 0.04 calories per step per kg of body weight
    return (steps * weightKg * 0.04).roundToDouble();
  }

  // Calculate distance from steps (rough estimation)
  static double estimateDistance(int steps) {
    // Average step length is about 0.762 meters
    return (steps * 0.762) / 1000; // Convert to kilometers
  }
}
