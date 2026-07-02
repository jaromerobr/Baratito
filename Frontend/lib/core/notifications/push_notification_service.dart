/// Servicio de notificaciones push (FCM) de Baratito.
///
/// - Pide permiso (incluye Android 13+ POST_NOTIFICATIONS).
/// - Registra el token FCM en Supabase (tabla push_tokens), multi-dispositivo.
/// - Maneja los 3 estados: foreground (muestra notificación local), background
///   y apertura desde notificación (getInitialMessage / onMessageOpenedApp).
/// - Navega según el campo `tipo` del payload (data message).
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_client.dart';
import '../../router/app_router.dart';

/// Handler de mensajes en segundo plano. DEBE ser función de nivel superior
/// y estar anotada para que el motor de Dart la pueda ejecutar aislada.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // El sistema muestra la notificación automáticamente cuando la app está en
  // background/cerrada (mensajes con bloque `notification`). Aquí solo dejamos
  // registro; no se puede navegar hasta que el usuario la toque.
  debugPrint('FCM background: ${message.messageId} data=${message.data}');
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  // Canal Android con nombre/descripción propios de Baratito (no genérico).
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'baratito_general',
    'Baratito · Actividad',
    description:
        'Mensajes del chat, confirmaciones de pago y novedades de tus compras y ventas.',
    importance: Importance.high,
  );

  bool _initialized = false;

  /// Llamar una vez desde main(), después de Firebase.initializeApp().
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Permiso (iOS + Android 13+).
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2. Notificaciones locales + canal (para mostrar en foreground).
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handleNavigation(_decode(payload));
        }
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Foreground: mostrar la notificación visualmente (no solo en consola).
    FirebaseMessaging.onMessage.listen(_showForeground);

    // 4. App en background y el usuario toca la notificación.
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _handleNavigation(m.data));

    // 5. App cerrada (terminated) abierta desde una notificación.
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      // Espera a que el router esté montado antes de navegar.
      Future.delayed(const Duration(milliseconds: 800),
          () => _handleNavigation(initial.data));
    }

    // 6. Token: guardar ahora (si hay sesión) y ante cambios de sesión/refresh.
    await _syncToken();
    _fcm.onTokenRefresh.listen((_) => _syncToken());
    SupabaseClientHelper.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) _syncToken();
      if (data.event == AuthChangeEvent.signedOut) _deactivateToken();
    });
  }

  /// Devuelve el token FCM del dispositivo (útil para pruebas desde consola).
  Future<String?> getToken() => _fcm.getToken();

  // ── Foreground display ──────────────────────────────────
  Future<void> _showForeground(RemoteMessage message) async {
    final n = message.notification;
    // Título/cuerpo: del bloque notification o del data.
    final title = n?.title ?? message.data['title'] ?? 'Baratito';
    final body = n?.body ?? message.data['body'] ?? '';

    await _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ── Navegación inteligente por tipo ─────────────────────
  void _handleNavigation(Map<String, dynamic> data) {
    final tipo = data['tipo']?.toString();
    final router = rootRouter;
    if (router == null) return;

    switch (tipo) {
      case 'nuevo_mensaje':
        final conv = data['conversation_id']?.toString();
        router.push(conv != null ? '/chat/$conv' : '/home');
        break;
      case 'pago_confirmado':
        router.push('/purchases');
        break;
      default:
        router.push('/home');
    }
  }

  Map<String, dynamic> _decode(String payload) {
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (_) {
      return {};
    }
  }

  // ── Registro del token en Supabase (multi-dispositivo) ──
  Future<void> _syncToken() async {
    final uid = SupabaseClientHelper.auth.currentUser?.id;
    if (uid == null) return; // se guardará cuando inicie sesión
    final token = await _fcm.getToken();
    if (token == null) return;

    try {
      await SupabaseClientHelper.client.from('push_tokens').upsert({
        'user_id': uid,
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'is_active': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');
    } catch (e) {
      debugPrint('No se pudo guardar el token FCM: $e');
    }
  }

  Future<void> _deactivateToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      await SupabaseClientHelper.client
          .from('push_tokens')
          .update({'is_active': false}).eq('token', token);
    } catch (e) {
      debugPrint('No se pudo desactivar el token FCM: $e');
    }
  }
}
