import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool showHome;
  const SplashScreen({super.key, required this.showHome});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _coreController;
  late AnimationController _orbitController;
  late AnimationController _fadeController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _coreOpacity;
  late Animation<double> _orbitsOpacity;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // 1. Core Pulse Animation
    _coreController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _coreController, curve: Curves.easeInOut),
    );

    // 2. Orbit Rotation Animation
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // 3. Fade Sequence Controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _coreOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.1, 0.3, curve: Curves.easeIn),
      ),
    );

    _orbitsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.23, 0.43, curve: Curves.easeIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.66, 1.0, curve: Curves.easeIn),
      ),
    );

    _fadeController.forward();

    // Navigation logic after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                widget.showHome
                ? const LoginScreen()
                : const OnboardingScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 1.05, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _coreController.dispose();
    _orbitController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02131D),
      body: Stack(
        children: [
          // 1. Background Gradient & Radial Glow
          _buildBackground(),

          // 2. Animated Orbit System
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_orbitController, _orbitsOpacity]),
              builder: (context, child) {
                return Opacity(
                  opacity: _orbitsOpacity.value,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: OrbitPainter(rotation: _orbitController.value),
                      size: const Size(300, 300),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Central AI Core
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseAnimation, _coreOpacity]),
              builder: (context, child) {
                return Opacity(
                  opacity: _coreOpacity.value,
                  child: Transform.scale(
                    scale: _pulseAnimation.value,
                    child: _buildCore(),
                  ),
                );
              },
            ),
          ),

          // 4. Typography
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _textOpacity,
              builder: (context, child) {
                return Opacity(
                  opacity: _textOpacity.value,
                  child: Column(
                    children: [
                      Text(
                        'KANMANTR AI',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Roadmap Intelligence Engine',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [Color(0xFF031F2D), Color(0xFF02131D)],
        ),
      ),
      child: Center(
        child: Container(
          width: 400,
          height: 400,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF00D1FF).withOpacity(0.08),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCore() {
    return Container(
      width: 120,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D1FF).withOpacity(0.3),
            blurRadius: 50,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Text(
        'AI',
        style: GoogleFonts.orbitron(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 2,
          shadows: [
            Shadow(
              color: const Color(0xFF00D1FF).withOpacity(0.8),
              blurRadius: 15,
            ),
          ],
        ),
      ),
    );
  }
}

class OrbitPainter extends CustomPainter {
  final double rotation;

  OrbitPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Orbit 1: Clockwise, Slow
    _drawOrbit(
      canvas,
      center,
      140,
      80,
      rotation * 2 * math.pi,
      const Color(0xFF00D1FF).withOpacity(0.3),
      1.2,
    );

    // Orbit 2: Counterclockwise, Medium
    _drawOrbit(
      canvas,
      center,
      110,
      150,
      -rotation * 3 * math.pi,
      const Color(0xFF00D1FF).withOpacity(0.22),
      1.2,
    );

    // Orbit 3: Tilted, Fast
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4);
    canvas.translate(-center.dx, -center.dy);
    _drawOrbit(
      canvas,
      center,
      160,
      60,
      rotation * 5 * math.pi,
      const Color(0xFF00D1FF).withOpacity(0.18),
      1.2,
    );
    canvas.restore();
  }

  void _drawOrbit(
    Canvas canvas,
    Offset center,
    double radiusX,
    double radiusY,
    double angle,
    Color color,
    double strokeWidth,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromCenter(
      center: center,
      width: radiusX * 2,
      height: radiusY * 2,
    );
    canvas.drawOval(rect, paint);

    // Draw Electron
    final electronPaint = Paint()
      ..color = const Color(0xFF00D1FF)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final x = center.dx + radiusX * math.cos(angle);
    final y = center.dy + radiusY * math.sin(angle);

    canvas.drawCircle(Offset(x, y), 4, electronPaint);
    canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant OrbitPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}
