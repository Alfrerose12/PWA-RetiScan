import 'package:flutter/material.dart';
import 'capture_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'admin_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    
    _fabController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  List<Widget> _getScreens() {
    if (_authService.isDoctor) {
      return [
        HomeContent(),
        AdminScreen(),
        ProfileScreen(),
      ];
    } else {
      return [
        HomeContent(),
        CaptureScreen(),
        HistoryScreen(),
        ProfileScreen(),
      ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems() {
    if (_authService.isDoctor) {
      return [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_outlined),
          activeIcon: Icon(Icons.admin_panel_settings),
          label: 'Gestión',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Usuario',
        ),
      ];
    } else {
      return [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera_alt_outlined),
          activeIcon: Icon(Icons.camera_alt),
          label: 'Captura',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history),
          label: 'Histórico',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Usuario',
        ),
      ];
    }
  }

  String _getAppBarTitle() {
    if (_authService.isDoctor) {
      switch (_currentIndex) {
        case 0:
          return 'RetiScan';
        case 1:
          return 'Gestión';
        case 2:
          return 'Perfil';
        default:
          return 'RetiScan';
      }
    } else {
      switch (_currentIndex) {
        case 0:
          return 'RetiScan';
        case 1:
          return 'Captura';
        case 2:
          return 'Histórico';
        case 3:
          return 'Perfil';
        default:
          return 'RetiScan';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _getScreens();
    final navItems = _getNavItems();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              _getAppBarTitle(),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_authService.currentUser != null) ...[ 
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF5258A4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _authService.isDoctor ? 'Médico' : 'Usuario',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SettingsScreen(),
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            _fabController.reset();
            _fabController.forward();
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.secondary,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: navItems,
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _slideAnimations;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimations = List.generate(
      5,
      (index) => Tween<Offset>(
        begin: Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.15,
            1.0,
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final isDoctor = user?.isDoctor ?? false;
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnimatedWidget(0, _buildWelcomeCard(context, isDoctor)),
              SizedBox(height: 24),
              if (isDoctor) ...[
                // Contenido para médicos
                _buildAnimatedWidget(1, _buildSectionTitle(context, 'Pacientes Recientes')),
                SizedBox(height: 16),
                _buildAnimatedWidget(2, _buildPatientItem(context, 'Juan Pérez', 'Normal', '15 Nov 2024')),
                _buildAnimatedWidget(3, _buildPatientItem(context, 'María García', 'Revisión', '14 Nov 2024')),
                _buildAnimatedWidget(4, _buildPatientItem(context, 'Carlos López', 'Leve', '13 Nov 2024')),
                SizedBox(height: 24),
                _buildSectionTitle(context, 'Acciones Rápidas'),
                SizedBox(height: 16),
                _buildRecommendationCard(
                  context,
                  'Revisar diagnósticos pendientes',
                  Icons.assignment_outlined,
                ),
                _buildRecommendationCard(
                  context,
                  'Actualizar protocolos de tratamiento',
                  Icons.medical_services_outlined,
                ),
              ] else ...[
                // Contenido para usuarios
                _buildAnimatedWidget(1, _buildSectionTitle(context, 'Historial Reciente')),
                SizedBox(height: 16),
                _buildAnimatedWidget(2, _buildHistoryItem(context, '15 Nov 2024', 'Normal')),
                _buildAnimatedWidget(3, _buildHistoryItem(context, '01 Nov 2024', 'Normal')),
                _buildAnimatedWidget(4, _buildHistoryItem(context, '15 Oct 2024', 'Leve')),
                SizedBox(height: 24),
                _buildSectionTitle(context, 'Recomendaciones'),
                SizedBox(height: 16),
                _buildRecommendationCard(
                  context,
                  'Realiza tu siguiente revisión en 15 días',
                  Icons.calendar_today,
                ),
                _buildRecommendationCard(
                  context,
                  'Mantén una dieta rica en vitamina A',
                  Icons.restaurant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedWidget(int index, Widget child) {
    return SlideTransition(
      position: _slideAnimations[index],
      child: FadeTransition(
        opacity: _controller,
        child: child,
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, bool isDoctor) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF5258A4).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDoctor ? Icons.medical_services : Icons.visibility,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDoctor ? '¡Bienvenido, Doctor!' : '¡Bienvenido!',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      isDoctor 
                        ? 'Panel de gestión de pacientes'
                        : 'Tu salud visual es nuestra prioridad',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.headlineMedium?.color,
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, String date, String status) {
    Color statusColor = status == 'Normal' ? Colors.green : Colors.orange;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              status == 'Normal' ? Icons.check_circle : Icons.warning,
              color: statusColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Estado: $status',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientItem(BuildContext context, String name, String status, String date) {
    Color statusColor = status == 'Normal' ? Colors.green : 
                        status == 'Leve' ? Colors.orange : Colors.blue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.person,
              color: statusColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$status • $date',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, String text, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
          ? primaryColor.withOpacity(0.1)
          : Color(0xFF5258A4).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
            ? primaryColor.withOpacity(0.3)
            : Color(0xFF5258A4).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                ? primaryColor.withOpacity(0.2)
                : Color(0xFF5258A4).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDark ? primaryColor : Color(0xFF5258A4),
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
