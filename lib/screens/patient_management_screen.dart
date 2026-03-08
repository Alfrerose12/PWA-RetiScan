import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/patient_service.dart';
import '../models/patient.dart';
import '../services/theme_service.dart';
import '../config/input_sanitizer.dart';
import '../widgets/responsive_wrapper.dart';
import '../widgets/dashboard_charts.dart';

class PatientManagementScreen extends StatefulWidget {
  @override
  _PatientManagementScreenState createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  final PatientService _patientService = PatientService();
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _tempUsername;
  String? _tempPassword;
  
  List<Patient> _patients = [];
  bool _isLoadingPatients = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoadingPatients = true);
    try {
      final list = await _patientService.getPatients();
      setState(() {
        _patients = list;
        _isLoadingPatients = false;
      });
    } catch (e) {
      setState(() => _isLoadingPatients = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al cargar pacientes: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    final parts = name.split(' ');
    final firstName = parts.isNotEmpty ? parts[0] : '';
    final paternalSurname = parts.length > 1 ? parts[1] : '';
    final maternalSurname = parts.length > 2 ? parts.sublist(2).join(' ') : '';

    try {
      final result = await _patientService.createPatient(
        firstName: firstName,
        paternalSurname: paternalSurname,
        maternalSurname: maternalSurname,
      );

      setState(() {
        _isLoading = false;
        _tempUsername = result['username'];
        _tempPassword = result['tempPassword'];
      });

      _nameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Paciente creado con éxito.'),
        backgroundColor: Colors.green,
      ));
      
      // Recargar lista
      _loadPatients();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
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
          _buildPatientList(),
        ],
      ),
    );
  }

  Widget _buildPatientList() {
    if (_isLoadingPatients) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text('Aún no tienes pacientes registrados.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _patients.length,
      itemBuilder: (context, index) {
        final patient = _patients[index];
        final emailStatus = patient.email != null ? patient.email! : 'Sin correo registrado';
        
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text(patient.fullName),
            subtitle: Text(emailStatus),
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
