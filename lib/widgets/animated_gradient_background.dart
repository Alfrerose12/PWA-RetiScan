import 'package:flutter/material.dart';

import 'dart:math' as math;

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;

  const AnimatedGradientBackground({Key? key, required this.child}) : super(key: key);

  @override
  _AnimatedGradientBackgroundState createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    // Animación de partículas idéntica al login
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el color actual del fondo para adaptarnos a modo claro oscuro general
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    
    // Color solicitado: Light Sky Blue (#8BD6FD)
    const skyBlue = Color(0xFF8BD6FD);
    
    // Ajustaremos el gradiente de fondo dependiendo del modo
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final color1 = isDark ? skyBlue.withOpacity(0.1) : skyBlue.withOpacity(0.05);
    final color2 = isDark ? skyBlue.withOpacity(0.05) : skyBlue.withOpacity(0.02);

    return Stack(
      children: [
        // 1. Fondo Gradiente Estático (Estilo Login)
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bgColor,
                color1,
                color2,
                bgColor,
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
        // 2. Partículas Flotantes (Reutilizando la lógica del Login)
        AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(_particleController.value, skyBlue),
              child: Container(),
            );
          },
        ),
        // 3. Contenido (Scaffold, etc.)
        widget.child,
      ],
    );
  }
}

// Lógica de partículas del login ajustada al color solicitado
class ParticlePainter extends CustomPainter {
  final double animationValue;
  final Color particleColor;

  ParticlePainter(this.animationValue, this.particleColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = particleColor.withOpacity(0.2) // Opacidad suave para no distraer
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final x = (size.width * (i * 0.1 + animationValue * 0.5)) % size.width;
      final y = (size.height * (math.sin(i + animationValue * math.pi * 2) * 0.5 + 0.5));
      final radius = 2.0 + math.sin(i + animationValue * math.pi) * 2;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
