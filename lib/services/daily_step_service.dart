import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Model for daily step data
class DailyStepData {
  final String id;
  final String userId;
  final DateTime date;
  final int totalSteps;
  final int pedometerSteps;
  final int manualSteps;
  final double distance;
  final double calories;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const DailyStepData({
    required this.id,
    required this.userId,
    required this.date,
    this.totalSteps = 0,
    this.pedometerSteps = 0,
    this.manualSteps = 0,
    this.distance = 0.0,
    this.calories = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'totalSteps': totalSteps,
      'pedometerSteps': pedometerSteps,
      'manualSteps': manualSteps,
      'distance': distance,
      'calories': calories,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  factory DailyStepData.fromMap(Map<String, dynamic> map, String documentId) {
    return DailyStepData(
      id: documentId,
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      totalSteps: map['totalSteps']?.toInt() ?? 0,
      pedometerSteps: map['pedometerSteps']?.toInt() ?? 0,
      manualSteps: map['manualSteps']?.toInt() ?? 0,
      distance: map['distance']?.toDouble() ?? 0.0,
      calories: map['calories']?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  factory DailyStepData.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return DailyStepData.fromMap(data, snapshot.id);
  }

  DailyStepData copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? totalSteps,
    int? pedometerSteps,
    int? manualSteps,
    double? distance,
    double? calories,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return DailyStepData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      totalSteps: totalSteps ?? this.totalSteps,
      pedometerSteps: pedometerSteps ?? this.pedometerSteps,
      manualSteps: manualSteps ?? this.manualSteps,
      distance: distance ?? this.distance,
      calories: calories ?? this.calories,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'DailyStepData(id: $id, date: ${DateFormat('yyyy-MM-dd').format(date)}, total: $totalSteps, pedometer: $pedometerSteps, manual: $manualSteps)';
  }
}

/// Service for managing daily step data in Firebase
class DailyStepService {
  static final DailyStepService _instance = DailyStepService._internal();
  factory DailyStepService() => _instance;
  DailyStepService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'daily_steps';

  /// Gets the document ID for a specific date
  String _getDocumentId(String userId, DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return '${userId}_$dateStr';
  }

  /// Gets the collection reference for daily steps
  CollectionReference get _collectionRef => _firestore.collection(_collection);

  /// Gets daily step data for a specific date
  Future<DailyStepData?> getDailyStepData(String userId, DateTime date) async {
    try {
      developer.log('DailyStepService: Getting daily step data for $userId on ${DateFormat('yyyy-MM-dd').format(date)}', name: 'DailyStepService');
      
      final docId = _getDocumentId(userId, date);
      final doc = await _collectionRef.doc(docId).get();
      
      if (doc.exists) {
        final data = DailyStepData.fromSnapshot(doc);
        developer.log('DailyStepService: Found daily step data: ${data.totalSteps} steps', name: 'DailyStepService');
        return data;
      } else {
        developer.log('DailyStepService: No daily step data found for date', name: 'DailyStepService');
        return null;
      }
    } catch (e) {
      developer.log('DailyStepService: Error getting daily step data: $e', name: 'DailyStepService');
      rethrow;
    }
  }

  /// Creates or updates daily step data
  Future<void> saveDailyStepData(DailyStepData data) async {
    try {
      developer.log('DailyStepService: Saving daily step data: ${data.totalSteps} steps', name: 'DailyStepService');
      
      final docId = _getDocumentId(data.userId, data.date);
      await _collectionRef.doc(docId).set(data.toMap(), SetOptions(merge: true));
      
      developer.log('DailyStepService: Daily step data saved successfully', name: 'DailyStepService');
    } catch (e) {
      developer.log('DailyStepService: Error saving daily step data: $e', name: 'DailyStepService');
      rethrow;
    }
  }

  /// Updates pedometer steps for a specific date
  Future<DailyStepData> updatePedometerSteps(
    String userId,
    DateTime date,
    int pedometerSteps,
    double distance,
    double calories,
  ) async {
    try {
      developer.log('DailyStepService: Updating pedometer steps: $pedometerSteps', name: 'DailyStepService');
      
      final docId = _getDocumentId(userId, date);
      final doc = await _collectionRef.doc(docId).get();
      final now = DateTime.now();
      
      DailyStepData data;
      if (doc.exists) {
        // Update existing data
        final existing = DailyStepData.fromSnapshot(doc);
        data = existing.copyWith(
          pedometerSteps: pedometerSteps,
          totalSteps: pedometerSteps + existing.manualSteps,
          distance: distance,
          calories: calories,
          updatedAt: now,
          metadata: {
            ...existing.metadata,
            'lastPedometerUpdate': now.toIso8601String(),
          },
        );
      } else {
        // Create new data
        data = DailyStepData(
          id: docId,
          userId: userId,
          date: date,
          pedometerSteps: pedometerSteps,
          manualSteps: 0,
          totalSteps: pedometerSteps,
          distance: distance,
          calories: calories,
          createdAt: now,
          updatedAt: now,
          metadata: {
            'source': 'pedometer',
            'createdBy': 'step_counter_service',
            'lastPedometerUpdate': now.toIso8601String(),
          },
        );
      }
      
      await saveDailyStepData(data);
      return data;
    } catch (e) {
      developer.log('DailyStepService: Error updating pedometer steps: $e', name: 'DailyStepService');
      rethrow;
    }
  }

  /// Updates manual steps for a specific date
  Future<DailyStepData> updateManualSteps(
    String userId,
    DateTime date,
    int additionalSteps,
    double distance,
    double calories,
  ) async {
    try {
      developer.log('DailyStepService: Adding manual steps: $additionalSteps', name: 'DailyStepService');
      
      final docId = _getDocumentId(userId, date);
      final doc = await _collectionRef.doc(docId).get();
      final now = DateTime.now();
      
      DailyStepData data;
      if (doc.exists) {
        // Update existing data
        final existing = DailyStepData.fromSnapshot(doc);
        final newManualSteps = existing.manualSteps + additionalSteps;
        data = existing.copyWith(
          manualSteps: newManualSteps,
          totalSteps: existing.pedometerSteps + newManualSteps,
          distance: distance,
          calories: calories,
          updatedAt: now,
          metadata: {
            ...existing.metadata,
            'lastManualUpdate': now.toIso8601String(),
          },
        );
      } else {
        // Create new data
        data = DailyStepData(
          id: docId,
          userId: userId,
          date: date,
          pedometerSteps: 0,
          manualSteps: additionalSteps,
          totalSteps: additionalSteps,
          distance: distance,
          calories: calories,
          createdAt: now,
          updatedAt: now,
          metadata: {
            'source': 'manual',
            'createdBy': 'activity_provider',
            'lastManualUpdate': now.toIso8601String(),
          },
        );
      }
      
      await saveDailyStepData(data);
      return data;
    } catch (e) {
      developer.log('DailyStepService: Error updating manual steps: $e', name: 'DailyStepService');
      rethrow;
    }
  }

  /// Streams daily step data for real-time updates
  Stream<DailyStepData?> streamDailyStepData(String userId, DateTime date) {
    try {
      developer.log('DailyStepService: Setting up stream for daily step data', name: 'DailyStepService');
      
      final docId = _getDocumentId(userId, date);
      return _collectionRef.doc(docId).snapshots().map((doc) {
        if (doc.exists) {
          return DailyStepData.fromSnapshot(doc);
        }
        return null;
      });
    } catch (e) {
      developer.log('DailyStepService: Error setting up daily step data stream: $e', name: 'DailyStepService');
      rethrow;
    }
  }

  /// Gets daily step data for a date range
  Future<List<DailyStepData>> getDailyStepDataRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      developer.log('DailyStepService: Getting daily step data range', name: 'DailyStepService');
      
      final query = await _collectionRef
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();
      
      final results = query.docs.map((doc) => DailyStepData.fromSnapshot(doc)).toList();
      developer.log('DailyStepService: Found ${results.length} daily step records', name: 'DailyStepService');
      
      return results;
    } catch (e) {
      developer.log('DailyStepService: Error getting daily step data range: $e', name: 'DailyStepService');
      rethrow;
    }
  }

  /// Deletes daily step data for a specific date
  Future<void> deleteDailyStepData(String userId, DateTime date) async {
    try {
      developer.log('DailyStepService: Deleting daily step data for date', name: 'DailyStepService');
      
      final docId = _getDocumentId(userId, date);
      await _collectionRef.doc(docId).delete();
      
      developer.log('DailyStepService: Daily step data deleted successfully', name: 'DailyStepService');
    } catch (e) {
      developer.log('DailyStepService: Error deleting daily step data: $e', name: 'DailyStepService');
      rethrow;
    }
  }

  /// Gets the total steps for the current week
  Future<int> getWeeklyStepTotal(String userId, DateTime date) async {
    try {
      final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      final weekData = await getDailyStepDataRange(userId, startOfWeek, endOfWeek);
      final totalSteps = weekData.fold(0, (sum, data) => sum + data.totalSteps);
      
      developer.log('DailyStepService: Weekly step total: $totalSteps', name: 'DailyStepService');
      return totalSteps;
    } catch (e) {
      developer.log('DailyStepService: Error getting weekly step total: $e', name: 'DailyStepService');
      rethrow;
    }
  }

  /// Gets the average steps for the current month
  Future<double> getMonthlyStepAverage(String userId, DateTime date) async {
    try {
      final startOfMonth = DateTime(date.year, date.month, 1);
      final endOfMonth = DateTime(date.year, date.month + 1, 0);
      
      final monthData = await getDailyStepDataRange(userId, startOfMonth, endOfMonth);
      if (monthData.isEmpty) return 0.0;
      
      final totalSteps = monthData.fold(0, (sum, data) => sum + data.totalSteps);
      final average = totalSteps / monthData.length;
      
      developer.log('DailyStepService: Monthly step average: $average', name: 'DailyStepService');
      return average;
    } catch (e) {
      developer.log('DailyStepService: Error getting monthly step average: $e', name: 'DailyStepService');
      rethrow;
    }
  }
}
