import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/rewards_models.dart';

/// Puntos, logros y tienda.
class RewardsRemoteDataSource {
  final ApiClient _apiClient;
  RewardsRemoteDataSource(this._apiClient);

  Future<RewardsSummary> getSummary() async {
    final response = await _apiClient.get(ApiConstants.rewardsSummary);
    return RewardsSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PointsMovement>> getHistory() async {
    final response = await _apiClient.get(ApiConstants.rewardsHistory);
    return (response.data as List<dynamic>)
        .map((e) => PointsMovement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ShopItem>> getShopItems() async {
    final response = await _apiClient.get(ApiConstants.shopItems);
    final data = response.data as Map<String, dynamic>;
    return (data['items'] as List<dynamic>)
        .map((e) => ShopItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Devuelve los premios desbloqueados con la compra (p. ej. "De compras").
  Future<List<GrantedReward>> buy(String itemCode) async {
    final response =
        await _apiClient.post(ApiConstants.shopBuy, data: {'itemCode': itemCode});
    return GrantedReward.listFrom((response.data as Map)['newRewards']);
  }

  Future<void> equip(String itemCode) =>
      _apiClient.post(ApiConstants.shopEquip, data: {'itemCode': itemCode});

  Future<void> unequip(String itemCode) =>
      _apiClient.post(ApiConstants.shopUnequip, data: {'itemCode': itemCode});
}
