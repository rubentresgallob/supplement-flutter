/// Constantes para la API del backend
class ApiConstants {
  /// URL del backend. Se elige al lanzar la app, sin tocar código:
  ///
  ///   flutter run --dart-define=API_URL=http://10.0.2.2:3000     (emulador → backend en tu PC)
  ///   flutter run --dart-define=API_URL=http://192.168.X.X:3000  (móvil físico, misma WiFi)
  ///   flutter run                                                 (por defecto: producción en Render)
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://supplement-backend.onrender.com',
  );
  
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

  // Puntos y tienda
  static const String rewardsSummary = '/rewards/summary';
  static const String rewardsHistory = '/rewards/history';
  static const String shopItems = '/shop/items';
  static const String shopBuy = '/shop/buy';
  static const String shopEquip = '/shop/equip';
  static const String shopUnequip = '/shop/unequip';

  // Plan Pro
  static const String subscription = '/subscription';
  static const String subscriptionTestActivate = '/subscription/test/activate';
  static const String subscriptionTestDeactivate = '/subscription/test/deactivate';
  static const String stats = '/stats';
}
