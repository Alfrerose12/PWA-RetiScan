import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  SharedPreferences? _prefs;

  User? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  bool get isDoctor => _currentUser?.isDoctor ?? false;

  bool get isClient => _currentUser?.isClient ?? true;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> loadUserFromStorage() async {
    await _initPrefs();
    
    final userId = _prefs?.getString('user_id');
    final fullName = _prefs?.getString('user_fullName');
    final age = _prefs?.getInt('user_age');
    final email = _prefs?.getString('user_email');
    final role = _prefs?.getString('user_role');

    if (userId != null && fullName != null && age != null && email != null && role != null) {
      _currentUser = User(
        id: userId,
        fullName: fullName,
        age: age,
        email: email,
        role: role,
      );
    }
  }

  Future<void> _saveUserToStorage(User user) async {
    await _initPrefs();
    
    await _prefs?.setString('user_id', user.id);
    await _prefs?.setString('user_fullName', user.fullName);
    await _prefs?.setInt('user_age', user.age);
    await _prefs?.setString('user_email', user.email);
    await _prefs?.setString('user_role', user.role);
  }

  Future<void> clearStorage() async {
    await _initPrefs();
    await _prefs?.clear();
    _currentUser = null;
  }

  Future<bool> login(String email, String password) async {
    await Future.delayed(Duration(seconds: 1));

    if (email == 'doctor@retiscan.com') {
      _currentUser = User(
        id: 'doc001',
        fullName: 'Dr. María González',
        age: 42,
        email: 'doctor@retiscan.com',
        role: 'doctor',
      );
      await _saveUserToStorage(_currentUser!);
      return true;
    } else if (email == 'juan.perez@email.com' || email.isNotEmpty) {
      _currentUser = User(
        id: 'user001',
        fullName: 'Juan Pérez',
        age: 45,
        email: email,
        role: 'client',
      );
      await _saveUserToStorage(_currentUser!);
      return true;
    }

    return false;
  }

  Future<bool> register({
    required String fullName,
    required int age,
    required String email,
    required String password,
    required String role,
  }) async {
    await Future.delayed(Duration(seconds: 1));

    _currentUser = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      age: age,
      email: email,
      role: role,
    );

    await _saveUserToStorage(_currentUser!);
    return true;
  }

  Future<void> switchRole(String newRole) async {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        fullName: _currentUser!.fullName,
        age: _currentUser!.age,
        email: _currentUser!.email,
        role: newRole,
      );
      await _saveUserToStorage(_currentUser!);
    }
  }

  Future<void> logout() async {
    await clearStorage();
  }

  void setMockUser({bool asDoctor = false}) {
    if (asDoctor) {
      _currentUser = User(
        id: 'doc001',
        fullName: 'Dr. María González',
        age: 42,
        email: 'doctor@retiscan.com',
        role: 'doctor',
      );
    } else {
      _currentUser = User(
        id: 'user001',
        fullName: 'Juan Pérez',
        age: 45,
        email: 'juan.perez@email.com',
        role: 'client',
      );
    }
    _saveUserToStorage(_currentUser!);
  }
}
