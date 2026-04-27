import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import '../../../data/datasources/local_storage_datasource.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC para manejar la autenticación
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRemoteDataSource _authDataSource;
  final LocalStorageDataSource _localStorage;
  
  AuthBloc(this._authDataSource, this._localStorage)
      : super(AuthInitialState()) {
    on<AuthCheckStatusEvent>(_onCheckStatus);
    on<AuthRegisterEvent>(_onRegister);
    on<AuthLoginEvent>(_onLogin);
    on<AuthLogoutEvent>(_onLogout);
  }
  
  /// Verifica si el usuario está autenticado
  Future<void> _onCheckStatus(
    AuthCheckStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoadingState());
      
      final isAuthenticated = await _localStorage.isAuthenticated();
      
      if (isAuthenticated) {
        final user = await _authDataSource.getProfile();
        emit(AuthAuthenticatedState(user));
      } else {
        emit(AuthUnauthenticatedState());
      }
    } catch (e) {
      emit(AuthUnauthenticatedState());
    }
  }
  
  /// Registra un nuevo usuario
  Future<void> _onRegister(
    AuthRegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoadingState());
      
      final user = await _authDataSource.register(
        email: event.email,
        password: event.password,
        username: event.username,
      );
      
      emit(AuthAuthenticatedState(user));
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }
  
  /// Inicia sesión
  Future<void> _onLogin(
    AuthLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoadingState());
      
      final user = await _authDataSource.login(
        email: event.email,
        password: event.password,
      );
      
      emit(AuthAuthenticatedState(user));
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }
  
  /// Cierra sesión
  Future<void> _onLogout(
    AuthLogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoadingState());
      await _authDataSource.logout();
      emit(AuthUnauthenticatedState());
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }
}
