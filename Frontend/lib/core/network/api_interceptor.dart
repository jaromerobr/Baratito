/// Custom Dio interceptor for logging and centralized error handling.
///
/// In debug mode, logs every request, response, and error with details.
/// On errors, maps [DioException] types to user-friendly Spanish messages.
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiInterceptor extends Interceptor {
  // ── Request ─────────────────────────────────────────────
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌──────────────────────────────────────────');
      debugPrint('│ 🌐 REQUEST: ${options.method} ${options.uri}');
      if (options.data != null) {
        debugPrint('│ 📦 Body: ${options.data}');
      }
      if (options.queryParameters.isNotEmpty) {
        debugPrint('│ 🔍 Query: ${options.queryParameters}');
      }
      debugPrint('└──────────────────────────────────────────');
    }

    super.onRequest(options, handler);
  }

  // ── Response ────────────────────────────────────────────
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌──────────────────────────────────────────');
      debugPrint(
        '│ ✅ RESPONSE [${response.statusCode}]: '
        '${response.requestOptions.method} ${response.requestOptions.uri}',
      );
      debugPrint('└──────────────────────────────────────────');
    }

    super.onResponse(response, handler);
  }

  // ── Error ───────────────────────────────────────────────
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌──────────────────────────────────────────');
      debugPrint('│ ❌ ERROR [${err.type}]: ${err.message}');
      debugPrint('│ 📍 URL: ${err.requestOptions.uri}');
      if (err.response != null) {
        debugPrint('│ 📄 Status: ${err.response?.statusCode}');
        debugPrint('│ 📄 Data: ${err.response?.data}');
      }
      debugPrint('└──────────────────────────────────────────');
    }

    super.onError(err, handler);
  }

  // ── Static helper: user-friendly error messages ─────────
  /// Map a [DioException] to a localized Spanish message.
  static String mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tiempo de conexión agotado. Verifica tu internet.';
      case DioExceptionType.sendTimeout:
        return 'El envío de datos tardó demasiado. Intenta de nuevo.';
      case DioExceptionType.receiveTimeout:
        return 'El servidor tardó en responder. Intenta más tarde.';
      case DioExceptionType.badCertificate:
        return 'Certificado de seguridad inválido.';
      case DioExceptionType.badResponse:
        return _mapStatusCode(e.response?.statusCode);
      case DioExceptionType.cancel:
        return 'La solicitud fue cancelada.';
      case DioExceptionType.connectionError:
        return 'Error de conexión. Verifica tu internet.';
      case DioExceptionType.unknown:
        return 'Ocurrió un error inesperado. Intenta de nuevo.';
    }
  }

  static String _mapStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Solicitud inválida (400).';
      case 401:
        return 'No autorizado. Inicia sesión nuevamente (401).';
      case 403:
        return 'No tienes permisos para esta acción (403).';
      case 404:
        return 'Recurso no encontrado (404).';
      case 409:
        return 'Conflicto con el estado actual del recurso (409).';
      case 422:
        return 'Datos inválidos. Verifica la información (422).';
      case 500:
        return 'Error interno del servidor (500).';
      case 502:
        return 'Error en el servidor (502).';
      case 503:
        return 'Servicio no disponible. Intenta más tarde (503).';
      default:
        return 'Error del servidor ($statusCode).';
    }
  }
}
