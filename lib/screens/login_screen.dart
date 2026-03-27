import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'package:another_flushbar/flushbar.dart';
import 'login_loading_screen.dart';
import 'change_password_screen.dart';
import 'forgot_password_screen.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/animated_button.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;
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
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await _authService.login(
        _identifierController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        if (result['requires2FA'] == true) {
          _showMfaDialog(result['userId'], result['message']);
          return;
        }
        _navigateAfterLogin(result);
      } else {
        Flushbar(
          title: 'Acceso denegado',
          message: result['message'] ?? 'Credenciales inválidas',
          icon: Icon(Icons.error_outline, size: 28, color: Colors.redAccent),
          backgroundColor: Color(0xFF1E1E2E),
          borderColor: Colors.redAccent.withOpacity(0.5),
          borderWidth: 1.5,
          borderRadius: BorderRadius.circular(12),
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          flushbarPosition: FlushbarPosition.TOP,
          duration: Duration(seconds: 4),
          boxShadows: [BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 12)],
          titleColor: Colors.white,
          messageColor: Colors.white70,
        ).show(context);
      }
    }
  }

  void _navigateAfterLogin(Map<String, dynamic> result) {
    if (result['mustChangePassword'] == true) {
      // Médico con contraseña temporal → debe cambiarla antes de entrar
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ChangePasswordScreen(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 400),
        ),
      );
    } else {
      // Login normal → pantalla de carga animada
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              LoginLoadingScreen(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 400),
        ),
      );
    }
  }

  void _showMfaDialog(String userId, String message) {
    final otpController = TextEditingController();
    bool isVerifying = false;
    bool rememberDevice = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Color(0xFF2D385E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Verificación en 2 Pasos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, style: TextStyle(color: Colors.white.withOpacity(0.9))),
                  SizedBox(height: 24),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.white, fontSize: 32, letterSpacing: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      counterStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                  SizedBox(height: 8),
                  // Checkbox: Recordar dispositivo
                  InkWell(
                    onTap: () => setModalState(() => rememberDevice = !rememberDevice),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20, height: 20,
                          child: Checkbox(
                            value: rememberDevice,
                            onChanged: (v) => setModalState(() => rememberDevice = v ?? false),
                            activeColor: Color(0xFF2563EB),
                            checkColor: Colors.white,
                            side: BorderSide(color: Colors.white54),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Recordar este dispositivo (30 días)',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.pop(context),
                  child: Text('Cancelar', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: isVerifying ? null : () async {
                    if (otpController.text.length < 6) return;
                    setModalState(() => isVerifying = true);
                    final res = await _authService.verifyLoginOtp(
                      userId, otpController.text,
                      rememberDevice: rememberDevice,
                    );
                    if (!mounted) return;
                    setModalState(() => isVerifying = false);
                    if (res['success'] == true) {
                      Navigator.pop(context); // Cerrar Modal
                      _navigateAfterLogin(res); // Navegar a Home
                    } else {
                      Navigator.pop(context); // Cerrar modal primero
                      Flushbar(
                        title: 'Código incorrecto',
                        message: res['message'] ?? 'Código OTP inválido o expirado',
                        icon: Icon(Icons.security_outlined, size: 28, color: Colors.orangeAccent),
                        backgroundColor: Color(0xFF1E1E2E),
                        borderColor: Colors.orangeAccent.withOpacity(0.5),
                        borderWidth: 1.5,
                        borderRadius: BorderRadius.circular(12),
                        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        flushbarPosition: FlushbarPosition.TOP,
                        duration: Duration(seconds: 5),
                        boxShadows: [BoxShadow(color: Colors.orangeAccent.withOpacity(0.3), blurRadius: 12)],
                        titleColor: Colors.white,
                        messageColor: Colors.white70,
                      ).show(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: isVerifying 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : Text('Verificar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
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
                            SizedBox(height: 40),
                            _buildLoginCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Spinner simple mientras espera respuesta del servidor
          if (_isLoading)
            Container(
              color: Colors.black38,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF00ccff)),
                ),
              ),
            ),
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
              padding: EdgeInsets.all(20),
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
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(-5, -5),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/ilustrator/logo_sin_fondo.png',
                width: 80,
                height: 80,
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
          SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.8)],
            ).createShader(bounds),
            child: Text(
              'RetiScan',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Inicia sesión en tu cuenta',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    // Usar LayoutBuilder para aplicar paddings relativos al tamaño
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = MediaQuery.of(context).size.width >= 800;
        final paddingVertical = isDesktop ? 40.0 : 28.0;
        final paddingHorizontal = isDesktop ? 48.0 : 24.0;
        
        return GlassmorphicCard(
          borderRadius: 24,
          padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: paddingVertical),
          child: Column(
            children: [
              _buildEmailField(),
              SizedBox(height: 20),
              _buildPasswordField(),
              SizedBox(height: 12),
              _buildForgotPassword(),
              SizedBox(height: 32),
              _buildLoginButton(),
            ],
          ),
        );
      }
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _identifierController,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Correo o usuario',
        hintText: 'doctor@email.com / juan.perez#1234',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
        prefixIcon: Icon(Icons.person_outline, color: Colors.white.withOpacity(0.8)),
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
      keyboardType: TextInputType.text,
      autocorrect: false,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa tu correo o usuario';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Contraseña',
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.8)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.white.withOpacity(0.8),
          ),
          onPressed: () {
            // Forzamos la actualización directa para evitar bugs del cursor en Web
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
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
          return 'Por favor ingresa tu contraseña';
        }
        if (value.length < 6) {
          return 'La contraseña debe tener al menos 6 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, _) => ForgotPasswordScreen(),
              transitionsBuilder: (context, animation, _, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: Duration(milliseconds: 400),
            ),
          );
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Text(
          '¿Olvidaste tu contraseña?',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: AnimatedButton(
        text: 'Iniciar Sesión',
        onPressed: _isLoading ? () {} : _login,
        backgroundColor: Colors.white,
        textColor: Color(0xFF2D385E),
        height: 56,
      ),
    );
  }

  // Eliminado _buildDivider y _buildRegisterLink


  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
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