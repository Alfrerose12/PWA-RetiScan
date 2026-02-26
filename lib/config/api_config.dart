// Configuración global de la API RetiScan
// Cambia baseUrl si el backend corre en otro host/puerto.

class ApiConfig {
  static const String baseUrl = 'http://localhost:3000/api';

  // Headers para requests autenticados
  static Map<String, String> authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // Headers para requests públicos (login, register)
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
  };
}
