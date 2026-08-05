/* `tone` dice sobre que suelo pisa el riel lateral en cada slide:
   'main' sigue al modo, 'light' es el hueso fijo, 'deep' el verde
   fijo del cierre. */
export const SLIDES = [
  { id: 'hero', label: 'Inicio', tone: 'main' },
  { id: 'quienes', label: 'Quiénes somos', tone: 'alt' },
  { id: 'como-funciona', label: 'Cómo funciona', tone: 'light' },
  { id: 'descarga', label: 'Descargar', tone: 'deep' },
]

/* La conversacion usa una publicacion que existe de verdad en la
   captura de la app, para que la landing no muestre productos que
   nadie va a encontrar al abrirla. */
export const CHAT = [
  { kind: 'in', text: '¿Sigue disponible la hoodie? 🧥' },
  { kind: 'out', text: '¡Sí! Te la dejo en $28 🤝' },
  { kind: 'in', text: '¡Perfecto! ¿Y cómo me llega?' },
  { kind: 'out', text: 'La recogen aquí y te la llevan hoy' },
  { kind: 'sys', text: 'Trato hecho · Pago retenido por Baratito' },
  { kind: 'sys', text: 'Entregada · Pago liberado ✓' },
]

export const PROMESAS = [
  { k: 'Identidad', t: 'Comunidad verificada', d: 'Cédula y selfie antes de publicar.' },
  { k: 'Mensajes', t: 'Chat en tiempo real', d: 'Acuerdas el precio sin salir de la app.' },
  { k: 'Entrega', t: 'Nosotros lo llevamos', d: 'Recogemos y entregamos dentro de Loja.' },
  { k: 'Dinero', t: 'Pago retenido', d: 'Se libera cuando confirmas que recibiste.' },
]

/* El recorrido real de una compra. Los numeros 01-04 son un orden
   de verdad —cada paso depende del anterior— no una decoracion. */
export const PASOS = [
  {
    n: '01',
    icon: '💬',
    t: 'Acuerdan en el chat',
    d: 'Precio, estado y detalles, sin salir de la app.',
  },
  {
    n: '02',
    icon: '🔒',
    t: 'El pago queda retenido',
    d: 'El comprador le paga a Baratito. El vendedor ve que ya está pagado, pero todavía no lo recibe.',
  },
  {
    n: '03',
    icon: '🚚',
    t: 'Nosotros lo llevamos',
    d: 'Recogemos donde el vendedor y entregamos donde el comprador, dentro de Loja.',
  },
  {
    n: '04',
    icon: '✅',
    t: 'Se libera el pago',
    d: 'Cuando el comprador confirma que recibió, el dinero pasa al vendedor.',
  },
]

export const FLOATERS = [
  { text: '24 guardados', icon: '❤️', pos: 'tl', style: 'light' },
  { text: 'Vendido en 2 horas', icon: '✅', pos: 'bl', style: 'green' },
  { text: '¿Sigue disponible?', icon: '💬', pos: 'tr', style: 'light' },
  { text: 'Vendedor verificado', icon: '🛡️', pos: 'br', style: 'deep' },
]

/* Los estados por los que pasa un pedido. Flotan en la slide del
   flujo porque son la misma historia que cuentan los pasos. */
export const ESTADOS = [
  { text: 'Pago retenido', icon: '🔒', pos: 'tl', style: 'deep' },
  { text: 'En camino', icon: '🚚', pos: 'bl', style: 'gold' },
  { text: 'Entregado', icon: '📦', pos: 'tr', style: 'gold' },
  { text: 'Pago liberado', icon: '✅', pos: 'br', style: 'deep' },
]

/* Publicaciones reales de la app, no ejemplos inventados */
export const DEALS = [
  { text: 'ASUS Vivobook Go 12 · $380', icon: '💻', pos: 'tl', style: 'gold' },
  { text: 'Vendido · San Cayetano', icon: '✅', pos: 'bl', style: 'glass' },
  { text: 'Essentials hoodie · $30', icon: '🧥', pos: 'tr', style: 'glass' },
  { text: 'Trato hecho', icon: '🤝', pos: 'br', style: 'gold' },
]
