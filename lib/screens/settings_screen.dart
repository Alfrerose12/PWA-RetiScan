import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'login_screen.dart';
import 'logout_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true;
  bool _developerMode = false;

  @override
  void initState() {
    super.initState();
    // Solo carga el estado del modo dev si el usuario es @yada.com
    _loadDeveloperMode();
  }

  Future<void> _loadDeveloperMode() async {
    if (!_authService.isDeveloper) return;
    // SharedPreferences solo para el toggle de modo desarrollador
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _developerMode = prefs.getBool('dev_mode') ?? false;
      });
    }
  }

  Future<void> _saveDeveloperMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dev_mode', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Drawer Header
          Container(
            padding: EdgeInsets.fromLTRB(16, 48, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).colorScheme.onPrimary, size: 28),
                SizedBox(width: 12),
                Text(
                  'Ajustes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Settings Content
          Expanded(
            child: ListView(
              children: [
                _buildUserInfoSection(),
                Divider(height: 1),
                SizedBox(height: 8),
                _buildSettingsSection(),
                Divider(height: 1),
                SizedBox(height: 8),
                if (_authService.isDeveloper) ...[
                  _buildDeveloperSection(),
                  Divider(height: 1),
                  SizedBox(height: 8),
                ],
                _buildAccountSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
    final user = _authService.currentUser;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D385E),
            Color(0xFF2563EB),
          ],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
            child: Icon(
              user?.isDoctor ?? false
                  ? Icons.medical_services
                  : Icons.person,
              size: 40,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          SizedBox(height: 16),
          Text(
            user?.fullName ?? 'Usuario',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user?.isDoctor ?? false ? 'Médico' : 'Usuario',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    final themeService = Provider.of<ThemeService>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Configuración',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
        ),
        ListTile(
          leading: Icon(
            themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text('Modo Oscuro'),
          trailing: Switch(
            value: themeService.isDarkMode,
            onChanged: (value) {
              themeService.toggleTheme();
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        ListTile(
          leading: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.primary),
          title: Text('Notificaciones'),
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            activeColor: Color(0xFF2563EB),
          ),
        ),
        ListTile(
          leading: Icon(Icons.security_outlined, color: Theme.of(context).colorScheme.primary),
          title: Text('Privacidad'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
          title: Text('Ayuda y Soporte'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
          title: Text('Acerca de'),
          subtitle: Text('Versión 1.0.0'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildDeveloperSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.code, size: 16, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Opciones de Desarrollador',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: Icon(Icons.bug_report_outlined, color: Colors.orange),
          title: Text('Modo Desarrollador'),
          trailing: Switch(
            value: _developerMode,
            onChanged: (value) {
              setState(() => _developerMode = value);
              _saveDeveloperMode(value);
            },
            activeColor: Colors.orange,
          ),
        ),
        if (_developerMode) ...[
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.swap_horiz, color: Colors.orange[700], size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Cambiar Rol',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Rol actual: ${_authService.isDoctor ? "Doctor" : "Usuario"}',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _authService.isClient
                            ? null
                            : () async {
                                await _authService.switchRole('client');
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Cambiado a Usuario'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                        icon: Icon(Icons.person),
                        label: Text('Usuario'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _authService.isClient
                              ? Theme.of(context).colorScheme.primary
                              : (Theme.of(context).brightness == Brightness.dark 
                                  ? Theme.of(context).colorScheme.surface 
                                  : Colors.grey[300]),
                          foregroundColor: _authService.isClient
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _authService.isDoctor
                            ? null
                            : () async {
                                await _authService.switchRole('doctor');
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Cambiado a Doctor'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                        icon: Icon(Icons.medical_services),
                        label: Text('Doctor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _authService.isDoctor
                              ? Theme.of(context).colorScheme.primary
                              : (Theme.of(context).brightness == Brightness.dark 
                                  ? Theme.of(context).colorScheme.surface 
                                  : Colors.grey[300]),
                          foregroundColor: _authService.isDoctor
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Nota: Reinicia la app para ver los cambios en la navegación',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text('Cerrar sesión y limpiar datos'),
            subtitle: Text('Elimina la sesión activa'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Limpiar Datos'),
                  content: Text(
                      '¿Estás seguro? Se cerrará tu sesión y se limpiarán los datos de la app.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _authService.clearStorage();
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()),
                          (route) => false,
                        );
                      },
                      child: Text(
                        'Limpiar',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Cuenta',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.exit_to_app, color: Color(0xFFd4183d)),
          title: Text(
            'Cerrar Sesión',
            style: TextStyle(color: Color(0xFFd4183d)),
          ),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LogoutScreen()),
            );
          },
        ),
        SizedBox(height: 20),
      ],
    );
  }
}