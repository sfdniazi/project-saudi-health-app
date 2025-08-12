import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'presentation/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NabdAlHayahApp());
}

class NabdAlHayahApp extends StatelessWidget {
  const NabdAlHayahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nabd Al-Hayah',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
