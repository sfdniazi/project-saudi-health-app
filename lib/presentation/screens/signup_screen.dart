import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_theme.dart';
import '../../services/firebase_service.dart';
import '../navigation/main_navigation.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // Controllers for all form fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _idealWeightController = TextEditingController();

  // Form state
  String _selectedGender = 'Male';
  String _selectedUnits = 'Metric (kg, cm)';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  int _currentPage = 0;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
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
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create Firebase Auth user
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user != null) {
        // Update Firebase Auth display name
        await user.updateDisplayName(_nameController.text.trim());

        // Create comprehensive user profile in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': _emailController.text.trim(),
          'displayName': _nameController.text.trim(),
          'age': int.parse(_ageController.text.trim()),
          'gender': _selectedGender,
          'height': double.parse(_heightController.text.trim()),
          'weight': double.parse(_weightController.text.trim()),
          'idealWeight': double.parse(_idealWeightController.text.trim()),
          'units': _selectedUnits,
          'dailyGoal': _calculateDailyCalorieGoal(),
          'notificationsEnabled': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Initialize user collections
        await FirebaseService.initializeUserCollections(user.uid);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred during registration';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered. Please use a different email.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'weak-password') {
        message = 'Password should be at least 6 characters long.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _calculateDailyCalorieGoal() {
    final age = int.tryParse(_ageController.text.trim()) ?? 25;
    final weight = double.tryParse(_weightController.text.trim()) ?? 70;
    final height = double.tryParse(_heightController.text.trim()) ?? 170;
    
    // Basic BMR calculation (Mifflin-St Jeor Equation)
    double bmr;
    if (_selectedGender == 'Male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }
    
    // Assuming moderate activity level (1.55 multiplier)
    return (bmr * 1.55).round();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Form Pages
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Form(
                      key: _formKey,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (page) => setState(() => _currentPage = page),
                        children: [
                          _buildAccountInfoPage(),
                          _buildPersonalInfoPage(),
                          _buildPhysicalInfoPage(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Bottom Navigation
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
          const SizedBox(height: 20),
          
          // Progress Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 32 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index 
                      ? Colors.white 
                      : Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s start with your basic account details',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'Enter your email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
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
            controller: _passwordController,
            label: 'Password',
            hint: 'Create a strong password',
            icon: Icons.lock_outline,
            isPassword: true,
            isPasswordVisible: _isPasswordVisible,
            onTogglePassword: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            icon: Icons.lock_outline,
            isPassword: true,
            isPasswordVisible: _isConfirmPasswordVisible,
            onTogglePassword: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us personalize your experience',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          _buildTextField(
            controller: _ageController,
            label: 'Age',
            hint: 'Enter your age',
            icon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your age';
              }
              final age = int.tryParse(value.trim());
              if (age == null || age < 13 || age > 120) {
                return 'Please enter a valid age (13-120)';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Gender Selection
          Text(
            'Gender',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGenderCard('Male', Icons.male),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderCard('Female', Icons.female),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Units Selection
          Text(
            'Measurement Units',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.textLight.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedUnits,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                prefixIcon: Icon(Icons.straighten, color: AppTheme.textSecondary),
              ),
              items: ['Metric (kg, cm)', 'Imperial (lb, in)']
                  .map((units) => DropdownMenuItem(
                        value: units,
                        child: Text(units),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedUnits = value!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Physical Information',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us calculate your nutritional needs',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          _buildTextField(
            controller: _heightController,
            label: _selectedUnits.contains('Metric') ? 'Height (cm)' : 'Height (in)',
            hint: _selectedUnits.contains('Metric') ? 'e.g., 170' : 'e.g., 67',
            icon: Icons.height,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your height';
              }
              final height = double.tryParse(value.trim());
              if (height == null) {
                return 'Please enter a valid height';
              }
              if (_selectedUnits.contains('Metric')) {
                if (height < 100 || height > 250) {
                  return 'Height must be between 100-250 cm';
                }
              } else {
                if (height < 39 || height > 98) {
                  return 'Height must be between 39-98 inches';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          _buildTextField(
            controller: _weightController,
            label: _selectedUnits.contains('Metric') ? 'Current Weight (kg)' : 'Current Weight (lb)',
            hint: _selectedUnits.contains('Metric') ? 'e.g., 70' : 'e.g., 154',
            icon: Icons.monitor_weight,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your current weight';
              }
              final weight = double.tryParse(value.trim());
              if (weight == null) {
                return 'Please enter a valid weight';
              }
              if (_selectedUnits.contains('Metric')) {
                if (weight < 30 || weight > 300) {
                  return 'Weight must be between 30-300 kg';
                }
              } else {
                if (weight < 66 || weight > 660) {
                  return 'Weight must be between 66-660 lbs';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          _buildTextField(
            controller: _idealWeightController,
            label: _selectedUnits.contains('Metric') ? 'Goal Weight (kg)' : 'Goal Weight (lb)',
            hint: _selectedUnits.contains('Metric') ? 'e.g., 65' : 'e.g., 143',
            icon: Icons.flag_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your goal weight';
              }
              final weight = double.tryParse(value.trim());
              if (weight == null) {
                return 'Please enter a valid goal weight';
              }
              if (_selectedUnits.contains('Metric')) {
                if (weight < 30 || weight > 300) {
                  return 'Goal weight must be between 30-300 kg';
                }
              } else {
                if (weight < 66 || weight > 660) {
                  return 'Goal weight must be between 66-660 lbs';
                }
              }
              return null;
            },
          ),
          
          const SizedBox(height: 40),
          
          // Create Account Button
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      color: AppTheme.surfaceLight,
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Button
          if (_currentPage > 0)
            TextButton.icon(
              onPressed: _previousPage,
              icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
              label: Text(
                'Previous',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox(),
          
          // Next Button
          if (_currentPage < 2)
            Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_currentPage == 0 && _validateCurrentPage()) {
                    _nextPage();
                  } else if (_currentPage == 1 && _validateCurrentPage()) {
                    _nextPage();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                label: Text(
                  'Next',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            const SizedBox(),
        ],
      ),
    );
  }

  bool _validateCurrentPage() {
    if (_currentPage == 0) {
      return _nameController.text.trim().isNotEmpty &&
             _emailController.text.trim().isNotEmpty &&
             _passwordController.text.isNotEmpty &&
             _confirmPasswordController.text == _passwordController.text &&
             RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim());
    } else if (_currentPage == 1) {
      return _ageController.text.trim().isNotEmpty &&
             int.tryParse(_ageController.text.trim()) != null;
    }
    return true;
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

  Widget _buildGenderCard(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen.withValues(alpha: 0.1) : AppTheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.textLight.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              gender,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
