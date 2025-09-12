import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../modules/auth/providers/auth_provider.dart' as custom_auth;
import 'compact_login_screen.dart';
import 'main_navigation_wrapper.dart';

class CompactSignUpScreen extends StatefulWidget {
  const CompactSignUpScreen({Key? key}) : super(key: key);

  @override
  State<CompactSignUpScreen> createState() => _CompactSignUpScreenState();
}

class _CompactSignUpScreenState extends State<CompactSignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _idealWeightController = TextEditingController();
  
  // Focus nodes
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _ageFocusNode = FocusNode();
  final _heightFocusNode = FocusNode();
  final _weightFocusNode = FocusNode();
  final _idealWeightFocusNode = FocusNode();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  int _currentPage = 0;
  String _selectedGender = 'Male';
  String _selectedUnits = 'Metric (kg, cm)';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _animationController.forward();
  }
  
  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _idealWeightController.dispose();
    
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _ageFocusNode.dispose();
    _heightFocusNode.dispose();
    _weightFocusNode.dispose();
    _idealWeightFocusNode.dispose();
    
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<custom_auth.AuthProvider>(context, listen: false);
      await authProvider.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _selectedGender,
        height: double.parse(_heightController.text.trim()),
        weight: double.parse(_weightController.text.trim()),
        idealWeight: double.parse(_idealWeightController.text.trim()),
        units: _selectedUnits,
      );

      if (authProvider.isAuthenticated && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationWrapper()),
        );
      } else if (mounted && authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      if (_validateCurrentPage()) {
        setState(() => _currentPage++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _handleSignUp();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        return _nameController.text.trim().isNotEmpty &&
               _emailController.text.trim().isNotEmpty &&
               _passwordController.text.isNotEmpty &&
               _confirmPasswordController.text == _passwordController.text &&
               RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim());
      case 1:
        return _ageController.text.trim().isNotEmpty &&
               int.tryParse(_ageController.text.trim()) != null;
      case 2:
        return _heightController.text.trim().isNotEmpty &&
               _weightController.text.trim().isNotEmpty &&
               _idealWeightController.text.trim().isNotEmpty &&
               double.tryParse(_heightController.text.trim()) != null &&
               double.tryParse(_weightController.text.trim()) != null &&
               double.tryParse(_idealWeightController.text.trim()) != null;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Header with progress
                _buildHeader(isTablet),
                
                // Form content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 400 : double.infinity,
                        ),
                        child: Column(
                          children: [
                            // Form Card
                            _buildFormCard(isTablet),
                            
                            SizedBox(height: isTablet ? 32 : 24),
                            
                            // Navigation buttons
                            _buildNavigationButtons(isTablet),
                            
                            SizedBox(height: isTablet ? 24 : 16),
                            
                            // Login prompt
                            _buildLoginPrompt(isTablet),
                          ],
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
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      child: Column(
        children: [
          // App Logo
          Container(
            width: isTablet ? 64 : 56,
            height: isTablet ? 64 : 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.nabdGreen,
                  AppTheme.nabdBlue,
                ],
              ),
              borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.nabdGreen.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.health_and_safety,
              color: Colors.white,
              size: isTablet ? 28 : 24,
            ),
          ),
          
          SizedBox(height: isTablet ? 16 : 12),
          
          // Title
          Text(
            'Create Account',
            style: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: isTablet ? 8 : 4),
          
          // Subtitle
          Text(
            'Join your health journey today',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: isTablet ? 24 : 20),
          
          // Progress indicator
          _buildProgressIndicator(isTablet),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(bool isTablet) {
    return Row(
      children: [
        for (int i = 0; i < 3; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= _currentPage ? AppTheme.nabdBlue : AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < 2) SizedBox(width: isTablet ? 12 : 8),
        ],
      ],
    );
  }

  Widget _buildFormCard(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SizedBox(
          height: isTablet ? 400 : 350, // Fixed height to prevent overflow
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (page) => setState(() => _currentPage = page),
            children: [
              _buildBasicInfoPage(isTablet),
              _buildPersonalInfoPage(isTablet),
              _buildPhysicalInfoPage(isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage(bool isTablet) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page title
          Text(
            'Basic Information',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: isTablet ? 24 : 20),
          
          // Name field
          _buildTextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person_outline,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
            isTablet: isTablet,
          ),
          
          SizedBox(height: isTablet ? 20 : 16),
          
          // Email field
          _buildTextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            label: 'Email',
            hint: 'Enter your email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
            isTablet: isTablet,
          ),
          
          SizedBox(height: isTablet ? 20 : 16),
          
          // Password field
          _buildTextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppTheme.textSecondary,
                size: isTablet ? 24 : 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            isTablet: isTablet,
          ),
          
          SizedBox(height: isTablet ? 20 : 16),
          
          // Confirm password field
          _buildTextField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            label: 'Confirm Password',
            hint: 'Confirm your password',
            icon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppTheme.textSecondary,
                size: isTablet ? 24 : 20,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoPage(bool isTablet) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page title
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: isTablet ? 24 : 20),
          
          // Age field
          _buildTextField(
            controller: _ageController,
            focusNode: _ageFocusNode,
            label: 'Age',
            hint: 'Enter your age',
            icon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your age';
              }
              final age = int.tryParse(value);
              if (age == null || age < 13 || age > 120) {
                return 'Please enter a valid age (13-120)';
              }
              return null;
            },
            isTablet: isTablet,
          ),
          
          SizedBox(height: isTablet ? 20 : 16),
          
          // Gender dropdown
          _buildDropdownField(
            label: 'Gender',
            value: _selectedGender,
            items: const ['Male', 'Female', 'Other'],
            onChanged: (value) => setState(() => _selectedGender = value!),
            icon: Icons.person_outline,
            isTablet: isTablet,
          ),
          
          SizedBox(height: isTablet ? 20 : 16),
          
          // Units dropdown
          _buildDropdownField(
            label: 'Units',
            value: _selectedUnits,
            items: const ['Metric (kg, cm)', 'Imperial (lbs, ft)'],
            onChanged: (value) => setState(() => _selectedUnits = value!),
            icon: Icons.straighten,
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalInfoPage(bool isTablet) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page title
          Text(
            'Physical Information',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: isTablet ? 24 : 20),
          
          // Height field
          _buildTextField(
            controller: _heightController,
            focusNode: _heightFocusNode,
            label: 'Height (${_selectedUnits.contains('Metric') ? 'cm' : 'ft'})',
            hint: 'Enter your height',
            icon: Icons.height,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _weightFocusNode.requestFocus(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your height';
              }
              final height = double.tryParse(value);
              if (height == null || height <= 0) {
                return 'Please enter a valid height';
              }
              return null;
            },
            isTablet: isTablet,
          ),
          
          SizedBox(height: isTablet ? 20 : 16),
          
          // Weight field
          _buildTextField(
            controller: _weightController,
            focusNode: _weightFocusNode,
            label: 'Current Weight (${_selectedUnits.contains('Metric') ? 'kg' : 'lbs'})',
            hint: 'Enter your current weight',
            icon: Icons.monitor_weight_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _idealWeightFocusNode.requestFocus(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your current weight';
              }
              final weight = double.tryParse(value);
              if (weight == null || weight <= 0) {
                return 'Please enter a valid weight';
              }
              return null;
            },
            isTablet: isTablet,
          ),
          
          SizedBox(height: isTablet ? 20 : 16),
          
          // Ideal weight field
          _buildTextField(
            controller: _idealWeightController,
            focusNode: _idealWeightFocusNode,
            label: 'Target Weight (${_selectedUnits.contains('Metric') ? 'kg' : 'lbs'})',
            hint: 'Enter your target weight',
            icon: Icons.flag_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your target weight';
              }
              final weight = double.tryParse(value);
              if (weight == null || weight <= 0) {
                return 'Please enter a valid target weight';
              }
              return null;
            },
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required bool isTablet,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: AppTheme.nabdBlue,
              size: isTablet ? 24 : 20,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.borderColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.nabdBlue,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 12,
              vertical: isTablet ? 16 : 14,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required bool isTablet,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: AppTheme.nabdBlue,
              size: isTablet ? 24 : 20,
            ),
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.borderColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.nabdBlue,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 12,
              vertical: isTablet ? 16 : 14,
            ),
          ),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(bool isTablet) {
    return Row(
      children: [
        // Back button
        if (_currentPage > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: _previousPage,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.nabdBlue,
                side: BorderSide(color: AppTheme.nabdBlue),
                padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Back',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
        ],
        
        // Next/Create button
        Expanded(
          flex: _currentPage == 0 ? 1 : 1,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.nabdBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? SizedBox(
                    height: isTablet ? 24 : 20,
                    width: isTablet ? 24 : 20,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _currentPage == 2 ? 'Create Account' : 'Next',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPrompt(bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            color: AppTheme.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CompactLoginScreen()),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Sign in',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: AppTheme.nabdBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}