import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';
import '../services/auth_service.dart';

class LogoutScreen extends StatefulWidget {
  @override
  _LogoutScreenState createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _logoFloatController;
  late AnimationController _progressController;
  late AnimationController _dotsController;
  late Animation<double> _logoFloatAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _logoFloatController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _dotsController = AnimationController(
      duration: Duration(milliseconds: 1400),
      vsync: this,
    );

    _logoFloatAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _logoFloatController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _startLogoutProcess();
  }

  void _startLogoutProcess() async {
    // Iniciar animaciones
    _logoFloatController.repeat(reverse: true);
    _dotsController.repeat();

    await Future.delayed(Duration(milliseconds: 300));
    _progressController.forward();

    // Ejecutar logout
    await _authService.logout();

    // Esperar a que termine la animación
    await Future.delayed(Duration(milliseconds: 1500));
    _navigateToLogin();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoFloatController.dispose();
    _progressController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Radial Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF1a4d7a), // Lighter blue center
                  Color(0xFF0d2847), // Mid blue
                  Color(0xFF051729), // Dark blue edges
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Starfield Effect
          CustomPaint(
            painter: StarfieldPainter(),
            size: Size.infinite,
          ),

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with Focus Frame
                AnimatedBuilder(
                  animation: _logoFloatAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _logoFloatAnimation.value),
                      child: child,
                    );
                  },
                  child: _buildLogoWithFocusFrame(),
                ),

                SizedBox(height: 24),

                // Brand Name
                Text(
                  'RETISCAN',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 6,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Color(0xFF64C8FF).withOpacity(0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),

                // Progress Section
                _buildProgressSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoWithFocusFrame() {
    return Container(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          // Focus Frame Corners
          Positioned(
            top: -10,
            left: -10,
            child: _buildCorner(topLeft: true),
          ),
          Positioned(
            top: -10,
            right: -10,
            child: _buildCorner(topRight: true),
          ),
          Positioned(
            bottom: -10,
            left: -10,
            child: _buildCorner(bottomLeft: true),
          ),
          Positioned(
            bottom: -10,
            right: -10,
            child: _buildCorner(bottomRight: true),
          ),

          // Logo
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF64C8FF).withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/ilustrator/logo_sin_fondo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.visibility,
                    size: 60,
                    color: Colors.white,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: (topLeft || topRight)
              ? BorderSide(color: Colors.white.withOpacity(0.8), width: 2)
              : BorderSide.none,
          bottom: (bottomLeft || bottomRight)
              ? BorderSide(color: Colors.white.withOpacity(0.8), width: 2)
              : BorderSide.none,
          left: (topLeft || bottomLeft)
              ? BorderSide(color: Colors.white.withOpacity(0.8), width: 2)
              : BorderSide.none,
          right: (topRight || bottomRight)
              ? BorderSide(color: Colors.white.withOpacity(0.8), width: 2)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      width: 280,
      child: Column(
        children: [
          // Progress Bar
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Background
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  // Progress Fill with Shimmer
                  FractionallySizedBox(
                    widthFactor: _progressAnimation.value,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF4dd0e1),
                            Color(0xFF00bcd4),
                            Color(0xFF4dd0e1),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF4dd0e1).withOpacity(0.6),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          SizedBox(height: 12),

          // Progress Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CERRANDO SESIÓN',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Text(
                    '${(_progressAnimation.value * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ],
          ),

          SizedBox(height: 12),

          // Loading Dots
          AnimatedBuilder(
            animation: _dotsController,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  double delay = index * 0.2;
                  double value = (_dotsController.value - delay) % 1.0;
                  double opacity = 0.0;

                  if (value >= 0 && value <= 0.3) {
                    opacity = 1.0;
                  } else if (value > 0.3 && value <= 0.6) {
                    opacity = 0.0;
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      '.',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.6 * opacity),
                        letterSpacing: 4,
                        height: 1,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Starfield Effect
class StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final stars = [
      {'x': 0.2, 'y': 0.3, 'size': 2.0, 'opacity': 0.3},
      {'x': 0.6, 'y': 0.7, 'size': 2.0, 'opacity': 0.2},
      {'x': 0.5, 'y': 0.5, 'size': 1.0, 'opacity': 0.3},
      {'x': 0.8, 'y': 0.1, 'size': 1.0, 'opacity': 0.25},
      {'x': 0.9, 'y': 0.6, 'size': 2.0, 'opacity': 0.2},
      {'x': 0.33, 'y': 0.8, 'size': 1.0, 'opacity': 0.3},
      {'x': 0.15, 'y': 0.9, 'size': 1.0, 'opacity': 0.2},
      {'x': 0.7, 'y': 0.4, 'size': 1.5, 'opacity': 0.25},
      {'x': 0.4, 'y': 0.2, 'size': 1.0, 'opacity': 0.2},
      {'x': 0.85, 'y': 0.85, 'size': 1.5, 'opacity': 0.3},
    ];

    for (var star in stars) {
      paint.color = Colors.white.withOpacity(star['opacity'] as double);
      canvas.drawCircle(
        Offset(
          size.width * (star['x'] as double),
          size.height * (star['y'] as double),
        ),
        star['size'] as double,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
