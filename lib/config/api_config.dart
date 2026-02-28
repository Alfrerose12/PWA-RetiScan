// Configuración global de la API RetiScan
// Cambia baseUrl si el backend corre en otro host/puerto.

class ApiConfig {
  // Para desarrollo local desde el mismo PC usa: http://localhost:3000/api
  // Para acceder desde celular (misma red WiFi), usa tu IP local:
  static const String baseUrl = 'http://192.168.1.83:3000/api';

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
