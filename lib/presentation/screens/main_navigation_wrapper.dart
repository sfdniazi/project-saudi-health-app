import 'package:flutter/material.dart';
import 'login_screen.dart';

class MainNavigationWrapper extends StatelessWidget {
  const MainNavigationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Start with login screen for proper authentication flow
    return const LoginScreen();
  }
}
