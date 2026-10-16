import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import 'notification_service.dart';

/// Notificaciones push (Firebase Cloud Messaging): los avisos de los amigos.
///
/// Solo en Android por ahora. En iPhone hace falta la cuenta de Apple Developer
/// (clave APNs) y `GoogleService-Info.plist`; en la web no hay push.
class PushService {
  static ApiClient? _api;
  static bool _ready = false;
  static String? _token;
  static StreamSubscription<String>? _refreshSub;

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Se llama una vez al arrancar la app.
  static Future<void> initialize(ApiClient api) async {
    if (!_supported) return;
    _api = api;
    try {
      await Firebase.initializeApp();
      // Con la app abierta Android no enseña el push: lo pintamos nosotros
      FirebaseMessaging.onMessage.listen((message) {
        final n = message.notification;
        if (n == null) return;
        NotificationService.showPush(n.title ?? '', n.body ?? '');
      });
      _ready = true;
    } catch (e) {
      debugPrint('Push no disponible: $e');
    }
  }

  /// Tras iniciar sesión: avisa al backend de que este móvil es de este usuario.
  static Future<void> register() async {
    if (!_ready) return;
    try {
      final messaging = FirebaseMessaging.instance;
      _token = await messaging.getToken();
      if (_token != null) await _send(_token!);
      _refreshSub ??= messaging.onTokenRefresh.listen((t) {
        _token = t;
        _send(t);
      });
    } catch (e) {
      debugPrint('No se pudo registrar el push: $e');
    }
  }

  /// Antes de cerrar sesión (aún con la sesión válida): este móvil deja de
  /// recibir los avisos de esta cuenta.
  static Future<void> unregister() async {
    if (!_ready || _token == null) return;
    try {
      await _api?.delete('/push/token', data: {'token': _token});
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('No se pudo dar de baja el push: $e');
    }
    _token = null;
  }

  static Future<void> _send(String token) async {
    await _api?.post('/push/token', data: {'token': token, 'platform': 'android'});
  }
}
