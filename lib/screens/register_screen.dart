import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'two_factor_screen.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/animated_button.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _logoController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _slideController.forward();
    _fadeController.forward();
    _logoController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _logoController.dispose();
    _particleController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Las contraseñas no coinciden'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      final result = await _authService.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Si el registro fue exitoso pero la API no devolvió token,
      // hacemos login automático para obtener el JWT antes de llamar a 2FA.
      // (El endpoint /auth/2fa/send requiere authMiddleware)
      if (result['success'] == true) {
        // Ignoramos el resultado del login: si falla, request2FA() lo manejará.
        // Si ya tenía token guardado del registro, esto lo refresca.
        await _authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // Registro exitoso → verificar correo con 2FA
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                TwoFactorScreen(
              userEmail: _emailController.text.trim(),
              afterRegister: true,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: Duration(milliseconds: 400),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al registrar usuario'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildGradientBackground(),
          _buildFloatingParticles(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLogoHeader(),
                            SizedBox(height: 32),
                            _buildRegisterCard(),
                            SizedBox(height: 20),
                            _buildLoginLink(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a237e),
            Color(0xFF2D385E),
            Color(0xFF2563EB),
            Color(0xFF2D385E),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particleController.value),
          child: Container(),
        );
      },
    );
  }

  Widget _buildLogoHeader() {
    return ScaleTransition(
      scale: _logoAnimation,
      child: Column(
        children: [
          Hero(
            tag: 'app_logo',
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF2563EB).withOpacity(0.4),
                    blurRadius: 30,
                    offset: Offset(0, 15),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/ilustrator/logo_sin_fondo.png',
                width: 70,
                height: 70,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.visibility, size: 50, color: Colors.white);
                },
              ),
            ),
          ),
          SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.8)],
            ).createShader(bounds),
            child: Text(
              'Crear Cuenta',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Completa tus datos para registrarte',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterCard() {
    return GlassmorphicCard(
      borderRadius: 24,
      padding: EdgeInsets.all(28),
      child: Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Nombre completo',
            icon: Icons.person_outline,
            delay: 400,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresa tu nombre';
              if (value.trim().length < 2) return 'Nombre demasiado corto';
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Correo electrónico',
            icon: Icons.email_outlined,
            delay: 500,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresa tu correo';
              if (!value.contains('@')) return 'Ingresa un correo válido';
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildPasswordField(
            controller: _passwordController,
            label: 'Contraseña',
            obscureText: _obscurePassword,
            delay: 600,
            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          SizedBox(height: 16),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirmar Contraseña',
            obscureText: _obscureConfirmPassword,
            delay: 700,
            isConfirm: true,
            onToggle: () =>
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          SizedBox(height: 28),
          _buildRegisterButton(),
        ],
      ),
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required int delay,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: delay),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required int delay,
    bool isConfirm = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: delay),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
          prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.8)),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.white.withOpacity(0.8),
            ),
            onPressed: onToggle,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return isConfirm ? 'Por favor confirma tu contraseña' : 'Por favor ingresa tu contraseña';
          }
          if (value.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
          return null;
        },
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: AnimatedButton(
        text: 'Registrarse',
        onPressed: _isLoading ? () {} : _register,
        backgroundColor: Colors.white,
        textColor: Color(0xFF2D385E),
        height: 56,
      ),
    );
  }

  Widget _buildLoginLink() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text.rich(
        TextSpan(
          text: '¿Ya tienes cuenta? ',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15),
          children: [
            TextSpan(
              text: 'Inicia sesión',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;
  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
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