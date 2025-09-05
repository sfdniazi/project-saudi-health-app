import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'core/error_handler.dart';
import 'presentation/screens/start_page.dart';
import 'modules/auth/screens/login_screen.dart';
import 'modules/auth/providers/auth_provider.dart' as custom_auth;
import 'modules/dashboard/providers/dashboard_provider.dart';
import 'modules/home/providers/home_provider.dart';
import 'modules/activity/providers/activity_provider.dart';
import 'modules/food_logging/providers/food_logging_provider.dart';
import 'modules/profile/providers/profile_provider.dart';
import 'modules/ai_recommendations/providers/ai_recommendations_provider.dart';
import 'services/global_step_counter_provider.dart';
import 'presentation/navigation/main_navigation.dart';
import 'presentation/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  ErrorHandler.initialize();
  FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  runApp(const NabdAlHayahApp());
}

class NabdAlHayahApp extends StatefulWidget {
  const NabdAlHayahApp({super.key});

  @override
  State<NabdAlHayahApp> createState() => _NabdAlHayahAppState();
}

class _NabdAlHayahAppState extends State<NabdAlHayahApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => custom_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => FoodLoggingProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => AIRecommendationsProvider()),
        ChangeNotifierProvider(create: (_) => GlobalStepCounterProvider()),
      ],
      child: MaterialApp(
        title: 'Nabd Al-Hayah',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        home: const RootScreen(),
      ),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData) {
          return const MainNavigationWithStepCounter();
        }
        return const StartPage();
      },
    );
  }
}

class MainNavigationWithStepCounter extends StatefulWidget {
  const MainNavigationWithStepCounter({super.key});

  @override
  State<MainNavigationWithStepCounter> createState() => _MainNavigationWithStepCounterState();
}

class _MainNavigationWithStepCounterState extends State<MainNavigationWithStepCounter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGlobalStepCounter();
    });
  }

  Future<void> _initializeGlobalStepCounter() async {
    try {
      final globalStepCounter = context.read<GlobalStepCounterProvider>();
      await globalStepCounter.initialize();
      context.read<HomeProvider>().setGlobalStepCounter(globalStepCounter);
      context.read<DashboardProvider>().setGlobalStepCounter(globalStepCounter);
      context.read<ProfileProvider>().setGlobalStepCounter(globalStepCounter);
      context.read<ActivityProvider>().setGlobalStepCounter(globalStepCounter);
    } catch (e) {
      debugPrint('Failed to initialize global step counter: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MainNavigation();
  }
}
