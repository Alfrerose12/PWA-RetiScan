import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajustes'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notificaciones'),
            trailing: Switch(value: true, onChanged: (value) {}),
          ),
          ListTile(
            leading: Icon(Icons.security),
            title: Text('Privacidad'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Ayuda y Soporte'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('Acerca de'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Cerrar Sesión'),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/login', 
                (route) => false
              );
            },
          ),
        ],
      ),
    );
  }
}