import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/app_theme.dart';
import '../../../presentation/design_system/components/nabd_card.dart';
import '../providers/profile_provider.dart';

/// 👤 Beautiful Profile Screen matching reference design
class ProfileScreenBeautiful extends StatefulWidget {
  const ProfileScreenBeautiful({super.key});

  @override
  State<ProfileScreenBeautiful> createState() => _ProfileScreenBeautifulState();
}

class _ProfileScreenBeautifulState extends State<ProfileScreenBeautiful>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Initialize profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().refreshProfile();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Modern app bar with gradient
                _buildSliverAppBar(),
                
                // Profile content
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Profile header
                      _buildProfileHeader(provider),
                      const SizedBox(height: AppTheme.spaceXxl),
                      
                      // Health stats overview
                      _buildHealthStats(provider),
                      const SizedBox(height: AppTheme.spaceXxl),
                      
                      // Quick settings
                      _buildQuickSettings(provider),
                      const SizedBox(height: AppTheme.spaceXxl),
                      
                      // Account settings
                      _buildAccountSettings(provider),
                      const SizedBox(height: AppTheme.spaceXxxl),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🎨 Beautiful sliver app bar with gradient
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.nabdBlue,
                AppTheme.nabdPurple,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -50,
                right: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              
              // Content
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your health journey',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 👤 Profile header with avatar and basic info
  Widget _buildProfileHeader(ProfileProvider provider) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? 'No email';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
      child: NabdCard.section(
        child: Column(
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.nabdBlue, AppTheme.nabdPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.nabdBlue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            
            // User info
            Text(
              displayName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXl),
            
            // Edit profile button
            ElevatedButton.icon(
              onPressed: () => _showEditProfileDialog(provider),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.nabdBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceXl,
                  vertical: AppTheme.spaceMd,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 Health stats overview
  Widget _buildHealthStats(ProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
          child: Text(
            'Health Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceLg),
        
        Row(
          children: [
            // Steps today
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AppTheme.spaceLg, right: AppTheme.spaceSm),
                child: _buildStatCard(
                  title: 'Steps Today',
                  value: '${provider.currentSteps}',
                  subtitle: 'steps',
                  icon: Icons.directions_walk,
                  color: AppTheme.nabdBlue,
                ),
              ),
            ),
            
            // BMI
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AppTheme.spaceSm, right: AppTheme.spaceLg),
                child: _buildStatCard(
                  title: 'BMI',
                  value: provider.userModel?.bmi.toStringAsFixed(1) ?? '0.0',
                  subtitle: 'kg/m²',
                  icon: Icons.monitor_weight,
                  color: provider.getBMIStatusColor(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 📊 Individual stat card
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return NabdCard.stat(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSizeSm,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceSm),
          
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
              fontSize: AppTheme.fontSizeXs,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// ⚙️ Quick settings
  Widget _buildQuickSettings(ProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
          child: Text(
            'Quick Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceLg),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
          child: NabdCard.section(
            child: Column(
              children: [
                _buildSettingsRow(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage your alerts',
                  onTap: () => _showNotificationSettings(provider),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                ),
                const Divider(),
                _buildSettingsRow(
                  icon: Icons.palette_outlined,
                  title: 'Daily Goal',
                  subtitle: '${provider.userModel?.calculatedDailyGoal ?? 2000} kcal/day',
                  onTap: () => _showGoalDialog(provider),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                ),
                const Divider(),
                _buildSettingsRow(
                  icon: Icons.straighten_outlined,
                  title: 'Units',
                  subtitle: provider.userModel?.units ?? 'Metric',
                  onTap: () => _showUnitsDialog(provider),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 🔐 Account settings
  Widget _buildAccountSettings(ProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
          child: Text(
            'Account',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceLg),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
          child: NabdCard.section(
            child: Column(
              children: [
                _buildSettingsRow(
                  icon: Icons.security_outlined,
                  title: 'Privacy & Security',
                  subtitle: 'Password, biometric login',
                  onTap: () => _showPrivacySettings(provider),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                ),
                const Divider(),
                _buildSettingsRow(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'FAQ, contact us',
                  onTap: () {
                    // TODO: Navigate to help screen
                  },
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                ),
                const Divider(),
                _buildSettingsRow(
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  onTap: () => _showLogoutDialog(provider),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Settings row helper
  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spaceMd,
          horizontal: AppTheme.spaceSm,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive 
                    ? Colors.red.withOpacity(0.1)
                    : AppTheme.nabdBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : AppTheme.nabdBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMd),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDestructive ? Colors.red : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  // Dialog methods
  void _showEditProfileDialog(ProfileProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('Profile editing will be implemented here'),
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
              value: provider.mealRemindersEnabled,
              onChanged: (value) => provider.updateNotificationSetting('meal_reminders', value),
            ),
            SwitchListTile(
              title: const Text('Water Reminders'),
              value: provider.waterRemindersEnabled,
              onChanged: (value) => provider.updateNotificationSetting('water_reminders', value),
            ),
            SwitchListTile(
              title: const Text('Goal Achievements'),
              value: provider.goalAchievementsEnabled,
              onChanged: (value) => provider.updateNotificationSetting('goal_achievements', value),
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

  void _showGoalDialog(ProfileProvider provider) {
    int currentGoal = provider.userModel?.calculatedDailyGoal ?? 2000;
    int tempGoal = currentGoal;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set Daily Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current goal: $tempGoal kcal'),
              Slider(
                value: tempGoal.toDouble(),
                min: 1200,
                max: 3000,
                divisions: 18,
                label: '$tempGoal kcal',
                onChanged: (value) => setState(() => tempGoal = value.round()),
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
                await provider.updateDailyGoal(tempGoal);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnitsDialog(ProfileProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Units'),
        content: const Text('Units settings will be implemented here'),
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
        content: const Text('Privacy settings will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await provider.logout(context);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
