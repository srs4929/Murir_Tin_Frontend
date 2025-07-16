import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _titleController;
  late AnimationController _subtitleController;
  late AnimationController _backgroundController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _backgroundGradient;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    // Title animations
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOutBack),
    );

    _titleOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _titleController, curve: Curves.easeIn));

    // Subtitle animations
    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeOut),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeIn),
    );

    // Background gradient animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _backgroundGradient = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );
  }

  void _startAnimationSequence() {
    // Start background animation immediately
    _backgroundController.forward();

    // Staggered animation sequence
    Timer(const Duration(milliseconds: 500), () {
      _logoController.forward();
    });

    Timer(const Duration(milliseconds: 1200), () {
      _titleController.forward();
    });

    Timer(const Duration(milliseconds: 1800), () {
      _subtitleController.forward();
    });

    // Navigate to next screen
    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => widget.nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(
                    const Color(0xFF0A0E27),
                    const Color(0xFF14213D),
                    _backgroundGradient.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF2E3A87),
                    const Color(0xFF4B6EAF),
                    _backgroundGradient.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF1A2F5C),
                    const Color(0xFF6B8AC7),
                    _backgroundGradient.value,
                  )!,
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoOpacity.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Image.asset(
                                  "assets/images/logo.png",
                                  width: 180,
                                  height: 180,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      // Animated Title
                      AnimatedBuilder(
                        animation: _titleController,
                        builder: (context, child) {
                          return SlideTransition(
                            position: _titleSlide,
                            child: FadeTransition(
                              opacity: _titleOpacity,
                              child: ShaderMask(
                                shaderCallback:
                                    (bounds) => const LinearGradient(
                                      colors: [Colors.white, Color(0xFFE8F4FD)],
                                    ).createShader(bounds),
                                child: Text(
                                  'Murir Tin',
                                  style: GoogleFonts.poppins(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 15),

                      // Animated Subtitle
                      AnimatedBuilder(
                        animation: _subtitleController,
                        builder: (context, child) {
                          return SlideTransition(
                            position: _subtitleSlide,
                            child: FadeTransition(
                              opacity: _subtitleOpacity,
                              child: Text(
                                'Smart Bus Transport System',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 60),

                      // Animated Loading Indicator
                      AnimatedBuilder(
                        animation: _subtitleController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _subtitleOpacity,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.1),
                                    Colors.white.withValues(alpha: 0.3),
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
