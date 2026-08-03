/// Cámara guiada para la verificación de identidad.
///
/// Muestra la vista previa de la cámara con una guía visual encima:
///  - [GuidedCaptureMode.document]: marco con proporción de cédula y
///    cuadrícula (regla de tercios) — cámara trasera.
///  - [GuidedCaptureMode.face]: óvalo donde debe ubicarse el rostro —
///    cámara frontal.
///
/// Devuelve el `XFile` capturado vía `Navigator.pop`.
library;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

enum GuidedCaptureMode { document, face }

class GuidedCameraScreen extends StatefulWidget {
  final GuidedCaptureMode mode;
  final String title;
  final String instruction;

  const GuidedCameraScreen({
    super.key,
    required this.mode,
    required this.title,
    required this.instruction,
  });

  @override
  State<GuidedCameraScreen> createState() => _GuidedCameraScreenState();
}

class _GuidedCameraScreenState extends State<GuidedCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      final wanted = widget.mode == GuidedCaptureMode.face
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == wanted,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high, // 720p: nítido para OCR/rostro y liviano
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudo abrir la cámara: $e');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _setupCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file);
    } catch (e) {
      if (!mounted) return;
      setState(() => _capturing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al capturar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Vista previa a pantalla completa ──────────
          if (_controller != null && _controller!.value.isInitialized)
            _FullScreenPreview(controller: _controller!)
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.white)),
              ),
            )
          else
            const Center(
                child: CircularProgressIndicator(color: Colors.white)),

          // ── Guía visual (cuadrícula / óvalo) ──────────
          if (_controller != null)
            IgnorePointer(
              child: CustomPaint(
                painter: _GuideOverlayPainter(mode: widget.mode),
              ),
            ),

          // ── Título + instrucción ──────────────────────
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(widget.title,
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(widget.instruction,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.white)),
                ),
              ],
            ),
          ),

          // ── Cerrar ────────────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // ── Botón de captura (solo si la cámara está lista) ──
          if (_controller != null && _controller!.value.isInitialized)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: GestureDetector(
                    onTap: _capture,
                    child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: _capturing
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3)
                          : Container(
                              width: 58,
                              height: 58,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vista previa que llena la pantalla (cover) ──────────
class _FullScreenPreview extends StatelessWidget {
  final CameraController controller;
  const _FullScreenPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return CameraPreview(controller);
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        // la cámara reporta el tamaño en horizontal; se invierte para retrato
        width: previewSize.height,
        height: previewSize.width,
        child: CameraPreview(controller),
      ),
    );
  }
}

// ── Overlay: oscurece todo menos la guía ────────────────
class _GuideOverlayPainter extends CustomPainter {
  final GuidedCaptureMode mode;
  const _GuideOverlayPainter({required this.mode});

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final dim = Paint()..color = Colors.black.withAlpha(140);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white;

    if (mode == GuidedCaptureMode.document) {
      // Marco con proporción de cédula (85.6 × 54 mm ≈ 1.586)
      final w = size.width * 0.88;
      final h = w / 1.586;
      final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.44),
        width: w,
        height: h,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));
      final cutout = Path()..addRRect(rrect);

      canvas.drawPath(
          Path.combine(PathOperation.difference, full, cutout), dim);
      canvas.drawRRect(rrect, border);

      // Cuadrícula (regla de tercios) dentro del marco
      final grid = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withAlpha(90);
      for (var i = 1; i <= 2; i++) {
        final x = rect.left + rect.width * i / 3;
        canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), grid);
        final y = rect.top + rect.height * i / 3;
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), grid);
      }
    } else {
      // Óvalo para el rostro
      final w = size.width * 0.68;
      final h = w * 1.32;
      final oval = Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.42),
        width: w,
        height: h,
      );
      final cutout = Path()..addOval(oval);

      canvas.drawPath(
          Path.combine(PathOperation.difference, full, cutout), dim);
      canvas.drawOval(oval, border);
    }
  }

  @override
  bool shouldRepaint(covariant _GuideOverlayPainter old) => old.mode != mode;
}
