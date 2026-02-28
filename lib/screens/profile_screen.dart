import 'package:flutter/material.dart';
import '../widgets/animated_button.dart';
import '../widgets/responsive_wrapper.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late TextEditingController _emailController;
  final _newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isEditing = false;
  bool _isSaving = false;
  bool _obscurePassword = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: _authService.currentUser?.email ?? '',
    );
    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // cancelar: restaurar email original
        _emailController.text = _authService.currentUser?.email ?? '';
        _newPasswordController.clear();
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final result = await _authService.updateProfile(
      email: _emailController.text.trim(),
      password: _newPasswordController.text.isNotEmpty
          ? _newPasswordController.text
          : null,
    );

    setState(() {
      _isSaving = false;
      if (result['success'] == true) {
        _isEditing = false;
        _newPasswordController.clear();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['success'] == true
            ? 'Perfil actualizado correctamente'
            : (result['message'] ?? 'Error al guardar')),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    return Scaffold(
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: ResponsiveWrapper(
              maxWidth: 900,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildProfileHeader(),
                      ),
                      SizedBox(height: 32),
                      _buildProfileForm(),
                      SizedBox(height: 24),
                      _buildRoleCard(user?.role ?? '—'),
                      SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: _isEditing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.extended(
                        heroTag: 'cancel',
                        onPressed: _toggleEdit,
                        backgroundColor: Colors.grey[700],
                        icon: Icon(Icons.close),
                        label: Text('Cancelar'),
                      ),
                      SizedBox(width: 12),
                      FloatingActionButton.extended(
                        heroTag: 'save',
                        onPressed: _isSaving ? null : _saveChanges,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        icon: _isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Icon(Icons.save),
                        label: Text(_isSaving ? 'Guardando...' : 'Guardar'),
                      ),
                    ],
                  )
                : FloatingActionButton(
                    onPressed: _toggleEdit,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(Icons.edit),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final user = _authService.currentUser;
    final hasName = user?.fullName != null && user!.fullName!.isNotEmpty;
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: Icon(
              Icons.person,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 16),
          if (hasName) ...[
            Text(
              user!.fullName!,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
          ] else
            Text(
              user?.email ?? '',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información de Cuenta',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        SizedBox(height: 16),
        _buildEditableField(
          label: 'Correo Electrónico',
          controller: _emailController,
          icon: Icons.email,
          isEditing: _isEditing,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Campo requerido';
            if (!v.contains('@')) return 'Email inválido';
            return null;
          },
        ),
        SizedBox(height: 16),
        _buildPasswordField(),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditing,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditing
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).dividerColor,
          width: isEditing ? 2 : 1,
        ),
        boxShadow: isEditing
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: isEditing ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
          ),
          floatingLabelStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: isEditing ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
          ),
          prefixIcon: Icon(
            icon,
            color: isEditing ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
          ),
          suffixIcon: !isEditing
              ? Icon(Icons.lock, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5))
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
        readOnly: !isEditing,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildPasswordField() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEditing
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).dividerColor,
          width: _isEditing ? 2 : 1,
        ),
        boxShadow: _isEditing
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: _newPasswordController,
        decoration: InputDecoration(
          labelText: _isEditing ? 'Nueva Contraseña (opcional)' : 'Contraseña',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _isEditing ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
          ),
          floatingLabelStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _isEditing ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
          ),
          prefixIcon: Icon(
            Icons.lock,
            color: _isEditing ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
          ),
          suffixIcon: _isEditing
              ? IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : Icon(Icons.lock, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
        readOnly: !_isEditing,
        obscureText: _obscurePassword,
        validator: (v) {
          if (v != null && v.isNotEmpty && v.length < 6) {
            return 'Mínimo 6 caracteres';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildRoleCard(String role) {
    final isDoctor = role == 'MEDICO';
    final isAdmin  = role == 'ADMINISTRADOR';

    final Color roleColor = isAdmin
        ? Colors.deepPurple
        : isDoctor
            ? Colors.blue
            : Colors.green;

    final IconData roleIcon = isAdmin
        ? Icons.admin_panel_settings_outlined
        : isDoctor
            ? Icons.medical_services_outlined
            : Icons.person_outline;

    final String roleLabel = isAdmin
        ? 'Administrador'
        : isDoctor
            ? 'Médico'
            : 'Paciente';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(roleIcon, color: roleColor, size: 24),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rol asignado',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))),
              Text(
                roleLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: roleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}