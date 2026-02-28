import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../widgets/responsive_wrapper.dart';

/// Pantalla de gestión de médicos — visible solo para ADMINISTRADORES
class DoctorManagementScreen extends StatefulWidget {
  @override
  _DoctorManagementScreenState createState() => _DoctorManagementScreenState();
}

class _DoctorManagementScreenState extends State<DoctorManagementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final AdminService _adminService = AdminService();

  List<DoctorUser> _doctors = [];
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
    _loadDoctors();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final res = await _adminService.listDoctors();
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _doctors = res['doctors'] as List<DoctorUser>;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Error al cargar los médicos';
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateDoctorDialog() async {
    final nameCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.medical_services_outlined, color: Color(0xFF2563EB)),
            SizedBox(width: 12),
            Text('Nuevo Médico'),
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
                  hintText: 'Ej: Dr. Juan García López',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: specCtrl,
                decoration: InputDecoration(
                  labelText: 'Especialización (opcional)',
                  hintText: 'Ej: Oftalmología',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF2563EB).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Color(0xFF2563EB).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Color(0xFF2563EB), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Se generará un email y contraseña temporal automáticamente.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
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
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) =>
              Center(child: CircularProgressIndicator()));

      final res = await _adminService.createDoctor(
        name: nameCtrl.text.trim(),
        specialization:
            specCtrl.text.trim().isEmpty ? null : specCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (res['success'] == true) {
        final doctor = res['doctor'] as DoctorUser;
        final tempPassword = res['tempPassword'] as String;
        await _loadDoctors();
        if (!mounted) return;
        _showDoctorCreatedDialog(doctor, tempPassword);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Error al crear el médico'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _showDoctorCreatedDialog(DoctorUser doctor, String tempPassword) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Médico creado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${doctor.name} ha sido registrado. Comparte estas credenciales temporales:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            _credentialTile(Icons.email_outlined, 'Email', doctor.email,
                Colors.blue),
            SizedBox(height: 10),
            _credentialTile(Icons.lock_outline, 'Contraseña temporal',
                tempPassword, Colors.orange),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El médico deberá cambiar su contraseña al primer inicio de sesión.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _credentialTile(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[600])),
                SelectableText(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDoctor(DoctorUser doctor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar médico'),
        content: Text(
            '¿Eliminar a "${doctor.name}" (${doctor.email})? Esta acción no se puede deshacer.'),
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

    final res = await _adminService.deleteDoctor(doctor.id);
    if (!mounted) return;

    if (res['success'] == true) {
      setState(() => _doctors.removeWhere((d) => d.id == doctor.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Médico eliminado'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Error al eliminar'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ResponsiveWrapper(
        maxWidth: 1400,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsSection(),
              SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Médicos registrados (${_doctors.length})',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Spacer(),
                  ElevatedButton.icon(
                    onPressed: _showCreateDoctorDialog,
                    icon: Icon(Icons.add, size: 18),
                    label: Text('Nuevo médico'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (_isLoading)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF2563EB)),
                    ),
                  ),
                )
              else if (_error != null)
                _buildErrorWidget()
              else if (_doctors.isEmpty)
                _buildEmpty()
              else
                _buildDoctorsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = ResponsiveBreakpoints.getGridColumns(context);
        return GridView.count(
          crossAxisCount: cols > 2 ? 4 : 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth > 900 ? 2.8 : 1.8,
          children: [
            _statCard('Total Médicos', _doctors.length.toString(),
                Icons.medical_services, Colors.teal),
            _statCard(
                'Con Especialización',
                _doctors
                    .where((d) => d.specialization != null)
                    .length
                    .toString(),
                Icons.local_hospital,
                Colors.blue),
            _statCard('Activos', _doctors.length.toString(),
                Icons.check_circle, Colors.green),
            _statCard('Sin Especialización',
                _doctors.where((d) => d.specialization == null).length.toString(),
                Icons.pending_outlined, Colors.orange),
          ],
        );
      },
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
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
          BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500)),
        ],
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
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDoctors,
              icon: Icon(Icons.refresh),
              label: Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(60),
        child: Column(
          children: [
            Icon(Icons.medical_services_outlined,
                size: 72,
                color: Colors.grey.withOpacity(0.5)),
            SizedBox(height: 16),
            Text('No hay médicos registrados',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Text('Crea el primer médico usando el botón "Nuevo médico"',
                style:
                    TextStyle(color: Colors.grey.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _doctors.length,
      itemBuilder: (context, index) => _buildDoctorCard(_doctors[index]),
    );
  }

  Widget _buildDoctorCard(DoctorUser doctor) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.teal.withOpacity(0.2),
                    Color(0xFF2563EB).withOpacity(0.1)
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.medical_services_outlined,
                  color: Colors.teal, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    doctor.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.75),
                    ),
                  ),
                  if (doctor.specialization != null) ...[
                    SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        doctor.specialization!,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.teal,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Colors.red.withOpacity(0.7)),
              onPressed: () => _deleteDoctor(doctor),
              tooltip: 'Eliminar médico',
            ),
          ],
        ),
      ),
    );
  }
}
