import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../screens/compact_login_screen.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _floatController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _floatAnimation = Tween<double>(
      begin: -10.0, 
      end: 10.0
    ).animate(CurvedAnimation(
      parent: _floatController, 
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const CompactLoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EB), // Cream/beige background
      body: Stack(
        children: [
          // Background curved shapes
          Positioned(
            bottom: -50,
            right: -80,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: 300,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B47), // Coral color
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            right: -20,
            child: Transform.rotate(
              angle: 0.3,
              child: Container(
                width: 180,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFB8860B), // Brown/golden color
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
            ),
          ),
          Container(
            child: SafeArea(
              child: AnimatedBuilder(
                animation: Listenable.merge([_fadeController, _scaleController, _floatController]),
                builder: (context, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        
                        // Illustration section with floating items
                        Expanded(
                          flex: 3,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Main illustration container
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Container(
                                    width: 280,
                                    height: 280,
                                    child: Stack(
                                      children: [
                                        // Basketball
                                        Positioned(
                                          top: 20,
                                          left: 20,
                                          child: Transform.translate(
                                            offset: Offset(0, _floatAnimation.value),
                                            child: _buildBasketball(),
                                          ),
                                        ),
                                        // Water glass
                                        Positioned(
                                          top: 10,
                                          right: 40,
                                          child: Transform.translate(
                                            offset: Offset(0, -_floatAnimation.value * 0.7),
                                            child: _buildWaterGlass(),
                                          ),
                                        ),
                                        // Eggplant
                                        Positioned(
                                          left: 60,
                                          top: 100,
                                          child: Transform.translate(
                                            offset: Offset(0, _floatAnimation.value * 0.5),
                                            child: _buildEggplant(),
                                          ),
                                        ),
                                        // Broccoli
                                        Positioned(
                                          bottom: 80,
                                          left: 20,
                                          child: Transform.translate(
                                            offset: Offset(0, -_floatAnimation.value * 0.8),
                                            child: _buildBroccoli(),
                                          ),
                                        ),
                                        // Light bulb
                                        Positioned(
                                          bottom: 60,
                                          right: 30,
                                          child: Transform.translate(
                                            offset: Offset(0, _floatAnimation.value * 0.6),
                                            child: _buildLightBulb(),
                                          ),
                                        ),
                                        // Stars scattered around
                                        ...List.generate(5, (index) => 
                                          Positioned(
                                            top: 30 + (index * 40.0),
                                            right: 10 + (index * 30.0),
                                            child: Transform.translate(
                                              offset: Offset(0, sin(index + _floatAnimation.value) * 5),
                                              child: Icon(
                                                Icons.star,
                                                color: const Color(0xFFFFD700),
                                                size: 12 + (index % 3) * 4,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                        const SizedBox(height: 40),
                        
                        // "Nabd Al-Hayah" title
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: const Text(
                            'Nabd Al-Hayah',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2D2D2D), // Dark text
                              letterSpacing: -1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Subtitle
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: const Text(
                            'Take charge of your health:\nall aspects, one app!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF666666),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      
                        const SizedBox(height: 60),
                        
                        // "Let's start!" button
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            child: ElevatedButton(
                              onPressed: _navigateToLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2D2D2D), // Black button
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "Let's start!",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Basketball illustration
  Widget _buildBasketball() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35),
        shape: BoxShape.circle,
      ),
      child: CustomPaint(
        painter: BasketballPainter(),
      ),
    );
  }

  // Water glass illustration
  Widget _buildWaterGlass() {
    return Container(
      width: 30,
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFF87CEEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4A90E2), width: 2),
      ),
    );
  }

  // Eggplant illustration
  Widget _buildEggplant() {
    return Container(
      width: 35,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFF6A4C93),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 15,
          height: 15,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // Broccoli illustration
  Widget _buildBroccoli() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 35,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        Container(
          width: 8,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF8BC34A),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  // Light bulb illustration
  Widget _buildLightBulb() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 35,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEB3B),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        Container(
          width: 20,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF757575),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

// Custom painter for basketball lines
class BasketballPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw basketball lines
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    
    // Draw curved lines
    final path1 = Path();
    path1.moveTo(0, size.height / 2);
    path1.quadraticBezierTo(size.width / 2, 0, size.width, size.height / 2);
    canvas.drawPath(path1, paint);
    
    final path2 = Path();
    path2.moveTo(0, size.height / 2);
    path2.quadraticBezierTo(size.width / 2, size.height, size.width, size.height / 2);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
