import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_supplement_model.dart';
import '../models/supplement_database_model.dart';

/// Data source remoto para suplementos
class SupplementsRemoteDataSource {
  final ApiClient _apiClient;
  
  SupplementsRemoteDataSource(this._apiClient);
  
  /// Obtiene todos los suplementos del usuario
  Future<List<UserSupplementModel>> getUserSupplements() async {
    final response = await _apiClient.get(ApiConstants.userSupplements);
    
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => UserSupplementModel.fromJson(json)).toList();
  }
  
  /// Obtiene un suplemento por ID
  Future<UserSupplementModel> getUserSupplementById(String id) async {
    final response = await _apiClient.get('${ApiConstants.userSupplements}/$id');
    return UserSupplementModel.fromJson(response.data);
  }
  
  /// Crea un nuevo suplemento
  Future<UserSupplementModel> createUserSupplement({
    String? supplementDatabaseId,
    required String customName,
    required String form,
    required double dosageAmount,
    required String dosageUnit,
    required int timesPerDay,
    required List<String> schedules,
  }) async {
    final dbId = supplementDatabaseId != null ? int.tryParse(supplementDatabaseId) : null;
    final response = await _apiClient.post(
      ApiConstants.userSupplements,
      data: {
        if (dbId != null) 'supplementDatabaseId': dbId,
        'customName': customName,
        'form': form,
        'dosageAmount': dosageAmount,
        'dosageUnit': dosageUnit,
        'timesPerDay': timesPerDay,
        'schedules': schedules,
      },
    );
    
    return UserSupplementModel.fromJson(response.data);
  }
  
  /// Actualiza un suplemento
  Future<UserSupplementModel> updateUserSupplement(
    String id, {
    String? customName,
    String? form,
    double? dosageAmount,
    String? dosageUnit,
    int? timesPerDay,
    List<String>? schedules,
    bool? active,
  }) async {
    final data = <String, dynamic>{};
    if (customName != null) data['customName'] = customName;
    if (form != null) data['form'] = form;
    if (dosageAmount != null) data['dosageAmount'] = dosageAmount;
    if (dosageUnit != null) data['dosageUnit'] = dosageUnit;
    if (timesPerDay != null) data['timesPerDay'] = timesPerDay;
    if (schedules != null) data['schedules'] = schedules;
    if (active != null) data['active'] = active;
    
    final response = await _apiClient.put(
      '${ApiConstants.userSupplements}/$id',
      data: data,
    );
    
    return UserSupplementModel.fromJson(response.data);
  }
  
  /// Elimina un suplemento
  Future<void> deleteUserSupplement(String id) async {
    await _apiClient.delete('${ApiConstants.userSupplements}/$id');
  }

  /// Obtiene todos los suplementos del catálogo global
  Future<List<SupplementDatabaseModel>> getSupplementsDatabase() async {
    final response = await _apiClient.get(ApiConstants.supplementsDatabase);
    final List<dynamic> data = (response.data['data'] ?? response.data) as List<dynamic>;
    return data.map((json) => SupplementDatabaseModel.fromJson(json)).toList();
  }

  /// Busca suplementos en el catálogo por nombre o categoría
  Future<List<SupplementDatabaseModel>> searchSupplementsDatabase(String query) async {
    final response = await _apiClient.get(
      ApiConstants.supplementsDatabaseSearch,
      queryParameters: {'q': query},
    );
    final List<dynamic> data = (response.data['data'] ?? response.data) as List<dynamic>;
    return data.map((json) => SupplementDatabaseModel.fromJson(json)).toList();
  }
}
