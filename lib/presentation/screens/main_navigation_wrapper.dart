import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../modules/auth/screens/login_screen.dart';
import '../../modules/auth/providers/auth_provider.dart' as custom_auth;
import '../../modules/dashboard/screens/dashboard_navigation_screen.dart';

class MainNavigationWrapper extends StatelessWidget {
  const MainNavigationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<custom_auth.AuthProvider>(
      builder: (context, authProvider, child) {
        // If user is authenticated, show dashboard navigation
        if (authProvider.isAuthenticated && authProvider.currentUser != null) {
          return const DashboardNavigationScreen();
        }
        
        // Otherwise, show login screen
        return const LoginScreen();
      },
    );
  }
}
