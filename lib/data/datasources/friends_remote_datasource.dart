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

  /// Mis interruptores de privacidad con los amigos.
  Future<SharingSettings> getSharing() async {
    final response = await _apiClient.get('/friends/sharing');
    return SharingSettings.fromJson(response.data as Map<String, dynamic>);
  }

  /// Cambia solo lo que se pasa (el servidor guarda cada activación y desactivación).
  Future<SharingSettings> setSharing({bool? progress, bool? supplements, bool? introSeen}) async {
    final response = await _apiClient.put('/friends/sharing', data: {
      if (progress != null) 'progress': progress,
      if (supplements != null) 'supplements': supplements,
      if (introSeen != null) 'introSeen': introSeen,
    });
    return SharingSettings.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Bloquear y denunciar ──

  Future<void> blockUser(int userId) async {
    await _apiClient.post('/users/$userId/block');
  }

  Future<void> unblockUser(int userId) async {
    await _apiClient.delete('/users/$userId/block');
  }

  Future<List<({int id, String username})>> getBlockedUsers() async {
    final response = await _apiClient.get('/users/blocked');
    return (response.data as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .map((e) => (id: e['id'] as int, username: e['username'] as String))
        .toList();
  }

  /// [reason]: offensive_name · impersonation · harassment · other
  Future<void> reportUser(int userId, String reason, String? details) async {
    await _apiClient.post('/users/$userId/report', data: {
      'reason': reason,
      if (details != null) 'details': details,
    });
  }

  Future<Map<String, dynamic>> getFriendProgress(int friendId) async {
    final response = await _apiClient.get('/friends/$friendId/progress');
    return response.data as Map<String, dynamic>;
  }
}

/// Interruptores: "Compartir mi progreso" y "Compartir mis suplementos" (apagados por defecto).
class SharingSettings {
  final bool progress;
  final bool supplements;

  /// Ya vio la pantalla que explica qué ven sus amigos.
  final bool introSeen;

  const SharingSettings({required this.progress, required this.supplements, required this.introSeen});

  factory SharingSettings.fromJson(Map<String, dynamic> json) => SharingSettings(
        progress: json['progress'] as bool? ?? false,
        supplements: json['supplements'] as bool? ?? false,
        introSeen: json['introSeen'] as bool? ?? false,
      );

  SharingSettings copyWith({bool? progress, bool? supplements}) => SharingSettings(
        progress: progress ?? this.progress,
        supplements: supplements ?? this.supplements,
        introSeen: introSeen,
      );
}
