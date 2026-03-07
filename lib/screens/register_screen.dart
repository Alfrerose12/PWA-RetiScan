import 'package:flutter/material.dart';
import 'dart:math' as math;
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
  final _pageController = PageController();
  
  // Section 1
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  
  // Section 2
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  final TextEditingController _birthDateController = TextEditingController();
  
  // Section 3
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Section 3.1 & 3.2
  String _selected2FAMethod = 'email'; // 'email' or 'sms'
  final _tokenController = TextEditingController();
  bool _isVerifyingToken = false;
  
  // Section 4
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
    _pageController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_formKey.currentState!.validate()) {
      // Validate page specific constraints
      if (_currentPage == 1) {
        if (_selectedGender == null) {
          _showError('Por favor selecciona tu género');
          return;
        }
        if (_selectedBirthDate == null) {
          _showError('Por favor selecciona tu fecha de nacimiento');
          return;
        }
      }
      
      if (_currentPage < 4) {
        if (_currentPage == 2) { // Sending 2FA before entering Token page
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _send2FACode() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    // Simulate SMS vs Email based on _selected2FAMethod for the frontend.
    // In this backend, sendUnauthOtp uses email.
    final code = await _authService.request2FAUnauth(email);
    setState(() => _isLoading = false);
    
    if (code != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código de verificación enviado. (Cód: $code)'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        )
      );
    } else {
      _showError('Error al enviar el código de verificación.');
    }
  }

  Future<void> _verifyToken() async {
    if (_tokenController.text.trim().isEmpty) {
      _showError('Por favor ingresa el código');
      return;
    }
    
    setState(() => _isVerifyingToken = true);
    final isValid = await _authService.verify2FAUnauth(
      _emailController.text.trim(),
      _tokenController.text.trim()
    );
    setState(() => _isVerifyingToken = false);
    
    if (isValid) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _showError('Código inválido o expirado.');
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showError('Las contraseñas no coinciden');
        return;
      }

      setState(() => _isLoading = true);

      final result = await _authService.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // Registro exitoso, regresar al login
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cuenta creada exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showError(result['message'] ?? 'Error al registrar usuario');
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
                                  _buildSection3_2(), // Token Verification
                                  _buildSection4(), // Password
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

  Widget _buildWizardProgress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
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
          Text('Información Personal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            label: 'Nombre completo',
            icon: Icons.person_outline,
            delay: 400,
            onChanged: (val) {
              // Auto-generate username
              if (val.isNotEmpty) {
                _usernameController.text = val.toLowerCase().replaceAll(' ', '_') + '${math.Random().nextInt(1000)}';
              } else {
                _usernameController.text = '';
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresa tu nombre';
              if (value.trim().length < 2) return 'Nombre demasiado corto';
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _usernameController,
            label: 'Nombre de usuario',
            icon: Icons.account_circle_outlined,
            delay: 500,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresa un usuario';
              return null;
            },
          ),
          SizedBox(height: 28),
          _buildNavButtons(),
          _buildLoginLink(),
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
          Text('Datos Demográficos', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
          _buildLoginLink(),
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
          Text('Contacto y Verificación', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
          SizedBox(height: 16),
          _buildDropdownField(
            label: 'Método de Autenticación 2FA',
            icon: Icons.security,
            value: _selected2FAMethod,
            items: ['email', 'sms'], // Underlying values, you can use a map to display nice labels
            onChanged: (val) => setState(() => _selected2FAMethod = val!),
          ),
          SizedBox(height: 28),
          _buildNavButtons(),
          _buildLoginLink(),
        ],
      ),
    );
  }

  Widget _buildSection3_2() {
    return GlassmorphicCard(
      borderRadius: 24,
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Verificación 2FA', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Ingresa el código que enviamos a tu $_selected2FAMethod', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
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
                  text: _isVerifyingToken ? 'Verificando...' : 'Verificar',
                  onPressed: _isVerifyingToken ? () {} : _verifyToken,
                  backgroundColor: Colors.white,
                  textColor: Color(0xFF2D385E),
                  height: 48,
                ),
              ),
            ],
          ),
          _buildLoginLink(),
        ],
      ),
    );
  }

  Widget _buildSection4() {
    return GlassmorphicCard(
      borderRadius: 24,
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Seguridad de la Cuenta', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          _buildPasswordField(
            controller: _passwordController,
            label: 'Contraseña',
            obscureText: _obscurePassword,
            delay: 400,
            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          SizedBox(height: 16),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirmar Contraseña',
            obscureText: _obscureConfirmPassword,
            delay: 500,
            isConfirm: true,
            onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
                  text: _isLoading ? '...' : 'Registrar',
                  onPressed: _isLoading ? () {} : _register,
                  backgroundColor: Colors.white,
                  textColor: Color(0xFF2D385E),
                  height: 48,
                ),
              ),
            ],
          ),
          _buildLoginLink(),
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
    void Function(String)? onChanged,
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
        onChanged: onChanged,
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

  Widget _buildLoginLink() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: TextButton(
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