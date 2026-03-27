import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:another_flushbar/flushbar.dart';
import 'dart:math' as math;
import '../widgets/glassmorphic_card.dart';
import '../services/auth_service.dart';

// ══════════════════════════════════════════════════
//  FORGOT PASSWORD SCREEN
//  Flujo de 3 pasos:
//    1. Ingresar correo electrónico
//    2. Ingresar código OTP que llegó al correo
//    3. Ingresar y confirmar nueva contraseña
// ══════════════════════════════════════════════════
class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  // Controlador del paso actual (0 = correo, 1 = OTP, 2 = nueva contraseña)
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Controladores de texto
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  // Estado
  bool _isLoading = false;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  String? _errorMsg;

  // Animaciones idénticas al login
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;
  late AnimationController _particleController;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(duration: Duration(milliseconds: 800), vsync: this);
    _fadeController = AnimationController(duration: Duration(milliseconds: 1000), vsync: this);
    _logoController = AnimationController(duration: Duration(milliseconds: 2000), vsync: this);
    _particleController = AnimationController(duration: Duration(seconds: 20), vsync: this)..repeat();

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));

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
    _pageController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // ── PASO 1: Enviar correo con OTP ──
  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMsg = 'Por favor ingresa un correo válido');
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      await _authService.forgotPassword(email);
      // Pasar al paso 2 (OTP)
      _pageController.nextPage(duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
      setState(() => _currentStep = 1);
    } catch (e) {
      setState(() => _errorMsg = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── PASO 2: Validar OTP y pasar a nueva contraseña ──
  void _verifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMsg = 'El código debe tener exactamente 6 dígitos');
      return;
    }
    setState(() => _errorMsg = null);
    _pageController.nextPage(duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
    setState(() => _currentStep = 2);
  }

  // ── PASO 3: Restablecer contraseña ──
  Future<void> _resetPassword() async {
    final otp = _otpController.text.trim();
    final email = _emailController.text.trim();
    final newPass = _newPassController.text;
    final confirmPass = _confirmPassController.text;

    if (newPass.length < 8) {
      setState(() => _errorMsg = 'La contraseña debe tener mínimo 8 caracteres');
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _errorMsg = 'Las contraseñas no coinciden');
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      await _authService.resetPassword(email: email, otp: otp, newPassword: newPass);
      if (!mounted) return;
      // Volver al login con mensaje de éxito
      Navigator.of(context).pop();
      Flushbar(
        title: 'Éxito',
        message: 'Contraseña restablecida. Ya puedes iniciar sesión.',
        icon: Icon(Icons.check_circle, size: 28, color: Colors.greenAccent),
        backgroundColor: Color(0xFF1E1E2E),
        borderColor: Colors.greenAccent.withOpacity(0.5),
        borderWidth: 1.5,
        borderRadius: BorderRadius.circular(12),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        flushbarPosition: FlushbarPosition.TOP,
        duration: Duration(seconds: 4),
        boxShadows: [BoxShadow(color: Colors.greenAccent.withOpacity(0.2), blurRadius: 12)],
        titleColor: Colors.white,
        messageColor: Colors.white70,
      ).show(context);
    } catch (e) {
      setState(() => _errorMsg = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo gradiente idéntico al login
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLogoHeader(),
                          SizedBox(height: 40),
                          // Indicador de pasos
                          _buildStepIndicator(),
                          SizedBox(height: 24),
                          // Tarjeta de contenido (PageView interno)
                          SizedBox(
                            height: 380,
                            child: PageView(
                              controller: _pageController,
                              physics: NeverScrollableScrollPhysics(),
                              children: [
                                _buildStep1Card(),
                                _buildStep2Card(),
                                _buildStep3Card(),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          // Link volver al login
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.arrow_back, color: Colors.white70, size: 16),
                            label: Text('Volver al inicio de sesión',
                              style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Overlay de carga
          if (_isLoading)
            Container(
              color: Colors.black38,
              child: Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00ccff)),
              )),
            ),
        ],
      ),
    );
  }

  // ── Logo header idéntico al login ──
  Widget _buildLogoHeader() {
    return ScaleTransition(
      scale: _logoAnimation,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0xFF2563EB).withOpacity(0.4), blurRadius: 30, offset: Offset(0, 15)),
                BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 20, offset: Offset(-5, -5)),
              ],
            ),
            child: Image.asset(
              'assets/ilustrator/logo_sin_fondo.png',
              width: 80, height: 80, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.visibility, size: 60, color: Colors.white),
            ),
          ),
          SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.8)],
            ).createShader(bounds),
            child: Text('RetiScan', style: TextStyle(
              fontSize: 40, fontWeight: FontWeight.bold,
              color: Colors.white, letterSpacing: 2.0,
              shadows: [Shadow(color: Colors.black.withOpacity(0.3), offset: Offset(0, 4), blurRadius: 10)],
            )),
          ),
          SizedBox(height: 8),
          Text('Recuperar contraseña', style: TextStyle(
            fontSize: 16, color: Colors.white.withOpacity(0.9), letterSpacing: 0.5,
          )),
        ],
      ),
    );
  }

  // ── Indicador de los 3 pasos ──
  Widget _buildStepIndicator() {
    final steps = ['Correo', 'Código', 'Nueva clave'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Línea conectora
          return Expanded(
            child: Container(
              height: 2,
              color: _currentStep > i ~/ 2
                  ? Color(0xFF2563EB)
                  : Colors.white.withOpacity(0.3),
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final isActive = stepIdx == _currentStep;
        final isDone = stepIdx < _currentStep;
        return Column(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: isDone ? Color(0xFF04B5A2) : isActive ? Color(0xFF2563EB) : Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isDone
                    ? Icon(Icons.check, color: Colors.white, size: 16)
                    : Text('${stepIdx + 1}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            SizedBox(height: 4),
            Text(steps[stepIdx], style: TextStyle(
              color: isActive ? Colors.white : Colors.white54,
              fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        );
      }),
    );
  }

  // ── Fondo gradiente ──
  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1a237e), Color(0xFF2D385E), Color(0xFF2563EB), Color(0xFF2D385E)],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  // ── Partículas flotantes ──
  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) => CustomPaint(
        painter: _ForgotParticlePainter(_particleController.value),
        child: Container(),
      ),
    );
  }

  // ── Helper para campos de texto con estilo glassmorphic ──
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    List<TextInputFormatter>? inputFormatters,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.white.withOpacity(0.8)),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white, width: 2)),
      ),
    );
  }

  // ── Botón de acción principal ──
  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF2563EB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: Color(0xFF2563EB).withOpacity(0.4),
        ),
        child: _isLoading
            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── PASO 1: Card de correo electrónico ──
  Widget _buildStep1Card() {
    return GlassmorphicCard(
      borderRadius: 24,
      padding: EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ingresa tu correo', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Te enviaremos un código de 6 dígitos para verificar tu identidad.',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          SizedBox(height: 24),
          _buildTextField(
            controller: _emailController,
            label: 'Correo electrónico',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            hint: 'doctor@ejemplo.com',
          ),
          if (_errorMsg != null) ...[
            SizedBox(height: 12),
            Text(_errorMsg!, style: TextStyle(color: Colors.red.shade300, fontSize: 13)),
          ],
          SizedBox(height: 24),
          _buildActionButton('Enviar código', _sendOtp),
        ],
      ),
    );
  }

  // ── PASO 2: Card de ingreso del OTP ──
  Widget _buildStep2Card() {
    return GlassmorphicCard(
      borderRadius: 24,
      padding: EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Código de verificación', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Revisá tu bandeja de entrada (o spam). El código expira en 15 minutos.',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          SizedBox(height: 24),
          _buildTextField(
            controller: _otpController,
            label: 'Código de 6 dígitos',
            icon: Icons.security_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            hint: '000000',
          ),
          if (_errorMsg != null) ...[
            SizedBox(height: 12),
            Text(_errorMsg!, style: TextStyle(color: Colors.red.shade300, fontSize: 13)),
          ],
          SizedBox(height: 16),
          // Link para reenviar código
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : _sendOtp,
              child: Text('¿No llegó el código? Reenviar', style: TextStyle(color: Colors.white54, fontSize: 13)),
            ),
          ),
          SizedBox(height: 8),
          _buildActionButton('Verificar código', _verifyOtp),
        ],
      ),
    );
  }

  // ── PASO 3: Card de nueva contraseña ──
  Widget _buildStep3Card() {
    return GlassmorphicCard(
      borderRadius: 24,
      padding: EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nueva contraseña', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Elige una contraseña segura de al menos 8 caracteres.',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          SizedBox(height: 24),
          _buildTextField(
            controller: _newPassController,
            label: 'Nueva contraseña',
            icon: Icons.lock_outline,
            obscure: _obscureNewPass,
            onToggleObscure: () => setState(() => _obscureNewPass = !_obscureNewPass),
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPassController,
            label: 'Confirmar contraseña',
            icon: Icons.lock_outline,
            obscure: _obscureConfirmPass,
            onToggleObscure: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
          ),
          if (_errorMsg != null) ...[
            SizedBox(height: 12),
            Text(_errorMsg!, style: TextStyle(color: Colors.red.shade300, fontSize: 13)),
          ],
          SizedBox(height: 24),
          _buildActionButton('Restablecer contraseña', _resetPassword),
        ],
      ),
    );
  }
}

// ── Painter de partículas (reutilizado del login) ──
class _ForgotParticlePainter extends CustomPainter {
  final double progress;
  _ForgotParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 40; i++) {
      final x = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final y = (baseY - progress * size.height * speed) % size.height;
      final radius = 1.0 + rng.nextDouble() * 3.0;
      final opacity = 0.05 + rng.nextDouble() * 0.25;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y < 0 ? y + size.height : y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ForgotParticlePainter old) => old.progress != progress;
}
