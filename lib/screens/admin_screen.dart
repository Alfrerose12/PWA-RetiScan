import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/patient_service.dart';
import '../widgets/responsive_wrapper.dart';
import 'patient_detail_screen.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final PatientService _patientService = PatientService();

  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
    _loadPatients();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final patients = await _patientService.getPatients();
      setState(() {
        _patients = patients;
        _filteredPatients = patients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = _patients;
      } else {
        _filteredPatients = _patients
            .where((p) =>
                p.fullName.toLowerCase().contains(query.toLowerCase()) ||
                (p.phone ?? '').toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _updatePatientLocal(Patient updated) {
    // Optimistic update first (instant UI response)
    setState(() {
      final idx = _patients.indexWhere((p) => p.id == updated.id);
      if (idx != -1) _patients[idx] = updated;
      _filterPatients(_searchController.text);
    });
    // Then reload from server to ensure data consistency
    _loadPatients();
  }

  Future<void> _showCreatePatientDialog() async {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_add, color: Color(0xFF2563EB)),
            SizedBox(width: 12),
            Text('Nuevo Paciente'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: ageCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Edad',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (int.tryParse(v) == null) return 'Ingresa un número';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: Text('Crear'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _patientService.createPatient(
          fullName: nameCtrl.text.trim(),
          age: int.parse(ageCtrl.text.trim()),
          phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
        );
        // Recargar desde el servidor para reflejar datos reales
        await _loadPatients();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paciente "${nameCtrl.text.trim()}" creado'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deletePatient(Patient patient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar paciente'),
        content: Text(
            '¿Eliminar a "${patient.fullName}"? También se eliminarán todos sus análisis.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _patientService.deletePatient(patient.id);
      setState(() {
        _patients.removeWhere((p) => p.id == patient.id);
        _filterPatients(_searchController.text);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paciente eliminado'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ResponsiveWrapper(
        maxWidth: 1400,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatisticsSection(),
              SizedBox(height: 24),
              if (isDesktop)
                Row(
                  children: [
                    Text(
                      'Pacientes (${_filteredPatients.length})',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Spacer(),
                    SizedBox(width: 340, child: _buildSearchBar()),
                    SizedBox(width: 12),
                    _buildAddButton(),
                  ],
                )
              else ...[
                _buildSearchBar(),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Pacientes (${_filteredPatients.length})',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Spacer(),
                    _buildAddButton(),
                  ],
                ),
              ],
              SizedBox(height: 16),
              if (_isLoading)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    ),
                  ),
                )
              else if (_error != null)
                _buildErrorWidget()
              else
                isDesktop ? _buildPatientsTable() : _buildPatientsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: _showCreatePatientDialog,
      icon: Icon(Icons.person_add, size: 18),
      label: Text('Nuevo'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF2563EB),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPatients,
              icon: Icon(Icons.refresh),
              label: Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final totalPatients = _patients.length;
    final totalAnalyses = _patients.fold(0, (sum, p) => sum + p.totalAnalyses);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ResponsiveBreakpoints.getGridColumns(context);
        return GridView.count(
          crossAxisCount: columns > 2 ? 4 : 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth > 900 ? 2.8 : 1.8,
          children: [
            _buildStatCard('Total Pacientes', totalPatients.toString(), Icons.people, Colors.blue),
            _buildStatCard('Análisis Totales', totalAnalyses.toString(), Icons.analytics, Colors.purple),
            _buildStatCard('Con Análisis', _patients.where((p) => p.totalAnalyses > 0).length.toString(), Icons.check_circle, Colors.green),
            _buildStatCard('Sin Análisis', _patients.where((p) => p.totalAnalyses == 0).length.toString(), Icons.pending_outlined, Colors.orange),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterPatients,
        decoration: InputDecoration(
          hintText: 'Buscar paciente por nombre...',
          prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterPatients('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildPatientsList() {
    if (_filteredPatients.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            'No se encontraron pacientes',
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _filteredPatients.length,
      itemBuilder: (context, index) => _buildPatientCard(_filteredPatients[index]),
    );
  }

  Widget _buildPatientCard(Patient patient) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientDetailScreen(
                patient: patient,
                onSave: _updatePatientLocal,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF2563EB).withOpacity(0.1),
                  child: Icon(Icons.person, color: Color(0xFF2563EB), size: 30),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.fullName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${patient.age} años • ${patient.totalAnalyses} análisis',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      if (patient.phone != null) ...[
                        SizedBox(height: 4),
                        Text(
                          patient.phone!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.7)),
                  onPressed: () => _deletePatient(patient),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _filteredPatients.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('No se encontraron pacientes'),
              ),
            )
          : Column(
              children: [
                // Encabezado
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF4D8FEF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      _tableHeader('Paciente', flex: 4),
                      _tableHeader('Teléfono', flex: 3),
                      _tableHeader('Edad', flex: 2),
                      _tableHeader('Análisis', flex: 2),
                      _tableHeader('Última Visita', flex: 3),
                      _tableHeader('', flex: 1),
                    ],
                  ),
                ),
                // Filas
                ..._filteredPatients.asMap().entries.map((entry) {
                  final patient = entry.value;
                  final isEven = entry.key.isEven;
                  final isLast = entry.key == _filteredPatients.length - 1;
                  return _buildHoverableRow(patient, isEven, isLast);
                }),
              ],
            ),
    );
  }

  Widget _tableHeader(String label, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildHoverableRow(Patient patient, bool isEven, bool isLast) {
    final baseColor = isEven
        ? Theme.of(context).cardTheme.color
        : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.25);

    return StatefulBuilder(
      builder: (context, setHoverState) {
        bool isHovered = false;
        return StatefulBuilder(
          builder: (context, setH) {
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setH(() => isHovered = true),
              onExit: (_) => setH(() => isHovered = false),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isHovered ? Color(0xFF2563EB).withOpacity(0.07) : baseColor,
                  border: Border(
                    left: BorderSide(
                      color: isHovered ? Color(0xFF2563EB) : Colors.transparent,
                      width: 3,
                    ),
                    bottom: isLast
                        ? BorderSide.none
                        : BorderSide(
                            color: Theme.of(context).dividerColor.withOpacity(0.5),
                            width: 1),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientDetailScreen(
                        patient: patient,
                        onSave: _updatePatientLocal,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Nombre
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: Color(0xFF2563EB).withOpacity(0.12),
                              child: Icon(Icons.person, color: Color(0xFF2563EB), size: 17),
                            ),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                patient.fullName,
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Teléfono
                      Expanded(
                        flex: 3,
                        child: Text(
                          patient.phone ?? '—',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.75),
                          ),
                        ),
                      ),
                      // Edad
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${patient.age} años',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      // Análisis
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Icon(Icons.analytics_outlined, size: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)),
                            SizedBox(width: 4),
                            Text(
                              patient.totalAnalyses.toString(),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      // Última visita
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Icon(Icons.schedule_outlined, size: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)),
                            SizedBox(width: 4),
                            Text(
                              patient.lastVisit != null ? _formatDate(patient.lastVisit!) : '—',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Eliminar
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.7), size: 18),
                          onPressed: () => _deletePatient(patient),
                          tooltip: 'Eliminar',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    if (difference == 0) return 'Hoy';
    if (difference == 1) return 'Ayer';
    if (difference < 7) return 'Hace $difference días';
    if (difference < 30) {
      final weeks = (difference / 7).floor();
      return 'Hace $weeks ${weeks == 1 ? "semana" : "semanas"}';
    }
    final months = (difference / 30).floor();
    return 'Hace $months ${months == 1 ? "mes" : "meses"}';
  }
}
