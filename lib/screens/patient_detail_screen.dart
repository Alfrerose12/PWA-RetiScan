import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/patient_service.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;
  final void Function(Patient)? onSave;

  const PatientDetailScreen({
    Key? key,
    required this.patient,
    this.onSave,
  }) : super(key: key);

  @override
  _PatientDetailScreenState createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final PatientService _patientService = PatientService();

  late Patient _patient;
  bool _editingPersonal = false;
  bool _saving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _phoneCtrl;
  final _personalKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    _resetControllers();
  }

  void _resetControllers() {
    _nameCtrl = TextEditingController(text: _patient.fullName);
    _ageCtrl = TextEditingController(text: _patient.age.toString());
    _phoneCtrl = TextEditingController(text: _patient.phone ?? '');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePersonal() async {
    if (!(_personalKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final updated = await _patientService.updatePatient(_patient.id, {
        'fullName': _nameCtrl.text.trim(),
        'age': int.parse(_ageCtrl.text.trim()),
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      });
      setState(() {
        _patient = updated;
        _editingPersonal = false;
        _saving = false;
      });
      widget.onSave?.call(_patient);
      _showSnack('Datos actualizados correctamente');
    } catch (e) {
      setState(() => _saving = false);
      _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Paciente',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPatientHeader(),
                  SizedBox(height: 24),
                  _buildPersonalSection(),
                  SizedBox(height: 24),
                  _buildStatsSection(),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: Colors.white, size: 32),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patient.fullName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${_patient.age} años • ${_patient.totalAnalyses} análisis',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                if (_patient.lastVisit != null) ...[
                  SizedBox(height: 4),
                  Text(
                    'Última visita: ${_formatDate(_patient.lastVisit)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    return _sectionCard(
      title: 'Información del Paciente',
      icon: Icons.person_outline,
      isEditing: _editingPersonal,
      onEdit: () {
        _resetControllers();
        setState(() => _editingPersonal = true);
      },
      onCancel: () => setState(() => _editingPersonal = false),
      onSave: _saving ? () {} : _savePersonal,
      viewContent: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 500;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _infoChip('Edad', '${_patient.age} años', Icons.cake, constraints, isWide),
              _infoChip('Teléfono', _patient.phone ?? 'No registrado', Icons.phone, constraints, isWide),
              _infoChip('Total Análisis', '${_patient.totalAnalyses}', Icons.analytics, constraints, isWide),
              _infoChip('Última Visita', _formatDate(_patient.lastVisit), Icons.calendar_today, constraints, isWide),
            ],
          );
        },
      ),
      editContent: Form(
        key: _personalKey,
        child: Column(
          children: [
            _editField(_nameCtrl, 'Nombre completo', Icons.badge_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _editField(_ageCtrl, 'Edad', Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 0 || n > 120) return 'Edad inválida';
                        return null;
                      }),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _editField(_phoneCtrl, 'Teléfono', Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.analytics_outlined, size: 18, color: Color(0xFF2563EB)),
              ),
              SizedBox(width: 10),
              Text('Estadísticas', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statChip(
                  label: 'Total Análisis',
                  value: _patient.totalAnalyses.toString(),
                  icon: Icons.biotech_outlined,
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _statChip(
                  label: 'Última visita',
                  value: _formatDate(_patient.lastVisit),
                  icon: Icons.calendar_today_outlined,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.6))),
                SizedBox(height: 2),
                Text(value,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required bool isEditing,
    required VoidCallback onEdit,
    required VoidCallback onCancel,
    required VoidCallback onSave,
    required Widget viewContent,
    required Widget editContent,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
        border: isEditing
            ? Border.all(color: Color(0xFF2563EB).withOpacity(0.4), width: 1.5)
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 18, color: Color(0xFF2563EB)),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(title,
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                    if (!isEditing)
                      Tooltip(
                        message: 'Editar',
                        child: InkWell(
                          onTap: onEdit,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFF2563EB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_outlined,
                                    size: 16, color: Color(0xFF2563EB)),
                                SizedBox(width: 4),
                                Text('Editar',
                                    style: TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (isEditing) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            side: BorderSide(
                                color: Theme.of(context).dividerColor),
                            padding: EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Cancelar'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : onSave,
                          icon: _saving
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Icon(Icons.check, size: 16),
                          label: Text(_saving ? 'Guardando...' : 'Guardar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            SizedBox(height: 16),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 250),
              child: isEditing
                  ? KeyedSubtree(
                      key: ValueKey('edit_$title'), child: editContent)
                  : KeyedSubtree(
                      key: ValueKey('view_$title'), child: viewContent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value, IconData icon,
      BoxConstraints constraints, bool isWide) {
    return SizedBox(
      width: isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surface
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF2563EB).withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Color(0xFF2563EB), size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.6))),
                  SizedBox(height: 3),
                  Text(value,
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF2563EB), size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
