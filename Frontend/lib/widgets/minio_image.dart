/// Muestra una imagen almacenada en MinIO a partir de su *object key*.
///
/// El bucket es privado, por lo que la URL se resuelve de forma asíncrona con
/// [MinioService.getImageUrl] y se pinta con `CachedNetworkImage` (caché en
/// memoria y disco). Centraliza en un único widget la lectura de imágenes de
/// producto de toda la app (listado, detalle, carrito, pedidos…), evitando
/// repetir la lógica de resolución de URL.
///
/// Es un [StatefulWidget] para memorizar el `Future` de la URL y no re-firmar
/// (ni parpadear) en cada reconstrucción; solo se recalcula si cambia la key.
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../core/minio_service.dart';

class MinioImage extends StatefulWidget {
  /// Key del objeto en MinIO (o `null` si el producto no tiene imagen).
  final String? objectKey;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Redondeo opcional aplicado a la imagen (evita envolver en ClipRRect).
  final BorderRadius? borderRadius;

  const MinioImage({
    super.key,
    required this.objectKey,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<MinioImage> createState() => _MinioImageState();
}

class _MinioImageState extends State<MinioImage> {
  Future<String>? _urlFuture;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(MinioImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo re-firmamos si la key cambió: así el caché sigue siendo efectivo.
    if (oldWidget.objectKey != widget.objectKey) _resolve();
  }

  void _resolve() {
    final key = widget.objectKey;
    _urlFuture = (key == null || key.isEmpty)
        ? null
        : MinioService().getImageUrl(key);
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = _buildImage(context);
    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }
    return child;
  }

  Widget _buildImage(BuildContext context) {
    final future = _urlFuture;
    if (future == null) return _placeholder(context);

    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _broken(context);
        if (!snapshot.hasData) return _placeholder(context, spinner: true);
        return CachedNetworkImage(
          imageUrl: snapshot.data!,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (_, _) => _placeholder(context, spinner: true),
          errorWidget: (_, _, _) => _broken(context),
        );
      },
    );
  }

  /// Caja neutra mientras carga o cuando no hay imagen.
  Widget _placeholder(BuildContext context, {bool spinner = false}) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: context.palette.inputFill,
      alignment: Alignment.center,
      child: spinner
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.image_outlined, color: context.palette.textHint, size: 40),
    );
  }

  /// Caja de error cuando la imagen no se pudo cargar.
  Widget _broken(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: context.palette.inputFill,
      alignment: Alignment.center,
      child: Icon(Icons.broken_image_outlined,
          color: context.palette.textHint, size: 40),
    );
  }
}
