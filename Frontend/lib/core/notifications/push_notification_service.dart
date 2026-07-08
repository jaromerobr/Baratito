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
import 'dart:ui' show Color;

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

  // Canales Android por categoría (el usuario puede silenciar cada uno
  // por separado en los ajustes del sistema).
  static const AndroidNotificationChannel _chGeneral =
      AndroidNotificationChannel(
    'baratito_general',
    'Baratito · Actividad',
    description: 'Novedades generales de Baratito.',
    importance: Importance.high,
  );
  static const AndroidNotificationChannel _chChat = AndroidNotificationChannel(
    'baratito_chat',
    'Baratito · Mensajes',
    description: 'Mensajes nuevos de compradores y vendedores.',
    importance: Importance.high,
  );
  static const AndroidNotificationChannel _chPedidos =
      AndroidNotificationChannel(
    'baratito_pedidos',
    'Baratito · Compras y ventas',
    description:
        'Ventas realizadas, pagos confirmados y estado de tus pedidos.',
    importance: Importance.high,
  );
  static const AndroidNotificationChannel _chCuenta =
      AndroidNotificationChannel(
    'baratito_cuenta',
    'Baratito · Tu cuenta',
    description: 'Verificación de identidad y avisos de tu cuenta.',
    importance: Importance.high,
  );

  /// Canal según el tipo de evento del payload.
  static AndroidNotificationChannel _channelFor(String? tipo) {
    switch (tipo) {
      case 'nuevo_mensaje':
        return _chChat;
      case 'venta_realizada':
      case 'pago_confirmado':
      case 'pedido_enviado':
        return _chPedidos;
      case 'verificacion_aprobada':
      case 'verificacion_rechazada':
      case 'nueva_verificacion':
        return _chCuenta;
      default:
        return _chGeneral;
    }
  }

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
    final androidImpl = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    for (final ch in [_chGeneral, _chChat, _chPedidos, _chCuenta]) {
      await androidImpl?.createNotificationChannel(ch);
    }
    // Android 13+: dispara el diálogo de permiso de notificaciones (POST_NOTIFICATIONS).
    await androidImpl?.requestNotificationsPermission();

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

    // 6. Token: imprimirlo (para pruebas desde consola), guardar (si hay sesión)
    //    y reaccionar a refresh/cambios de sesión.
    final token = await _fcm.getToken();
    debugPrint('════════════ FCM TOKEN ════════════');
    debugPrint('$token');
    debugPrint('═══════════════════════════════════');
    await _syncToken();
    _fcm.onTokenRefresh.listen((_) => _syncToken());
    SupabaseClientHelper.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) _syncToken();
      if (data.event == AuthChangeEvent.signedOut) _deactivateToken();
    });
  }

  /// Devuelve el token FCM del dispositivo (útil para pruebas desde consola).
  Future<String?> getToken() => _fcm.getToken();

  // ── Foreground display (estilo Baratito) ────────────────
  Future<void> _showForeground(RemoteMessage message) async {
    final n = message.notification;
    // Título/cuerpo: del bloque notification o del data.
    final title = n?.title ?? message.data['title'] ?? 'Baratito';
    final body = n?.body ?? message.data['body'] ?? '';
    final channel = _channelFor(message.data['tipo']?.toString());

    await _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          // Silueta del logo en la barra de estado + tinte verde Baratito.
          icon: '@drawable/ic_stat_baratito',
          color: const Color(0xFF2D6A4F),
          // Logo a color dentro de la notificación.
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
          styleInformation: BigTextStyleInformation(body),
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
      // Chat: abre la conversación exacta.
      case 'nuevo_mensaje':
        final conv = data['conversation_id']?.toString();
        router.push(conv != null ? '/chat/$conv' : '/home');
        break;
      // Vendedor: alguien compró tu producto → tus publicaciones.
      case 'venta_realizada':
        router.push('/my-products');
        break;
      // Comprador: pago confirmado o pedido enviado → historial de compras.
      case 'pago_confirmado':
      case 'pedido_enviado':
        router.push('/purchases');
        break;
      // Cuenta: resultado de la verificación de identidad.
      case 'verificacion_aprobada':
      case 'verificacion_rechazada':
        router.push('/verify');
        break;
      // Equipo Baratito: nueva verificación por revisar.
      case 'nueva_verificacion':
        router.push('/admin');
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
