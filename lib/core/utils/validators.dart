/// Validadores para formularios
class Validators {
  /// Valida que el email tenga formato correcto
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    
    return null;
  }
  
  /// Valida que la contraseña tenga al menos 6 caracteres
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    
    return null;
  }
  
  /// Valida que el campo no esté vacío
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    
    return null;
  }
  
  /// Valida que el username tenga formato correcto
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre de usuario es requerido';
    }
    
    if (value.length < 3) {
      return 'El nombre de usuario debe tener al menos 3 caracteres';
    }
    
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'El nombre de usuario solo puede contener letras, números y guiones bajos';
    }
    
    return null;
  }
}
