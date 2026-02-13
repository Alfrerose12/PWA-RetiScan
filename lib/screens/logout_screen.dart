import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'login_screen.dart';
import '../services/auth_service.dart';

class LogoutScreen extends StatefulWidget {
  @override
  _LogoutScreenState createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  
  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _breatheController;
  late AnimationController _rippleController;
  late AnimationController _scanLineController;
  late AnimationController _bracketsController;
  late AnimationController _irisController;
  late AnimationController _dotsController;
  
  // Animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _breatheAnimation;
  late Animation<double> _scanLineAnimation;
  
  // Progress
  double _progress = 0.0;
  Timer? _progressTimer;
  bool _showProgress = false;
  bool _showScanLine = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startLogoutSequence();
  }

  void _initializeAnimations() {
    // Logo appear
    _logoController = AnimationController(
      duration: Duration(milliseconds: 700),
      vsync: this,
    );
    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // Breathe effect
    _breatheController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _breatheAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    // Ripple effect
    _rippleController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Scan line
    _scanLineController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _scanLineAnimation = Tween<double>(begin: 0.15, end: 0.85).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.linear),
    );

    // Brackets pulse
    _bracketsController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Iris animation
    _irisController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Loading dots
    _dotsController = AnimationController(
      duration: Duration(milliseconds: 900),
      vsync: this,
    )..repeat();
  }

  void _startLogoutSequence() async {
    // Phase 0: Logo appears
    _logoController.forward();

    // Phase 1: Scanning starts
    await Future.delayed(Duration(milliseconds: 400));
    setState(() {
      _showScanLine = true;
    });

    // Phase 2: Progress visible
    await Future.delayed(Duration(milliseconds: 800));
    setState(() {
      _showProgress = true;
    });

    // Start progress animation (faster - 1.5 seconds)
    _startProgressAnimation();

    // Execute logout
    await _authService.logout();

    // Wait for progress to complete
    await Future.delayed(Duration(milliseconds: 1500));
    _navigateToLogin();
  }

  void _startProgressAnimation() {
    const updateInterval = Duration(milliseconds: 30);
    const totalDuration = 1500; // 1.5 seconds
    const totalSteps = totalDuration ~/ 30;
    int currentStep = 0;

    _progressTimer = Timer.periodic(updateInterval, (timer) {
      setState(() {
        currentStep++;
        double remaining = 100 - _progress;
        double step = math.max(1.0, remaining * 0.06);
        _progress = math.min(100, _progress + step);

        if (_progress >= 100 || currentStep >= totalSteps) {
          timer.cancel();
          _progress = 100;
        }
      });
    });
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _breatheController.dispose();
    _rippleController.dispose();
    _scanLineController.dispose();
    _bracketsController.dispose();
    _irisController.dispose();
    _dotsController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Diagonal gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF000d26),
                  Color(0xFF001a4d),
                  Color(0xFF0033a0),
                  Color(0xFF001a4d),
                  Color(0xFF000d26),
                ],
                stops: [0.0, 0.3, 0.6, 0.85, 1.0],
              ),
            ),
          ),

          // Breathe glow effect
          AnimatedBuilder(
            animation: _breatheAnimation,
            builder: (context, child) {
              return Positioned(
                left: MediaQuery.of(context).size.width / 2,
                top: MediaQuery.of(context).size.height / 2,
                child: Transform.translate(
                  offset: Offset(
                    -MediaQuery.of(context).size.width / 2,
                    -MediaQuery.of(context).size.height / 2,
                  ),
                  child: Transform.scale(
                    scale: _breatheAnimation.value,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFF00ccff).withOpacity(0.15),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.7],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Grid pattern
          CustomPaint(
            painter: GridPainter(),
            size: Size.infinite,
          ),

          // Floating particles
          ...List.generate(20, (index) => _buildParticle(index)),

          // Scan line
          if (_showScanLine)
            AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, child) {
                return Positioned(
                  left: 0,
                  right: 0,
                  top: MediaQuery.of(context).size.height * _scanLineAnimation.value,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0xFF00ccff),
                          Colors.white,
                          Color(0xFF00ccff),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00ccff),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with animations
                AnimatedBuilder(
                  animation: Listenable.merge([_logoScaleAnimation, _logoOpacityAnimation]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacityAnimation.value,
                      child: Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: _buildAnimatedLogo(),
                      ),
                    );
                  },
                ),

                SizedBox(height: 60),

                // Progress section
                if (_showProgress)
                  AnimatedOpacity(
                    opacity: _showProgress ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 500),
                    child: _buildProgressSection(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticle(int index) {
    final random = math.Random(index);
    final left = random.nextDouble() * 100;
    final top = random.nextDouble() * 100;
    final duration = 3000 + random.nextInt(3000);

    return Positioned(
      left: MediaQuery.of(context).size.width * (left / 100),
      top: MediaQuery.of(context).size.height * (top / 100),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: duration),
        builder: (context, double value, child) {
          return Opacity(
            opacity: (math.sin(value * math.pi * 2) * 0.5 + 0.5) * 0.4,
            child: Container(
              width: 1,
              height: 1,
              decoration: BoxDecoration(
                color: Color(0xFF00ccff),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return Container(
      width: 200,
      height: 220,
      child: Stack(
        children: [
          // Ripple rings
          AnimatedBuilder(
            animation: _rippleController,
            builder: (context, child) {
              return Center(
                child: Container(
                  width: 150,
                  height: 150,
                  child: Stack(
                    children: [
                      _buildRipple(0.0),
                      _buildRipple(0.5),
                    ],
                  ),
                ),
              );
            },
          ),

          // Eye logo with brackets
          Center(
            child: CustomPaint(
              size: Size(200, 220),
              painter: EyeLogoPainter(
                bracketsAnimation: _bracketsController,
                irisAnimation: _irisController,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRipple(double delay) {
    final value = (_rippleController.value + delay) % 1.0;
    final scale = 0.8 + (value * 0.7);
    final opacity = (1.0 - value) * 0.6;

    return Transform.scale(
      scale: scale,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Color(0xFF00ccff).withOpacity(opacity),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      width: 224,
      child: Column(
        children: [
          // Progress bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: _progress / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF00ccff),
                          Colors.white,
                          Color(0xFF00ccff),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00ccff).withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12),

          // Text row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // "CERRANDO SESIÓN" text
              Row(
                children: [
                  Text(
                    'CERRANDO SESIÓN',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  // Animated dots
                  AnimatedBuilder(
                    animation: _dotsController,
                    builder: (context, child) {
                      return Row(
                        children: List.generate(3, (index) {
                          final delay = index * 0.15;
                          final value = (_dotsController.value - delay) % 1.0;
                          final opacity = value < 0.5 ? 1.0 : 0.3;
                          
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 1),
                            child: Container(
                              width: 1.5,
                              height: 1.5,
                              decoration: BoxDecoration(
                                color: Color(0xFF00ccff).withOpacity(opacity),
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
              // Percentage
              Container(
                width: 32,
                child: Text(
                  '${_progress.toInt()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF00ccff),
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Grid painter (reused)
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF00ccff).withOpacity(0.02)
      ..strokeWidth = 1;

    const gridSize = 60.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Eye logo painter (reused)
class EyeLogoPainter extends CustomPainter {
  final Animation<double> bracketsAnimation;
  final Animation<double> irisAnimation;

  EyeLogoPainter({
    required this.bracketsAnimation,
    required this.irisAnimation,
  }) : super(repaint: Listenable.merge([bracketsAnimation, irisAnimation]));

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 10);

    _drawBrackets(canvas, center);
    _drawEye(canvas, center);
    _drawText(canvas, size);
  }

  void _drawBrackets(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4 + (bracketsAnimation.value * 0.6))
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    final bracketSize = 20.0;
    final distance = 80.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - distance, center.dy - distance + bracketSize)
        ..lineTo(center.dx - distance, center.dy - distance)
        ..lineTo(center.dx - distance + bracketSize, center.dy - distance),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(center.dx + distance - bracketSize, center.dy - distance)
        ..lineTo(center.dx + distance, center.dy - distance)
        ..lineTo(center.dx + distance, center.dy - distance + bracketSize),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - distance, center.dy + distance - bracketSize)
        ..lineTo(center.dx - distance, center.dy + distance)
        ..lineTo(center.dx - distance + bracketSize, center.dy + distance),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(center.dx + distance - bracketSize, center.dy + distance)
        ..lineTo(center.dx + distance, center.dy + distance)
        ..lineTo(center.dx + distance, center.dy + distance - bracketSize),
      paint,
    );
  }

  void _drawEye(Canvas canvas, Offset center) {
    // Outer eye shape
    final eyePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;

    final eyePath = Path()
      ..moveTo(center.dx - 60, center.dy)
      ..quadraticBezierTo(center.dx - 30, center.dy - 35, center.dx, center.dy - 40)
      ..quadraticBezierTo(center.dx + 30, center.dy - 35, center.dx + 60, center.dy)
      ..quadraticBezierTo(center.dx + 30, center.dy + 35, center.dx, center.dy + 40)
      ..quadraticBezierTo(center.dx - 30, center.dy + 35, center.dx - 60, center.dy);

    canvas.drawPath(eyePath, eyePaint);

    // Iris ring
    final irisPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final irisScale = 1.0 + (irisAnimation.value * 0.05);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(irisScale);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawCircle(center, 42, irisPaint);
    canvas.restore();

    // Pupil
    final pupilPaint = Paint()
      ..color = Color(0xFF001a4d)
      ..style = PaintingStyle.fill;

    final pupilScale = 1.0 - (irisAnimation.value * 0.1);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(pupilScale);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawCircle(center, 28, pupilPaint);
    canvas.restore();

    // Inner iris
    final innerIrisPaint = Paint()
      ..color = Color(0xFF00ccff).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 22, innerIrisPaint);

    // Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(center.dx + 12, center.dy - 17), 6, highlightPaint);
  }

  void _drawText(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'RETISCAN',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 8,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        size.height - 30,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
