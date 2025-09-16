import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/enhanced_login_screen.dart';
import '../../modules/dashboard/screens/dashboard_navigation_screen.dart';

class MainNavigationWrapper extends StatelessWidget {
  const MainNavigationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If user is authenticated, show dashboard navigation
        if (snapshot.hasData) {
          return const DashboardNavigationScreen();
        }
        
        // Otherwise, show login screen
        return const EnhancedLoginScreen();
      },
    );
  }
}
