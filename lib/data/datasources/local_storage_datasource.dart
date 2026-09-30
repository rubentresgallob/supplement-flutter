import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class LocalStorageDataSource {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  LocalStorageDataSource(this._prefs)
      : _secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  // ── Token JWT (almacenamiento seguro — Keystore/Keychain) ─────────────────

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _secureStorage.read(key: AppConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Datos de usuario (SharedPreferences — no sensibles) ───────────────────

  Future<void> saveUserId(String userId) async {
    await _prefs.setString(AppConstants.userIdKey, userId);
  }

  Future<String?> getUserId() async {
    return _prefs.getString(AppConstants.userIdKey);
  }

  Future<void> saveUsername(String username) async {
    await _prefs.setString(AppConstants.usernameKey, username);
  }

  Future<String?> getUsername() async {
    return _prefs.getString(AppConstants.usernameKey);
  }

  Future<void> clearUserData() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
    await _prefs.remove(AppConstants.userIdKey);
    await _prefs.remove(AppConstants.usernameKey);
  }

  // ── Horarios de notificación ──────────────────────────────────────────────

  Future<void> saveNotificationTime(String supplementId, TimeOfDay time) async {
    await _prefs.setString('notif_time_$supplementId', '${time.hour}:${time.minute}');
  }

  TimeOfDay? getNotificationTime(String supplementId) {
    final str = _prefs.getString('notif_time_$supplementId');
    if (str == null) return null;
    final parts = str.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> removeNotificationTime(String supplementId) async {
    await _prefs.remove('notif_time_$supplementId');
  }

  // ── Bio del usuario ───────────────────────────────────────────────────────

  Future<void> saveBio(String bio) async {
    await _prefs.setString('user_bio', bio);
  }

  String getBio() {
    return _prefs.getString('user_bio') ?? '';
  }

  // ── Tutorial inicial con Capsu ────────────────────────────────────────────

  bool isOnboardingDone() {
    return _prefs.getBool('onboarding_done') ?? false;
  }

  Future<void> setOnboardingDone() async {
    await _prefs.setBool('onboarding_done', true);
  }
}
