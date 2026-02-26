import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import 'login_screen.dart';
import 'login_loading_screen.dart';
import '../widgets/glassmorphic_card.dart';
import '../services/auth_service.dart';

class TwoFactorScreen extends StatefulWidget {
  final String userEmail;
  final bool afterRegister;
  const TwoFactorScreen({
    Key? key,
    required this.userEmail,
    this.afterRegister = false,
  }) : super(key: key);

  @override
  _TwoFactorScreenState createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late AnimationController _particleController;
  late AnimationController _shakeController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  final AuthService _authService = AuthService();

  /// Código devuelto por la API (visible en banner para desarrollo)
  String _serverCode = '';
  bool _isLoadingCode = false;
  int _secondsLeft = 30;
  Timer? _countdownTimer;
  bool _isVerifying = false;
  bool _codeExpired = false;
  bool _showCode = false;
  String? _apiError;

  @override
  void initState() {
    super.initState();

    _particleController = AnimationController(
      duration: Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _shakeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _requestCode();
  }

  Future<void> _requestCode() async {
    setState(() {
      _isLoadingCode = true;
      _apiError = null;
      _showCode = false;
      _codeExpired = false;
      _serverCode = '';
      for (var c in _controllers) {
        c.clear();
      }
    });

    final code = await _authService.request2FA();

    if (!mounted) return;

    if (code != null) {
      setState(() {
        _serverCode = code;
        _isLoadingCode = false;
        _secondsLeft = 30;
        _codeExpired = false;
      });
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) setState(() => _showCode = true);
      });
      _startCountdown();
    } else {
      setState(() {
        _isLoadingCode = false;
        _apiError = 'No se pudo enviar el código. Verifica la conexión.';
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          timer.cancel();
          _codeExpired = true;
          _showCode = false;
        }
      });
    });
  }

  Future<void> _verify() async {
    final entered = _controllers.map((c) => c.text).join();
    if (entered.length < 6) return;
    if (_codeExpired) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('El código ha expirado. Solicita uno nuevo.'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _isVerifying = true);

    final ok = await _authService.verify2FA(entered);

    if (!mounted) return;

    if (ok) {
      _countdownTimer?.cancel();
      if (widget.afterRegister) {
        // Verificación de registro exitosa → volver al login con mensaje
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('¡Cuenta verificada! Ya puedes iniciar sesión.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: Duration(milliseconds: 400),
          ),
          (route) => false,
        );
      } else {
        // Verificación de inicio de sesión
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
    } else {
      setState(() => _isVerifying = false);
      _shakeController.forward(from: 0);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Código incorrecto. Inténtalo de nuevo.'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      for (var c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _fadeController.dispose();
    _shakeController.dispose();
    _countdownTimer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ─────────────────────────── BUILD ────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          _buildParticles(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(),
                        SizedBox(height: 32),
                        _buildCodeBanner(),
                        SizedBox(height: 24),
                        if (_apiError != null)
                          Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.red.withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.wifi_off,
                                      color: Colors.red.shade300, size: 18),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _apiError!,
                                      style: TextStyle(
                                          color: Colors.red.shade200,
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        _buildCodeCard(),
                        SizedBox(height: 20),
                        _buildResendSection(),
                        SizedBox(height: 16),
                        _buildBackButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isVerifying)
            Container(
              color: Colors.black38,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00ccff)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
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

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _TFAParticlePainter(_particleController.value),
          child: Container(),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.05),
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
          child: Icon(Icons.shield_outlined, size: 52, color: Colors.white),
        ),
        SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.white, Colors.white.withOpacity(0.8)],
          ).createShader(bounds),
          child: Text(
            widget.afterRegister
                ? 'Verifica tu correo'
                : 'Verificación en 2 pasos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          widget.afterRegister
              ? 'Ingresa el código de verificación\nque fue enviado a ${widget.userEmail}'
              : 'Ingresa el código de 6 dígitos\ngenerado para tu sesión',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeBanner() {
    if (_isLoadingCode) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF00ccff)),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Enviando código...',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return AnimatedSwitcher(
      duration: Duration(milliseconds: 400),
      child: _codeExpired
          ? Container(
              key: ValueKey('expired'),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade300, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Código expirado — solicita uno nuevo',
                    style:
                        TextStyle(color: Colors.red.shade200, fontSize: 13),
                  ),
                ],
              ),
            )
          : Container(
              key: ValueKey('code'),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFF00ccff).withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF00ccff).withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mark_email_read_outlined,
                          color: Color(0xFF00ccff).withOpacity(0.8),
                          size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Código enviado por la API',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: _showCode
                        ? Text(
                            _serverCode.split('').join('  '),
                            key: ValueKey(_serverCode),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          )
                        : Text(
                            '•  •  •  •  •  •',
                            key: ValueKey('hidden'),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 30,
                              letterSpacing: 4,
                            ),
                          ),
                  ),
                  SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _secondsLeft / 30,
                      minHeight: 4,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _secondsLeft > 10
                            ? Color(0xFF00ccff)
                            : Colors.orange,
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Expira en $_secondsLeft s',
                    style: TextStyle(
                      color: _secondsLeft > 10
                          ? Colors.white.withOpacity(0.5)
                          : Colors.orange.withOpacity(0.9),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCodeCard() {
    return GlassmorphicCard(
      borderRadius: 24,
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Tu código',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 20),
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              final shake = math.sin(_shakeAnimation.value * math.pi * 6) *
                  (1 - _shakeAnimation.value) *
                  10;
              return Transform.translate(
                offset: Offset(shake, 0),
                child: child,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) => _buildDigitField(index)),
            ),
          ),
          SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _verify,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF2D385E),
                disabledBackgroundColor: Colors.white.withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Verificar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitField(int index) {
    return SizedBox(
      width: 44,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
              // Auto-verify when last digit entered
              _verify();
            }
          }
        },
        onEditingComplete: () {
          if (index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildResendSection() {
    return TextButton.icon(
      onPressed: (_codeExpired || _secondsLeft < 28) && !_isLoadingCode
          ? _requestCode
          : null,
      icon: Icon(
        Icons.refresh_rounded,
        size: 18,
        color: (_codeExpired || _secondsLeft < 28) && !_isLoadingCode
            ? Colors.white
            : Colors.white.withOpacity(0.3),
      ),
      label: Text(
        _codeExpired ? 'Enviar nuevo código' : 'Reenviar código',
        style: TextStyle(
          color: (_codeExpired || _secondsLeft < 28) && !_isLoadingCode
              ? Colors.white
              : Colors.white.withOpacity(0.3),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text.rich(
        TextSpan(
          text: '← ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
          children: [
            TextSpan(
              text: 'Volver al inicio de sesión',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────── Particle painter ─────────────────

class _TFAParticlePainter extends CustomPainter {
  final double animationValue;
  _TFAParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 20; i++) {
      final x =
          (size.width * (i * 0.1 + animationValue * 0.5)) % size.width;
      final y = (size.height *
          (math.sin(i + animationValue * math.pi * 2) * 0.5 + 0.5));
      final radius = 2.0 + math.sin(i + animationValue * math.pi) * 2;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_TFAParticlePainter oldDelegate) => true;
}
