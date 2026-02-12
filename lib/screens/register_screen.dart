import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/animated_button.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Las contraseñas no coinciden'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2D385E),
              Color(0xFF5258A4),
              Color(0xFF2D385E),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
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
                        GlassmorphicCard(
                          borderRadius: 24,
                          padding: EdgeInsets.all(28),
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _nameController,
                                label: 'Nombre Completo',
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu nombre';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              _buildTextField(
                                controller: _ageController,
                                label: 'Edad',
                                icon: Icons.calendar_today,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu edad';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Ingresa una edad válida';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              _buildTextField(
                                controller: _emailController,
                                label: 'Correo electrónico',
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu correo';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Ingresa un correo válido';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              _buildPasswordField(
                                controller: _passwordController,
                                label: 'Contraseña',
                                obscureText: _obscurePassword,
                                onToggle: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              SizedBox(height: 16),
                              _buildPasswordField(
                                controller: _confirmPasswordController,
                                label: 'Confirmar Contraseña',
                                obscureText: _obscureConfirmPassword,
                                onToggle: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                                isConfirm: true,
                              ),
                              SizedBox(height: 28),
                              _buildRegisterButton(),
                            ],
                          ),
                        ),
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
    );
  }

  Widget _buildLogoHeader() {
    return Column(
      children: [
        Hero(
          tag: 'app_logo',
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(
              'assets/ilustrator/logo_sin_fondo.png',
              width: 70,
              height: 70,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.visibility,
                  size: 50,
                  color: Colors.white,
                );
              },
            ),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Crear Cuenta',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: Offset(0, 4),
                blurRadius: 10,
              ),
            ],
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
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
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    bool isConfirm = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
        prefixIcon: Icon(
          isConfirm ? Icons.lock_outline : Icons.lock,
          color: Colors.white.withOpacity(0.8),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: Colors.white.withOpacity(0.8),
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return isConfirm
              ? 'Por favor confirma tu contraseña'
              : 'Por favor ingresa tu contraseña';
        }
        if (value.length < 6) {
          return 'La contraseña debe tener al menos 6 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: AnimatedButton(
        text: 'Registrarse',
        onPressed: _register,
        backgroundColor: Colors.white,
        textColor: Color(0xFF2D385E),
        height: 54,
      ),
    );
  }

  Widget _buildLoginLink() {
    return TextButton(
      onPressed: () {
        Navigator.pop(context);
      },
      child: Text.rich(
        TextSpan(
          text: '¿Ya tienes cuenta? ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 15,
          ),
          children: [
            TextSpan(
              text: 'Inicia sesión',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}