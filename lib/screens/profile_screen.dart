import 'package:flutter/material.dart';
import '../widgets/responsive_wrapper.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  // ── Cambiar contraseña ───────────────────────────────────────────────────

  Future<void> _showChangePasswordDialog() async {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock_reset, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Text('Cambiar Contraseña'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogPasswordField(
                  ctrl: newCtrl,
                  label: 'Nueva contraseña',
                  obscure: obscureNew,
                  onToggle: () => setS(() => obscureNew = !obscureNew),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                SizedBox(height: 14),
                _dialogPasswordField(
                  ctrl: confirmCtrl,
                  label: 'Confirmar nueva contraseña',
                  obscure: obscureConfirm,
                  onToggle: () =>
                      setS(() => obscureConfirm = !obscureConfirm),
                  validator: (v) =>
                      v != newCtrl.text ? 'Las contraseñas no coinciden' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: Text('Cancelar'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(Icons.save, size: 18),
              label: Text(isSaving ? 'Guardando...' : 'Guardar'),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setS(() => isSaving = true);

                      final result = await _authService
                          .changePassword(newCtrl.text.trim());

                      if (!mounted) return;

                      if (result['success'] == true) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Contraseña actualizada correctamente'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ));
                      } else {
                        setS(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              result['message'] ?? 'Error al cambiar contraseña'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
            ),
          ],
        ),
      ),
    );

    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  Widget _dialogPasswordField({
    required TextEditingController ctrl,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: onToggle,
        ),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ResponsiveWrapper(
        maxWidth: 700,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: _buildHeader(user),
              ),
              SizedBox(height: 32),
              _buildInfoSection(user),
              SizedBox(height: 16),
              _buildPasswordSection(),
              SizedBox(height: 16),
              _buildRoleCard(user?.role ?? 'PACIENTE'),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header con avatar de iniciales ───────────────────────────────────────

  Widget _buildHeader(user) {
    final name = user?.fullName;
    final email = user?.email ?? '';
    final initials = _getInitials(name ?? email);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.primary.withOpacity(0.35),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar con iniciales
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 3),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          // Nombre
          if (name != null && name.isNotEmpty) ...[
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ] else
            Text(
              email,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  String _getInitials(String text) {
    final parts = text.trim().split(RegExp(r'[\s@.]+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return text.isNotEmpty ? text[0].toUpperCase() : '?';
  }

  // ── Sección de información ───────────────────────────────────────────────

  Widget _buildInfoSection(user) {
    return _sectionCard(
      title: 'Información de Cuenta',
      icon: Icons.person_outline,
      children: [
        _infoRow(
          icon: Icons.email_outlined,
          label: 'Correo Electrónico',
          value: user?.email ?? '—',
        ),
        if (user?.fullName != null && user!.fullName!.isNotEmpty) ...[
          Divider(height: 1),
          _infoRow(
            icon: Icons.badge_outlined,
            label: 'Nombre completo',
            value: user.fullName!,
          ),
        ],
      ],
    );
  }

  // ── Sección de contraseña ────────────────────────────────────────────────

  Widget _buildPasswordSection() {
    return _sectionCard(
      title: 'Seguridad',
      icon: Icons.security_outlined,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.lock_outline,
                    color: Color(0xFF2563EB), size: 18),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contraseña',
                        style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.6))),
                    Text('••••••••',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2,
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.color)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _showChangePasswordDialog,
                icon: Icon(Icons.edit_outlined, size: 16),
                label: Text('Cambiar'),
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF2563EB),
                  padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tarjeta de rol ───────────────────────────────────────────────────────

  Widget _buildRoleCard(String role) {
    final isDoctor = role == 'MEDICO';
    final isAdmin = role == 'ADMINISTRADOR';

    final Color color = isAdmin
        ? Colors.deepPurple
        : isDoctor
            ? Colors.blue
            : Colors.green;
    final IconData icon = isAdmin
        ? Icons.admin_panel_settings_outlined
        : isDoctor
            ? Icons.medical_services_outlined
            : Icons.person_outline;
    final String label = isAdmin
        ? 'Administrador'
        : isDoctor
            ? 'Médico'
            : 'Paciente';

    return _sectionCard(
      title: 'Rol en el sistema',
      icon: Icons.verified_user_outlined,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rol asignado',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.6))),
                  Text(label,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon,
                    size: 16,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.6)),
                SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.6),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: Theme.of(context).colorScheme.primary, size: 18),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.6))),
                Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}