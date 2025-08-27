import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/consent_manager.dart'; // 🔒 Privacy consent
import '../widgets/nutrient_indicator.dart';
import '../widgets/animated_user_avatar.dart'; // 🎨 Animated avatar
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../main.dart'; // 🎨 For ThemeModeProvider
import '../../modules/auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _notificationsEnabled = true;
  String _selectedUnit = 'Metric (kg, cm)';
  int _dailyGoal = 2000;
  ThemeMode _currentThemeMode = ThemeMode.system; // 🎨 Track current theme mode

  @override
  void initState() {
    super.initState();
    _loadSavedThemeMode();
  }

  // 🎨 Load saved theme mode on widget init
  Future<void> _loadSavedThemeMode() async {
    final savedTheme = await AppTheme.getSavedThemeMode();
    setState(() {
      _currentThemeMode = savedTheme;
    });
  }

  // ==============================
  // DIALOGS
  // ==============================

  void _showGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Daily Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current goal: $_dailyGoal kcal'),
            const SizedBox(height: 16),
            Slider(
              value: _dailyGoal.toDouble(),
              min: 1200,
              max: 3000,
              divisions: 18,
              label: '$_dailyGoal kcal',
              onChanged: (value) {
                setState(() {
                  _dailyGoal = value.round();
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseService.updateUserData(dailyGoal: _dailyGoal);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Daily goal updated successfully!')),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating goal: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Units'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('Metric (kg, cm)'),
              value: 'Metric (kg, cm)',
              groupValue: _selectedUnit,
              onChanged: (value) async {
                try {
                  await FirebaseService.updateUserData(units: value.toString());
                  if (mounted) {
                    setState(() {
                      _selectedUnit = value.toString();
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Units updated successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating units: $e')),
                    );
                  }
                }
              },
            ),
            RadioListTile(
              title: const Text('Imperial (lb, in)'),
              value: 'Imperial (lb, in)',
              groupValue: _selectedUnit,
              onChanged: (value) async {
                try {
                  await FirebaseService.updateUserData(units: value.toString());
                  if (mounted) {
                    setState(() {
                      _selectedUnit = value.toString();
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Units updated successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating units: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Meal Reminders'),
              subtitle: const Text('Get notified about meal times'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Water Reminders'),
              subtitle: const Text('Stay hydrated throughout the day'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Goal Achievements'),
              subtitle: const Text('Celebrate your milestones'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change Password'),
              onTap: () {
                Navigator.pop(context);
                _showChangePasswordDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('Biometric Login'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off),
              title: const Text('Private Profile'),
              trailing: Switch(
                value: false,
                onChanged: (value) {},
              ),
            ),
            // 🔒 Privacy consent option
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: AppTheme.primaryGreen),
              title: const Text('Privacy Consent'),
              subtitle: const Text('Manage data collection preferences'),
              onTap: () {
                Navigator.pop(context);
                ConsentManager.showConsentSettings(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// ✅ Show theme settings dialog with proper current theme tracking
  void _showThemeSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.palette_outlined, color: AppTheme.primaryGreen),
            SizedBox(width: 12),
            Text('Theme Settings'),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Light Mode'),
                subtitle: const Text('Use light theme always'),
                value: ThemeMode.light,
                groupValue: _currentThemeMode, // 🎨 Use tracked theme mode
                onChanged: (value) {
                  if (value != null) {
                    // 🎨 Update theme instantly across entire app
                    final provider = ThemeModeProvider.of(context);
                    provider?.updateThemeMode(value);
                    setState(() {
                      _currentThemeMode = value;
                    });
                    setDialogState(() {});
                    Navigator.pop(context);
                    // 🎨 Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Theme changed to Light Mode'),
                        backgroundColor: AppTheme.primaryGreen,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme always'),
                value: ThemeMode.dark,
                groupValue: _currentThemeMode, // 🎨 Use tracked theme mode
                onChanged: (value) {
                  if (value != null) {
                    // 🎨 Update theme instantly across entire app
                    final provider = ThemeModeProvider.of(context);
                    provider?.updateThemeMode(value);
                    setState(() {
                      _currentThemeMode = value;
                    });
                    setDialogState(() {});
                    Navigator.pop(context);
                    // 🎨 Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Theme changed to Dark Mode'),
                        backgroundColor: AppTheme.primaryGreen,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                subtitle: const Text('Follow device system settings'),
                value: ThemeMode.system,
                groupValue: _currentThemeMode, // 🎨 Use tracked theme mode
                onChanged: (value) {
                  if (value != null) {
                    // 🎨 Update theme instantly across entire app
                    final provider = ThemeModeProvider.of(context);
                    provider?.updateThemeMode(value);
                    setState(() {
                      _currentThemeMode = value;
                    });
                    setDialogState(() {});
                    Navigator.pop(context);
                    // 🎨 Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Theme set to follow system preferences'),
                        backgroundColor: AppTheme.primaryGreen,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// ✅ Show editable profile dialog
  void _showEditProfileDialog(UserModel userModel) {
    final nameController = TextEditingController(text: userModel.displayName);
    final ageController = TextEditingController(text: userModel.age.toString());
    final heightController = TextEditingController(text: userModel.height.toString());
    final weightController = TextEditingController(text: userModel.weight.toString());
    final idealWeightController = TextEditingController(text: userModel.idealWeight.toString());
    String selectedGender = userModel.gender;
    String selectedUnits = userModel.units;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.edit_outlined, color: AppTheme.primaryGreen),
                SizedBox(width: 12),
                Text('Edit Profile'),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: ageController,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          prefixIcon: Icon(Icons.cake_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final age = int.tryParse(value ?? '');
                          if (age == null || age < 13 || age > 120) {
                            return 'Please enter a valid age (13-120)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        items: ['Male', 'Female', 'Other']
                            .map((gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedGender = value ?? 'Male';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: heightController,
                        decoration: InputDecoration(
                          labelText: selectedUnits.contains('Metric') ? 'Height (cm)' : 'Height (in)',
                          prefixIcon: const Icon(Icons.height),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final height = double.tryParse(value ?? '');
                          if (height == null || height <= 0) {
                            return 'Please enter a valid height';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: weightController,
                        decoration: InputDecoration(
                          labelText: selectedUnits.contains('Metric') ? 'Weight (kg)' : 'Weight (lb)',
                          prefixIcon: const Icon(Icons.monitor_weight),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final weight = double.tryParse(value ?? '');
                          if (weight == null || weight <= 0) {
                            return 'Please enter a valid weight';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: idealWeightController,
                        decoration: InputDecoration(
                          labelText: selectedUnits.contains('Metric') ? 'Goal Weight (kg)' : 'Goal Weight (lb)',
                          prefixIcon: const Icon(Icons.flag_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final weight = double.tryParse(value ?? '');
                          if (weight == null || weight <= 0) {
                            return 'Please enter a valid goal weight';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedUnits,
                        decoration: const InputDecoration(
                          labelText: 'Units',
                          prefixIcon: Icon(Icons.straighten),
                          border: OutlineInputBorder(),
                        ),
                        items: ['Metric (kg, cm)', 'Imperial (lb, in)']
                            .map((units) => DropdownMenuItem(
                                  value: units,
                                  child: Text(units),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedUnits = value ?? 'Metric (kg, cm)';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      await FirebaseService.updateUserData(
                        displayName: nameController.text.trim(),
                        age: int.parse(ageController.text.trim()),
                        gender: selectedGender,
                        height: double.parse(heightController.text.trim()),
                        weight: double.parse(weightController.text.trim()),
                        idealWeight: double.parse(idealWeightController.text.trim()),
                        units: selectedUnits,
                      );
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully!'),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating profile: $e'),
                            backgroundColor: AppTheme.accentOrange,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('Update Profile'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text ==
                  confirmPasswordController.text) {
                try {
                  await _auth.currentUser?.updatePassword(
                    newPasswordController.text,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated successfully!')),
                  );
                  Navigator.pop(context);
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.message}')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match!')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _performLogout(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  /// ✅ Optimized logout with loading state and timeout
  Future<void> _performLogout() async {
    // Show loading indicator immediately
    Navigator.pop(context); // Close dialog
    
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryGreen),
                  SizedBox(height: 16),
                  Text('Logging out...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      // Perform logout with timeout to prevent hanging
      await _auth.signOut().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Even if sign out times out, we can still navigate
          // The user will be signed out locally
        },
      );
      
      // Navigate to login screen
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      // Even if there's an error, proceed with navigation
      // The user's local session is still cleared
      debugPrint('Logout error (non-critical): $e');
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    }
  }

  // ==============================
  // HELPER METHODS
  // ==============================

  Future<void> _createMissingProfile(User user) async {
    try {
      await FirebaseService.createInitialUserProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
      );
      // Trigger a rebuild after profile creation
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  // ==============================
  // UI
  // ==============================

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view profile')),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Custom App Bar - 🎨 Theme-aware header gradient
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: BoxDecoration(
              gradient: AppTheme.getHeaderGradient(context),
            ),
            child: Row(
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<UserModel?>(
              stream: FirebaseService.streamCurrentUserProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: AppTheme.accentOrange, size: 48),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final userModel = snapshot.data;
                if (userModel == null) {
                  // Auto-create profile if it doesn't exist
                  return FutureBuilder(
                    future: _createMissingProfile(user),
                    builder: (context, createSnapshot) {
                      if (createSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: AppTheme.primaryGreen),
                              SizedBox(height: 16),
                              Text('Setting up your profile...'),
                            ],
                          ),
                        );
                      }
                      
                      if (createSnapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, color: AppTheme.accentOrange, size: 48),
                              const SizedBox(height: 16),
                              const Text('Failed to create profile'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => setState(() {}),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      // Profile created, rebuild with new data
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                      );
                    },
                  );
                }

                // Update local state variables with Firebase data
                _dailyGoal = userModel.calculatedDailyGoal; // 🎯 Use calculated dynamic goal
                _selectedUnit = userModel.units;
                _notificationsEnabled = userModel.notificationsEnabled;

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                // 🎨 Enhanced profile header with smooth animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.15),
                        blurRadius: 40,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 🎨 Use animated avatar instead of plain CircleAvatar
                      AnimatedUserAvatar(
                        displayName: userModel.displayName,
                        email: userModel.email,
                        age: userModel.age,
                        gender: userModel.gender,
                        size: 80,
                        showPulse: true, // Add pulse animation
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // 📝 Show user name instead of email
                              userModel.displayName.isNotEmpty 
                                  ? userModel.displayName 
                                  : (user.email?.split('@').first ?? 'User'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // ℹ️ Show age and gender info instead of email
                            Text(
                              '${userModel.age} years old • ${userModel.gender}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              userModel.bmi > 0 
                                  ? 'BMI: ${userModel.bmi.toStringAsFixed(1)} (${userModel.bmiStatus})'
                                  : 'Nutrition & Fitness Enthusiast',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Stats
                Row(
                  children: [
                    _StatTile(
                      label: 'Weight',
                      value: userModel.weight > 0 ? userModel.weight.toStringAsFixed(1) : '--',
                      unit: userModel.units.contains('kg') ? 'kg' : 'lb',
                      icon: Icons.monitor_weight,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 12),
                    _StatTile(
                      label: 'Height',
                      value: userModel.height > 0 ? userModel.height.toStringAsFixed(0) : '--',
                      unit: userModel.units.contains('cm') ? 'cm' : 'in',
                      icon: Icons.height,
                      color: AppTheme.accentBlue,
                    ),
                    const SizedBox(width: 12),
                    _StatTile(
                      label: 'BMI',
                      value: userModel.bmi > 0 ? userModel.bmi.toStringAsFixed(1) : '--',
                      unit: '',
                      icon: Icons.analytics,
                      color: AppTheme.accentBlack,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 🎨 Enhanced daily goals with animation and dark mode support
                AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutQuart,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    // 🌙 Theme-aware background color
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.surfaceDarkCard 
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    // 🌙 Add border for dark mode
                    border: Theme.of(context).brightness == Brightness.dark 
                        ? Border.all(color: AppTheme.dividerDark, width: 0.5) 
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.4)
                            : Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(
                          Theme.of(context).brightness == Brightness.dark ? 0.1 : 0.05,
                        ),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.track_changes, color: AppTheme.primaryGreen),
                          const SizedBox(width: 12),
                          Text(
                            'Daily Goals',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Real-time data indicators
                      StreamBuilder(
                        stream: FirebaseService.streamFoodLogData(user.uid, DateTime.now()),
                        builder: (context, foodSnapshot) {
                          final todayCalories = foodSnapshot.data?.totalCalories ?? 0.0;
                          return NutrientIndicator(
                            icon: Icons.local_fire_department,
                            name: 'Calories',
                            value: todayCalories,
                            target: _dailyGoal.toDouble(),
                            unit: 'kcal',
                            color: AppTheme.primaryGreen,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder(
                        stream: FirebaseService.streamHydrationData(user.uid, DateTime.now()),
                        builder: (context, hydrationSnapshot) {
                          final todayWater = hydrationSnapshot.data?.waterIntake ?? 0.0;
                          final goal = hydrationSnapshot.data?.goalAmount ?? 2.5;
                          return NutrientIndicator(
                            icon: Icons.water_drop,
                            name: 'Water',
                            value: todayWater,
                            target: goal,
                            unit: 'L',
                            color: AppTheme.accentBlue,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder(
                        stream: FirebaseService.streamActivityData(user.uid, DateTime.now()),
                        builder: (context, activitySnapshot) {
                          final todaySteps = activitySnapshot.data?.steps.toDouble() ?? 0.0;
                          return NutrientIndicator(
                            icon: Icons.directions_run,
                            name: 'Steps',
                            value: todaySteps,
                            target: 10000.0,
                            unit: 'steps',
                            color: AppTheme.accentBlack,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ Edit Profile Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditProfileDialog(userModel),
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    label: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Settings
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.flag, color: AppTheme.primaryGreen),
                        title: const Text('Daily Goal'),
                        subtitle: Text('${userModel.calculatedDailyGoal} kcal'), // 🎯 Show calculated goal
                        trailing: const Icon(Icons.edit),
                        onTap: _showGoalDialog,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.straighten, color: AppTheme.accentBlue),
                        title: const Text('Units'),
                        subtitle: Text(_selectedUnit),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showUnitDialog,
                      ),
                      const Divider(height: 1),
                      // 🎨 Theme setting removed - using light theme only
                      ListTile(
                        leading: const Icon(Icons.notifications_outlined,
                            color: AppTheme.accentBlack),
                        title: const Text('Notifications'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showNotificationSettings,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_outline,
                            color: AppTheme.accentOrange),
                        title: const Text('Privacy & Security'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showPrivacySettings,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Logout
                ElevatedButton.icon(
                  onPressed: _showLogoutDialog,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // 🎨 Always use light theme colors
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight, // Always use light surface
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary, // Always use light text
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary, // Always use light text
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: const TextStyle(
                      color: AppTheme.textSecondary, // Always use light text
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
