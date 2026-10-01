import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/pro_models.dart';
import '../models/user_supplement_model.dart';

/// Plan Pro: suscripción, estadísticas y stock.
class ProRemoteDataSource {
  final ApiClient _apiClient;
  ProRemoteDataSource(this._apiClient);

  Future<ProStatus> getStatus() async {
    final response = await _apiClient.get(ApiConstants.subscription);
    return ProStatus.fromJson(response.data as Map<String, dynamic>);
  }

  /// Solo funciona si el backend tiene PRO_TEST_MODE=true.
  Future<ProStatus> activateTest() async {
    final response = await _apiClient.post(ApiConstants.subscriptionTestActivate, data: {});
    return ProStatus.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProStatus> deactivateTest() async {
    final response = await _apiClient.post(ApiConstants.subscriptionTestDeactivate);
    return ProStatus.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StatsReport> getStats(int days) async {
    final response =
        await _apiClient.get(ApiConstants.stats, queryParameters: {'days': days});
    return StatsReport.fromJson(response.data as Map<String, dynamic>, days);
  }

  /// [stockUnits] null desactiva el control de stock.
  Future<UserSupplementModel> updateStock(
    String supplementId, {
    required double? stockUnits,
    double? unitsPerIntake,
  }) async {
    final response = await _apiClient.put(
      '${ApiConstants.userSupplements}/$supplementId/stock',
      data: {
        'stockUnits': stockUnits,
        if (unitsPerIntake != null) 'unitsPerIntake': unitsPerIntake,
      },
    );
    return UserSupplementModel.fromJson(response.data as Map<String, dynamic>);
  }
}
