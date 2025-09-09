import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_recommendations_provider.dart';
import 'ai_recommendations_screen.dart';

/// Wrapper screen that provides the AIRecommendationsProvider
/// This follows the same pattern as other screens in the app
class AIRecommendationsScreenWithProvider extends StatelessWidget {
  const AIRecommendationsScreenWithProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AIRecommendationsProvider(),
      child: const AIRecommendationsScreen(),
    );
  }
}
