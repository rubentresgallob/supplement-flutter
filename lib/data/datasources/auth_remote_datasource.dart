import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import 'local_storage_datasource.dart';

/// Data source remoto para autenticación
class AuthRemoteDataSource {
  final ApiClient _apiClient;
  final LocalStorageDataSource _localStorage;
  
  AuthRemoteDataSource(this._apiClient, this._localStorage);
  
  /// Registra un nuevo usuario. NO inicia sesión: el servidor envía un código
  /// al email y hay que llamar a [verifyEmail] con él.
  Future<void> register({
    required String email,
    required String password,
    required String username,
  }) async {
    await _apiClient.post(
      ApiConstants.register,
      data: {
        'email': email,
        'password': password,
        'username': username,
        // La pantalla de registro no deja continuar sin marcar las tres casillas
        'ageConfirmed': true,
        'acceptTerms': true,
        'healthConsent': true,
      },
    );
  }

  /// Verifica el email con el código de 6 cifras y deja la sesión iniciada.
  Future<UserModel> verifyEmail({required String email, required String code}) async {
    final response = await _apiClient.post(
      ApiConstants.verifyEmail,
      data: {'email': email, 'code': code},
    );
    final token = response.data['access_token'] as String;
    await _localStorage.saveToken(token);
    final user = UserModel.fromJson(response.data['user']);
    await _localStorage.saveUserId(user.id);
    await _localStorage.saveUsername(user.username);
    return user;
  }

  /// Pide otro código de verificación (el servidor envía como mucho 1 por minuto).
  Future<void> resendVerification(String email) async {
    await _apiClient.post(ApiConstants.resendVerification, data: {'email': email});
  }
  
  /// Inicia sesión
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );
    
    final token = response.data['access_token'] as String;
    await _localStorage.saveToken(token);
    
    final user = UserModel.fromJson(response.data['user']);
    await _localStorage.saveUserId(user.id);
    await _localStorage.saveUsername(user.username);
    
    return user;
  }
  
  /// Obtiene el perfil del usuario autenticado
  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(ApiConstants.profile);
    return UserModel.fromJson(response.data);
  }
  
  /// Pide un código de 6 cifras por email para recuperar la contraseña.
  Future<void> forgotPassword(String email) async {
    await _apiClient.post(ApiConstants.forgotPassword, data: {'email': email});
  }

  /// Cambia la contraseña con el código y deja la sesión iniciada.
  Future<UserModel> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.resetPassword,
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    );
    final token = response.data['access_token'] as String;
    await _localStorage.saveToken(token);
    final user = UserModel.fromJson(response.data['user']);
    await _localStorage.saveUserId(user.id);
    await _localStorage.saveUsername(user.username);
    return user;
  }

  /// Acepta la versión vigente de los Términos y la Política (las tres casillas).
  Future<void> acceptLegal() async {
    await _apiClient.post(ApiConstants.acceptLegal, data: {
      'ageConfirmed': true,
      'acceptTerms': true,
      'healthConsent': true,
    });
  }

  /// Todos mis datos en JSON (derecho de portabilidad).
  Future<Map<String, dynamic>> exportData() async {
    final response = await _apiClient.get('/auth/export');
    return response.data as Map<String, dynamic>;
  }

  /// Borra la cuenta y todos sus datos en el servidor (pide la contraseña).
  Future<void> deleteAccount(String password) async {
    await _apiClient.post(ApiConstants.deleteAccount, data: {'password': password});
    await _localStorage.clearUserData();
  }

  /// Cierra sesión
  Future<void> logout() async {
    await _localStorage.clearUserData();
  }
}
