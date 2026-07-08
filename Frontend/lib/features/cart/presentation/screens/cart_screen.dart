/// Cart screen — items grouped by seller, with a single checkout that
/// splits into one order per seller on the backend.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../../../products/domain/product_model.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cartProductsProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Text('Carrito',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) {
          if (products.isEmpty) return const _EmptyCart();

          // Group by seller.
          final groups = <String, List<Product>>{};
          for (final p in products) {
            groups.putIfAbsent(p.sellerId, () => []).add(p);
          }
          final total =
              products.fold<double>(0, (sum, p) => sum + p.price);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 18, color: AppColors.primary),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              'Tu pedido se dividirá en ${groups.length} '
                              '${groups.length == 1 ? "entrega" : "entregas"} '
                              '(una por vendedor).',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: context.palette.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    ...groups.entries.map((e) => _SellerGroup(
                          sellerName: e.value.first.sellerName ?? 'Vendedor',
                          products: e.value,
                          onRemove: (id) =>
                              ref.read(cartControllerProvider).remove(id),
                        )),
                  ],
                ),
              ),
              _CheckoutBar(total: total, sellerCount: groups.length),
            ],
          );
        },
      ),
    );
  }
}

class _SellerGroup extends StatelessWidget {
  final String sellerName;
  final List<Product> products;
  final void Function(String productId) onRemove;

  const _SellerGroup({
    required this.sellerName,
    required this.products,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = products.fold<double>(0, (s, p) => s + p.price);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                const Icon(Icons.store_mall_directory_outlined,
                    size: 18, color: AppColors.primary),
                const Gap(8),
                Expanded(
                  child: Text('Vendedor: $sellerName',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ),
                Text('\$${subtotal.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...products.map((p) => _CartRow(
                product: p,
                onRemove: () => onRemove(p.id),
              )),
        ],
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  final Product product;
  final VoidCallback onRemove;
  const _CartRow({required this.product, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: product.primaryImageUrl != null
                ? Image.network(product.primaryImageUrl!,
                    width: 56, height: 56, fit: BoxFit.cover)
                : Container(
                    width: 56,
                    height: 56,
                    color: context.palette.inputFill,
                    child: Icon(Icons.image_outlined,
                        color: context.palette.textHint)),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const Gap(2),
                Text(product.priceLabel,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends ConsumerStatefulWidget {
  final double total;
  final int sellerCount;
  const _CheckoutBar({required this.total, required this.sellerCount});

  @override
  ConsumerState<_CheckoutBar> createState() => _CheckoutBarState();
}

class _CheckoutBarState extends ConsumerState<_CheckoutBar> {
  bool _loading = false;

  Future<void> _checkout() async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(cartControllerProvider).checkout();
      if (!mounted) return;
      final checkoutId = result['checkout_id'] as String?;
      if (checkoutId != null) {
        // Va a la pantalla de pago (transferencia a Baratito).
        context.pushReplacement('/checkout/$checkoutId');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Envío: $2 con un vendedor; $1 por vendedor si son 2 o más
    // (Baratito consolida las entregas). Misma regla que checkout_cart().
    final shipping =
        widget.sellerCount <= 1 ? 2.0 : widget.sellerCount * 1.0;
    final grandTotal = widget.total + shipping;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: context.palette.surface,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 12)],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total + envío \$${shipping.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: context.palette.textSecondary)),
              Text('\$${grandTotal.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
            ],
          ),
          const Gap(16),
          Expanded(
            child: ElevatedButton(
              onPressed: _loading ? null : _checkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Realizar pedido',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 60, color: context.palette.textHint),
          const Gap(12),
          Text('Tu carrito está vacío',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const Gap(4),
          Text('Agrega productos para hacer un pedido',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: context.palette.textSecondary)),
        ],
      ),
    );
  }
}
