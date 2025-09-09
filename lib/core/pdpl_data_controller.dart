import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';

import '../services/firebase_service.dart';
import 'audit_logger.dart';

/// Data processing purposes for granular consent
enum DataProcessingPurpose {
  essential, // Required for app functionality
  analytics, // Usage analytics and improvements
  personalization, // Personalized recommendations
  marketing, // Marketing communications
  research, // Anonymized research purposes
}

/// Data categories for consent management
enum DataCategory {
  personalInfo, // Name, email, age, gender
  healthMetrics, // Height, weight, BMI
  activityData, // Steps, exercise, calories
  nutritionData, // Food logs, dietary preferences
  locationData, // GPS for activity tracking
  deviceData, // Device information, app usage
}

/// Consent record structure
class ConsentRecord {
  final String userId;
  final DataCategory category;
  final DataProcessingPurpose purpose;
  final bool granted;
  final DateTime timestamp;
  final String? legalBasis;
  final bool isWithdrawn;
  final DateTime? withdrawnAt;

  const ConsentRecord({
    required this.userId,
    required this.category,
    required this.purpose,
    required this.granted,
    required this.timestamp,
    this.legalBasis,
    this.isWithdrawn = false,
    this.withdrawnAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category.toString(),
      'purpose': purpose.toString(),
      'granted': granted,
      'timestamp': Timestamp.fromDate(timestamp),
      'legalBasis': legalBasis,
      'isWithdrawn': isWithdrawn,
      'withdrawnAt': withdrawnAt != null ? Timestamp.fromDate(withdrawnAt!) : null,
    };
  }

  factory ConsentRecord.fromMap(Map<String, dynamic> map) {
    return ConsentRecord(
      userId: map['userId'] ?? '',
      category: DataCategory.values.firstWhere(
        (e) => e.toString() == map['category'],
        orElse: () => DataCategory.personalInfo,
      ),
      purpose: DataProcessingPurpose.values.firstWhere(
        (e) => e.toString() == map['purpose'],
        orElse: () => DataProcessingPurpose.essential,
      ),
      granted: map['granted'] ?? false,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      legalBasis: map['legalBasis'],
      isWithdrawn: map['isWithdrawn'] ?? false,
      withdrawnAt: map['withdrawnAt'] != null 
          ? (map['withdrawnAt'] as Timestamp).toDate() 
          : null,
    );
  }
}

/// ✅ PDPL Data Controller - Comprehensive data protection management
class PDPLDataController {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _consentDataKey = 'pdpl_consent_data';
  static const String _dataRetentionKey = 'pdpl_retention_settings';
  
  // Data retention periods (in days)
  static const Map<String, int> _defaultRetentionPeriods = {
    'personal_profile': 2555, // 7 years
    'health_activity': 1095,  // 3 years
    'nutrition_logs': 1095,   // 3 years
    'scan_history': 365,      // 1 year
    'recommendations': 365,   // 1 year
    'audit_logs': 2555,       // 7 years (compliance requirement)
  };

  /// Get current user ID with validation
  static String? get currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      AuditLogger.logSecurityEvent(
        'UNAUTHORIZED_ACCESS_ATTEMPT',
        {'reason': 'No authenticated user for data operation'},
      );
      return null;
    }
    return user.uid;
  }

  /// ========== CONSENT MANAGEMENT ==========

  /// Record user consent for specific data category and purpose
  static Future<void> recordConsent({
    required DataCategory category,
    required DataProcessingPurpose purpose,
    required bool granted,
    String? legalBasis,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final consent = ConsentRecord(
        userId: userId,
        category: category,
        purpose: purpose,
        granted: granted,
        timestamp: DateTime.now(),
        legalBasis: legalBasis ?? 'Consent',
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('consent_records')
          .add(consent.toMap());

      await AuditLogger.logDataEvent(
        userId,
        'CONSENT_RECORDED',
        {
          'category': category.toString(),
          'purpose': purpose.toString(),
          'granted': granted,
          'legalBasis': legalBasis,
        },
      );
    } catch (e) {
      throw Exception('Failed to record consent: $e');
    }
  }

  /// Check if user has granted consent for specific data use
  static Future<bool> hasConsent({
    required DataCategory category,
    required DataProcessingPurpose purpose,
  }) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('consent_records')
          .where('category', isEqualTo: category.toString())
          .where('purpose', isEqualTo: purpose.toString())
          .where('isWithdrawn', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return false;
      
      final consent = ConsentRecord.fromMap(query.docs.first.data());
      return consent.granted;
    } catch (e) {
      debugPrint('Error checking consent: $e');
      return false;
    }
  }

  /// Withdraw consent for specific data use
  static Future<void> withdrawConsent({
    required DataCategory category,
    required DataProcessingPurpose purpose,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('consent_records')
          .where('category', isEqualTo: category.toString())
          .where('purpose', isEqualTo: purpose.toString())
          .where('isWithdrawn', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'isWithdrawn': true,
          'withdrawnAt': FieldValue.serverTimestamp(),
        });

        await AuditLogger.logDataEvent(
          userId,
          'CONSENT_WITHDRAWN',
          {
            'category': category.toString(),
            'purpose': purpose.toString(),
          },
        );
      }
    } catch (e) {
      throw Exception('Failed to withdraw consent: $e');
    }
  }

  /// Get all consent records for user
  static Future<List<ConsentRecord>> getUserConsentHistory() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('consent_records')
          .orderBy('timestamp', descending: true)
          .get();

      return query.docs
          .map((doc) => ConsentRecord.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get consent history: $e');
    }
  }

  /// ========== DATA SUBJECT RIGHTS ==========

  /// Export all user data (Right to Data Portability)
  static Future<Map<String, dynamic>> exportUserData() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      await AuditLogger.logDataEvent(
        userId,
        'DATA_EXPORT_REQUESTED',
        {'requestTime': DateTime.now().toIso8601String()},
      );

      final exportData = <String, dynamic>{
        'exportMetadata': {
          'userId': userId,
          'exportDate': DateTime.now().toIso8601String(),
          'version': '1.0',
          'format': 'JSON',
        }
      };

      // Export user profile
      final userProfile = await FirebaseService.getUserProfile(userId);
      if (userProfile != null) {
        exportData['userProfile'] = _anonymizeForExport(userProfile.toMap());
      }

      // Export activity data (last 3 years)
      final activityData = await _exportActivityData(userId);
      exportData['activityData'] = activityData;

      // Export nutrition data
      final nutritionData = await _exportNutritionData(userId);
      exportData['nutritionData'] = nutritionData;

      // Export hydration data
      final hydrationData = await _exportHydrationData(userId);
      exportData['hydrationData'] = hydrationData;

      // Export consent records
      final consentRecords = await getUserConsentHistory();
      exportData['consentHistory'] = consentRecords.map((c) => c.toMap()).toList();

      await AuditLogger.logDataEvent(
        userId,
        'DATA_EXPORT_COMPLETED',
        {'dataSize': json.encode(exportData).length},
      );

      return exportData;
    } catch (e) {
      await AuditLogger.logDataEvent(
        userId ?? 'unknown',
        'DATA_EXPORT_FAILED',
        {'error': e.toString()},
      );
      throw Exception('Failed to export user data: $e');
    }
  }

  /// Delete all user data (Right to Erasure)
  static Future<void> deleteAllUserData({bool keepAuditLogs = true}) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      await AuditLogger.logDataEvent(
        userId,
        'DATA_DELETION_REQUESTED',
        {'keepAuditLogs': keepAuditLogs},
      );

      final batch = _firestore.batch();

      // Delete user profile
      batch.delete(_firestore.collection('users').doc(userId));

      // Delete subcollections
      final subCollections = [
        'activity',
        'hydration',
        'food_logs',
        'recommendations',
        'scanHistory',
        'consent_records',
      ];

      for (final collection in subCollections) {
        final docs = await _firestore
            .collection('users')
            .doc(userId)
            .collection(collection)
            .get();
        
        for (final doc in docs.docs) {
          batch.delete(doc.reference);
        }
      }

      // Optionally preserve audit logs for compliance
      if (!keepAuditLogs) {
        final auditDocs = await _firestore
            .collection('users')
            .doc(userId)
            .collection('audit_logs')
            .get();
        
        for (final doc in auditDocs.docs) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();

      // Delete Firebase Auth account
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }

      await AuditLogger.logDataEvent(
        userId,
        'DATA_DELETION_COMPLETED',
        {'totalCollections': subCollections.length},
      );

    } catch (e) {
      await AuditLogger.logDataEvent(
        userId ?? 'unknown',
        'DATA_DELETION_FAILED',
        {'error': e.toString()},
      );
      throw Exception('Failed to delete user data: $e');
    }
  }

  /// ========== DATA ANONYMIZATION ==========

  /// Anonymize sensitive data for export
  static Map<String, dynamic> _anonymizeForExport(Map<String, dynamic> data) {
    final anonymized = Map<String, dynamic>.from(data);
    
    // Hash email for privacy
    if (anonymized['email'] != null) {
      anonymized['email_hash'] = _hashValue(anonymized['email']);
      anonymized.remove('email');
    }
    
    // Keep only aggregated health metrics
    anonymized['profile_created'] = anonymized['createdAt'];
    anonymized.remove('createdAt');
    anonymized.remove('updatedAt');
    
    return anonymized;
  }

  /// Create hash for sensitive values
  static String _hashValue(String value) {
    final bytes = utf8.encode(value);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // Truncate for privacy
  }

  /// ========== DATA EXPORT HELPERS ==========

  static Future<List<Map<String, dynamic>>> _exportActivityData(String userId) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 1095)); // 3 years
      
      final activities = await FirebaseService.getActivityRange(userId, startDate, endDate);
      return activities.map((a) => _anonymizeActivityData(a.toMap())).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _exportNutritionData(String userId) async {
    try {
      // Implementation would get nutrition data for export
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _exportHydrationData(String userId) async {
    try {
      // Implementation would get hydration data for export
      return [];
    } catch (e) {
      return [];
    }
  }

  static Map<String, dynamic> _anonymizeActivityData(Map<String, dynamic> data) {
    final anonymized = Map<String, dynamic>.from(data);
    anonymized.remove('userId'); // Remove direct user identifier
    return anonymized;
  }

  /// ========== DATA RETENTION ==========

  /// Clean up expired data based on retention policies
  static Future<void> enforceDataRetention() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await AuditLogger.logDataEvent(
        userId,
        'DATA_RETENTION_CLEANUP_START',
        {'policies': _defaultRetentionPeriods},
      );

      int totalDeleted = 0;

      // Clean up scan history (1 year retention)
      totalDeleted += await _cleanupCollection(
        userId,
        'scanHistory',
        _defaultRetentionPeriods['scan_history']!,
      );

      // Clean up old recommendations (1 year retention)
      totalDeleted += await _cleanupCollection(
        userId,
        'recommendations',
        _defaultRetentionPeriods['recommendations']!,
      );

      await AuditLogger.logDataEvent(
        userId,
        'DATA_RETENTION_CLEANUP_COMPLETED',
        {'itemsDeleted': totalDeleted},
      );

    } catch (e) {
      await AuditLogger.logDataEvent(
        userId,
        'DATA_RETENTION_CLEANUP_FAILED',
        {'error': e.toString()},
      );
    }
  }

  static Future<int> _cleanupCollection(String userId, String collection, int retentionDays) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection(collection)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return query.docs.length;
    } catch (e) {
      debugPrint('Failed to cleanup $collection: $e');
      return 0;
    }
  }

  /// ========== PRIVACY SETTINGS ==========

  /// Get user's current privacy settings
  static Future<Map<String, dynamic>> getPrivacySettings() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('privacy')
          .get();

      if (doc.exists) {
        return doc.data() ?? {};
      }

      // Return default privacy settings
      return {
        'dataRetentionPeriod': 1095, // 3 years default
        'allowAnalytics': false,
        'allowPersonalization': true,
        'allowMarketingCommunications': false,
        'shareAnonymizedData': false,
        'autoDeleteInactive': true,
        'inactivityPeriod': 730, // 2 years
      };
    } catch (e) {
      throw Exception('Failed to get privacy settings: $e');
    }
  }

  /// Update user's privacy settings
  static Future<void> updatePrivacySettings(Map<String, dynamic> settings) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('privacy')
          .set({
        ...settings,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await AuditLogger.logDataEvent(
        userId,
        'PRIVACY_SETTINGS_UPDATED',
        {'settings': settings.keys.toList()},
      );
    } catch (e) {
      throw Exception('Failed to update privacy settings: $e');
    }
  }

  /// ========== COMPLIANCE HELPERS ==========

  /// Validate if data processing is lawful
  static Future<bool> isProcessingLawful({
    required DataCategory category,
    required DataProcessingPurpose purpose,
  }) async {
    // Essential processing is always lawful
    if (purpose == DataProcessingPurpose.essential) {
      return true;
    }

    // Check if user has given consent
    return await hasConsent(category: category, purpose: purpose);
  }

  /// Generate compliance report
  static Future<Map<String, dynamic>> generateComplianceReport() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final consentRecords = await getUserConsentHistory();
      final privacySettings = await getPrivacySettings();
      
      return {
        'userId': _hashValue(userId), // Anonymized user ID
        'reportDate': DateTime.now().toIso8601String(),
        'totalConsentRecords': consentRecords.length,
        'activeConsents': consentRecords.where((c) => c.granted && !c.isWithdrawn).length,
        'withdrawnConsents': consentRecords.where((c) => c.isWithdrawn).length,
        'privacySettings': privacySettings,
        'dataRetentionCompliance': _defaultRetentionPeriods,
      };
    } catch (e) {
      throw Exception('Failed to generate compliance report: $e');
    }
  }
}
