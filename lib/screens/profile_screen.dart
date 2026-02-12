import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/animated_button.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController(text: 'Juan Pérez');
  final _ageController = TextEditingController(text: '45');
  final _emailController = TextEditingController(text: 'juan.perez@email.com');
  final _passwordController = TextEditingController(text: 'password123');

  bool _isEditing = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() {
    setState(() {
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Cambios guardados exitosamente'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Foto de perfil actualizada'),
          backgroundColor: Color(0xFF5258A4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isEditing ? _saveChanges : _toggleEdit,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: _buildProfileHeader(),
              ),
              SizedBox(height: 32),
              _buildProfileForm(),
              SizedBox(height: 24),
              _buildStatisticsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D385E),
            Color(0xFF5258A4),
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
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Color(0xFF5258A4),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.white.withOpacity(0.9)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.camera_alt, color: Color(0xFF5258A4)),
                    onPressed: _changeProfilePicture,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            _nameController.text,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            _emailController.text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Personal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D385E),
          ),
        ),
        SizedBox(height: 16),
        _buildEditableField(
          label: 'Nombre Completo',
          controller: _nameController,
          icon: Icons.person,
          isEditing: _isEditing,
        ),
        SizedBox(height: 16),
        _buildEditableField(
          label: 'Edad',
          controller: _ageController,
          icon: Icons.calendar_today,
          isEditing: _isEditing,
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16),
        _buildEditableField(
          label: 'Correo Electrónico',
          controller: _emailController,
          icon: Icons.email,
          isEditing: _isEditing,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 16),
        _buildPasswordField(),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditing,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isEditing ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditing
              ? Color(0xFF5258A4).withOpacity(0.3)
              : Colors.grey[300]!,
          width: isEditing ? 2 : 1,
        ),
        boxShadow: isEditing
            ? [
                BoxShadow(
                  color: Color(0xFF5258A4).withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isEditing ? Color(0xFF5258A4) : Colors.grey[600],
          ),
          prefixIcon: Icon(
            icon,
            color: isEditing ? Color(0xFF5258A4) : Colors.grey[600],
          ),
          suffixIcon: !isEditing
              ? Icon(Icons.lock, size: 18, color: Colors.grey[400])
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
        readOnly: !isEditing,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildPasswordField() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _isEditing ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEditing
              ? Color(0xFF5258A4).withOpacity(0.3)
              : Colors.grey[300]!,
          width: _isEditing ? 2 : 1,
        ),
        boxShadow: _isEditing
            ? [
                BoxShadow(
                  color: Color(0xFF5258A4).withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: _passwordController,
        decoration: InputDecoration(
          labelText: 'Contraseña',
          labelStyle: TextStyle(
            color: _isEditing ? Color(0xFF5258A4) : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.lock,
            color: _isEditing ? Color(0xFF5258A4) : Colors.grey[600],
          ),
          suffixIcon: !_isEditing
              ? Icon(Icons.lock, size: 18, color: Colors.grey[400])
              : IconButton(
                  icon: Icon(Icons.visibility),
                  onPressed: () {},
                ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
        readOnly: !_isEditing,
        obscureText: true,
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D385E),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Análisis',
                '12',
                Icons.analytics,
                Colors.blue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Normal',
                '10',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Alertas',
                '2',
                Icons.warning,
                Colors.orange,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Días',
                '45',
                Icons.calendar_month,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D385E),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}