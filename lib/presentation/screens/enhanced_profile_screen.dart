import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/app_theme.dart';
import '../../core/consent_manager.dart';
import '../widgets/nutrient_indicator.dart';
import '../widgets/animated_user_avatar.dart';
import '../../services/firebase_service.dart';
import '../../services/global_step_counter_provider.dart';
import '../../modules/profile/providers/profile_provider.dart';

/// Enhanced Profile Screen with restored functionality and pixel-perfect design
class EnhancedProfileScreen extends StatefulWidget {
  const EnhancedProfileScreen({super.key});

  @override
  State<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen>
    with TickerProviderStateMixin {
  
  // Animation controllers for smooth animations
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  // Current theme mode for theme switching
  ThemeMode _currentThemeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentTheme();
    
    // Connect to global step counter if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectToGlobalStepCounter();
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  Future<void> _loadCurrentTheme() async {
    final savedTheme = await AppTheme.getSavedThemeMode();
    setState(() {
      _currentThemeMode = savedTheme;
    });
  }

  void _connectToGlobalStepCounter() {
    try {
      final globalStepCounter = Provider.of<GlobalStepCounterProvider>(
        context, 
        listen: false
      );
      final profileProvider = Provider.of<ProfileProvider>(
        context, 
        listen: false
      );
      
      profileProvider.setGlobalStepCounter(globalStepCounter);
    } catch (e) {
      debugPrint('Failed to connect to GlobalStepCounterProvider: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          // Show loading state
          if (profileProvider.isLoading) {
            return _buildLoadingState();
          }

          // Show error state
          if (profileProvider.hasError && profileProvider.userModel == null) {
            return _buildErrorState(profileProvider);
          }

          // Show profile content
          return _buildProfileContent(profileProvider);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.getHeaderGradient(context),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading your profile...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ProfileProvider profileProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.getHeaderGradient(context),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load profile',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                profileProvider.errorMessage ?? 'An unknown error occurred',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => profileProvider.refreshProfile(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(ProfileProvider profileProvider) {
    final userModel = profileProvider.userModel;
    final user = profileProvider.currentUser;

    // Show message snackbars
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (profileProvider.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileProvider.successMessage!),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        profileProvider.clearMessages();
      } else if (profileProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileProvider.errorMessage!),
            backgroundColor: AppTheme.accentOrange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        profileProvider.clearMessages();
      }
    });

    if (userModel == null || user == null) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Enhanced Header with gradient
          _buildEnhancedHeader(profileProvider, userModel, user),
          
          // Content
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.backgroundDark
                        : AppTheme.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: _buildProfileContentBody(profileProvider, userModel, user),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
                onPressed: () => _showLogoutDialog(),
              ),
            ],
          ),
        ),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 64,
                  color: AppTheme.textLight,
                ),
                SizedBox(height: 16),
                Text(
                  'Profile not available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please log in to view your profile',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedHeader(
    ProfileProvider profileProvider,
    dynamic userModel,
    User user,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        gradient: AppTheme.getHeaderGradient(context),
      ),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              Text(
                'Profile',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // Debug button (only in debug mode)
              if (kDebugMode)
                IconButton(
                  icon: const Icon(
                    Icons.bug_report,
                    color: Colors.white70,
                  ),
                  onPressed: () => _showStepCountDebugDialog(profileProvider),
                  tooltip: 'Debug Info',
                ),
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
                onPressed: profileProvider.isBusy
                    ? null
                    : () => profileProvider.refreshProfile(),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Enhanced profile card
          _buildProfileCard(userModel, user, profileProvider),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    dynamic userModel, 
    User user,
    ProfileProvider profileProvider,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated avatar
          AnimatedUserAvatar(
            displayName: userModel.displayName,
            email: userModel.email,
            age: userModel.age,
            gender: userModel.gender,
            size: 80,
            showPulse: true,
          ),
          
          const SizedBox(width: 20),
          
          // User info
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    userModel.bmi > 0
                        ? 'BMI: ${userModel.bmi.toStringAsFixed(1)} (${userModel.bmiStatus})'
                        : 'Fitness Enthusiast',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContentBody(
    ProfileProvider profileProvider,
    dynamic userModel,
    User user,
  ) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Quick Stats
        _buildQuickStats(userModel),
        
        const SizedBox(height: 24),
        
        // Daily Goals Section
        _buildDailyGoalsSection(profileProvider, userModel, user),
        
        const SizedBox(height: 24),
        
        // Edit Profile Button
        _buildEditProfileButton(profileProvider, userModel),
        
        const SizedBox(height: 24),
        
        // Settings Section
        _buildSettingsSection(profileProvider, userModel),
        
        const SizedBox(height: 24),
        
        // Logout Button
        _buildLogoutButton(profileProvider),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQuickStats(dynamic userModel) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Weight',
            value: userModel.weight > 0
                ? userModel.weight.toStringAsFixed(1)
                : '--',
            unit: userModel.units.contains('kg') ? 'kg' : 'lb',
            icon: Icons.monitor_weight,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Height',
            value: userModel.height > 0
                ? userModel.height.toStringAsFixed(0)
                : '--',
            unit: userModel.units.contains('cm') ? 'cm' : 'in',
            icon: Icons.height,
            color: AppTheme.accentBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              return _StatTile(
                label: 'BMI',
                value: userModel.bmi > 0
                    ? userModel.bmi.toStringAsFixed(1)
                    : '--',
                unit: '',
                icon: Icons.analytics,
                color: provider.getBMIStatusColor(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyGoalsSection(
    ProfileProvider profileProvider,
    dynamic userModel,
    User user,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutQuart,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDarkCard : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: AppTheme.dividerDark, width: 0.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.08),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.track_changes,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Daily Goals',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Calories indicator
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
          
          const SizedBox(height: 16),
          
          // Water indicator
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
          
          const SizedBox(height: 16),
          
          // Steps indicator with real-time data
          Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              return StreamBuilder(
                stream: FirebaseService.streamActivityData(user.uid, DateTime.now()),
                builder: (context, activitySnapshot) {
                  final firebaseSteps = activitySnapshot.data?.steps ?? 0;
                  final realTimeSteps = provider.getRealTimeStepCount(
                    firebaseSteps: firebaseSteps,
                  );
                  final isRealTime = provider.hasRealTimeStepData;

                  return Column(
                    children: [
                      NutrientIndicator(
                        icon: Icons.directions_run,
                        name: 'Steps',
                        value: realTimeSteps.toDouble(),
                        target: 10000.0,
                        unit: 'steps',
                        color: isRealTime
                            ? AppTheme.primaryGreen
                            : AppTheme.accentBlack,
                      ),
                      
                      // Real-time indicator
                      if (isRealTime)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                              const SizedBox(width: 6),
                              Text(
                                'Real-time tracking active',
                                style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontSize: 11,
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
    );
  }

  Widget _buildEditProfileButton(
    ProfileProvider profileProvider,
    dynamic userModel,
  ) {
    return Container(
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
        onPressed: profileProvider.isBusy
            ? null
            : () => _showEditProfileDialog(profileProvider, userModel),
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
    );
  }

  Widget _buildSettingsSection(
    ProfileProvider profileProvider,
    dynamic userModel,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDarkCard : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: AppTheme.dividerDark, width: 0.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.flag,
            iconColor: AppTheme.primaryGreen,
            title: 'Daily Goal',
            subtitle: '${userModel.calculatedDailyGoal} kcal',
            trailing: const Icon(Icons.edit),
            onTap: profileProvider.isBusy
                ? null
                : () => _showGoalDialog(profileProvider, userModel),
          ),
          
          const Divider(height: 1),
          
          _SettingsTile(
            icon: Icons.straighten,
            iconColor: AppTheme.accentBlue,
            title: 'Units',
            subtitle: userModel.units,
            trailing: const Icon(Icons.chevron_right),
            onTap: profileProvider.isBusy
                ? null
                : () => _showUnitDialog(profileProvider, userModel),
          ),
          
          const Divider(height: 1),
          
          _SettingsTile(
            icon: Icons.palette_outlined,
            iconColor: AppTheme.primaryGreen,
            title: 'Theme',
            subtitle: _getThemeModeLabel(_currentThemeMode),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeSettings(),
          ),
          
          const Divider(height: 1),
          
          _SettingsTile(
            icon: Icons.notifications_outlined,
            iconColor: AppTheme.accentBlack,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNotificationSettings(profileProvider),
          ),
          
          const Divider(height: 1),
          
          _SettingsTile(
            icon: Icons.lock_outline,
            iconColor: AppTheme.accentOrange,
            title: 'Privacy & Security',
            subtitle: 'Biometrics and data privacy',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPrivacySettings(profileProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(ProfileProvider profileProvider) {
    return ElevatedButton.icon(
      onPressed: profileProvider.isBusy
          ? null
          : () => _showLogoutDialog(),
      icon: profileProvider.profileState.isLoggingOut
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
        profileProvider.profileState.isLoggingOut ? 'Logging out...' : 'Logout',
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: AppTheme.accentOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // Dialog methods
  void _showEditProfileDialog(ProfileProvider provider, dynamic userModel) {
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
        builder: (context, setDialogState) {
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
                          setDialogState(() {
                            selectedGender = value ?? 'Male';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: heightController,
                        decoration: InputDecoration(
                          labelText: selectedUnits.contains('Metric')
                              ? 'Height (cm)'
                              : 'Height (in)',
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
                          labelText: selectedUnits.contains('Metric')
                              ? 'Weight (kg)'
                              : 'Weight (lb)',
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
                          labelText: selectedUnits.contains('Metric')
                              ? 'Goal Weight (kg)'
                              : 'Goal Weight (lb)',
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
                          setDialogState(() {
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
                    Navigator.pop(context);
                    await provider.updateProfile(
                      displayName: nameController.text.trim(),
                      age: int.parse(ageController.text.trim()),
                      gender: selectedGender,
                      height: double.parse(heightController.text.trim()),
                      weight: double.parse(weightController.text.trim()),
                      idealWeight: double.parse(idealWeightController.text.trim()),
                      units: selectedUnits,
                    );
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

  void _showGoalDialog(ProfileProvider provider, dynamic userModel) {
    int dailyGoal = userModel.calculatedDailyGoal;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Set Daily Goal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current goal: $dailyGoal kcal'),
                const SizedBox(height: 16),
                Slider(
                  value: dailyGoal.toDouble(),
                  min: 1200,
                  max: 3000,
                  divisions: 36,
                  label: '$dailyGoal kcal',
                  onChanged: (value) {
                    setDialogState(() {
                      dailyGoal = value.round();
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
                onPressed: () {
                  Navigator.pop(context);
                  provider.updateDailyGoal(dailyGoal);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUnitDialog(ProfileProvider provider, dynamic userModel) {
    String selectedUnit = userModel.units;

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
              groupValue: selectedUnit,
              onChanged: (value) {
                if (value != null) {
                  Navigator.pop(context);
                  provider.updateUnits(value);
                }
              },
            ),
            RadioListTile(
              title: const Text('Imperial (lb, in)'),
              value: 'Imperial (lb, in)',
              groupValue: selectedUnit,
              onChanged: (value) {
                if (value != null) {
                  Navigator.pop(context);
                  provider.updateUnits(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

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
                groupValue: _currentThemeMode,
                onChanged: (value) {
                  if (value != null) {
                    AppTheme.saveThemeMode(value);
                    setState(() {
                      _currentThemeMode = value;
                    });
                    setDialogState(() {});
                    Navigator.pop(context);
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
                groupValue: _currentThemeMode,
                onChanged: (value) {
                  if (value != null) {
                    AppTheme.saveThemeMode(value);
                    setState(() {
                      _currentThemeMode = value;
                    });
                    setDialogState(() {});
                    Navigator.pop(context);
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
                groupValue: _currentThemeMode,
                onChanged: (value) {
                  if (value != null) {
                    AppTheme.saveThemeMode(value);
                    setState(() {
                      _currentThemeMode = value;
                    });
                    setDialogState(() {});
                    Navigator.pop(context);
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

  void _showNotificationSettings(ProfileProvider provider) {
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
              value: provider.mealRemindersEnabled,
              onChanged: (value) {
                provider.updateNotificationSetting('meal_reminders', value);
              },
            ),
            SwitchListTile(
              title: const Text('Water Reminders'),
              subtitle: const Text('Stay hydrated throughout the day'),
              value: provider.waterRemindersEnabled,
              onChanged: (value) {
                provider.updateNotificationSetting('water_reminders', value);
              },
            ),
            SwitchListTile(
              title: const Text('Goal Achievements'),
              subtitle: const Text('Celebrate your milestones'),
              value: provider.goalAchievementsEnabled,
              onChanged: (value) {
                provider.updateNotificationSetting('goal_achievements', value);
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

  void _showPrivacySettings(ProfileProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('Biometric Login'),
              trailing: Switch(
                value: provider.biometricLoginEnabled,
                onChanged: (value) {
                  provider.toggleBiometricLogin(value);
                },
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.privacy_tip,
                color: AppTheme.primaryGreen,
              ),
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
        stream: FirebaseService.streamActivityData(
          provider.currentUser!.uid,
          DateTime.now(),
        ),
        builder: (context, activitySnapshot) {
          final firebaseSteps = activitySnapshot.data?.steps ?? 0;
          final debugInfo = provider.getStepCountDebugInfo(
            firebaseSteps: firebaseSteps,
          );

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

  String _getThemeModeLabel(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.system:
        return 'System Default';
    }
  }
}

// Custom Widgets

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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDarkCard : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: AppTheme.dividerDark, width: 0.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.06),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
    );
  }
}
