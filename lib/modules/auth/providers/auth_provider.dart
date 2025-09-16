import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/auth_user_model.dart';
import '../models/auth_state_model.dart';
import '../../../core/security_middleware.dart';

class AuthProvider with ChangeNotifier {
  // Private fields
  AuthStateModel _authState = AuthStateModel.initial();
  AuthUserModel? _currentUser;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getters
  AuthStateModel get authState => _authState;
  AuthUserModel? get currentUser => _currentUser;
  bool get isLoading => _authState.isLoading;
  bool get isAuthenticated => _authState.isAuthenticated && _currentUser != null;
  String? get errorMessage => _authState.errorMessage;
  String? get successMessage => _authState.successMessage;

  /// Initialize auth provider and listen to auth state changes
  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    // Listen to Firebase auth state changes
    _firebaseAuth.authStateChanges().listen((User? user) {
      if (user != null) {
        // Immediately set authenticated state when Firebase user exists
        _setAuthState(AuthStateModel.authenticated());
        // Then fetch full profile asynchronously
        _fetchUserProfile(user.uid);
      } else {
        _setAuthState(AuthStateModel.unauthenticated());
        _currentUser = null;
      }
    });
  }

  /// Set authentication state and notify listeners
  void _setAuthState(AuthStateModel state) {
    _authState = state;
    notifyListeners();
  }

  /// Check internet connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      // If connectivity check fails, assume connection exists to avoid false negatives
      debugPrint('Connectivity check failed: $e');
      return true; // Don't block auth attempts if connectivity plugin fails
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setAuthState(AuthStateModel.loading());
      
      // Security: Rate limiting check
      if (SecurityMiddleware.isRateLimited(email)) {
        SecurityMiddleware.logSecurityEvent('RATE_LIMITED_LOGIN', {'email': email});
        throw Exception('Too many login attempts. Please wait before trying again.');
      }
      
      // Record authentication attempt
      SecurityMiddleware.recordAuthAttempt(email);
      
      // Security: Check device integrity
      final isDeviceCompromised = await SecurityMiddleware.isDeviceCompromised();
      if (isDeviceCompromised) {
        SecurityMiddleware.logSecurityEvent('COMPROMISED_DEVICE_LOGIN', {'email': email});
        throw Exception('Security risk detected. Please use a secure device.');
      }

      // Check connectivity
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        throw Exception('No internet connection. Please check your network and try again.');
      }

      // Sign in with Firebase Auth with timeout
      final credential = await _firebaseAuth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Login timed out. Please try again.');
            },
          );

      final user = credential.user;
      if (user != null) {
        // Fetch or create user profile
        await _fetchOrCreateUserProfile(user);
        // Do NOT manually set authenticated here; rely on Firebase authStateChanges()
        // End loading state and surface success message only
        _setAuthState(_authState.copyWith(
          status: AuthStatus.initial,
          successMessage: 'Welcome back to Nabd Al-Hayah!',
        ));
      } else {
        throw Exception('Authentication failed. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      String message = _getFirebaseAuthErrorMessage(e);
      _setAuthState(AuthStateModel.error(message));
    } catch (e) {
      debugPrint('Login error: $e');
      _setAuthState(AuthStateModel.error('Login failed. Please check your credentials and try again.'));
    }
  }

  /// Create account with email and password
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required int age,
    required String gender,
    required double height,
    required double weight,
    required double idealWeight,
    required String units,
  }) async {
    try {
      _setAuthState(AuthStateModel.loading());

      // Check connectivity
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        throw Exception('No internet connection. Please check your network and try again.');
      }

      // Create user with Firebase Auth with timeout
      final credential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Signup timed out. Please try again.');
            },
          );

      final user = credential.user;
      if (user != null) {
        // Create user profile with provided data
        final userModel = AuthUserModel(
          uid: user.uid,
          email: user.email ?? email,
          displayName: fullName,
          age: age,
          gender: gender,
          height: height,
          weight: weight,
          idealWeight: idealWeight,
          units: units,
        );

        await _createUserProfile(userModel);
        _currentUser = userModel;
        
        // Do NOT manually set authenticated here; rely on Firebase authStateChanges()
        // End loading state and surface success message only
        _setAuthState(_authState.copyWith(
          status: AuthStatus.initial,
          successMessage: 'Account created successfully! Welcome to Nabd Al-Hayah!',
        ));
      } else {
        throw Exception('Account creation failed. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      String message = _getFirebaseAuthErrorMessage(e);
      _setAuthState(AuthStateModel.error(message));
    } catch (e) {
      debugPrint('Signup error: $e');
      _setAuthState(AuthStateModel.error('Account creation failed. Please try again.'));
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      _setAuthState(AuthStateModel.loading());

      // Check connectivity
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        throw Exception('No internet connection. Please check your network and try again.');
      }

      await _firebaseAuth
          .sendPasswordResetEmail(email: email.trim())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Password reset timed out. Please try again.');
            },
          );

      // End loading state and surface success message only
      _setAuthState(_authState.copyWith(
        status: AuthStatus.initial,
        successMessage: 'Password reset email sent! Please check your inbox.',
      ));
    } on FirebaseAuthException catch (e) {
      String message = _getFirebaseAuthErrorMessage(e);
      _setAuthState(AuthStateModel.error(message));
    } catch (e) {
      debugPrint('Password reset error: $e');
      _setAuthState(AuthStateModel.error('Password reset failed. Please try again.'));
    }
  }

  /// ✅ Optimized sign out with timeout and immediate local clearing
  Future<void> signOut() async {
    try {
      _setAuthState(AuthStateModel.loading());
      
      // Clear local state immediately for faster UX
      _currentUser = null;
      _setAuthState(AuthStateModel.unauthenticated());
      
      // Perform Firebase sign out with timeout
      await _firebaseAuth.signOut().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('Sign out timed out, but local state is cleared');
          // This is acceptable - user is signed out locally
        },
      );
      
    } catch (e) {
      debugPrint('Sign out error (non-critical): $e');
      // Even if Firebase sign out fails, keep local state cleared
      _currentUser = null;
      _setAuthState(AuthStateModel.unauthenticated());
    }
  }

  /// Fetch user profile from Firestore
  Future<void> _fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        _currentUser = AuthUserModel.fromMap(doc.data()!);
        _setAuthState(AuthStateModel.authenticated());
      } else {
        // User document doesn't exist, create one
        final user = _firebaseAuth.currentUser;
        if (user != null) {
          await _fetchOrCreateUserProfile(user);
        }
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      _setAuthState(AuthStateModel.error('Failed to fetch user profile'));
    }
  }

  /// Fetch or create user profile (used during login)
  Future<void> _fetchOrCreateUserProfile(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        // Create user profile with default values
        final userModel = AuthUserModel.fromFirebaseUser(user);
        await _createUserProfile(userModel);
        _currentUser = userModel;
      } else {
        _currentUser = AuthUserModel.fromMap(userDoc.data()!);
      }
    } catch (e) {
      debugPrint('Error in profile creation/fetch: $e');
      // Continue anyway - the user is authenticated with Firebase Auth
      _currentUser = AuthUserModel.fromFirebaseUser(user);
    }
  }

  /// Create user profile in Firestore
  Future<void> _createUserProfile(AuthUserModel userModel) async {
    final userData = userModel.toMap();
    userData['createdAt'] = FieldValue.serverTimestamp();
    userData['updatedAt'] = FieldValue.serverTimestamp();
    
    await _firestore.collection('users').doc(userModel.uid).set(userData);
  }

  /// Get user-friendly error messages from FirebaseAuthException
  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address. Please check your email or create a new account.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or use "Forgot Password" to reset it.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please use a different email or try signing in.';
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'The email address is not valid. Please enter a correct email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      default:
        return e.message ?? 'An authentication error occurred. Please try again.';
    }
  }

  /// Clear error and success messages
  void clearMessages() {
    if (_authState.hasError || _authState.successMessage != null) {
      _setAuthState(_authState.copyWith(
        errorMessage: null,
        successMessage: null,
      ));
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(AuthUserModel updatedUser) async {
    try {
      _setAuthState(AuthStateModel.loading());
      
      final userData = updatedUser.toMap();
      userData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('users').doc(updatedUser.uid).update(userData);
      _currentUser = updatedUser;
      
      _setAuthState(AuthStateModel.authenticated(
        successMessage: 'Profile updated successfully!',
      ));
    } catch (e) {
      _setAuthState(AuthStateModel.error('Failed to update profile: ${e.toString()}'));
    }
  }
}
