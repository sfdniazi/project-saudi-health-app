import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../core/consent_manager.dart';
import '../../../presentation/widgets/nutrient_indicator.dart';
import '../../../presentation/widgets/animated_user_avatar.dart';
import '../../../services/firebase_service.dart';
import '../../../models/user_model.dart';
import '../providers/profile_provider.dart';

class ProfileScreenWithProvider extends StatefulWidget {
  const ProfileScreenWithProvider({super.key});

  @override
  State<ProfileScreenWithProvider> createState() => _ProfileScreenWithProviderState();
}

class _ProfileScreenWithProviderState extends State<ProfileScreenWithProvider> {
  @override
  void initState() {
    super.initState();
    // Initialize profile data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().refreshProfile();
    });
  }

  // ==============================
  // DIALOG METHODS
  // ==============================

  void _showGoalDialog(ProfileProvider provider, UserModel userModel) {
    int currentGoal = userModel.calculatedDailyGoal;
    int tempGoal = currentGoal;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Set Daily Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current goal: $tempGoal kcal'),
              const SizedBox(height: 16),
              Slider(
                value: tempGoal.toDouble(),
                min: 1200,
                max: 3000,
                divisions: 18,
                label: '$tempGoal kcal',
                onChanged: (value) {
                  setDialogState(() {
                    tempGoal = value.round();
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
            Consumer<ProfileProvider>(
              builder: (context, profileProvider, child) {
                return ElevatedButton(
                  onPressed: profileProvider.isBusy
                      ? null
                      : () async {
                          await profileProvider.updateDailyGoal(tempGoal);
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                  child: profileProvider.isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUnitDialog(ProfileProvider provider, UserModel userModel) {
    String selectedUnit = userModel.units;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Units'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                title: const Text('Metric (kg, cm)'),
                value: 'Metric (kg, cm)',
                groupValue: selectedUnit,
                onChanged: (value) {
                  setDialogState(() {
                    selectedUnit = value.toString();
                  });
                },
              ),
              RadioListTile(
                title: const Text('Imperial (lb, in)'),
                value: 'Imperial (lb, in)',
                groupValue: selectedUnit,
                onChanged: (value) {
                  setDialogState(() {
                    selectedUnit = value.toString();
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
            Consumer<ProfileProvider>(
              builder: (context, profileProvider, child) {
                return ElevatedButton(
                  onPressed: profileProvider.isBusy
                      ? null
                      : () async {
                          await profileProvider.updateUnits(selectedUnit);
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                  child: profileProvider.isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings(ProfileProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Meal Reminders'),
                  trailing: Switch(
                    value: profileProvider.mealRemindersEnabled,
                    onChanged: profileProvider.isBusy
                        ? null
                        : (value) => profileProvider.updateNotificationSetting('meal_reminders', value),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.water_drop_outlined),
                  title: const Text('Water Reminders'),
                  trailing: Switch(
                    value: profileProvider.waterRemindersEnabled,
                    onChanged: profileProvider.isBusy
                        ? null
                        : (value) => profileProvider.updateNotificationSetting('water_reminders', value),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.track_changes),
                  title: const Text('Goal Achievements'),
                  trailing: Switch(
                    value: profileProvider.goalAchievementsEnabled,
                    onChanged: profileProvider.isBusy
                        ? null
                        : (value) => profileProvider.updateNotificationSetting('goal_achievements', value),
                  ),
                ),
              ],
            );
          },
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

  void _showPrivacySettings(ProfileProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) {
            return Column(
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
                    value: profileProvider.biometricLoginEnabled,
                    onChanged: profileProvider.isBusy
                        ? null
                        : (value) => profileProvider.toggleBiometricLogin(value),
                  ),
                ),
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
            );
          },
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


  void _showEditProfileDialog(ProfileProvider provider, UserModel userModel) {
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
              Consumer<ProfileProvider>(
                builder: (context, profileProvider, child) {
                  return ElevatedButton(
                    onPressed: profileProvider.isBusy
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              await profileProvider.updateProfile(
                                displayName: nameController.text.trim(),
                                age: int.parse(ageController.text.trim()),
                                gender: selectedGender,
                                height: double.parse(heightController.text.trim()),
                                weight: double.parse(weightController.text.trim()),
                                idealWeight: double.parse(idealWeightController.text.trim()),
                                units: selectedUnits,
                              );
                              
                              if (mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                    child: profileProvider.isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update Profile'),
                  );
                },
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
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() {
                          isLoading = true;
                        });

                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            // Re-authenticate user with current password
                            final credential = EmailAuthProvider.credential(
                              email: user.email!,
                              password: currentPasswordController.text,
                            );
                            await user.reauthenticateWithCredential(credential);

                            // Update password
                            await user.updatePassword(newPasswordController.text);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password updated successfully!'),
                                  backgroundColor: AppTheme.primaryGreen,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          }
                        } on FirebaseAuthException catch (e) {
                          String errorMessage;
                          switch (e.code) {
                            case 'wrong-password':
                              errorMessage = 'Current password is incorrect';
                              break;
                            case 'weak-password':
                              errorMessage = 'New password is too weak';
                              break;
                            case 'requires-recent-login':
                              errorMessage = 'Please log out and log back in before changing password';
                              break;
                            default:
                              errorMessage = e.message ?? 'An error occurred';
                          }
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: AppTheme.accentOrange,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppTheme.accentOrange,
                              ),
                            );
                          }
                        }

                        setDialogState(() {
                          isLoading = false;
                        });
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(ProfileProvider provider) {
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
          Consumer<ProfileProvider>(
            builder: (context, profileProvider, child) {
              return ElevatedButton(
                onPressed: profileProvider.isBusy
                    ? null
                    : () async {
                        Navigator.pop(context); // Close dialog
                        await profileProvider.logout(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                ),
                child: profileProvider.isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Logout'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showStepCountDebugDialog(ProfileProvider provider) {
    showDialog(
      context: context,
      builder: (context) => StreamBuilder(
        stream: FirebaseService.streamActivityData(provider.currentUser!.uid, DateTime.now()),
        builder: (context, activitySnapshot) {
          final firebaseSteps = activitySnapshot.data?.steps ?? 0;
          final debugInfo = provider.getStepCountDebugInfo(firebaseSteps: firebaseSteps);
          
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.bug_report, color: AppTheme.primaryGreen),
                SizedBox(width: 8),
                Text('Step Count Debug'),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final entry in debugInfo.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 140,
                              child: Text(
                                '${entry.key}:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  provider.logStepCountVerification(firebaseSteps: firebaseSteps);
                },
                child: const Text('Log to Console'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          // Show loading indicator
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            );
          }

          // Show error state
          if (provider.hasError && provider.userModel == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: AppTheme.accentOrange, size: 48),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage ?? 'Unknown error occurred'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refreshProfile(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Show message snackbars
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (provider.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.successMessage!),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
              provider.clearMessages();
            } else if (provider.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage!),
                  backgroundColor: AppTheme.accentOrange,
                ),
              );
              provider.clearMessages();
            }
          });

          // If no user model, show basic UI with logout option
          if (provider.userModel == null) {
            return Column(
              children: [
                // Header
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
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () => _showLogoutDialog(provider),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text('Please log in to view profile'),
                  ),
                ),
              ],
            );
          }

          final userModel = provider.userModel!;
          final user = provider.currentUser!;

          return Column(
            children: [
              // Header
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
                    // Debug button (only in debug mode)
                    if (kDebugMode) 
                      IconButton(
                        icon: const Icon(Icons.bug_report, color: Colors.white70),
                        onPressed: () => _showStepCountDebugDialog(provider),
                        tooltip: 'Step Count Debug Info',
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: provider.isBusy
                          ? null
                          : () => provider.refreshProfile(),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Profile Header
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutBack,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                            blurRadius: 40,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AnimatedUserAvatar(
                            displayName: userModel.displayName,
                            email: userModel.email,
                            age: userModel.age,
                            gender: userModel.gender,
                            size: 80,
                            showPulse: true,
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
                          color: provider.getBMIStatusColor(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Daily Goals Section with StreamBuilder
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutQuart,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.surfaceDarkCard
                            : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Theme.of(context).brightness == Brightness.dark
                            ? Border.all(color: AppTheme.dividerDark, width: 0.5)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
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
                          // Calories
                          StreamBuilder(
                            stream: FirebaseService.streamFoodLogData(user.uid, DateTime.now()),
                            builder: (context, foodSnapshot) {
                              final todayCalories = foodSnapshot.data?.totalCalories ?? 0.0;
                              return NutrientIndicator(
                                icon: Icons.local_fire_department,
                                name: 'Calories',
                                value: todayCalories,
                                target: userModel.calculatedDailyGoal.toDouble(),
                                unit: 'kcal',
                                color: AppTheme.primaryGreen,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          // Water
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
                          // Steps - Real-time with Firebase fallback
                          Consumer<ProfileProvider>(
                            builder: (context, profileProvider, child) {
                              return StreamBuilder(
                                stream: FirebaseService.streamActivityData(user.uid, DateTime.now()),
                                builder: (context, activitySnapshot) {
                                  final firebaseSteps = activitySnapshot.data?.steps ?? 0;
                                  final realTimeSteps = profileProvider.getRealTimeStepCount(firebaseSteps: firebaseSteps);
                                  final isRealTime = profileProvider.hasRealTimeStepData;
                                  
                                  return Column(
                                    children: [
                                      NutrientIndicator(
                                        icon: Icons.directions_run,
                                        name: 'Steps',
                                        value: realTimeSteps.toDouble(),
                                        target: 10000.0,
                                        unit: 'steps',
                                        color: isRealTime ? AppTheme.primaryGreen : AppTheme.accentBlack,
                                      ),
                                      // Real-time indicator
                                      if (isRealTime) 
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: AppTheme.primaryGreen,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Real-time tracking',
                                                style: TextStyle(
                                                  color: AppTheme.primaryGreen,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Edit Profile Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: provider.isBusy
                            ? null
                            : () => _showEditProfileDialog(provider, userModel),
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
                            subtitle: Text('${userModel.calculatedDailyGoal} kcal'),
                            trailing: const Icon(Icons.edit),
                            onTap: provider.isBusy
                                ? null
                                : () => _showGoalDialog(provider, userModel),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.straighten, color: AppTheme.accentBlue),
                            title: const Text('Units'),
                            subtitle: Text(userModel.units),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: provider.isBusy
                                ? null
                                : () => _showUnitDialog(provider, userModel),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.notifications_outlined,
                                color: AppTheme.accentBlack),
                            title: const Text('Notifications'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showNotificationSettings(provider),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.lock_outline,
                                color: AppTheme.accentOrange),
                            title: const Text('Privacy & Security'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showPrivacySettings(provider),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Logout Button
                    ElevatedButton.icon(
                      onPressed: provider.isBusy
                          ? null
                          : () => _showLogoutDialog(provider),
                      icon: provider.profileState.isLoggingOut
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.logout),
                      label: Text(
                        provider.profileState.isLoggingOut ? 'Logging out...' : 'Logout'
                      ),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// StatTile Widget (same as before but moved here)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDarkCard : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: AppTheme.dividerDark, width: 0.5) : null,
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.06),
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
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
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
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                  ),
                ),
                if (unit.isNotEmpty) ...[ 
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
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
