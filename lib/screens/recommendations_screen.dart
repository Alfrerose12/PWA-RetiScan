import 'package:flutter/material.dart';
import '../services/recommendation_service.dart';
import '../widgets/responsive_wrapper.dart';

class RecommendationsScreen extends StatefulWidget {
  @override
  _RecommendationsScreenState createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen>
    with SingleTickerProviderStateMixin {
  final RecommendationService _service = RecommendationService();
  late TabController _tabController;

  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final all = await _service.getMyRecommendations();
      setState(() {
        _recommendations =
            all.where((r) => r['type'] == 'RECOMMENDATION').toList();
        _medications =
            all.where((r) => r['type'] == 'MEDICATION').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmTaken(String id) async {
    try {
      final result = await _service.confirmMedicationTaken(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Toma registrada correctamente'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadData(); // Recargar para actualizar el próximo horario
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis Recomendaciones',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Recomendaciones, medicamentos y recordatorios de tu médico',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          // TabBar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ??
                  Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor:
                  Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              labelStyle:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 14),
                      SizedBox(width: 4),
                      Text('Consejos', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication_outlined, size: 14),
                      SizedBox(width: 4),
                      Text('Medicina', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.alarm, size: 14),
                      SizedBox(width: 4),
                      Text('Alertas', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRecommendationsTab(),
                          _buildMedicationsTab(),
                          _buildRemindersTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final primaryColor = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            SizedBox(height: 16),
            Text(
              _error ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: Icon(Icons.refresh),
              label: Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Recomendaciones generales ──
  Widget _buildRecommendationsTab() {
    if (_recommendations.isEmpty) {
      return _buildEmptyState(
        Icons.lightbulb_outline,
        'Sin recomendaciones',
        'Tu médico aún no ha agregado recomendaciones para ti.',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final rec = _recommendations[index];
        return _buildRecommendationCard(rec);
      },
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    final primaryColor = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.tips_and_updates,
                color: primaryColor, size: 22),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec['title'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (rec['description'] != null) ...[
                  SizedBox(height: 6),
                  Text(
                    rec['description'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.7),
                      height: 1.4,
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

  // ── Tab 2: Medicamentos ──
  Widget _buildMedicationsTab() {
    if (_medications.isEmpty) {
      return _buildEmptyState(
        Icons.medication_outlined,
        'Sin medicamentos',
        'Tu médico aún no te ha asignado medicamentos.',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: _medications.length,
      itemBuilder: (context, index) {
        final med = _medications[index];
        return _buildMedicationCard(med);
      },
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> med) {
    final primaryColor = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;
    final freqHours = med['frequency_hours'];
    final nextDose = med['next_dose_at'] != null
        ? DateTime.tryParse(med['next_dose_at'])
        : null;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.medication, color: Colors.teal, size: 22),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med['title'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    if (med['dosage'] != null)
                      Text(
                        med['dosage'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
              if (freqHours != null)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'c/${freqHours}h',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          if (med['description'] != null) ...[
            SizedBox(height: 8),
            Text(
              med['description'],
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ],
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule,
                  size: 14,
                  color: nextDose != null && nextDose.isBefore(DateTime.now())
                      ? Colors.orange
                      : Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.5)),
              SizedBox(width: 6),
              Text(
                nextDose != null
                    ? 'Próxima toma: ${_formatDateTime(nextDose)}'
                    : 'Sin horario de toma',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      nextDose != null && nextDose.isBefore(DateTime.now())
                          ? Colors.orange
                          : Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.5),
                  fontWeight:
                      nextDose != null && nextDose.isBefore(DateTime.now())
                          ? FontWeight.bold
                          : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Recordatorios (medicamentos con acción de confirmar) ──
  Widget _buildRemindersTab() {
    final pendingMeds = _medications.where((m) {
      final nextDose = m['next_dose_at'] != null
          ? DateTime.tryParse(m['next_dose_at'])
          : null;
      return nextDose != null;
    }).toList();

    // Ordenar por próxima dosis más cercana
    pendingMeds.sort((a, b) {
      final da = DateTime.tryParse(a['next_dose_at'] ?? '');
      final db = DateTime.tryParse(b['next_dose_at'] ?? '');
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    if (pendingMeds.isEmpty) {
      return _buildEmptyState(
        Icons.alarm,
        'Sin recordatorios',
        'No tienes medicamentos con horarios programados.',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: pendingMeds.length,
      itemBuilder: (context, index) {
        final med = pendingMeds[index];
        return _buildReminderCard(med);
      },
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> med) {
    final nextDose = DateTime.tryParse(med['next_dose_at'] ?? '');
    final isPastDue = nextDose != null && nextDose.isBefore(DateTime.now());
    final id = med['id'] as String;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPastDue
              ? Colors.orange.withOpacity(0.4)
              : Theme.of(context).dividerColor.withOpacity(0.1),
          width: isPastDue ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isPastDue ? Colors.orange : Colors.blue)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPastDue ? Icons.notification_important : Icons.alarm,
                  color: isPastDue ? Colors.orange : Colors.blue,
                  size: 22,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med['title'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      isPastDue
                          ? '⚠️ Toma pendiente desde ${_formatDateTime(nextDose!)}'
                          : 'Próxima toma: ${_formatDateTime(nextDose!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isPastDue ? Colors.orange : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        fontWeight:
                            isPastDue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmTaken(id),
              icon: Icon(Icons.check_circle_outline, size: 18),
              label: Text('Ya tomé este medicamento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPastDue
                    ? Colors.orange
                    : (Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary),
                foregroundColor:
                    Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (med['frequency_hours'] != null) ...[
            SizedBox(height: 8),
            Center(
              child: Text(
                'Se reprogramará en ${med['frequency_hours']} horas',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 56,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.3)),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    
    if (diff.isNegative) {
      final absDiff = diff.abs();
      if (absDiff.inMinutes < 60) return 'hace ${absDiff.inMinutes} min';
      if (absDiff.inHours < 24) return 'hace ${absDiff.inHours}h';
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      if (diff.inMinutes < 60) return 'en ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'en ${diff.inHours}h';
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }
}
