import 'package:flutter/services.dart';

class InputSanitizer {
  // ── Formateadores (bloquean en tiempo real) ──────────────────

  /// Solo letras (a-z A-Z), acentos (áéíóúñ) y espacios.
  /// Ideal para: Nombre, Apellido Paterno, Apellido Materno.
  static final TextInputFormatter nameOnly = FilteringTextInputFormatter.allow(
    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]'),
  );

  /// Solo dígitos (0-9).
  /// Ideal para: Teléfono.
  static final TextInputFormatter phoneOnly = FilteringTextInputFormatter.digitsOnly;

  /// Solo letras, números, guion bajo y punto.
  /// Ideal para: Nombre de usuario.
  static final TextInputFormatter usernameOnly = FilteringTextInputFormatter.allow(
    RegExp(r'[a-zA-Z0-9._]'),
  );

  /// Bloquea comillas, punto y coma, y tags HTML.
  static final TextInputFormatter blockDangerousChars = FilteringTextInputFormatter.deny(
    RegExp(r"[';<>`]"),
  );

  // ── Validadores (retornan mensaje de error o null) ──────────

  /// Valida que sea un nombre válido: 2-50 caracteres, solo letras.
  static String? validateName(String? value, {String campo = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$campo es requerido';
    }
    if (value.trim().length < 2) {
      return '$campo debe tener al menos 2 caracteres';
    }
    if (value.trim().length > 50) {
      return '$campo no puede exceder 50 caracteres';
    }
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$').hasMatch(value.trim())) {
      return '$campo solo puede contener letras';
    }
    return null;
  }

  /// Valida teléfono de exactamente 10 dígitos.
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es requerido';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
      return 'Ingresa un teléfono válido de 10 dígitos';
    }
    return null;
  }

  /// Valida formato básico de email.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es requerido';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  /// Detecta patrones de SQL Injection.
  static String? validateSafeInput(String? value) {
    if (value == null || value.isEmpty) return null;
    final sqlPattern = RegExp(
      r"(\b(SELECT|INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|TRUNCATE|GRANT|REVOKE|EXEC|UNION|ALL)\b)|(--)|(;)|(OR\s+1\s*=\s*1)",
      caseSensitive: false,
    );
    if (sqlPattern.hasMatch(value)) {
      return 'Entrada inválida o caracteres no permitidos';
    }
    return null;
  }
}
