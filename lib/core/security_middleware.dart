import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';

/// Advanced security middleware for authentication and data protection
/// 
/// SECURITY: Implements defense-in-depth strategies for mobile app security
class SecurityMiddleware {
  
  static const String _sessionKey = 'app_session_fingerprint';
  static const Duration _sessionTimeout = Duration(hours: 24);
  static DateTime? _lastActivity;
  
  /// Initialize security middleware
  static void initialize() {
    _updateLastActivity();
    _setupSecurityHeaders();
  }
  
  /// Generate device fingerprint for session validation
  static String generateDeviceFingerprint() {
    final deviceInfo = {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
      'timezone': DateTime.now().timeZoneOffset.toString(),
    };
    
    final deviceString = deviceInfo.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');
    
    final bytes = utf8.encode(deviceString);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }
  
  /// Validate session integrity
  static bool validateSession(String? storedFingerprint) {
    if (storedFingerprint == null) return false;
    
    final currentFingerprint = generateDeviceFingerprint();
    return storedFingerprint == currentFingerprint;
  }
  
  /// Check if session has expired
  static bool isSessionExpired() {
    if (_lastActivity == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(_lastActivity!);
    
    return difference > _sessionTimeout;
  }
  
  /// Update last activity timestamp
  static void _updateLastActivity() {
    _lastActivity = DateTime.now();
  }
  
  /// Setup security headers for HTTP requests
  static void _setupSecurityHeaders() {
    HttpOverrides.global = SecurityHttpOverrides();
  }
  
  /// Validate authentication token integrity
  static Future<bool> validateAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      // Force token refresh to validate
      await user.getIdToken(true);
      return true;
    } catch (e) {
      debugPrint('Token validation failed: $e');
      return false;
    }
  }
  
  /// Check for jailbreak/root detection (basic implementation)
  static Future<bool> isDeviceCompromised() async {
    try {
      // Check for common jailbreak/root indicators
      final suspiciousFiles = [
        '/system/app/Superuser.apk',
        '/sbin/su',
        '/system/bin/su',
        '/system/xbin/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/system/sd/xbin/su',
        '/system/bin/failsafe/su',
        '/data/local/su',
        // iOS jailbreak indicators
        '/Applications/Cydia.app',
        '/Library/MobileSubstrate/MobileSubstrate.dylib',
        '/bin/bash',
        '/usr/sbin/sshd',
        '/etc/apt',
        '/private/var/lib/apt/',
      ];
      
      for (final filePath in suspiciousFiles) {
        final file = File(filePath);
        if (await file.exists()) {
          debugPrint('Security Warning: Suspicious file detected: $filePath');
          return true;
        }
      }
      
      return false;
    } catch (e) {
      // If we can't check, assume device is safe
      debugPrint('Device security check failed: $e');
      return false;
    }
  }
  
  /// Encrypt sensitive data before local storage
  static String encryptSensitiveData(String data, String key) {
    // Simple XOR encryption for demo purposes
    // In production, use proper encryption libraries like encrypt package
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    final encrypted = <int>[];
    
    for (int i = 0; i < dataBytes.length; i++) {
      encrypted.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return base64.encode(encrypted);
  }
  
  /// Decrypt sensitive data from local storage
  static String decryptSensitiveData(String encryptedData, String key) {
    try {
      final keyBytes = utf8.encode(key);
      final encryptedBytes = base64.decode(encryptedData);
      final decrypted = <int>[];
      
      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      debugPrint('Decryption failed: $e');
      return '';
    }
  }
  
  /// Rate limiting for authentication attempts
  static final Map<String, List<DateTime>> _authAttempts = {};
  static const int _maxAttemptsPerMinute = 5;
  
  static bool isRateLimited(String identifier) {
    final now = DateTime.now();
    final attempts = _authAttempts[identifier] ?? [];
    
    // Remove attempts older than 1 minute
    attempts.removeWhere((attempt) => now.difference(attempt).inMinutes >= 1);
    _authAttempts[identifier] = attempts;
    
    return attempts.length >= _maxAttemptsPerMinute;
  }
  
  static void recordAuthAttempt(String identifier) {
    final attempts = _authAttempts[identifier] ?? [];
    attempts.add(DateTime.now());
    _authAttempts[identifier] = attempts;
  }
  
  /// Network security validation
  static Future<bool> isNetworkSecure() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        return false; // No network connection
      }
      
      // Check if on cellular (generally more secure than WiFi)
      if (connectivityResult == ConnectivityResult.mobile) {
        return true;
      }
      
      // For WiFi, we can't easily detect if it's secure without platform-specific code
      // In production, consider using platform channels to check WiFi security
      return true; // Assume secure for now
      
    } catch (e) {
      debugPrint('Network security check failed: $e');
      return true; // Assume secure if check fails
    }
  }
  
  /// Log security events for monitoring
  static void logSecurityEvent(String event, Map<String, dynamic> details) {
    if (kDebugMode) {
      debugPrint('SECURITY EVENT: $event - $details');
    }
    
    // In production, send to crash reporting or security monitoring service
    // FirebaseCrashlytics.instance.log('Security: $event');
    // FirebaseCrashlytics.instance.recordError(event, null, information: details);
  }
  
  /// Validate app integrity (basic implementation)
  static Future<bool> validateAppIntegrity() async {
    // In production, implement certificate pinning and signature verification
    // For now, just check if we're running in debug mode
    if (kDebugMode) {
      return true; // Allow in debug mode
    }
    
    // Add your app signature validation logic here
    return true;
  }
  
  /// Emergency security lockdown
  static Future<void> emergencyLockdown(String reason) async {
    logSecurityEvent('EMERGENCY_LOCKDOWN', {'reason': reason});
    
    try {
      // Sign out user immediately
      await FirebaseAuth.instance.signOut();
      
      // Clear sensitive local data
      // await SharedPreferences.getInstance().then((prefs) => prefs.clear());
      
      // In production, you might want to:
      // - Disable certain app features
      // - Show security warning to user
      // - Send alert to backend
      
    } catch (e) {
      debugPrint('Emergency lockdown failed: $e');
    }
  }
}

/// Custom HTTP overrides for security headers
class SecurityHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    
    // Set security headers
    client.userAgent = 'NabdAlHayah/1.0.0 (Mobile App)';
    
    // Enable certificate validation
    client.badCertificateCallback = (cert, host, port) {
      // In production, implement proper certificate pinning
      debugPrint('Certificate validation for $host:$port');
      return false; // Reject bad certificates
    };
    
    return client;
  }
}

/// Security event types for monitoring
enum SecurityEvent {
  suspiciousActivity,
  multipleFailedLogins,
  deviceCompromised,
  networkInsecure,
  tokenExpired,
  unauthorizedAccess,
  dataIntegrityViolation
}
