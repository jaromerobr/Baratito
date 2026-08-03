/// Formulario de datos de entrega. Aparece tras subir el comprobante
/// ("estamos verificando tu pago…"). Precarga la dirección guardada del perfil.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import 'package:baratito/widgets/baratito_app_bar.dart';
import '../data/delivery_repository.dart';

final _deliveryRepoProvider =
    Provider<DeliveryRepository>((ref) => DeliveryRepository());

class DeliveryFormScreen extends ConsumerStatefulWidget {
  final String checkoutId;

  /// true si el pago ya quedó validado (auto por OCR); false si en revisión.
  final bool validated;

  const DeliveryFormScreen({
    super.key,
    required this.checkoutId,
    this.validated = false,
  });

  @override
  ConsumerState<DeliveryFormScreen> createState() => _DeliveryFormScreenState();
}

class _DeliveryFormScreenState extends ConsumerState<DeliveryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipient = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _reference = TextEditingController();
  final _city = TextEditingController(text: 'Loja');
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await ref.read(_deliveryRepoProvider).getDefaults();
    if (!mounted) return;
    _recipient.text = d.recipient;
    _phone.text = d.phone;
    _address.text = d.address;
    _reference.text = d.reference;
    if (d.city.isNotEmpty) _city.text = d.city;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _recipient.dispose();
    _phone.dispose();
    _address.dispose();
    _reference.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(_deliveryRepoProvider).save(
            checkoutId: widget.checkoutId,
            recipient: _recipient.text.trim(),
            phone: _phone.text.trim(),
            address: _address.text.trim(),
            reference: _reference.text.trim(),
            city: _city.text.trim(),
          );
      if (!mounted) return;
      // Al terminar, al historial/seguimiento de compras.
      context.go('/home');
      context.push('/purchases');
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('¡Listo! Datos de entrega guardados.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: const BaratitoAppBar(title: Text('Datos de entrega')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    // Estado del pago.
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (widget.validated
                                ? AppColors.success
                                : AppColors.warning)
                            .withAlpha(22),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.validated
                                ? Icons.verified_rounded
                                : Icons.hourglass_top_rounded,
                            color: widget.validated
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const Gap(10),
                          Expanded(
                            child: Text(
                              widget.validated
                                  ? '¡Pago validado! Ahora completa tu dirección para enviarte el pedido.'
                                  : 'Estamos verificando tu pago. Mientras tanto, necesitamos tu dirección de entrega.',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: context.palette.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(20),
                    _field(_recipient, 'Nombre de quien recibe',
                        required: true),
                    _field(_phone, 'Teléfono de contacto',
                        keyboard: TextInputType.phone, required: true),
                    _field(_address, 'Dirección (calle, número, barrio)',
                        required: true, maxLines: 2),
                    _field(_reference,
                        'Referencia / descripción de la casa (color, punto cercano…)',
                        maxLines: 2),
                    _field(_city, 'Ciudad', required: true),
                    const Gap(8),
                    Text(
                      'Guardaremos esta dirección para tus próximas compras.',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: context.palette.textSecondary),
                    ),
                    const Gap(20),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text('Guardar y continuar',
                                style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: context.palette.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
