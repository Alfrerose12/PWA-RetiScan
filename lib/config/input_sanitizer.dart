import 'package:flutter/services.dart';

class InputSanitizer {
  /// Regular expression to detect basic SQL Injection patterns
  static final RegExp _sqlInjectionPattern = RegExp(
    r"(\b(SELECT|INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|TRUNCATE|GRANT|REVOKE|EXEC|UNION|ALL)\b)|(--)|(;)|(OR\s+1\s*=\s*1)",
    caseSensitive: false,
  );

  /// RegExp to allow only alphanumeric, spaces, and standard punctuation (Safe chars)
  static final RegExp _safeCharacters = RegExp(r'^[a-zA-Z0-9\s.,@_\-\+]+$');

  /// Validador que puede usarse en un TextFormField para rechazar caracteres peligrosos
  static String? validateSafeInput(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    // Check for SQL keywords or patterns
    if (_sqlInjectionPattern.hasMatch(value)) {
      return 'Entrada inválida o caracteres no permitidos';
    }

    return null;
  }

  /// Formateador que bloquea la escritura de comillas simples y punto y coma
  static final TextInputFormatter blockDangerousChars = FilteringTextInputFormatter.deny(
    RegExp(r"[';<>`]"),
  );
}
