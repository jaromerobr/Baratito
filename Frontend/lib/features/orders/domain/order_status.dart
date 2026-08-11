/// Lógica compartida del flujo de estado pago → entrega de un pedido.
///
/// Tanto la vista del comprador (`PedidoTracking`) como la del vendedor
/// (`SaleGroup`) leen las mismas dos columnas del backend
/// (`checkouts.status` y `checkouts.fulfillment_status`) y antes repetían
/// la misma lógica de `currentStep` / `isRejected` / `needsProof` /
/// `isDelivered` en dos archivos distintos. Este mixin la centraliza.
///
/// REGLA DE NEGOCIO (ver documentation/ESTADO_DEL_PROYECTO.md §3.9, paso 5):
/// cuando el admin RECHAZA un comprobante de pago desde el panel, el pedido
/// vuelve a `pending_payment` para que el comprador re-suba el comprobante
/// — NO pasa a `cancelled` ni a `fulfillment_status = 'rejected'`. Por eso
/// `isRejected` no se activa solo con `needsProof == true`: un pedido puede
/// pedir comprobante varias veces sin considerarse "rechazado". Solo se
/// considera rechazado si el pedido fue cancelado por completo
/// (`paymentStatus == 'cancelled'`) o si la entrega en sí fue rechazada
/// (`fulfillmentStatus == 'rejected'`).
library;

mixin OrderStatusFlow {
  /// pending_payment | awaiting_confirmation | paid | cancelled
  String get paymentStatus;

  /// pending | received | reviewing | delivering | delivered | rejected
  String get fulfillmentStatus;

  bool get isRejected =>
      fulfillmentStatus == 'rejected' || paymentStatus == 'cancelled';

  /// El comprador aún no ha subido comprobante válido (o el admin rechazó
  /// el anterior y está esperando uno nuevo).
  bool get needsProof => paymentStatus == 'pending_payment';

  bool get isDelivered => fulfillmentStatus == 'delivered';

  /// Índice (0..5) de la etapa alcanzada en `OrderStages.labels`.
  /// -1 si falta el comprobante.
  int get currentStep {
    if (needsProof) return -1;
    if (paymentStatus == 'awaiting_confirmation') return 0;
    // paid → depende del fulfillment.
    switch (fulfillmentStatus) {
      case 'received':
        return 2;
      case 'reviewing':
        return 3;
      case 'delivering':
        return 4;
      case 'delivered':
        return 5;
      case 'pending':
      default:
        return 1; // pago aceptado
    }
  }
}
