/// Regla de negocio del costo de envío (lógica pura, testeable).
///
/// - 1 vendedor  → $2.00 (una entrega)
/// - 2+ vendedores → $1.00 por vendedor (Baratito consolida las entregas)
///
/// La fuente de verdad al cobrar es `checkout_cart()` en Postgres; esta
/// función replica la misma regla para MOSTRAR el total en el carrito.
/// Si cambia una, debe cambiar la otra.
library;

double shippingFeeForSellers(int sellerCount) {
  if (sellerCount <= 0) return 0;
  return sellerCount == 1 ? 2.0 : sellerCount * 1.0;
}
