import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';

// Use the new dashboard navigation screen
import '../../modules/dashboard/screens/dashboard_navigation_screen.dart';
import '../../modules/auth/providers/auth_provider.dart' as custom_auth;

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  @override
  Widget build(BuildContext context) {
    return Consumer<custom_auth.AuthProvider>(
      builder: (context, authProvider, child) {
        // Check if user is authenticated
        if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
          return Container(
            decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "⚠️ User not authenticated",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please log in to continue",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show loading state if auth is still loading
        if (authProvider.isLoading) {
          return Container(
            decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "Loading...",
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

        // User is authenticated, show dashboard navigation
        return const DashboardNavigationScreen();
      },
    );
  }
}
