import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import '../../data/datasources/local_storage_datasource.dart';
import '../errors/exceptions.dart';

/// Cliente API configurado con Dio
class ApiClient {
  late final Dio _dio;
  final LocalStorageDataSource _localStorage;
  final Logger _logger = Logger(
    level: kReleaseMode ? Level.off : Level.debug,
  );

  ApiClient(this._localStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        // Render gratis "duerme" el servidor tras 15 min sin uso:
        // la primera petición puede tardar ~50 s en despertarlo.
        connectTimeout: const Duration(seconds: 70),
        receiveTimeout: const Duration(seconds: 70),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    _setupInterceptors();
  }
  
  /// Configura los interceptores de Dio
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Agregar token JWT si existe
          final token = await _localStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          _logger.d('➡️ ${options.method} ${options.path}');
          _logger.d('Headers: ${options.headers}');
          if (options.data != null) {
            _logger.d('Body: ${options.data}');
          }
          
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('⬅️ ${response.statusCode} ${response.requestOptions.path}');
          _logger.d('Response: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('❌ Error: ${error.message}');
          _logger.e('Response: ${error.response?.data}');
          handler.next(error);
        },
      ),
    );
  }
  
  /// Realiza una petición GET
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Realiza una petición POST
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Realiza una petición PUT
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Realiza una petición DELETE
  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Maneja los errores de Dio y los convierte en excepciones personalizadas
  Exception _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return NetworkException(
          'El servidor está tardando en responder (puede estar despertando). Inténtalo de nuevo en unos segundos.');
    }
    
    if (error.type == DioExceptionType.connectionError) {
      return NetworkException('No se pudo conectar al servidor. Verifica tu conexión a internet.');
    }
    
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final rawMessage = data is Map ? data['message'] : null;
    // class-validator devuelve una lista de mensajes en los 400
    final String message = rawMessage is List
        ? rawMessage.join('\n')
        : (rawMessage?.toString() ?? 'Error desconocido');
    final path = error.requestOptions.path;

    if (statusCode == 403 && data is Map && data['code'] == 'EMAIL_NOT_VERIFIED') {
      return EmailNotVerifiedException(message);
    }
    if (statusCode == 403 && data is Map && data['code'] == 'PRO_REQUIRED') {
      return ProRequiredException(message);
    }

    switch (statusCode) {
      case 400:
        return ValidationException(message);
      case 401:
        // En login/registro un 401 son credenciales incorrectas, no una sesión caducada
        if (path == ApiConstants.login || path == ApiConstants.register) {
          return AuthException('Email o contraseña incorrectos.');
        }
        return AuthException('Sesión expirada. Por favor, inicia sesión nuevamente.');
      case 429:
        return ValidationException('Demasiados intentos. Espera un poco y vuelve a probar.');
      case 503:
        return ServerException(message);
      case 409:
        if (message.contains('Email')) {
          return ValidationException('Ya existe una cuenta con ese email.');
        }
        if (message.contains('Username')) {
          return ValidationException('Ese nombre de usuario ya está en uso.');
        }
        return ValidationException(message);
      case 404:
        return NotFoundException(message);
      case 500:
        return ServerException('Error del servidor. Inténtalo de nuevo más tarde.');
      default:
        return ServerException(message);
    }
  }
}
