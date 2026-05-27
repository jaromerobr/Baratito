/// Dio HTTP client — Global configuration for the Baratito app.
///
/// Provides a singleton [Dio] instance pre-configured with:
/// - Base URL for JSONPlaceholder (demo) or custom APIs.
/// - Timeouts: connect, receive, send (15 s each).
/// - Content-Type & Accept headers.
/// - Custom [ApiInterceptor] for logging and error handling.
///
/// **Ventajas de Dio vs http:**
/// 1. Interceptores: permiten inyectar tokens, loguear y reintentar requests.
/// 2. Timeouts globales configurables (connectTimeout, receiveTimeout, sendTimeout).
/// 3. Decodificación automática de JSON — no necesitas `jsonDecode` manual.
/// 4. Soporte de cancelación de requests con `CancelToken`.
/// 5. `Transformers` para transformar request/response antes de procesarlos.
/// 6. `FormData` nativo para subir archivos (multipart).
/// 7. Manejo de errores tipado con `DioException` (timeout, connection, response).
import 'package:dio/dio.dart';
import 'api_interceptor.dart';

class DioClient {
  DioClient._();

  static final DioClient _instance = DioClient._();
  static DioClient get instance => _instance;

  late final Dio _dio;

  /// Whether the client has been initialized.
  bool _initialized = false;

  /// Initialize the Dio client. Call once, typically in `main()`.
  void initialize({String? baseUrl}) {
    if (_initialized) return;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? 'https://jsonplaceholder.typicode.com',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );

    // Add custom interceptor for logging & error handling
    _dio.interceptors.add(ApiInterceptor());

    _initialized = true;
  }

  /// The configured [Dio] instance.
  Dio get dio {
    assert(_initialized, 'DioClient must be initialized before use.');
    return _dio;
  }

  /// Shorthand GET request.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  /// Shorthand POST request.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      cancelToken: cancelToken,
    );
  }

  /// Shorthand PUT request.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      cancelToken: cancelToken,
    );
  }

  /// Shorthand DELETE request.
  Future<Response<T>> delete<T>(
    String path, {
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      cancelToken: cancelToken,
    );
  }
}
