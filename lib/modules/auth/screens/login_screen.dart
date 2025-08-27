import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../../presentation/navigation/main_navigation.dart';
import '../providers/auth_provider.dart';
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

  void _handleAuthStateChange(AuthProvider authProvider) {
    // Navigate to main screen when authenticated
    if (authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        }
      });
      return; // Don't show messages when navigating
    }

    // Show error dialog if there's an error
    if (authProvider.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          String errorTitle = 'Login Failed';
          String errorMessage = authProvider.errorMessage!;
          
          // Check for specific type casting error
          if (errorMessage.contains("type 'List<Object?>' is not a subtype of type 'PigeonUserDetails?'")) {
            errorTitle = 'Login Failed';
            errorMessage = 'There was a temporary issue with your login. Please try again.';
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

    // Show success message if available (but not when authenticated to avoid duplicate messages)
    if (authProvider.successMessage != null && !authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showSuccessSnackBar(authProvider.successMessage!);
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
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

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get keyboard height to detect if keyboard is visible
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
    
    return Scaffold(
      // Prevent the scaffold from resizing when keyboard appears
      resizeToAvoidBottomInset: false,
      body: Consumer<AuthProvider>(
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
              child: SingleChildScrollView(
                // Add padding to account for keyboard
                padding: EdgeInsets.only(
                  bottom: mediaQuery.viewInsets.bottom,
                ),
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: mediaQuery.size.height - 
                        mediaQuery.padding.top - 
                        mediaQuery.padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Header - Adaptive height
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: isKeyboardVisible 
                              ? 80 // Much smaller height when keyboard is visible
                              : 280, // Full height when keyboard is hidden
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 32.0,
                                vertical: isKeyboardVisible ? 8.0 : 32.0,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Show icon only when keyboard is hidden
                                  if (!isKeyboardVisible) ...[
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.favorite,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  Text(
                                    'Welcome Back',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: isKeyboardVisible ? 24 : 32,
                                    ),
                                  ),
                                  if (!isKeyboardVisible) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Sign in to continue your wellness journey',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Form section - Flexible height
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(36),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 32,
                                    offset: const Offset(0, -8),
                                  ),
                                ],
                              ),
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      32, 
                                      isKeyboardVisible ? 24 : 40, 
                                      32, 
                                      32
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
                                          const SizedBox(height: 20),
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
                                              if (value.length < 6) {
                                                return 'Password must be at least 6 characters';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 16),

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

                                          const SizedBox(height: 8),
                                          _buildSubmitButton(authProvider.isLoading),
                                          const SizedBox(height: 20),

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
                                                  Navigator.of(context).push(
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
                      ],
                    ),
                  ),
                ),
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
    return Container(
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
    );
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
