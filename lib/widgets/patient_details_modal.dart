import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import '../models/patient.dart';
import '../models/analysis.dart';
import '../services/analysis_service.dart';
import 'analysis_detail_modal.dart';

class PatientDetailsModal extends StatefulWidget {
  final Patient patient;

  const PatientDetailsModal({Key? key, required this.patient}) : super(key: key);

  @override
  _PatientDetailsModalState createState() => _PatientDetailsModalState();
}

class _PatientDetailsModalState extends State<PatientDetailsModal> {
  final AnalysisService _analysisService = AnalysisService();
  List<Analysis> _patientAnalyses = [];
  bool _isLoadingAnalyses = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
  }

  Future<void> _loadAnalyses() async {
    try {
      final analyses = await _analysisService.getAnalysesByPatient(widget.patient.id);
      setState(() {
        _patientAnalyses = analyses;
        _isLoadingAnalyses = false;
      });
    } catch (e) {
      setState(() => _isLoadingAnalyses = false);
    }
  }

  void _showAnalysisDetail(Analysis analysis) async {
    await showDialog(
      context: context,
      builder: (context) => AnalysisDetailModal(analysis: analysis),
    );
    // Recargar análisis por si el doctor actualizó las notas
    _loadAnalyses();
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    final primaryColor = Theme.of(context).brightness == Brightness.dark 
        ? Theme.of(context).colorScheme.secondary 
        : Theme.of(context).colorScheme.primary;
        
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealAnalysisCard(Analysis analysis) {
    Color statusColor;
    switch (analysis.status) {
      case 'COMPLETED':
        statusColor = Colors.green;
        break;
      case 'PENDING':
        statusColor = Colors.orange;
        break;
      case 'FAILED':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    String date = "Sin fecha";
    if (analysis.createdAt != null) {
      date = "${analysis.createdAt!.day.toString().padLeft(2, '0')}/${analysis.createdAt!.month.toString().padLeft(2, '0')}/${analysis.createdAt!.year}";
    }
    
    String resultDesc = 'En progreso';
    if (analysis.status == 'COMPLETED' && analysis.aiResult != null && analysis.aiResult!['grade'] != null) {
      resultDesc = 'Grado: ${analysis.aiResult!['grade']} (${analysis.aiResult!['confidence']})';
    }

    return InkWell(
      onTap: () => _showAnalysisDetail(analysis),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 4),
                    Text(resultDesc, style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(analysis.status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    String formatDate(DateTime? date) {
      if (date == null) return 'No disponible';
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: 500, maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Text('Detalles del Paciente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF17387A), Color(0xFF2B52B6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF17387A).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            child: const Icon(Icons.person, size: 40, color: Colors.white),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.patient.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(widget.patient.email ?? 'Sin correo', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    Text('Información del Paciente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
                    const SizedBox(height: 16),
                    
                    _buildInfoCard(Icons.cake, 'Edad', '${widget.patient.age} años'),
                    _buildInfoCard(Icons.phone, 'Teléfono', widget.patient.phone ?? 'No disponible'),
                    _buildInfoCard(Icons.calendar_today, 'Última Visita', formatDate(widget.patient.lastVisit)),
                    
                    const SizedBox(height: 32),
                    Text('Historial de Análisis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
                    const SizedBox(height: 16),
                    
                    if (_isLoadingAnalyses)
                      const Center(child: CircularProgressIndicator())
                    else if (_patientAnalyses.isEmpty)
                      Text('El paciente no tiene análisis registrados.', style: TextStyle(color: textPrimary.withOpacity(0.6)))
                    else
                      ..._patientAnalyses.map((analysis) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildRealAnalysisCard(analysis),
                      )).toList(),
                      
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
