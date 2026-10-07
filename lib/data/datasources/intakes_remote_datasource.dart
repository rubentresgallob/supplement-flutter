import 'dart:async';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/calendar_models.dart';
import '../models/intake_model.dart';
import '../models/streak_model.dart';
import '../models/rewards_models.dart';

/// Data source remoto para tomas
class IntakesRemoteDataSource {
  final ApiClient _apiClient;
  
  IntakesRemoteDataSource(this._apiClient);

  final _rewardsController = StreamController<List<GrantedReward>>.broadcast();

  /// Premios que el backend entrega al registrar una toma (día completo, logros...).
  /// La tienda los escucha para celebrarlos con Capsu y actualizar el saldo.
  Stream<List<GrantedReward>> get rewards => _rewardsController.stream;
  
  /// Registra una nueva toma
  Future<IntakeModel> createIntake({
    required String userSupplementId,
    DateTime? takenAt,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.intakes,
      data: {
        'userSupplementId': int.tryParse(userSupplementId) ?? userSupplementId,
        // En UTC ("...Z"): sin zona horaria el servidor la interpretaría en su hora local
        'takenAt': (takenAt ?? DateTime.now()).toUtc().toIso8601String(),
      },
    );
    final data = response.data as Map<String, dynamic>;
    final granted = GrantedReward.listFrom(data['rewards']);
    if (granted.isNotEmpty) _rewardsController.add(granted);
    return IntakeModel.fromJson(data);
  }
  
  /// Deshace la última toma de hoy de un suplemento.
  Future<void> undoIntake(String userSupplementId) async {
    await _apiClient.post(
      ApiConstants.intakesUndo,
      data: {
        'userSupplementId': int.tryParse(userSupplementId) ?? userSupplementId,
      },
    );
  }

  /// Progreso día a día de un mes (calendario).
  Future<CalendarMonth> getCalendar(int year, int month) async {
    final response = await _apiClient.get(
      ApiConstants.calendar,
      queryParameters: {'month': '$year-${month.toString().padLeft(2, '0')}'},
    );
    return CalendarMonth.fromJson(response.data as Map<String, dynamic>);
  }

  /// Obtiene las tomas de hoy
  Future<List<IntakeModel>> getIntakesToday() async {
    final response = await _apiClient.get(ApiConstants.intakesToday);
    
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => IntakeModel.fromJson(json)).toList();
  }
  
  /// Obtiene el progreso de hoy — devuelve mapa supplementId→{taken,shouldTake}
  Future<Map<String, dynamic>> getProgressToday() async {
    final response = await _apiClient.get(ApiConstants.intakesProgressToday);
    final data = response.data as Map<String, dynamic>;
    final supplements = (data['supplements'] as List<dynamic>? ?? []);
    return {
      for (final s in supplements)
        (s['supplementId']).toString(): {
          'taken': s['takenToday'] as int,
          'shouldTake': s['shouldTake'] as int,
        },
    };
  }
  
  /// Obtiene las estadísticas de un suplemento
  Future<Map<String, dynamic>> getSupplementStats(String supplementId) async {
    final response = await _apiClient.get(
      '${ApiConstants.intakes}/stats/$supplementId',
    );
    return response.data as Map<String, dynamic>;
  }
  
  /// Obtiene la racha del usuario
  Future<StreakModel> getUserStreak() async {
    final response = await _apiClient.get(ApiConstants.streaksUser);
    return StreakModel.fromJson(response.data);
  }
  
  /// Obtiene la racha de un suplemento específico
  Future<StreakModel> getSupplementStreak(String supplementId) async {
    final response = await _apiClient.get(
      '${ApiConstants.streaksSupplement}/$supplementId',
    );
    return StreakModel.fromJson(response.data);
  }
}
