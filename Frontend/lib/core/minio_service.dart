/// Almacenamiento de objetos en MinIO (S3) — Singleton único de la app.
///
/// Toda imagen de producto se sube y se lee EXCLUSIVAMENTE a través de esta
/// clase. Centraliza en un solo lugar el endpoint, las credenciales y el
/// bucket (única fuente de verdad, principio DRY): ninguna otra clase debe
/// crear un cliente [Minio] ni repetir esta configuración.
///
/// Patrón Singleton real:
/// - constructor privado [MinioService._internal],
/// - una sola instancia estática [_instance] viva durante toda la app,
/// - la fábrica `MinioService()` devuelve siempre esa misma instancia,
/// - el cliente [Minio] se construye una única vez de forma perezosa.
///
/// Seguridad: igual que [SupabaseClientHelper], la configuración se lee de
/// variables `--dart-define` con los valores del entorno de la actividad como
/// respaldo, de modo que las credenciales no queden fijas en el binario si se
/// compila con otro entorno.
library;

import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:minio/minio.dart';
import 'package:uuid/uuid.dart';

class MinioService {
  // ─────────────────────────── Singleton ───────────────────────────
  static final MinioService _instance = MinioService._internal();

  /// Devuelve SIEMPRE la misma instancia (única en toda la app).
  factory MinioService() => _instance;

  MinioService._internal();

  // ───────────────── Configuración centralizada ─────────────────
  // Único punto donde viven endpoint/credenciales/bucket de MinIO.
  static const String _endpoint = String.fromEnvironment(
    'MINIO_ENDPOINT',
    defaultValue: 's3.uidehub.tech',
  );
  static const String _accessKey = String.fromEnvironment(
    'MINIO_ACCESS_KEY',
    defaultValue: 'admin_uidehub',
  );
  static const String _secretKey = String.fromEnvironment(
    'MINIO_SECRET_KEY',
    defaultValue: 'gOggAJFliVtNFlX7aibcb/MCaVrpN/cQtLkUMPLaUlU=',
  );
  static const String _bucket = String.fromEnvironment(
    'MINIO_BUCKET',
    defaultValue: 'baratito',
  );
  // Región fija: al proveerla, la firma de URLs es 100% local (MinIO no
  // necesita consultar la ubicación del bucket por red).
  static const String _region = String.fromEnvironment(
    'MINIO_REGION',
    defaultValue: 'us-east-1',
  );

  /// Nombre del bucket (solo lectura, por si algún consumidor lo necesita).
  String get bucket => _bucket;

  // ─────────── Cliente perezoso: se crea una sola vez ───────────
  Minio? _clientInstance;

  Minio get _client => _clientInstance ??= Minio(
        endPoint: _endpoint,
        accessKey: _accessKey,
        secretKey: _secretKey,
        region: _region,
        useSSL: true, // s3.uidehub.tech vía HTTPS (puerto 443)
        pathStyle: true, // MinIO usa estilo path: host/bucket/objeto
      );

  final Uuid _uuid = const Uuid();

  /// Caché de URLs firmadas para no volver a firmar en cada reconstrucción del
  /// widget: mantiene efectivo el caché de disco/memoria de las imágenes.
  final Map<String, _SignedUrl> _urlCache = {};

  /// Sube una imagen al bucket y devuelve la **key** del objeto almacenado.
  ///
  /// Recibe el [XFile] que entrega `image_picker`. Genera un nombre único
  /// (`<folder>/<uuid>.<ext>`), sube los bytes con su `Content-Type` y
  /// devuelve la key para persistirla en la base de datos.
  ///
  /// Lanza [MinioServiceException] si la subida falla.
  Future<String> uploadImage(XFile file, {String folder = 'products'}) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      final String ext = _extensionOf(file.name);
      final String key = '$folder/${_uuid.v4()}.$ext';

      await _client.putObject(
        _bucket,
        key,
        Stream<Uint8List>.value(bytes),
        size: bytes.length,
        metadata: {'Content-Type': _contentTypeFor(ext)},
      );

      return key;
    } on MinioError catch (e) {
      throw MinioServiceException('No se pudo subir la imagen: ${e.message}');
    } catch (e) {
      throw MinioServiceException('No se pudo subir la imagen: $e');
    }
  }

  /// Sube bytes arbitrarios (p. ej. media de chat: video/audio/imagen) y
  /// devuelve la key. [ext] sin punto (mp4, m4a, jpg…), [contentType] el MIME.
  Future<String> uploadBytes(
    Uint8List bytes, {
    required String ext,
    required String contentType,
    String folder = 'chat',
  }) async {
    try {
      final String key = '$folder/${_uuid.v4()}.$ext';
      await _client.putObject(
        _bucket,
        key,
        Stream<Uint8List>.value(bytes),
        size: bytes.length,
        metadata: {'Content-Type': contentType},
      );
      return key;
    } on MinioError catch (e) {
      throw MinioServiceException('No se pudo subir el archivo: ${e.message}');
    } catch (e) {
      throw MinioServiceException('No se pudo subir el archivo: $e');
    }
  }

  /// Devuelve una URL utilizable para mostrar la imagen dada su [key].
  ///
  /// El bucket `baratito` es privado, así que se genera una **URL firmada**
  /// (presigned GET) válida durante [expiry]. La URL se memoriza por key para
  /// no re-firmar en cada `build`.
  ///
  /// Si la [key] ya es una URL http(s) (p. ej. datos semilla), se devuelve tal
  /// cual sin firmar.
  ///
  /// Lanza [MinioServiceException] si no se puede generar la URL.
  Future<String> getImageUrl(
    String key, {
    Duration expiry = const Duration(days: 7),
  }) async {
    if (key.startsWith('http://') || key.startsWith('https://')) return key;

    final cached = _urlCache[key];
    if (cached != null && cached.isValid) return cached.url;

    try {
      final String url = await _client.presignedGetObject(
        _bucket,
        key,
        expires: expiry.inSeconds,
      );
      // Se refresca una hora antes de vencer para nunca servir una URL caduca.
      _urlCache[key] = _SignedUrl(
        url,
        DateTime.now().add(expiry - const Duration(hours: 1)),
      );
      return url;
    } on MinioError catch (e) {
      throw MinioServiceException('No se pudo generar la URL: ${e.message}');
    }
  }

  // ────────────────────── Helpers privados ──────────────────────
  /// Extensión normalizada a partir del nombre del archivo.
  String _extensionOf(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  /// `Content-Type` correspondiente a la extensión de imagen.
  String _contentTypeFor(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

/// URL firmada junto a su instante de expiración (para el caché en memoria).
class _SignedUrl {
  final String url;
  final DateTime expiresAt;

  const _SignedUrl(this.url, this.expiresAt);

  bool get isValid => DateTime.now().isBefore(expiresAt);
}

/// Excepción de dominio para errores de almacenamiento en MinIO.
class MinioServiceException implements Exception {
  final String message;

  const MinioServiceException(this.message);

  @override
  String toString() => message;
}
