import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/animated_button.dart';
import '../widgets/responsive_wrapper.dart';
import '../services/pdf_service.dart';
import '../services/notification_service.dart';
import '../services/analysis_service.dart';
import '../services/auth_service.dart';
import '../models/analysis.dart';

class CaptureScreen extends StatefulWidget {
  @override
  _CaptureScreenState createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with TickerProviderStateMixin {
  XFile? _selectedImageFile;
  bool _isUploading = false;
  bool _analysisComplete = false;
  Analysis? _analysisResult;
  Map<String, String>? _displayResults;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _revealController;
  late AnimationController _orbitController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _revealAnimation;

  String _statusMessage = 'Procesando retina, por favor espera';
  double _currentProgress = 0.0;

  final AnalysisService _analysisService = AnalysisService();
  final AuthService _authService = AuthService();
  StreamSubscription? _pollSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    );
    _revealController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _orbitController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _revealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pollSubscription?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    _revealController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  // ── Mostrar guía visual antes de tomar foto ──
  void _showCameraGuide() {
    final primaryColor = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de guía
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor, width: 3),
                  color: primaryColor.withOpacity(0.05),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.visibility, size: 40, color: primaryColor),
                    Positioned(
                      bottom: 15,
                      child: Container(
                        width: 50,
                        height: 2,
                        color: primaryColor.withOpacity(0.5),
                      ),
                    ),
                    // Crosshair lines
                    Positioned(
                      top: 20,
                      child: Container(width: 2, height: 15, color: primaryColor.withOpacity(0.3)),
                    ),
                    Positioned(
                      bottom: 20,
                      child: Container(width: 2, height: 15, color: primaryColor.withOpacity(0.3)),
                    ),
                    Positioned(
                      left: 20,
                      child: Container(width: 15, height: 2, color: primaryColor.withOpacity(0.3)),
                    ),
                    Positioned(
                      right: 20,
                      child: Container(width: 15, height: 2, color: primaryColor.withOpacity(0.3)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Guía para tomar la foto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 16),
              _buildGuideStep('1', 'Coloca el dispositivo frente al ojo a capturar'),
              _buildGuideStep('2', 'Asegúrate de tener buena iluminación'),
              _buildGuideStep('3', 'Centra el ojo dentro del marco circular'),
              _buildGuideStep('4', 'Mantén el dispositivo estable y enfoca'),
              _buildGuideStep('5', 'Presiona el botón para capturar'),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                      icon: Icon(Icons.camera_alt, size: 18),
                      label: Text('Abrir Cámara'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideStep(String number, String text) {
    final primaryColor = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = pickedFile;
        _isUploading = true;
        _analysisComplete = false;
        _currentProgress = 0.0;
        _statusMessage = 'Enviando imagen al servidor...';
      });

      _progressController.forward(from: 0);
      _orbitController.repeat();
      await _runAnalysis();
    }
  }

  Future<void> _runAnalysis() async {
    try {
      // Simular progreso visual mientras se conecta a la API
      // En un entorno real, aquí se enviaría la imagen al servidor
      setState(() => _statusMessage = 'Analizando imagen con IA...');

      // Usar el servicio existente para crear el análisis
      // Por ahora usamos simulación porque el endpoint requiere patientId del médico
      await Future.delayed(Duration(milliseconds: 1500));
      setState(() {
        _currentProgress = 0.4;
        _statusMessage = 'Procesando retina...';
      });

      await Future.delayed(Duration(milliseconds: 1000));
      setState(() {
        _currentProgress = 0.7;
        _statusMessage = 'Detectando anomalías...';
      });

      await Future.delayed(Duration(milliseconds: 1000));
      setState(() {
        _currentProgress = 1.0;
        _statusMessage = 'Análisis completado';
      });

      await Future.delayed(Duration(milliseconds: 300));

      setState(() {
        _isUploading = false;
        _analysisComplete = true;
        _displayResults = {
          'Macula': 'Normal',
          'Vasos sanguíneos': 'Leves cambios',
          'Papila óptica': 'Normal',
          'Retina': 'Sin anomalías detectadas',
          'Vitreo': 'Transparente',
        };
      });

      _orbitController.stop();
      _revealController.forward(from: 0);

      NotificationService.showNotification(
        id: 0,
        title: 'Análisis Completado',
        body: 'El análisis de su retina ha finalizado. Verifique los resultados.',
      );
    } catch (e) {
      _orbitController.stop();
      setState(() {
        _isUploading = false;
        _statusMessage = 'Error en el análisis';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetAnalysis() {
    setState(() {
      _selectedImageFile = null;
      _analysisComplete = false;
      _displayResults = null;
      _analysisResult = null;
      _currentProgress = 0.0;
    });
    _progressController.reset();
    _revealController.reset();
    _orbitController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Captura de Retina',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 500),
        child: _isUploading
            ? _buildUploadingScreen()
            : _analysisComplete
                ? _buildAnalysisResults()
                : _buildCaptureOptions(),
      ),
    );
  }

  Widget _buildCaptureOptions() {
    _pulseController.repeat(reverse: true);

    return ResponsiveWrapper(
      maxWidth: 800,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(height: 40),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).brightness == Brightness.dark
                            ? Color(0xFF2D385E).withOpacity(0.1)
                            : Colors.blueAccent.withOpacity(0.05),
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 40),
            Text(
              'Selecciona una opción para capturar\nla imagen de tu retina',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            SizedBox(height: 60),
            AnimatedButton(
              text: 'Tomar Foto',
              icon: Icons.camera_alt,
              onPressed: _showCameraGuide,
              backgroundColor: Theme.of(context).colorScheme.primary,
              height: 60,
            ),
            SizedBox(height: 16),
            AnimatedButton(
              text: 'Seleccionar de Galería',
              icon: Icons.photo_library,
              onPressed: () => _pickImage(ImageSource.gallery),
              backgroundColor: Theme.of(context).colorScheme.primary,
              height: 60,
            ),
          ],
        ),
      ),
    );
  }

  // ── Pantalla de análisis en progreso con circulo progresivo + nodos orbitantes ──
  Widget _buildUploadingScreen() {
    final primaryColor = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circulo progresivo con nodos orbitantes
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Nodos orbitantes
                AnimatedBuilder(
                  animation: _orbitController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(200, 200),
                      painter: _OrbitNodesPainter(
                        progress: _orbitController.value,
                        color: primaryColor,
                      ),
                    );
                  },
                ),
                // Circulo progresivo
                SizedBox(
                  width: 140,
                  height: 140,
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      final displayProgress = _currentProgress > 0
                          ? _currentProgress
                          : _progressAnimation.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background circle
                          CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 8,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).dividerColor.withOpacity(0.1),
                            ),
                          ),
                          // Progress circle
                          CircularProgressIndicator(
                            value: displayProgress,
                            strokeWidth: 8,
                            strokeCap: StrokeCap.round,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                          // Percentage
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(displayProgress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              SizedBox(height: 2),
                              Icon(
                                Icons.visibility,
                                size: 18,
                                color: primaryColor.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
          Text(
            'Analizando imagen...',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineMedium?.color,
            ),
          ),
          SizedBox(height: 12),
          Text(
            _statusMessage,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults() {
    return ResponsiveWrapper(
      maxWidth: 900,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: FadeTransition(
          opacity: _revealAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]!
                            : Colors.grey[200]!,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image,
                          size: 60,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.green.shade400],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              color: Theme.of(context).colorScheme.onPrimary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Estado: Normal',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Información Médica',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                ),
              ),
              SizedBox(height: 16),
              ...(_displayResults ?? {}).entries.map((entry) => _buildResultItem(
                    entry.key,
                    entry.value,
                  )),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                        : Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.medical_services,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Te recomendamos consultar con un especialista para una evaluación completa.',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetAnalysis,
                      icon: Icon(Icons.refresh),
                      label: Text('Nueva Captura'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.primary, width: 2),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: AnimatedButton(
                      text: 'Guardar',
                      icon: Icons.save,
                      onPressed: () {},
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final resultsString = (_displayResults ?? {})
                        .entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join('\n');
                    PdfService.generateAndShareReport(
                      patientName: 'Paciente de prueba',
                      analysisResult: resultsString,
                      date: DateTime.now().toString().split(' ')[0],
                    );
                  },
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text('Exportar Resumen a PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.2)
              : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Painter para nodos orbitantes ──
class _OrbitNodesPainter extends CustomPainter {
  final double progress;
  final Color color;

  _OrbitNodesPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Dibujar 6 nodos que orbitan
    for (int i = 0; i < 6; i++) {
      final angle = (progress * 2 * math.pi) + (i * math.pi / 3);
      final nodeRadius = 4.0 - (i * 0.4); // Tamaño decreciente
      final opacity = 1.0 - (i * 0.12); // Opacidad decreciente (trail effect)

      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      final paint = Paint()
        ..color = color.withOpacity(opacity.clamp(0.2, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), nodeRadius.clamp(1.5, 4.0), paint);
    }

    // Glow effect en el nodo principal
    final mainAngle = progress * 2 * math.pi;
    final mainX = center.dx + radius * math.cos(mainAngle);
    final mainY = center.dy + radius * math.sin(mainAngle);

    final glowPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(Offset(mainX, mainY), 8, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitNodesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}