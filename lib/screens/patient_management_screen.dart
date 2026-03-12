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

  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).brightness == Brightness.dark 
        ? Theme.of(context).colorScheme.secondary 
        : Theme.of(context).colorScheme.primary;
        
    // Widget puro sin Scaffold propio (HomeScreen ya provee la shell)
    return Column(
      children: [
        // Toggle segmentado
        Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedTab == 0 ? primaryColor : (Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedTab == 0 ? primaryColor : Theme.of(context).dividerColor.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, size: 18, color: _selectedTab == 0 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)),
                        SizedBox(width: 8),
                        Text(
                          'Directorio',
                          style: TextStyle(
                            color: _selectedTab == 0 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedTab == 1 ? primaryColor : (Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedTab == 1 ? primaryColor : Theme.of(context).dividerColor.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add, size: 18, color: _selectedTab == 1 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)),
                        SizedBox(width: 8),
                        Text(
                          'Nuevo Paciente',
                          style: TextStyle(
                            color: _selectedTab == 1 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Contenido
        Expanded(
          child: _selectedTab == 0 ? _buildDashboardTab() : _buildCreationTab(),
        ),
      ],
    );
  }

  Widget _buildDashboardTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsHeader(isDesktop),
                _buildFilterRow(isDesktop),
                Text('Pacientes (${_patients.length})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                SizedBox(height: 16),
                _buildPatientesTable(isDesktop),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildStatsHeader(bool isDesktop) {
    if (!isDesktop) return SizedBox.shrink();

    final primaryColor = Theme.of(context).brightness == Brightness.dark 
        ? Theme.of(context).colorScheme.secondary 
        : Theme.of(context).colorScheme.primary;
    int totalPacientes = _patients.length;
    int totalAnalisis = _patients.fold(0, (sum, p) => sum + p.totalAnalyses);
    // Asumiremos que 'Estado' no está en el modelo todavía, simulamos.
    int estadoNormal = totalPacientes > 0 ? (totalPacientes * 0.8).round() : 0;
    int requierenAtencion = totalPacientes - estadoNormal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Expanded(child: _buildMetricCard('Total Pacientes', '$totalPacientes', Icons.people, Colors.blue)),
          SizedBox(width: 16),
          Expanded(child: _buildMetricCard('Análisis Totales', '$totalAnalisis', Icons.bar_chart, Colors.purple)),
          SizedBox(width: 16),
          Expanded(child: _buildMetricCard('Estado Normal', '$estadoNormal', Icons.check_circle, Colors.green)),
          SizedBox(width: 16),
          Expanded(child: _buildMetricCard('Requieren Atención', '$requierenAtencion', Icons.warning, Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color baseColor) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: baseColor.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          SizedBox(height: 12),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildFilterRow(bool isDesktop) {
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
        ),
        child: TextField(
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: 'Buscar paciente por nombre o email...',
            hintStyle: TextStyle(color: textSecondary, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: textSecondary),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientesTable(bool isDesktop) {
    if (_isLoadingPatients) {
      return Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()));
    }
    
    if (_patients.isEmpty) {
      return Padding(padding: EdgeInsets.all(48), child: Center(child: Text('Aún no tienes pacientes.', style: TextStyle(color: Colors.grey))));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? Color(0xFF23325B) : (Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface);
    final primaryColor = isDark ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary;

    if (!isDesktop) {
      // Vista móvil: Lista de tarjetas
      return ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: _patients.length,
        separatorBuilder: (_, __) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          final patient = _patients[index];
          // Simulación de valores
          String estado = "Normal";
          Color estadoColor = Colors.green;
          if (index % 3 == 1) { estado = "Leve"; estadoColor = Colors.orange; }
          if (index % 5 == 2) { estado = "Moderado"; estadoColor = Colors.deepOrange; }

          return InkWell(
            onTap: () => _showPatientDetailsModal(patient),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Icon(Icons.person, color: primaryColor, size: 28),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patient.fullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                        SizedBox(height: 2),
                        Text(patient.email ?? 'Sin correo', style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
                        SizedBox(height: 4),
                        Text("${patient.age} años • ${patient.totalAnalyses} análisis", style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: estadoColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: estadoColor.withOpacity(0.3)),
                        ),
                        child: Text(estado, style: TextStyle(color: estadoColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 8),
                      Text("Hace 2 semanas", style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5))),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // Vista Escritorio (Tabla)
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey;
    final headerStyle = TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13);
    
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Theme.of(context).dividerColor.withOpacity(0.1)),
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor: WidgetStateProperty.all(Theme.of(context).dividerColor.withOpacity(0.05)),
            dataRowMaxHeight: 65,
            dataRowMinHeight: 65,
            horizontalMargin: 24,
            columns: [
              DataColumn(label: Text('Paciente', style: headerStyle)),
              DataColumn(label: Text('Email', style: headerStyle)),
              DataColumn(label: Text('Edad', style: headerStyle)),
              DataColumn(label: Text('Análisis', style: headerStyle)),
              DataColumn(label: Text('Estado', style: headerStyle)),
              DataColumn(label: Text('Última Visita', style: headerStyle)),
            ],
            rows: _patients.asMap().entries.map((entry) {
              final index = entry.key;
              final patient = entry.value;
              final isOdd = index % 2 == 1;
              
              String estado = "Normal";
              Color estadoColor = Colors.green;
              if (index % 3 == 1) { estado = "Leve"; estadoColor = Colors.orange; }
              if (index % 5 == 2) { estado = "Moderado"; estadoColor = Colors.deepOrange; }

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                  if (states.contains(WidgetState.hovered)) return primaryColor.withOpacity(0.05);
                  return isOdd ? Theme.of(context).dividerColor.withOpacity(0.01) : Colors.transparent;
                }),
                onSelectChanged: (_) => _showPatientDetailsModal(patient),
                cells: [
                  DataCell(Row(
                    children: [
                      Icon(Icons.person, size: 16, color: primaryColor.withOpacity(0.7)),
                      SizedBox(width: 8),
                      Text(patient.fullName, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                    ],
                  )),
                  DataCell(Text(patient.email ?? '-', style: TextStyle(color: textSecondary))),
                  DataCell(Text('${patient.age} años', style: TextStyle(color: textSecondary))),
                  DataCell(Text('${patient.totalAnalyses}', style: TextStyle(color: textSecondary))),
                  DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: estadoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: estadoColor.withOpacity(0.3)),
                      ),
                      child: Text(estado, style: TextStyle(color: estadoColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    )
                  ),
                  DataCell(Text('Hace 2 semanas', style: TextStyle(color: textSecondary))),
                ]
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCreationTab() {
    final primaryColor = Theme.of(context).brightness == Brightness.dark 
        ? Theme.of(context).colorScheme.secondary 
        : Theme.of(context).colorScheme.primary;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: ResponsiveWrapper(
          maxWidth: 700,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crear Nuevo Paciente',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                SizedBox(height: 8),
                Text(
                  'Genera credenciales temporales para un nuevo paciente. Deberá cambiar su contraseña al iniciar sesión.',
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          inputFormatters: [InputSanitizer.blockDangerousChars],
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Nombre Completo',
                            labelStyle: TextStyle(color: textSecondary),
                            prefixIcon: Icon(Icons.person, color: primaryColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                            filled: true,
                            fillColor: Theme.of(context).scaffoldBackgroundColor,
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
                                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary))
                                : Text('Crear y Generar Contraseña'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isLoading ? null : _createPatient,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_tempUsername != null && _tempPassword != null) ...[
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.cyanAccent.withOpacity(0.08) : Colors.cyan.withOpacity(0.1),
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.cyanAccent.withOpacity(0.3) : Colors.cyan.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Theme.of(context).brightness == Brightness.dark ? Colors.cyanAccent : Colors.cyan.shade700),
                            SizedBox(width: 8),
                            Text('Credenciales Generadas', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.cyanAccent : Colors.cyan.shade700, fontSize: 16)),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text('Usuario/Correo: $_tempUsername', style: TextStyle(fontSize: 15, color: textPrimary)),
                        SizedBox(height: 8),
                        Text('Contraseña: $_tempPassword', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary)),
                        SizedBox(height: 16),
                        Text('Proporciona estos datos al paciente para que inicie sesión.', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.cyanAccent.withOpacity(0.7) : Colors.cyan.shade800, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPatientDetailsModal(Patient patient) {
    showDialog(
      context: context,
      builder: (context) {
        final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
        final textSecondary = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey;
        final primaryColor = Theme.of(context).brightness == Brightness.dark 
            ? Theme.of(context).colorScheme.secondary 
            : Theme.of(context).colorScheme.primary;

        String formatDate(DateTime? date) {
          if (date == null) return 'No disponible';
          return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
        }

        // Simulación
        String estado = "Normal";
        Color estadoColor = Colors.green;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: 500, maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (App bar like)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      SizedBox(width: 8),
                      Text('Detalles del Paciente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card Header Azul
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF17387A), Color(0xFF2B52B6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Color(0xFF17387A).withOpacity(0.3), blurRadius: 10, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.white.withOpacity(0.15),
                                child: Icon(Icons.person, size: 40, color: Colors.white),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(patient.fullName, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text(patient.email ?? 'Sin correo', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                                    SizedBox(height: 12),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: estadoColor.withOpacity(0.2), // Idealmente un verde brillante
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: estadoColor.withOpacity(0.5)),
                                      ),
                                      child: Text('Estado: $estado', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32),
                        
                        Text('Información del Paciente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
                        SizedBox(height: 16),
                        
                        // Tarjetas de información
                        _buildInfoCard(Icons.cake, 'Edad', '${patient.age} años', context),
                        _buildInfoCard(Icons.phone, 'Teléfono', patient.phone ?? 'No disponible', context),
                        _buildInfoCard(Icons.bar_chart, 'Total Análisis', '${patient.totalAnalyses}', context),
                        _buildInfoCard(Icons.calendar_today, 'Última Visita', formatDate(patient.lastVisit), context),
                        
                        SizedBox(height: 32),
                        Text('Análisis Recientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
                        SizedBox(height: 16),
                        
                        // Lista de Análisis Recientes Simulados
                        _buildAnalysisCard('15/11/2024', 'Sin anomalías detectadas', 'Normal', Colors.green, context),
                        SizedBox(height: 12),
                        _buildAnalysisCard('01/11/2024', 'Sin anomalías detectadas', 'Normal', Colors.green, context),
                        SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.edit),
                            label: Text('Editar Datos Básicos'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showEditPatientModal(patient);
                            },
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value, BuildContext context) {
    final primaryColor = Theme.of(context).brightness == Brightness.dark 
        ? Theme.of(context).colorScheme.secondary 
        : Theme.of(context).colorScheme.primary;
        
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))),
                SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(String date, String description, String status, Color statusColor, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPatientModal(Patient patient) {
    final phoneController = TextEditingController(text: patient.phone);
    final emailController = TextEditingController(text: patient.email);
    String? selectedGender = patient.gender;
    DateTime? selectedBirthDate = patient.birthDate;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
            final textSecondary = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey;
            final primaryColor = Theme.of(context).brightness == Brightness.dark 
                ? Theme.of(context).colorScheme.secondary 
                : Theme.of(context).colorScheme.primary;
            bool isSaving = false;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxWidth: 500, maxHeight: MediaQuery.of(context).size.height * 0.9),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header (App bar like)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.close, color: textPrimary),
                            onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                          ),
                          SizedBox(width: 8),
                          Text('Editar Paciente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: phoneController,
                              style: TextStyle(color: textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Teléfono',
                                labelStyle: TextStyle(color: textSecondary),
                                prefixIcon: Icon(Icons.phone, color: primaryColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: emailController,
                              style: TextStyle(color: textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Correo (Opcional)',
                                labelStyle: TextStyle(color: textSecondary),
                                prefixIcon: Icon(Icons.email, color: primaryColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: selectedGender,
                              dropdownColor: Theme.of(context).cardColor,
                              style: TextStyle(color: textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Género',
                                labelStyle: TextStyle(color: textSecondary),
                                prefixIcon: Icon(Icons.transgender, color: primaryColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: ['MASCULINO', 'FEMENINO', 'OTRO'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (val) => setStateModal(() => selectedGender = val),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                selectedBirthDate == null
                                    ? 'Seleccionar Fecha de Nac.'
                                    : "${selectedBirthDate!.day}/${selectedBirthDate!.month}/${selectedBirthDate!.year}",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).cardColor,
                                foregroundColor: textPrimary,
                                elevation: 0,
                                side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                alignment: Alignment.centerLeft,
                                minimumSize: Size(double.infinity, 50),
                              ),
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedBirthDate ?? DateTime(2000),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) setStateModal(() => selectedBirthDate = date);
                              },
                            ),
                            SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                                  child: Text('Cancelar', style: TextStyle(color: textSecondary)),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: isSaving ? null : () async {
                                    setStateModal(() => isSaving = true);
                                    try {
                                      await _patientService.updatePatient(patient.id, {
                                        'phone': phoneController.text.trim(),
                                        'email': emailController.text.trim(),
                                        'gender': selectedGender,
                                        if (selectedBirthDate != null)
                                          'birthDate': selectedBirthDate!.toIso8601String().split('T').first,
                                      });
                                      await _loadPatients();
                                      if (!context.mounted) return;
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('Paciente actualizado correctamente', style: TextStyle(color: Colors.white)),
                                        backgroundColor: Colors.green,
                                      ));
                                      
                                      try {
                                        final modifiedPatient = _patients.firstWhere((p) => p.id == patient.id);
                                        _showPatientDetailsModal(modifiedPatient);
                                      } catch (_) {}
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}', style: TextStyle(color: Colors.white)),
                                        backgroundColor: Colors.red,
                                      ));
                                      setStateModal(() => isSaving = false);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  child: isSaving
                                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Text('Guardar'),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
