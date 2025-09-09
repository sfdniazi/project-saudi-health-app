import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';

/// Audit log severity levels
enum LogSeverity {
  info,    // Normal operations
  warning, // Potential issues
  error,   // Error conditions
  critical // Security incidents, compliance violations
}

/// Audit log categories
enum LogCategory {
  dataAccess,     // Data read operations
  dataModification, // Data write/update/delete operations
  authentication, // Login, logout, password changes
  authorization,  // Permission checks, access denials
  consent,        // Consent changes and privacy decisions
  security,       // Security events and violations
  compliance,     // PDPL compliance events
  system,         // System operations and maintenance
}

/// Audit log entry structure
class AuditLogEntry {
  final String id;
  final String? userId; // Can be null for system events
  final LogCategory category;
  final LogSeverity severity;
  final String event;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final String? sessionId;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceFingerprint;

  const AuditLogEntry({
    required this.id,
    this.userId,
    required this.category,
    required this.severity,
    required this.event,
    required this.metadata,
    required this.timestamp,
    this.sessionId,
    this.ipAddress,
    this.userAgent,
    this.deviceFingerprint,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId != null ? AuditLogger._hashUserId(userId!) : null,
      'category': category.toString(),
      'severity': severity.toString(),
      'event': event,
      'metadata': AuditLogger._sanitizeMetadata(metadata),
      'timestamp': Timestamp.fromDate(timestamp),
      'sessionId': sessionId,
      'ipAddress': ipAddress != null ? AuditLogger._hashValue(ipAddress!) : null,
      'userAgent': userAgent,
      'deviceFingerprint': deviceFingerprint,
    };
  }

  factory AuditLogEntry.fromMap(Map<String, dynamic> map, String documentId) {
    return AuditLogEntry(
      id: documentId,
      userId: map['userId'],
      category: LogCategory.values.firstWhere(
        (e) => e.toString() == map['category'],
        orElse: () => LogCategory.system,
      ),
      severity: LogSeverity.values.firstWhere(
        (e) => e.toString() == map['severity'],
        orElse: () => LogSeverity.info,
      ),
      event: map['event'] ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      sessionId: map['sessionId'],
      ipAddress: map['ipAddress'],
      userAgent: map['userAgent'],
      deviceFingerprint: map['deviceFingerprint'],
    );
  }
}

/// ✅ Audit Logger - Comprehensive logging system for PDPL compliance
class AuditLogger {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Log retention periods (in days)
  static const int _auditLogRetentionDays = 2555; // 7 years for compliance
  static const int _securityLogRetentionDays = 1095; // 3 years for security events

  /// Hash user ID for privacy protection in logs
  static String _hashUserId(String userId) {
    final bytes = utf8.encode(userId);
    final digest = sha256.convert(bytes);
    return 'user_${digest.toString().substring(0, 12)}';
  }

  /// Hash sensitive values in logs
  static String _hashValue(String value) {
    final bytes = utf8.encode(value);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Sanitize metadata to remove sensitive information
  static Map<String, dynamic> _sanitizeMetadata(Map<String, dynamic> metadata) {
    final sanitized = Map<String, dynamic>.from(metadata);
    
    // Remove or hash sensitive fields
    final sensitiveKeys = ['email', 'phone', 'address', 'ssn', 'creditCard', 'password'];
    for (final key in sensitiveKeys) {
      if (sanitized.containsKey(key) && sanitized[key] != null) {
        sanitized['${key}_hash'] = _hashValue(sanitized[key].toString());
        sanitized.remove(key);
      }
    }
    
    return sanitized;
  }

  /// Generate unique session ID
  static String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return _hashValue('session_${timestamp}_$random');
  }

  /// Get current session information
  static Map<String, String?> _getCurrentSession() {
    return {
      'sessionId': _generateSessionId(),
      'deviceFingerprint': _generateDeviceFingerprint(),
      'userAgent': _getUserAgent(),
    };
  }

  /// Generate device fingerprint for tracking
  static String _generateDeviceFingerprint() {
    final deviceInfo = {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
    };
    
    return _hashValue(deviceInfo.toString());
  }

  /// Get user agent information
  static String _getUserAgent() {
    return 'NabdAlHayah/1.0.0 (${Platform.operatingSystem})';
  }

  /// ========== PUBLIC LOGGING METHODS ==========

  /// Log data access events
  static Future<void> logDataEvent(
    String userId,
    String event,
    Map<String, dynamic> metadata, {
    LogSeverity severity = LogSeverity.info,
  }) async {
    await _logEvent(
      userId: userId,
      category: LogCategory.dataAccess,
      severity: severity,
      event: event,
      metadata: metadata,
    );
  }

  /// Log authentication events
  static Future<void> logAuthEvent(
    String event,
    Map<String, dynamic> metadata, {
    String? userId,
    LogSeverity severity = LogSeverity.info,
  }) async {
    await _logEvent(
      userId: userId,
      category: LogCategory.authentication,
      severity: severity,
      event: event,
      metadata: metadata,
    );
  }

  /// Log consent and privacy events
  static Future<void> logConsentEvent(
    String userId,
    String event,
    Map<String, dynamic> metadata,
  ) async {
    await _logEvent(
      userId: userId,
      category: LogCategory.consent,
      severity: LogSeverity.info,
      event: event,
      metadata: metadata,
    );
  }

  /// Log security events
  static Future<void> logSecurityEvent(
    String event,
    Map<String, dynamic> metadata, {
    String? userId,
    LogSeverity severity = LogSeverity.warning,
  }) async {
    await _logEvent(
      userId: userId,
      category: LogCategory.security,
      severity: severity,
      event: event,
      metadata: metadata,
    );
    
    // Alert on critical security events
    if (severity == LogSeverity.critical) {
      await _triggerSecurityAlert(event, metadata);
    }
  }

  /// Log compliance events
  static Future<void> logComplianceEvent(
    String userId,
    String event,
    Map<String, dynamic> metadata, {
    LogSeverity severity = LogSeverity.info,
  }) async {
    await _logEvent(
      userId: userId,
      category: LogCategory.compliance,
      severity: severity,
      event: event,
      metadata: metadata,
    );
  }

  /// Log system events
  static Future<void> logSystemEvent(
    String event,
    Map<String, dynamic> metadata, {
    LogSeverity severity = LogSeverity.info,
  }) async {
    await _logEvent(
      category: LogCategory.system,
      severity: severity,
      event: event,
      metadata: metadata,
    );
  }

  /// ========== INTERNAL LOGGING METHODS ==========

  /// Core logging method
  static Future<void> _logEvent({
    String? userId,
    required LogCategory category,
    required LogSeverity severity,
    required String event,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final sessionInfo = _getCurrentSession();
      final logId = _generateLogId();
      
      final logEntry = AuditLogEntry(
        id: logId,
        userId: userId,
        category: category,
        severity: severity,
        event: event,
        metadata: metadata,
        timestamp: DateTime.now(),
        sessionId: sessionInfo['sessionId'],
        deviceFingerprint: sessionInfo['deviceFingerprint'],
        userAgent: sessionInfo['userAgent'],
      );

      // Store in Firestore with automatic sharding by date
      final dateKey = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
      await _firestore
          .collection('audit_logs')
          .doc(dateKey)
          .collection('entries')
          .doc(logId)
          .set(logEntry.toMap());

      // Also store user-specific logs for easier access control
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('audit_logs')
            .doc(logId)
            .set(logEntry.toMap());
      }

      // Debug logging in development
      if (kDebugMode) {
        debugPrint('🔍 AUDIT: $event (${category.toString()}) - $metadata');
      }

    } catch (e) {
      // Failsafe: Never let audit logging break the app
      debugPrint('❌ Audit logging failed: $e');
    }
  }

  /// Generate unique log ID
  static String _generateLogId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'log_${timestamp}_$random';
  }

  /// ========== SECURITY ALERTING ==========

  /// Trigger security alerts for critical events
  static Future<void> _triggerSecurityAlert(
    String event,
    Map<String, dynamic> metadata,
  ) async {
    try {
      // Store critical security alert
      await _firestore
          .collection('security_alerts')
          .add({
        'event': event,
        'metadata': _sanitizeMetadata(metadata),
        'timestamp': FieldValue.serverTimestamp(),
        'severity': 'CRITICAL',
        'acknowledged': false,
      });

      // In production, this would also:
      // - Send notifications to administrators
      // - Trigger automated response procedures
      // - Update threat intelligence systems

    } catch (e) {
      debugPrint('❌ Security alert failed: $e');
    }
  }

  /// ========== COMPLIANCE REPORTING ==========

  /// Generate audit trail report for compliance
  static Future<Map<String, dynamic>> generateAuditReport({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    LogCategory? category,
    LogSeverity? minSeverity,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      Query query = _firestore.collectionGroup('audit_logs');

      // Apply filters
      if (userId != null) {
        query = query.where('userId', isEqualTo: _hashUserId(userId));
      }
      
      if (category != null) {
        query = query.where('category', isEqualTo: category.toString());
      }

      query = query
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true);

      final querySnapshot = await query.limit(10000).get();
      
      final logs = querySnapshot.docs
          .map((doc) => AuditLogEntry.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((log) => minSeverity == null || _severityValue(log.severity) >= _severityValue(minSeverity))
          .toList();

      // Generate summary statistics
      final categoryStats = <String, int>{};
      final severityStats = <String, int>{};
      final eventStats = <String, int>{};

      for (final log in logs) {
        categoryStats[log.category.toString()] = 
            (categoryStats[log.category.toString()] ?? 0) + 1;
        severityStats[log.severity.toString()] = 
            (severityStats[log.severity.toString()] ?? 0) + 1;
        eventStats[log.event] = (eventStats[log.event] ?? 0) + 1;
      }

      return {
        'reportMetadata': {
          'generatedAt': DateTime.now().toIso8601String(),
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'userId': userId != null ? _hashUserId(userId) : null,
          'category': category?.toString(),
          'minSeverity': minSeverity?.toString(),
        },
        'summary': {
          'totalEvents': logs.length,
          'categoryBreakdown': categoryStats,
          'severityBreakdown': severityStats,
          'topEvents': eventStats.entries
              .toList()
              ..sort((a, b) => b.value.compareTo(a.value))
              ..take(10)
              ..map((e) => {'event': e.key, 'count': e.value})
              ..toList(),
        },
        'events': logs.take(1000).map((l) => l.toMap()).toList(), // Limit for performance
      };
    } catch (e) {
      throw Exception('Failed to generate audit report: $e');
    }
  }

  /// Get numeric value for severity comparison
  static int _severityValue(LogSeverity severity) {
    switch (severity) {
      case LogSeverity.info:
        return 1;
      case LogSeverity.warning:
        return 2;
      case LogSeverity.error:
        return 3;
      case LogSeverity.critical:
        return 4;
    }
  }

  /// ========== DATA RETENTION ==========

  /// Clean up old audit logs based on retention policy
  static Future<void> cleanupOldLogs() async {
    try {
      await logSystemEvent('AUDIT_LOG_CLEANUP_START', {
        'auditRetentionDays': _auditLogRetentionDays,
        'securityRetentionDays': _securityLogRetentionDays,
      });

      final now = DateTime.now();
      int totalDeleted = 0;

      // Clean up regular audit logs
      final auditCutoffDate = now.subtract(Duration(days: _auditLogRetentionDays));
      totalDeleted += await _cleanupLogsByDate(auditCutoffDate, 'audit_logs');

      // Clean up security alerts (keep longer)
      final securityCutoffDate = now.subtract(Duration(days: _securityLogRetentionDays));
      totalDeleted += await _cleanupLogsByDate(securityCutoffDate, 'security_alerts');

      await logSystemEvent('AUDIT_LOG_CLEANUP_COMPLETED', {
        'totalLogsDeleted': totalDeleted,
      });

    } catch (e) {
      await logSystemEvent('AUDIT_LOG_CLEANUP_FAILED', {
        'error': e.toString(),
      }, severity: LogSeverity.error);
    }
  }

  /// Clean up logs by date
  static Future<int> _cleanupLogsByDate(DateTime cutoffDate, String collection) async {
    try {
      final query = await _firestore
          .collection(collection)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(500) // Process in batches
          .get();

      if (query.docs.isEmpty) return 0;

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

  /// ========== MONITORING HELPERS ==========

  /// Get recent security events
  static Future<List<AuditLogEntry>> getRecentSecurityEvents({
    int limit = 100,
  }) async {
    try {
      final query = await _firestore
          .collectionGroup('audit_logs')
          .where('category', isEqualTo: LogCategory.security.toString())
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => AuditLogEntry.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Failed to get security events: $e');
      return [];
    }
  }

  /// Check for suspicious activity patterns
  static Future<List<Map<String, dynamic>>> detectSuspiciousActivity() async {
    try {
      final suspiciousPatterns = <Map<String, dynamic>>[];
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));

      // Check for multiple failed login attempts
      final failedLogins = await _firestore
          .collectionGroup('audit_logs')
          .where('category', isEqualTo: LogCategory.authentication.toString())
          .where('event', isEqualTo: 'LOGIN_FAILED')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .get();

      if (failedLogins.docs.length > 10) {
        suspiciousPatterns.add({
          'type': 'MULTIPLE_FAILED_LOGINS',
          'count': failedLogins.docs.length,
          'severity': 'HIGH',
          'timeWindow': '24h',
        });
      }

      // Check for unusual data access patterns
      final dataAccess = await _firestore
          .collectionGroup('audit_logs')
          .where('category', isEqualTo: LogCategory.dataAccess.toString())
          .where('timestamp', isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .get();

      if (dataAccess.docs.length > 1000) {
        suspiciousPatterns.add({
          'type': 'EXCESSIVE_DATA_ACCESS',
          'count': dataAccess.docs.length,
          'severity': 'MEDIUM',
          'timeWindow': '24h',
        });
      }

      return suspiciousPatterns;
    } catch (e) {
      debugPrint('Failed to detect suspicious activity: $e');
      return [];
    }
  }

  /// ========== COMPLIANCE VALIDATION ==========

  /// Validate audit trail integrity
  static Future<bool> validateAuditIntegrity() async {
    try {
      // This would implement cryptographic validation of audit logs
      // to ensure they haven't been tampered with
      
      // For now, just check basic consistency
      final recentLogs = await _firestore
          .collectionGroup('audit_logs')
          .where('timestamp', isGreaterThan: 
              Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))))
          .get();

      // Validate log structure and required fields
      for (final doc in recentLogs.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (!_validateLogStructure(data)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Audit integrity validation failed: $e');
      return false;
    }
  }

  /// Validate individual log entry structure
  static bool _validateLogStructure(Map<String, dynamic> logData) {
    final requiredFields = ['category', 'severity', 'event', 'timestamp'];
    
    for (final field in requiredFields) {
      if (!logData.containsKey(field) || logData[field] == null) {
        return false;
      }
    }
    
    return true;
  }
}
