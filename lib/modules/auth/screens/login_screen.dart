import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../providers/auth_provider.dart' as custom_auth;
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleAuthStateChange(custom_auth.AuthProvider authProvider) {
    // Only show error dialogs, let RootScreen handle navigation
    if (authProvider.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          String errorTitle = 'Login Failed';
          String errorMessage = authProvider.errorMessage!;
          
          // Check for specific errors and provide better messages
          if (errorMessage.contains('PigeonUserDetails') || 
              errorMessage.contains('type cast') ||
              errorMessage.contains('subtype')) {
            // This is a known issue, let the login succeed silently
            authProvider.clearMessages();
            return;
          }
          
          _showErrorDialog(
            errorTitle,
            errorMessage,
            showRetry: true,
          );
          authProvider.clearMessages();
        }
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() => _isPasswordVisible = !_isPasswordVisible);
  }

  /// Submit login form
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<custom_auth.AuthProvider>(context, listen: false);
    await authProvider.signInWithEmailAndPassword(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
    );
  }

  /// Reset password
  Future<void> _resetPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _showErrorDialog(
        'Email Required',
        'Please enter your email address first, then tap "Forgot Password?" again.',
      );
      return;
    }

    final authProvider = Provider.of<custom_auth.AuthProvider>(context, listen: false);
    await authProvider.resetPassword(_emailCtrl.text.trim());
  }

  /// Show error dialog
  void _showErrorDialog(String title, String message, {bool showRetry = false}) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              title.contains('Network') || title.contains('Internet') 
                ? Icons.wifi_off 
                : title.contains('Timeout') 
                  ? Icons.access_time 
                  : Icons.error_outline,
              color: AppTheme.accentOrange,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          if (showRetry) ...{
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submit(); // Retry the login
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          },
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get keyboard height to detect if keyboard is visible
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
    
    return Scaffold(
      // Allow scaffold to resize when keyboard appears for better handling
      resizeToAvoidBottomInset: true,
      body: Consumer<custom_auth.AuthProvider>(
        builder: (context, authProvider, child) {
          // Listen to auth changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleAuthStateChange(authProvider);
          });

          return Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.headerGradient,
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight;
                  
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: availableHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // Optimized Header - Larger logo and text with efficient rendering
                            RepaintBoundary(
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.0,
                                    vertical: isKeyboardVisible ? 8.0 : 40.0,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Larger logo with better visual presence
                                      if (!isKeyboardVisible) ...[
                                        const _LogoWidget(),
                                        const SizedBox(height: 24),
                                      ],
                                      // Larger welcome text
                                      const _WelcomeTextWidget(),
                                      if (!isKeyboardVisible) ...[
                                        const SizedBox(height: 12),
                                        const _SubtitleWidget(),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Optimized Form section - Prevents unnecessary rebuilds
                            Expanded(
                              child: Center(
                                child: RepaintBoundary(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxHeight: isKeyboardVisible ? 420 : double.infinity,
                                    ),
                                    margin: EdgeInsets.fromLTRB(
                                      16.0, 
                                      isKeyboardVisible ? 12.0 : 20.0, 
                                      16.0, 
                                      isKeyboardVisible ? 12.0 : 24.0
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.12),
                                          blurRadius: 24,
                                          offset: const Offset(0, -6),
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withValues(alpha: 0.1),
                                          blurRadius: 1,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SingleChildScrollView(
                                      padding: EdgeInsets.fromLTRB(
                                        24, 
                                        isKeyboardVisible ? 16 : 24, 
                                        24, 
                                        isKeyboardVisible ? 16 : 24
                                      ),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            _buildTextField(
                                              controller: _emailCtrl,
                                              label: 'Email',
                                              hint: 'Enter your email',
                                              icon: Icons.email_outlined,
                                              keyboardType: TextInputType.emailAddress,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter your email';
                                                }
                                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                                  return 'Please enter a valid email';
                                                }
                                                return null;
                                              },
                                            ),
                                            SizedBox(height: isKeyboardVisible ? 12 : 16),
                                            _buildTextField(
                                              controller: _passCtrl,
                                              label: 'Password',
                                              hint: 'Enter your password',
                                              icon: Icons.lock_outlined,
                                              isPassword: true,
                                              isPasswordVisible: _isPasswordVisible,
                                              onTogglePassword: _togglePasswordVisibility,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter your password';
                                                }
                                                if (value.length < 8) {
                                                  return 'Password must be at least 8 characters';
                                                }
                                                return null;
                                              },
                                            ),
                                            SizedBox(height: isKeyboardVisible ? 8 : 12),

                                            // Forgot password
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton(
                                                onPressed: _resetPassword,
                                                child: const Text(
                                                  "Forgot Password?",
                                                  style: TextStyle(
                                                    color: AppTheme.primaryGreen,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            SizedBox(height: isKeyboardVisible ? 6 : 8),
                                            _buildSubmitButton(authProvider.isLoading),
                                            SizedBox(height: isKeyboardVisible ? 12 : 16),

                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Don\'t have an account? ',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    Navigator.of(context).pushReplacement(
                                                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                                                    );
                                                  },
                                                  child: Text(
                                                    'Sign Up',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: AppTheme.primaryGreen,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  ),
                                ),
                              ),
                            ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return RepaintBoundary(
      child: Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textLight.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword && !isPasswordVisible,
        validator: validator,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textLight,
          ),
          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
          prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
          suffixIcon: isPassword
              ? IconButton(
            onPressed: onTogglePassword,
            icon: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    ));
  }

  Widget _buildSubmitButton(bool isLoading) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          'Sign In',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

/// Optimized logo widget with RepaintBoundary to prevent unnecessary repaints
class _LogoWidget extends StatelessWidget {
  const _LogoWidget();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Hero(
        tag: 'app_logo',
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.25),
                Colors.white.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite,
            size: 36,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Optimized welcome text widget
class _WelcomeTextWidget extends StatelessWidget {
  const _WelcomeTextWidget();

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
    
    return RepaintBoundary(
      child: Text(
        'Welcome Back',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: isKeyboardVisible ? 20 : 32,
          letterSpacing: -0.5,
          height: 1.1,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Optimized subtitle widget
class _SubtitleWidget extends StatelessWidget {
  const _SubtitleWidget();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Text(
        'Sign in to continue your wellness journey',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.3,
          letterSpacing: 0.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
