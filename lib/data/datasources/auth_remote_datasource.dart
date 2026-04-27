import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import 'local_storage_datasource.dart';

/// Data source remoto para autenticación
class AuthRemoteDataSource {
  final ApiClient _apiClient;
  final LocalStorageDataSource _localStorage;
  
  AuthRemoteDataSource(this._apiClient, this._localStorage);
  
  /// Registra un nuevo usuario
  Future<UserModel> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.register,
      data: {
        'email': email,
        'password': password,
        'username': username,
      },
    );
    
    final token = response.data['access_token'] as String;
    await _localStorage.saveToken(token);
    
    final user = UserModel.fromJson(response.data['user']);
    await _localStorage.saveUserId(user.id);
    await _localStorage.saveUsername(user.username);
    
    return user;
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
  
  /// Cierra sesión
  Future<void> logout() async {
    await _localStorage.clearUserData();
  }
}
