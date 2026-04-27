/// Constantes para la API del backend
class ApiConstants {
  // Producción
  static const String baseUrl = 'https://mysupple.abacusai.app';

  // Desarrollo local (Chrome / desktop):
  // static const String baseUrl = 'http://localhost:3000';

  // Emulador Android:
  // static const String baseUrl = 'http://10.0.2.2:3000';
  
  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String profile = '/auth/profile';
  
  // Supplements endpoints
  static const String supplementsDatabase = '/supplements/database';
  static const String supplementsDatabaseSearch = '/supplements/database/search';
  
  // User Supplements endpoints
  static const String userSupplements = '/user-supplements';
  
  // Intakes endpoints
  static const String intakes = '/intakes';
  static const String intakesToday = '/intakes/today';
  static const String intakesProgressToday = '/intakes/progress/today';
  
  // Streaks endpoints
  static const String streaksUser = '/streaks/user';
  static const String streaksSupplement = '/streaks/supplement';
  
  // Friends endpoints
  static const String friends = '/friends';
  static const String friendsRequest = '/friends/request';
  static const String friendsAccept = '/friends/accept';
  static const String friendsReject = '/friends/reject';
  static const String friendsRequests = '/friends/requests';
  
  // Leaderboard endpoints
  static const String leaderboardFriends = '/leaderboard/friends';
  static const String leaderboardAdherence = '/leaderboard/adherence';
  
  // Notifications endpoints
  static const String notificationsConfig = '/notifications/config';
}
