import 'package:cloud_firestore/cloud_firestore.dart';

class HydrationModel {
  final String id;
  final String userId;
  final DateTime date;
  final double waterIntake; // in liters
  final double goalAmount; // in liters
  final List<WaterEntry> entries;
  final DateTime createdAt;
  final DateTime updatedAt;

  HydrationModel({
    required this.id,
    required this.userId,
    required this.date,
    this.waterIntake = 0.0,
    this.goalAmount = 2.5, // Default 2.5L per day
    this.entries = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'waterIntake': waterIntake,
      'goalAmount': goalAmount,
      'entries': entries.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory HydrationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return HydrationModel(
      id: documentId,
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      waterIntake: map['waterIntake']?.toDouble() ?? 0.0,
      goalAmount: map['goalAmount']?.toDouble() ?? 2.5,
      entries: (map['entries'] as List<dynamic>?)
          ?.map((e) => WaterEntry.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory HydrationModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return HydrationModel.fromMap(data, snapshot.id);
  }

  HydrationModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? waterIntake,
    double? goalAmount,
    List<WaterEntry>? entries,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HydrationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      waterIntake: waterIntake ?? this.waterIntake,
      goalAmount: goalAmount ?? this.goalAmount,
      entries: entries ?? this.entries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calculate progress percentage
  double get progressPercentage {
    if (goalAmount <= 0) return 0.0;
    return (waterIntake / goalAmount * 100).clamp(0.0, 100.0);
  }

  // Check if goal is reached
  bool get isGoalReached => waterIntake >= goalAmount;

  // Get remaining amount to reach goal
  double get remainingAmount => (goalAmount - waterIntake).clamp(0.0, double.infinity);
}

class WaterEntry {
  final double amount; // in liters
  final DateTime timestamp;
  final String? note;

  WaterEntry({
    required this.amount,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
    };
  }

  factory WaterEntry.fromMap(Map<String, dynamic> map) {
    return WaterEntry(
      amount: map['amount']?.toDouble() ?? 0.0,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      note: map['note'],
    );
  }

  WaterEntry copyWith({
    double? amount,
    DateTime? timestamp,
    String? note,
  }) {
    return WaterEntry(
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
    );
  }
}
