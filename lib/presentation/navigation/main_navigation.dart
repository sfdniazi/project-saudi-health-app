import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_theme.dart';

import '../screens/home_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/activity_screen.dart';
import '../screens/food_logging_screen.dart';
import '../widgets/animated_bottom_nav.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  void _onTap(int idx) => setState(() => _selectedIndex = idx);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Container(
        decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        child: Center(
          child: Text(
            "⚠️ User not logged in",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("users").doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
            child: Center(
              child: Text(
                "⚠️ No user profile found in Firestore",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        // User profile exists, show the main navigation

        final pages = [
          const HomeScreen(),
          const ActivityScreen(), 
          const FoodLoggingScreen(),
          const StatisticsScreen(),
          const ProfileScreen(),
        ];

        return Scaffold(
          body: pages[_selectedIndex],
          bottomNavigationBar: AnimatedBottomNav(
            currentIndex: _selectedIndex,
            onTap: _onTap,
          ),
        );
      },
    );
  }
}
