import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_theme.dart';
import '../widgets/nutrient_indicator.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';

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
            onPressed: () async {
              await _auth.signOut();
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
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
          // Custom App Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: const BoxDecoration(
              gradient: AppTheme.headerGradient,
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
                _dailyGoal = userModel.dailyGoal;
                _selectedUnit = userModel.units;
                _notificationsEnabled = userModel.notificationsEnabled;

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: Text(
                          userModel.displayName.isNotEmpty
                              ? userModel.displayName.substring(0, 1).toUpperCase()
                              : (user.email?.substring(0, 1).toUpperCase() ?? 'U'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
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
                            Text(
                              userModel.email.isNotEmpty 
                                  ? userModel.email 
                                  : (user.email ?? 'No email'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Nutrition & Fitness Enthusiast',
                              style: TextStyle(
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

                // Daily Goals
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
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
                        subtitle: Text('$_dailyGoal kcal'),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
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
                  style: TextStyle(
                    color: AppTheme.textSecondary,
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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
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
