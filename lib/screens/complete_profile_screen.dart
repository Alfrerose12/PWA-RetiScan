import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'dart:math' as math;
import '../widgets/glassmorphic_card.dart';
import '../widgets/animated_button.dart';
import '../services/auth_service.dart';
import '../services/patient_service.dart';
import 'login_loading_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  @override
  _CompleteProfileScreenState createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // Section 1: Demographics
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  final TextEditingController _birthDateController = TextEditingController();
  
  // Section 2: Contact
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selected2FAMethod = 'email'; // 'email' or 'sms'
  
  // Section 3: Token Verification
  final _tokenController = TextEditingController();
  bool _isVerifyingToken = false;
  
  final AuthService _authService = AuthService();
  final PatientService _patientService = PatientService();
  bool _isLoading = false;
  int _currentPage = 0;

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
        duration: Duration(milliseconds: 800), vsync: this);
    _fadeController = AnimationController(
        duration: Duration(milliseconds: 1000), vsync: this);
    _logoController = AnimationController(
        duration: Duration(milliseconds: 2000), vsync: this);
    _particleController = AnimationController(
        duration: Duration(seconds: 20), vsync: this)..repeat();

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
    _pageController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_formKey.currentState!.validate()) {
      if (_currentPage == 0) {
        if (_selectedGender == null) {
          _showError('Por favor selecciona tu género');
          return;
        }
        if (_selectedBirthDate == null) {
          _showError('Por favor selecciona tu fecha de nacimiento');
          return;
        }
      }
      
      if (_currentPage < 2) {
        if (_currentPage == 1) { 
          // Enviar el OTP al correo/télefono del usuario ingresado antes de pasar a validarlo.
          _send2FACode();
        }
        _pageController.nextPage(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }
  
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showError(String message) {
    Flushbar(
      title: 'Error',
      message: message,
      icon: Icon(Icons.error_outline, size: 28, color: Colors.redAccent),
      backgroundColor: Color(0xFF1E1E2E),
      borderColor: Colors.redAccent.withOpacity(0.5),
      borderWidth: 1.5,
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      flushbarPosition: FlushbarPosition.TOP,
      duration: Duration(seconds: 4),
      boxShadows: [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 12)],
      titleColor: Colors.white,
      messageColor: Colors.white70,
    ).show(context);
  }

  Future<void> _send2FACode() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    // Use the authenticated sendOtp method directly
    final res = await _authService.sendOtp(email);
    setState(() => _isLoading = false);
    
    if (res['success'] == true) {
      Flushbar(
        title: 'Éxito',
        message: 'Código de verificación enviado. Revisa tu correo.',
        icon: Icon(Icons.check_circle, size: 28, color: Colors.greenAccent),
        backgroundColor: Color(0xFF1E1E2E),
        borderColor: Colors.greenAccent.withOpacity(0.5),
        borderWidth: 1.5,
        borderRadius: BorderRadius.circular(12),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        flushbarPosition: FlushbarPosition.TOP,
        duration: Duration(seconds: 5),
        boxShadows: [BoxShadow(color: Colors.greenAccent.withOpacity(0.2), blurRadius: 12)],
        titleColor: Colors.white,
        messageColor: Colors.white70,
      ).show(context);
    } else if (res['message']?.toString().contains('ya está verificada') == true || res['message']?.toString().contains('already verified') == true) {
      // Si por error de conexión o fallos previos la cuenta ya está verificada, saltamos el OTP
      _saveProfileDirectly();
    } else {
      _showError(res['message'] ?? 'Error al enviar el código de verificación.');
    }
  }

  Future<void> _verifyAndSaveProfile() async {
    if (_tokenController.text.trim().isEmpty) {
      _showError('Por favor ingresa el código');
      return;
    }
    
    setState(() => _isVerifyingToken = true);
    
    // 1. Verificamos el OTP
    final result = await _authService.verifyOtp(_tokenController.text.trim());
    
    if (result['success'] != true) {
      setState(() => _isVerifyingToken = false);
      _showError(result['message'] ?? 'Código inválido o expirado.');
      return;
    }
    
    // 2. Si es válido, disparamos el guardado del perfil
    await _saveProfileDirectly();
  }

  Future<void> _saveProfileDirectly() async {
    setState(() => _isVerifyingToken = true);
    try {
      String mappedGender = 'OTRO';
      if (_selectedGender == 'Masculino') mappedGender = 'MASCULINO';
      if (_selectedGender == 'Femenino') mappedGender = 'FEMENINO';

      await _patientService.updateMyProfile(
        birthDate: _selectedBirthDate,
        gender: mappedGender,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim()
      );

      // Refrescar el usuario para que el email aparezca en la configuración
      await _authService.loadUserFromSession();
      
      setState(() => _isVerifyingToken = false);
      
      // 3. Ya con todo completo, avanzamos al dashboard
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => LoginLoadingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      setState(() => _isVerifyingToken = false);
      _showError('Error al guardar el perfil: $e');
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
                            _buildWizardProgress(),
                            SizedBox(height: 20),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: 450),
                              child: PageView(
                                controller: _pageController,
                                physics: NeverScrollableScrollPhysics(),
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentPage = index;
                                  });
                                },
                                children: [
                                  _buildSection1(),
                                  _buildSection2(),
                                  _buildSection3(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading || _isVerifyingToken) _buildLoadingOverlay(),
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
                  return Icon(Icons.person_add_alt_1, size: 50, color: Colors.white);
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
              '¡Bienvenido!',
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
            'Unos últimos datos para completar tu perfil',
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

  Widget _buildWizardProgress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage >= index ? Colors.blue : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildSection1() {
    return GlassmorphicCard(
      borderRadius: 24,
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Datos Personales', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          _buildDropdownField(
            label: 'Género',
            icon: Icons.wc,
            value: _selectedGender,
            items: ['Masculino', 'Femenino', 'Otro', 'Prefiero no decirlo'],
            onChanged: (val) => setState(() => _selectedGender = val),
          ),
          SizedBox(height: 16),
          _buildDateField(
            controller: _birthDateController,
            label: 'Fecha de nacimiento',
            icon: Icons.calendar_today,
          ),
          SizedBox(height: 28),
          _buildNavButtons(),
        ],
      ),
    );
  }

  Widget _buildSection2() {
    return GlassmorphicCard(
      borderRadius: 24,
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Contacto', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Correo electrónico',
            icon: Icons.email_outlined,
            delay: 400,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresa tu correo';
              if (!value.contains('@')) return 'Ingresa un correo válido';
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Teléfono',
            icon: Icons.phone_outlined,
            delay: 500,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresa tu teléfono';
              if (value.length < 10) return 'Teléfono inválido';
              return null;
            },
          ),
          // Se eliminó la selección de SMS (ahora solo es por email)
          SizedBox(height: 28),
          _buildNavButtons(),
        ],
      ),
    );
  }

  Widget _buildSection3() {
    return GlassmorphicCard(
      borderRadius: 24,
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Verificación', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Ingresa el código que enviamos a tu correo electrónico', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          SizedBox(height: 16),
          _buildTextField(
            controller: _tokenController,
            label: 'Código de verificación',
            icon: Icons.lock_clock,
            delay: 400,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          TextButton(
            onPressed: () => _send2FACode(),
            child: Text('Reenviar código', style: TextStyle(color: Colors.white)),
          ),
          SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: AnimatedButton(
                  text: 'Atrás',
                  onPressed: _previousPage,
                  backgroundColor: Colors.transparent,
                  textColor: Colors.white,
                  borderColor: Colors.white,
                  height: 48,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: AnimatedButton(
                  text: _isVerifyingToken ? 'Guardando...' : 'Completar',
                  onPressed: _isVerifyingToken ? () {} : _verifyAndSaveProfile,
                  backgroundColor: Colors.white,
                  textColor: Color(0xFF2D385E),
                  height: 48,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButtons() {
    return Row(
      children: [
        if (_currentPage > 0) ...[
          Expanded(
            child: AnimatedButton(
              text: 'Atrás',
              onPressed: _previousPage,
              backgroundColor: Colors.transparent,
              textColor: Colors.white,
              borderColor: Colors.white,
              height: 48,
            ),
          ),
          SizedBox(width: 16),
        ],
        Expanded(
          child: AnimatedButton(
            text: 'Siguiente',
            onPressed: _nextPage,
            backgroundColor: Colors.white,
            textColor: Color(0xFF2D385E),
            height: 48,
          ),
        ),
      ],
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

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: Color(0xFF2D385E),
      style: TextStyle(color: Colors.white),
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
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(Map<String,String>.from({'email':'Correo Electrónico', 'sms':'SMS (Simulado)'})[e] ?? e))).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Selecciona una opción' : null,
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: TextStyle(color: Colors.white),
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
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() {
            _selectedBirthDate = date;
            controller.text = "${date.day}/${date.month}/${date.year}";
          });
        }
      },
      validator: (val) => val == null || val.isEmpty ? 'Selecciona una fecha' : null,
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
