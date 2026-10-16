import '../../core/network/api_client.dart';
import '../models/calendar_models.dart';
import '../models/friend_profile.dart';

class FriendsRemoteDataSource {
  final ApiClient _apiClient;
  FriendsRemoteDataSource(this._apiClient);

  Future<List<Map<String, dynamic>>> getFriends() async {
    final response = await _apiClient.get('/friends');
    return (response.data as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final response = await _apiClient.get('/friends/requests');
    return (response.data as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<void> sendRequest(String identifier) async {
    await _apiClient.post('/friends/request', data: {'identifier': identifier});
  }

  Future<void> acceptRequest(int requestId) async {
    await _apiClient.post('/friends/accept/$requestId');
  }

  Future<void> rejectRequest(int requestId) async {
    await _apiClient.post('/friends/reject/$requestId');
  }

  Future<void> removeFriend(int friendId) async {
    await _apiClient.delete('/friends/$friendId');
  }

  /// Manda un push al amigo. Devuelve si le ha llegado a algún móvil.
  Future<bool> sendMotivation(int friendId) async {
    final response = await _apiClient.post('/friends/$friendId/motivate');
    final data = response.data;
    return data is Map && data['delivered'] == true;
  }

  Future<Map<String, dynamic>> getLeaderboardStreaks() async {
    final response = await _apiClient.get('/leaderboard/friends');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getLeaderboardAdherence() async {
    final response = await _apiClient.get('/leaderboard/adherence');
    return response.data as Map<String, dynamic>;
  }

  /// Perfil de un amigo: su Capsu, racha y, si lo comparte, su stack de hoy.
  Future<FriendProfile> getFriendProfile(int friendId) async {
    final response = await _apiClient.get('/friends/$friendId/profile');
    return FriendProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// Calendario mensual de un amigo (solo si lo comparte).
  Future<CalendarMonth> getFriendCalendar(int friendId, int year, int month) async {
    final response = await _apiClient.get(
      '/friends/$friendId/calendar',
      queryParameters: {'month': '$year-${month.toString().padLeft(2, '0')}'},
    );
    return CalendarMonth.fromJson(response.data as Map<String, dynamic>);
  }

  /// ¿Comparto mi stack y mi calendario con mis amigos?
  Future<bool> getSharing() async {
    final response = await _apiClient.get('/friends/sharing');
    return (response.data as Map<String, dynamic>)['enabled'] as bool? ?? true;
  }

  Future<void> setSharing(bool enabled) async {
    await _apiClient.put('/friends/sharing', data: {'enabled': enabled});
  }

  Future<Map<String, dynamic>> getFriendProgress(int friendId) async {
    final response = await _apiClient.get('/friends/$friendId/progress');
    return response.data as Map<String, dynamic>;
  }
}
