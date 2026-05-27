/// Post repository — Network layer powered by Dio.
///
/// Fetches posts from JSONPlaceholder using the global [DioClient].
/// Returns `Future<List<Post>>` for use with `FutureBuilder`.
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_interceptor.dart';
import 'post_model.dart';

class PostRepository {
  final DioClient _client = DioClient.instance;

  /// GET /posts — Fetch all posts asynchronously.
  ///
  /// Dio handles JSON decoding automatically, so `response.data`
  /// is already a `List<dynamic>` instead of a raw String.
  /// This is a key advantage over `package:http`.
  Future<List<Post>> getPosts() async {
    try {
      final response = await _client.get<List<dynamic>>('/posts');

      // Dio already decoded the JSON → we get List<dynamic> directly
      final data = response.data;
      if (data == null) {
        throw Exception('No se recibieron datos del servidor.');
      }

      return data
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      // Use our centralized error mapping
      throw Exception(ApiInterceptor.mapDioError(e));
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// POST /posts — Create a new post.
  ///
  /// Demonstrates sending data with Dio. The body is automatically
  /// serialized to JSON (no need for `jsonEncode`).
  Future<Post> createPost({
    required String title,
    required String body,
    int userId = 1,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/posts',
        data: {
          'title': title,
          'body': body,
          'userId': userId,
        },
      );

      final data = response.data;
      if (data == null) {
        throw Exception('No se recibió respuesta del servidor.');
      }

      return Post.fromJson(data);
    } on DioException catch (e) {
      throw Exception(ApiInterceptor.mapDioError(e));
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}
