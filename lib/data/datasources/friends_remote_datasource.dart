import '../../core/network/api_client.dart';

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

  Future<void> sendMotivation(int friendId) async {
    await _apiClient.post('/friends/$friendId/motivate');
  }

  Future<Map<String, dynamic>> getLeaderboardStreaks() async {
    final response = await _apiClient.get('/leaderboard/friends');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getLeaderboardAdherence() async {
    final response = await _apiClient.get('/leaderboard/adherence');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getFriendProgress(int friendId) async {
    final response = await _apiClient.get('/friends/$friendId/progress');
    return response.data as Map<String, dynamic>;
  }
}
