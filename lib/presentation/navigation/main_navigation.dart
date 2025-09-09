import 'package:flutter/material.dart';
import '../../modules/dashboard/screens/dashboard_navigation_screen.dart';

/// MainNavigation - Post-authentication navigation shell
/// 
/// SECURITY: This widget assumes user is authenticated.
/// Authentication gating is handled by RootScreen in main.dart
class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    // User is authenticated at this point, show dashboard navigation
    return const DashboardNavigationScreen();
  }
}
