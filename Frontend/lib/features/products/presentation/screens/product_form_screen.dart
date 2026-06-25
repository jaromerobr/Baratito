/// ProductFormScreen — Publish or edit a product listing.
///
/// Fields: title, description, category, condition, price, negotiable, photos, brand.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router.dart';
import '../../domain/product_model.dart';
import '../providers/product_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _brandController = TextEditingController();

  final List<File> _images = [];
  ProductCondition _condition = ProductCondition.buenEstado;
  bool _isNegotiable = false;
  String? _selectedCategoryId;

  static const int _maxImages = 5;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_images.length >= _maxImages) {
      _showSnack('Máximo $_maxImages fotos por artículo.');
      return;
    }
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() => _images.add(File(picked.path)));
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _reorderImage(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      _showSnack('Agrega al menos una foto.');
      return;
    }

    final price = double.tryParse(
      _priceController.text.replaceAll(',', '.'),
    );
    if (price == null || price <= 0) {
      _showSnack('El precio debe ser mayor a 0.');
      return;
    }

    final ok = await ref
        .read(productFormControllerProvider.notifier)
        .submitProduct(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          price: price,
          isNegotiable: _isNegotiable,
          condition: _condition,
          categoryId: _selectedCategoryId,
          brand: _brandController.text.trim().isEmpty
              ? null
              : _brandController.text.trim(),
          images: List.from(_images),
        );

    if (ok && mounted) {
      _showSnack('¡Producto publicado con éxito!');
      context.go(AppRoutes.home);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(productFormControllerProvider);
    final categories = ref.watch(categoriesProvider);

    ref.listen(productFormControllerProvider, (_, next) {
      if (next.errorMessage != null) _showSnack(next.errorMessage!);
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Publicar artículo',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            // ── Photos section ────────────────────────────
            _SectionTitle(title: 'Fotos', required: true),
            const Gap(12),
            _PhotosGrid(
              images: _images,
              maxImages: _maxImages,
              onAdd: _pickImage,
              onRemove: _removeImage,
              onReorder: _reorderImage,
            ),
            const Gap(24),

            // ── Title ─────────────────────────────────────
            _SectionTitle(title: 'Título', required: true),
            const Gap(8),
            _FormField(
              controller: _titleController,
              hint: 'Ej: iPhone 13 Pro Max 256GB',
              maxLength: 100,
              validator: (v) {
                if (v == null || v.trim().length < 5) {
                  return 'El título debe tener al menos 5 caracteres.';
                }
                return null;
              },
            ),
            const Gap(20),

            // ── Description ───────────────────────────────
            _SectionTitle(title: 'Descripción'),
            const Gap(8),
            _FormField(
              controller: _descController,
              hint: 'Describe el estado, accesorios incluidos...',
              maxLines: 4,
              maxLength: 1000,
            ),
            const Gap(20),

            // ── Category ──────────────────────────────────
            _SectionTitle(title: 'Categoría', required: true),
            const Gap(8),
            categories.when(
              data: (cats) => _CategorySelector(
                categories: cats,
                selectedId: _selectedCategoryId,
                onSelected: (id) => setState(() => _selectedCategoryId = id),
              ),
              loading: () => const _LoadingChips(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const Gap(20),

            // ── Condition ─────────────────────────────────
            _SectionTitle(title: 'Condición', required: true),
            const Gap(8),
            _ConditionSelector(
              selected: _condition,
              onSelected: (c) => setState(() => _condition = c),
            ),
            const Gap(20),

            // ── Price + negotiable ─────────────────────────
            _SectionTitle(title: 'Precio', required: true),
            const Gap(8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FormField(
                    controller: _priceController,
                    hint: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*[,.]?\d{0,2}'),
                      ),
                    ],
                    prefix: Text(
                      '\$',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    validator: (v) {
                      final parsed = double.tryParse(
                        v?.replaceAll(',', '.') ?? '',
                      );
                      if (parsed == null || parsed <= 0) {
                        return 'Precio inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: _NegotiableToggle(
                    value: _isNegotiable,
                    onChanged: (v) => setState(() => _isNegotiable = v),
                  ),
                ),
              ],
            ),
            const Gap(20),

            // ── Brand (optional) ──────────────────────────
            _SectionTitle(title: 'Marca (opcional)'),
            const Gap(8),
            _FormField(
              controller: _brandController,
              hint: 'Ej: Apple, Samsung, Nike...',
              maxLength: 60,
            ),
            const Gap(36),

            // ── Submit button ─────────────────────────────
            _SubmitButton(
              isLoading: formState.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool required;

  const _SectionTitle({required this.title, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (required) ...[
          const Gap(4),
          Text(
            '*',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Form text field ───────────────────────────────────────

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Widget? prefix;

  const _FormField({
    required this.controller,
    required this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textHint,
        ),
        prefixIcon: prefix != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: prefix,
              )
            : null,
        prefixIconConstraints: prefix != null
            ? const BoxConstraints(minWidth: 0, minHeight: 0)
            : null,
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        counterStyle: GoogleFonts.poppins(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Photos grid ───────────────────────────────────────────

class _PhotosGrid extends StatelessWidget {
  final List<File> images;
  final int maxImages;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  final void Function(int, int) onReorder;

  const _PhotosGrid({
    required this.images,
    required this.maxImages,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: true,
        onReorder: onReorder,
        itemCount: images.length,
        proxyDecorator: (child, index, animation) => child,
        itemBuilder: (context, index) {
          return Padding(
            key: ValueKey(images[index].path),
            padding: const EdgeInsets.only(right: 10),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    images[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                if (index == 0)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Principal',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => onRemove(index),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        footer: images.length < maxImages
            ? GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    border: Border.all(
                      color: AppColors.primary.withAlpha(80),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const Gap(4),
                      Text(
                        '${images.length}/$maxImages',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

// ── Category selector ─────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  final List<ProductCategory> categories;
  final String? selectedId;
  final void Function(String?) onSelected;

  const _CategorySelector({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = selectedId == cat.id;
        return GestureDetector(
          onTap: () => onSelected(isSelected ? null : cat.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.inputFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.inputBorder,
              ),
            ),
            child: Text(
              cat.name,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LoadingChips extends StatelessWidget {
  const _LoadingChips();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: List.generate(
        4,
        (_) => Container(
          width: 80,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

// ── Condition selector ────────────────────────────────────

class _ConditionSelector extends StatelessWidget {
  final ProductCondition selected;
  final void Function(ProductCondition) onSelected;

  const _ConditionSelector({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ProductCondition.values.map((c) {
        final isSelected = selected == c;
        return GestureDetector(
          onTap: () => onSelected(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : AppColors.inputFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.accent
                    : AppColors.inputBorder,
              ),
            ),
            child: Text(
              c.label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Negotiable toggle ─────────────────────────────────────

class _NegotiableToggle extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;

  const _NegotiableToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value
              ? AppColors.accent.withAlpha(30)
              : AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? AppColors.accent : AppColors.inputBorder,
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Negociable?',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  value ? 'Sí' : 'No',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: value
                        ? AppColors.accentDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.accent,
              activeTrackColor: AppColors.accentLight.withAlpha(100),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Submit button ─────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SubmitButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Publicar artículo',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
