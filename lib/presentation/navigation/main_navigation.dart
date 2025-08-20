import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/dashboard_screen.dart';
import '../screens/home_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/profile_screen.dart';
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
      return const Center(child: Text("⚠️ User not logged in"));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("users").doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("⚠️ No user profile found in Firestore"));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        // ---- Safe converters (handle int/double/string/null) ----
        int toInt(dynamic v, int d) {
          if (v == null) return d;
          if (v is int) return v;
          if (v is num) return v.toInt();
          if (v is String) return int.tryParse(v) ?? d;
          return d;
        }

        double toDouble(dynamic v, double d) {
          if (v == null) return d;
          if (v is num) return v.toDouble();
          if (v is String) return double.tryParse(v) ?? d;
          return d;
        }

        // ---- Read with sane defaults + correct types ----
        final int age = toInt(data["age"], 25);
        final double height = toDouble(data["height"], 170.0);       // <- double
        final double idealWeight = toDouble(data["idealWeight"], 65.0); // <- double

        final pages = [
          const DashboardScreen(),
          const HomeScreen(),
          StatisticsScreen(
            age: age,
            height: height,
            idealWeight: idealWeight,
          ),
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
