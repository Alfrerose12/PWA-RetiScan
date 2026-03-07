import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../config/input_sanitizer.dart';
import '../widgets/responsive_wrapper.dart';
import '../widgets/dashboard_charts.dart';

class PatientManagementScreen extends StatefulWidget {
  @override
  _PatientManagementScreenState createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  String? _tempUsername;
  String? _tempPassword;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _createPatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _tempUsername = null;
      _tempPassword = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final generatedPassword = _generateRandomPassword();

    final result = await _authService.createPatientAccount(
      email: email,
      password: generatedPassword,
      fullName: name,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      setState(() {
        _tempPassword = generatedPassword;
        _tempUsername = email; // El usuario accederá con su email
      });
      _nameController.clear();
      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Paciente creado con éxito.'),
        backgroundColor: Colors.green,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Error al crear paciente'),
        backgroundColor: Colors.red,
      ));
    }
  }

  String _generateRandomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*';
    final random = math.Random();
    return String.fromCharCodes(Iterable.generate(
      8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Gestión de Pacientes'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard y Pacientes'),
              Tab(icon: Icon(Icons.person_add), text: 'Nuevo Paciente'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _buildDashboardTab(),
              _buildCreationTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            child: DashboardCharts(),
          ),
          SizedBox(height: 24),
          Text('Directorio de Pacientes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar paciente por nombre o email...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            onChanged: (value) {
              // lógica de filtrado...
            },
          ),
          SizedBox(height: 16),
          _buildMockPatientList(),
        ],
      ),
    );
  }

  Widget _buildMockPatientList() {
    // Ejemplo de UI de listado (simulado)
    final pacientes = ['Juan Pérez', 'María García', 'Carlos López', 'Ana Martínez'];
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: pacientes.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text(pacientes[index]),
            subtitle: Text('Paciente de seguimiento'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Navegar a detalles...
            },
          ),
        );
      },
    );
  }

  Widget _buildCreationTab() {
    return Center(
      child: ResponsiveWrapper(
        maxWidth: 700,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crear Nuevo Paciente',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Genera credenciales temporales para un nuevo paciente. Deberá cambiar su contraseña al iniciar sesión.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      inputFormatters: [InputSanitizer.blockDangerousChars],
                      decoration: InputDecoration(
                        labelText: 'Nombre Completo',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        final safe = InputSanitizer.validateSafeInput(val);
                        if (safe != null) return safe;
                        return val!.isEmpty ? 'Requerido' : null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: [InputSanitizer.blockDangerousChars],
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        final safe = InputSanitizer.validateSafeInput(val);
                        if (safe != null) return safe;
                        if (val == null || val.isEmpty) return 'Requerido';
                        if (!val.contains('@')) return 'Correo no válido';
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: _isLoading ? Container() : Icon(Icons.add_circle_outline),
                        label: _isLoading
                            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                            : Text('Crear y Generar Contraseña'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _createPatient,
                      ),
                    ),
                  ],
                ),
              ),
              if (_tempUsername != null && _tempPassword != null) ...[
                SizedBox(height: 32),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Credenciales Generadas', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text('Usuario/Correo: $_tempUsername', style: TextStyle(fontSize: 15)),
                      SizedBox(height: 8),
                      Text('Contraseña: $_tempPassword', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      Text('Proporciona estos datos al paciente para que inicie sesión.', style: TextStyle(color: Colors.green[800], fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
