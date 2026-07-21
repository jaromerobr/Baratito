/// Publish product screen — form + image picker.
///
/// Lets a signed-in user create a listing: photos, title, description,
/// price, category, condition and "negotiable". On success it refreshes
/// the marketplace and pops back.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../../domain/product_model.dart';
import '../providers/products_provider.dart';

class PublishProductScreen extends ConsumerStatefulWidget {
  const PublishProductScreen({super.key});

  @override
  ConsumerState<PublishProductScreen> createState() =>
      _PublishProductScreenState();
}

class _PublishProductScreenState extends ConsumerState<PublishProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();

  final List<XFile> _images = [];
  String? _categoryId;
  String _conditionLabel = 'Nuevo';
  bool _negotiable = false;
  bool _loading = false;
  // Ubicación opcional: dónde se publica. Si el usuario no la comparte, Loja.
  String _locationCity = 'Loja';
  bool _locating = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _brandCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    // Preguntar de dónde: cámara (tomar ahora) o galería (fotos existentes).
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.primary),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final picker = ImagePicker();
      // Redimensiona en el dispositivo antes de subir: fotos a resolución
      // completa (varios MB) hacían la subida lenta y pesada.
      // Guardamos el XFile tal cual; MinioService lee los bytes al subir.
      if (source == ImageSource.camera) {
        if (_images.length >= 6) return;
        final f = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 75,
          maxWidth: 1600,
        );
        if (f == null) return;
        _images.add(f);
      } else {
        final files = await picker.pickMultiImage(
          imageQuality: 75,
          maxWidth: 1600,
        );
        if (files.isEmpty) return;
        for (final f in files) {
          if (_images.length >= 6) break;
          _images.add(f);
        }
      }
      setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudieron cargar las imágenes')),
        );
      }
    }
  }

  /// Pide permiso de ubicación y usa la ciudad detectada. Si el usuario no la
  /// concede o falla, se mantiene "Loja" (valor por defecto, opcional).
  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _locMsg('Activa la ubicación del dispositivo para usarla.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _locMsg('Sin permiso de ubicación. Se usará Loja.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final places =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      String? city;
      if (places.isNotEmpty) {
        final p = places.first;
        city = (p.locality != null && p.locality!.trim().isNotEmpty)
            ? p.locality!.trim()
            : p.subAdministrativeArea?.trim();
      }
      if (!mounted) return;
      setState(() =>
          _locationCity = (city == null || city.isEmpty) ? 'Loja' : city);
    } catch (_) {
      _locMsg('No pudimos obtener tu ubicación. Se usará Loja.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _locMsg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos una foto')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(productRepositoryProvider);
      await repo.createProduct(
        title: _titleCtrl.text,
        description: _descCtrl.text,
        price: double.parse(_priceCtrl.text.replaceAll(',', '.')),
        categoryId: _categoryId,
        conditionRaw: ProductCondition.selectable[_conditionLabel]!,
        brand: _brandCtrl.text.isEmpty ? null : _brandCtrl.text,
        isNegotiable: _negotiable,
        locationCity: _locationCity,
        images: _images,
      );

      ref.invalidate(productsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Producto publicado! 🎉')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo publicar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Text('Publicar artículo',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              _ImagePickerRow(images: _images, onAdd: _pickImages, onRemove: (i) {
                setState(() => _images.removeAt(i));
              }),
              const Gap(20),
              _label('Título'),
              TextFormField(
                controller: _titleCtrl,
                maxLength: 100,
                decoration: _dec('Ej. iPhone 13 Pro 128GB'),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.length < 5) return 'Mínimo 5 caracteres';
                  return null;
                },
              ),
              _label('Descripción'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                maxLength: 1000,
                decoration: _dec('Describe el estado, detalles, etc.'),
              ),
              _label('Precio (USD)'),
              TextFormField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: _dec('Ej. 380.00'),
                validator: (v) {
                  final p = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (p == null || p < 0) return 'Ingresa un precio válido';
                  return null;
                },
              ),
              _label('Categoría'),
              categoriesAsync.when(
                data: (cats) => DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  isExpanded: true,
                  decoration: _dec('Selecciona una categoría'),
                  items: cats
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('No se pudieron cargar categorías'),
              ),
              _label('Estado del artículo'),
              DropdownButtonFormField<String>(
                initialValue: _conditionLabel,
                isExpanded: true,
                decoration: _dec(''),
                items: ProductCondition.selectable.keys
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _conditionLabel = v ?? 'Nuevo'),
              ),
              _label('Marca (opcional)'),
              TextFormField(
                controller: _brandCtrl,
                maxLength: 40,
                decoration: _dec('Ej. Apple, Nike...'),
              ),
              const Gap(8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Precio negociable',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: context.palette.textPrimary)),
                value: _negotiable,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _negotiable = v),
              ),
              _label('Ubicación'),
              Material(
                color: context.palette.surface,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
                  child: Row(
                    children: [
                      const Icon(Icons.place_outlined, color: AppColors.primary),
                      const Gap(10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_locationCity,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    color: context.palette.textPrimary)),
                            Text('Dónde se publica (opcional)',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: context.palette.textSecondary)),
                          ],
                        ),
                      ),
                      _locating
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            )
                          : TextButton(
                              onPressed: _useMyLocation,
                              child: const Text('Usar mi ubicación')),
                    ],
                  ),
                ),
              ),
              const Gap(16),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Publicar artículo',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(text,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.palette.textPrimary)),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: context.palette.textHint),
        filled: true,
        fillColor: context.palette.surface,
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.palette.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.palette.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );
}

// ── Image picker row ────────────────────────────────────
class _ImagePickerRow extends StatelessWidget {
  final List<XFile> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _ImagePickerRow({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _AddButton(onTap: onAdd, count: images.length),
          const Gap(10),
          for (var i = 0; i < images.length; i++) ...[
            _Thumb(file: images[i], onRemove: () => onRemove(i)),
            const Gap(10),
          ],
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  final int count;
  const _AddButton({required this.onTap, required this.count});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary, width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined,
                color: AppColors.primary, size: 26),
            const Gap(4),
            Text('$count/6',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: context.palette.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;
  const _Thumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(File(file.path),
              width: 100, height: 100, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              padding: const EdgeInsets.all(3),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
