import 'package:flutter/foundation.dart';
import '../../../core/pdpl_data_controller.dart';
import '../../../core/audit_logger.dart';

/// ✅ Privacy Provider - State management for PDPL compliance features
class PrivacyProvider with ChangeNotifier {
  // Privacy settings
  Map<String, dynamic> _privacySettings = {};
  Map<String, dynamic> get privacySettings => _privacySettings;

  // Consent records
  List<ConsentRecord> _consentRecords = [];
  List<ConsentRecord> get consentRecords => _consentRecords;

  // Data insights
  DateTime? _accountCreationDate;
  DateTime? get accountCreationDate => _accountCreationDate;

  List<String> _dataCategories = [];
  List<String> get dataCategories => _dataCategories;

  DateTime? _lastPrivacyUpdate;
  DateTime? get lastPrivacyUpdate => _lastPrivacyUpdate;

  // Loading states
  bool _isLoadingSettings = false;
  bool get isLoadingSettings => _isLoadingSettings;

  bool _isLoadingConsent = false;
  bool get isLoadingConsent => _isLoadingConsent;

  bool _isExportingData = false;
  bool get isExportingData => _isExportingData;

  // Error states
  String? _lastError;
  String? get lastError => _lastError;

  /// Load all privacy-related data
  Future<void> loadPrivacyData() async {
    await Future.wait([
      loadPrivacySettings(),
      loadConsentRecords(),
      loadDataInsights(),
    ]);
  }

  /// Load user's privacy settings
  Future<void> loadPrivacySettings() async {
    _isLoadingSettings = true;
    _lastError = null;
    notifyListeners();

    try {
      _privacySettings = await PDPLDataController.getPrivacySettings();
      _lastPrivacyUpdate = DateTime.now();
    } catch (e) {
      _lastError = 'Failed to load privacy settings: $e';
      debugPrint(_lastError);
    } finally {
      _isLoadingSettings = false;
      notifyListeners();
    }
  }

  /// Update privacy settings
  Future<bool> updatePrivacySettings(Map<String, dynamic> newSettings) async {
    try {
      await PDPLDataController.updatePrivacySettings(newSettings);
      _privacySettings = {..._privacySettings, ...newSettings};
      _lastPrivacyUpdate = DateTime.now();
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to update privacy settings: $e';
      debugPrint(_lastError);
      notifyListeners();
      return false;
    }
  }

  /// Load user's consent records
  Future<void> loadConsentRecords() async {
    _isLoadingConsent = true;
    _lastError = null;
    notifyListeners();

    try {
      _consentRecords = await PDPLDataController.getUserConsentHistory();
    } catch (e) {
      _lastError = 'Failed to load consent records: $e';
      debugPrint(_lastError);
    } finally {
      _isLoadingConsent = false;
      notifyListeners();
    }
  }

  /// Record user consent
  Future<bool> recordConsent({
    required DataCategory category,
    required DataProcessingPurpose purpose,
    required bool granted,
    String? legalBasis,
  }) async {
    try {
      await PDPLDataController.recordConsent(
        category: category,
        purpose: purpose,
        granted: granted,
        legalBasis: legalBasis,
      );

      // Reload consent records to reflect changes
      await loadConsentRecords();
      return true;
    } catch (e) {
      _lastError = 'Failed to record consent: $e';
      debugPrint(_lastError);
      notifyListeners();
      return false;
    }
  }

  /// Withdraw user consent
  Future<bool> withdrawConsent({
    required DataCategory category,
    required DataProcessingPurpose purpose,
  }) async {
    try {
      await PDPLDataController.withdrawConsent(
        category: category,
        purpose: purpose,
      );

      // Reload consent records to reflect changes
      await loadConsentRecords();
      return true;
    } catch (e) {
      _lastError = 'Failed to withdraw consent: $e';
      debugPrint(_lastError);
      notifyListeners();
      return false;
    }
  }

  /// Check if user has granted consent for specific data use
  Future<bool> hasConsent({
    required DataCategory category,
    required DataProcessingPurpose purpose,
  }) async {
    try {
      return await PDPLDataController.hasConsent(
        category: category,
        purpose: purpose,
      );
    } catch (e) {
      debugPrint('Error checking consent: $e');
      return false;
    }
  }

  /// Load data insights and statistics
  Future<void> loadDataInsights() async {
    try {
      // Load account creation date from user profile or settings
      // This would be implemented based on your user model
      _accountCreationDate = DateTime.now().subtract(const Duration(days: 90));
      
      // Load data categories that the user has data for
      _dataCategories = [
        'Personal Information',
        'Health Metrics',
        'Activity Data',
        'Nutrition Data',
      ];

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load data insights: $e');
    }
  }

  /// Export user data
  Future<Map<String, dynamic>?> exportUserData() async {
    _isExportingData = true;
    _lastError = null;
    notifyListeners();

    try {
      final exportData = await PDPLDataController.exportUserData();
      return exportData;
    } catch (e) {
      _lastError = 'Failed to export user data: $e';
      debugPrint(_lastError);
      return null;
    } finally {
      _isExportingData = false;
      notifyListeners();
    }
  }

  /// Delete all user data
  Future<bool> deleteAllUserData({bool keepAuditLogs = true}) async {
    try {
      await PDPLDataController.deleteAllUserData(keepAuditLogs: keepAuditLogs);
      return true;
    } catch (e) {
      _lastError = 'Failed to delete user data: $e';
      debugPrint(_lastError);
      notifyListeners();
      return false;
    }
  }

  /// Generate compliance report
  Future<Map<String, dynamic>?> generateComplianceReport() async {
    try {
      return await PDPLDataController.generateComplianceReport();
    } catch (e) {
      _lastError = 'Failed to generate compliance report: $e';
      debugPrint(_lastError);
      notifyListeners();
      return null;
    }
  }

  /// Get audit trail
  Future<Map<String, dynamic>?> getAuditReport({
    DateTime? startDate,
    DateTime? endDate,
    LogCategory? category,
    LogSeverity? minSeverity,
  }) async {
    try {
      return await AuditLogger.generateAuditReport(
        startDate: startDate,
        endDate: endDate,
        category: category,
        minSeverity: minSeverity,
      );
    } catch (e) {
      _lastError = 'Failed to get audit report: $e';
      debugPrint(_lastError);
      notifyListeners();
      return null;
    }
  }

  /// Clear error state
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  /// Get privacy setting value with default
  T getPrivacySetting<T>(String key, T defaultValue) {
    return _privacySettings[key] as T? ?? defaultValue;
  }

  /// Check if processing is lawful for given category and purpose
  Future<bool> isProcessingLawful({
    required DataCategory category,
    required DataProcessingPurpose purpose,
  }) async {
    try {
      return await PDPLDataController.isProcessingLawful(
        category: category,
        purpose: purpose,
      );
    } catch (e) {
      debugPrint('Error checking processing lawfulness: $e');
      return false;
    }
  }

  /// Get current consent status for all categories and purposes
  Map<String, Map<String, bool>> getConsentMatrix() {
    final matrix = <String, Map<String, bool>>{};
    
    for (final category in DataCategory.values) {
      matrix[category.toString()] = {};
      
      for (final purpose in DataProcessingPurpose.values) {
        // Find the most recent consent record for this category/purpose combination
        final relevantRecords = _consentRecords
            .where((record) => 
                record.category == category && 
                record.purpose == purpose &&
                !record.isWithdrawn)
            .toList();
        
        if (relevantRecords.isNotEmpty) {
          // Sort by timestamp and get the most recent
          relevantRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          matrix[category.toString()]![purpose.toString()] = relevantRecords.first.granted;
        } else {
          matrix[category.toString()]![purpose.toString()] = false;
        }
      }
    }
    
    return matrix;
  }

  /// Get privacy score based on settings and consents
  double getPrivacyScore() {
    int totalScore = 0;
    int maxScore = 0;

    // Score based on privacy settings
    final privacySettings = [
      'allowAnalytics',
      'allowPersonalization', 
      'allowMarketingCommunications',
      'shareAnonymizedData',
    ];

    for (final setting in privacySettings) {
      maxScore += 10;
      if (!getPrivacySetting<bool>(setting, true)) {
        totalScore += 10; // Higher score for more private settings
      }
    }

    // Score based on consent granularity
    final consentMatrix = getConsentMatrix();
    int consentCount = 0;
    int grantedConsents = 0;

    for (final category in consentMatrix.values) {
      for (final granted in category.values) {
        consentCount++;
        if (granted) grantedConsents++;
      }
    }

    if (consentCount > 0) {
      maxScore += 50;
      // Score inversely to granted consents (more privacy = higher score)
      totalScore += ((consentCount - grantedConsents) / consentCount * 50).round();
    }

    return maxScore > 0 ? (totalScore / maxScore * 100) : 0.0;
  }
}
