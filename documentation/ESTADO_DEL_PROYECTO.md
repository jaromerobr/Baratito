# 🏷️ Baratito — Estado del Proyecto

Marketplace de compra-venta de segunda mano para **Loja, Ecuador** (estilo Depop/Wallapop).
Documento de estado: **qué está hecho, qué funciona, y qué falta por hacer/mejorar**, explicado desde el login hasta lo último implementado.

> Última actualización: 2026-07-06 · Rama de trabajo: `Eduardo`

---

## 1. Stack y arquitectura

| Capa | Tecnología |
|---|---|
| **App móvil** | Flutter (Dart) · Material 3 · fuente Poppins |
| **Estado** | Riverpod (features) + Provider/ChangeNotifier (auth y tema) |
| **Navegación** | go_router (router único global, no se reconstruye al cambiar tema) |
| **Backend** | Supabase (Postgres + Auth + Storage + Realtime + RPC + Edge Functions) |
| **Notificaciones push** | Firebase Cloud Messaging (FCM) + flutter_local_notifications |
| **Verificación facial** | Servicio Python (FastAPI + DeepFace, detector RetinaFace) |
| **OCR de comprobantes** | Google ML Kit Text Recognition (on-device, gratuito) |
| **Mapas** | OpenStreetMap vía `flutter_map` (sin API key ni costos) |
| **Correo** | SMTP propio vía Resend |

**Identidad visual:** verde bosque `#2D6A4F` + amarillo mostaza `#D4A017`. Tema claro/oscuro real en toda la app (ThemeExtension `AppPalette`), con **persistencia** de la preferencia.

### Arquitectura del código (Flutter)

```
Frontend/lib/
├── core/            # cliente Supabase, tema/paleta, notificaciones push, rutas
├── features/
│   ├── auth/          # sesión y perfil (providers Riverpod)
│   ├── products/      # catálogo, detalle (con mapa), publicar, mis productos, shell
│   ├── verification/  # KYC: cédula + selfie, estados
│   ├── favorites/     # guardados (corazón)
│   ├── cart/          # carrito + checkout con envío
│   ├── payments/      # pago por transferencia + OCR del comprobante
│   ├── orders/        # historial de compras
│   ├── chat/          # mensajes en tiempo real
│   ├── profile/       # editar perfil + avatar
│   └── admin/         # panel: métricas, verificaciones, pagos
└── screens/auth/    # pantallas de login/registro/OTP (stack Provider)
```

---

## 2. Configuración del backend (orden de ejecución)

Scripts SQL en `Backend/` — correr **en orden** en el SQL Editor de Supabase:

| Script | Qué hace |
|---|---|
| `00_setup_auth_profiles.sql` | Trigger que crea `profiles` al registrarse + RLS + backfill |
| `01_catalog_setup.sql` | RLS catálogo, bucket `product-images`, categorías base |
| `02_seed_products.sql` | Productos de ejemplo (opcional) |
| `03_fix_permissions.sql` | Restaura permisos estándar del schema public |
| `04_verification_setup.sql` | Bucket privado `verification-docs`, RLS KYC, trigger `is_verified` |
| `05_admin_setup.sql` | `is_admin()`, RLS admin, RPC `admin_overview()` |
| `06_profile_chat_setup.sql` | Bucket `avatars`, RLS órdenes/chat, Realtime |
| `07_cart_favorites_checkout.sql` | RLS favoritos, tabla `cart_items`, checkout |
| `08_commission_payments.sql` | `platform_settings`, `checkouts`, `payouts`, comprobantes |
| `09_push_tokens_setup.sql` | RLS de `push_tokens` (tokens FCM multi-dispositivo) |
| `10_notifications_push.sql` | Triggers de notificaciones + webhook pg_net → Edge Function |
| `11_payments_shipping_ocr.sql` | Comisión 8%, envío, RPC de validación OCR, QR, anti auto-compra |

**Edge Function:** `supabase/functions/send-push/index.ts` — se despliega con `supabase functions deploy send-push` (requiere el secreto `FIREBASE_SERVICE_ACCOUNT`).

**Firebase:** proyecto `baratito-543ac`; `google-services.json` en `Frontend/android/app/` (config de cliente, commiteable). La **service account** (llave privada para enviar push) va SOLO como secreto en Supabase — protegida en `.gitignore`.

**Buckets de Storage:**
| Bucket | Contenido | Acceso |
|---|---|---|
| `product-images` | fotos de productos | público |
| `avatars` | fotos de perfil | público |
| `platform-assets` | QR de cobro de Baratito | público |
| `verification-docs` | cédulas y selfies | 🔒 privado (URLs firmadas) |
| `payment-proofs` | comprobantes de pago | 🔒 privado |

**Servicio Python (verificación facial):** `Backend/verification_service/`. Corre local en entorno conda `baratito-verify` (Python 3.11). La app lo llama vía `--dart-define=VERIFY_SERVICE_URL=http://<IP_LAN>:8000`.

---

## 3. Funcionalidades implementadas (✅ funciona)

### 3.1 Autenticación
- Registro con confirmación por **código OTP de 6 dígitos** al correo (SMTP Resend), login, recuperación de contraseña por código, modo invitado.
- Trigger crea el perfil automáticamente; errores traducidos al español.
- Dominio `baratito.shop` comprado para el remitente (verificación en Resend pendiente de completar).

### 3.2 Tema claro/oscuro (persistente)
- Toggle en Home, Perfil y login. Toda la app reacciona (paleta dinámica).
- La preferencia se guarda (shared_preferences). **Cambiar el tema ya no reinicia la navegación** (el router es una instancia única global).

### 3.3 Catálogo / Home
- Productos publicados desde Supabase, búsqueda por título, **botón de filtros** (categorías + estado del producto) en panel desplegable con chips removibles.
- Estados de carga/error/vacío, pull-to-refresh, saludo personalizado.

### 3.4 Detalle de producto
- Carrusel de fotos, precio, condición, descripción, tarjeta del vendedor.
- **Mapa OpenStreetMap** con marcador en la ciudad del producto (`location_city`).
- Acciones: favorito, contactar (chat), agregar al carrito.
- **Producto propio:** no se muestran carrito/chat/favorito — solo "Este producto es tuyo" con acceso a Mis productos. Reforzado también en el backend (RLS impide meter productos propios al carrito).

### 3.5 Publicar producto
- Hasta 6 fotos, título, descripción, precio, categoría, condición, marca, negociable.
- **Bloqueado por verificación** para usuarios normales; **los admins están exentos** (publican sin verificarse y no ven la tarjeta de verificación).

### 3.6 Verificación de identidad (KYC) — probada de punta a punta ✅
- Flujo: cédula frontal + posterior + **selfie en vivo** (cámara frontal) → bucket privado → servicio Python compara rostros.
- Motor: DeepFace **Facenet512** con detector **RetinaFace** (el haarcascade por defecto fallaba con la foto pequeña de la cédula) + **corrección de rotación EXIF** de las fotos de celular.
- **Regla de decisión (interna):** coincidencia **>70% → aprobado automático**; **≤70% → revisión manual** por el equipo. **El sistema nunca rechaza solo** — rechazar es siempre decisión humana.
- Al aprobar (auto o admin), trigger marca `profiles.is_verified = true`.
- Mensaje al usuario: la revisión manual tarda máx. 2 horas (8:00–24:00).
- Validado con pruebas reales: misma persona 84% (auto-aprobado), personas distintas 5%, selfie vs cédula real ≈ 54–62% (→ revisión manual, esperado con foto de documento).

### 3.7 Favoritos, 3.8 Carrito — igual que antes
- Corazón en tarjeta/detalle y pestaña Guardados; carrito persistente agrupado por vendedor.

### 3.9 💰 PAGOS — lógica completa (Banco de Loja + OCR)

**Reglas de negocio:**
| Concepto | Regla |
|---|---|
| Comisión Baratito | **8%** del precio de los productos (configurable en `platform_settings`) |
| Envío | **$2** si el pedido es de 1 vendedor · **$1 × vendedor** si son 2+ (Baratito consolida las entregas) |
| El envío se lo queda | **Baratito** (cubre la logística) |
| El vendedor recibe | precio de sus productos **− 8%** |
| El comprador paga | productos + envío |

**Flujo del dinero:**
```
1. Checkout → se crea el pedido (una orden por producto, dividido por vendedor,
   unidas por checkout_id) con el envío ya sumado al total.
2. Pantalla de pago: QR del Banco de Loja + cuenta 2905730802 (Ahorros,
   copiable) + desglose productos/envío.
3. El comprador transfiere desde su app bancaria y SUBE EL COMPROBANTE.
4. La app lee el comprobante con OCR (ML Kit, on-device): extrae el monto
   ("Monto transferido", formato $X,XX) y el Nro. de comprobante.
   → Si el monto cubre el total: PAGO CONFIRMADO AUTOMÁTICAMENTE (RPC
     submit_payment_proof): checkout = paid, se generan los payouts por
     vendedor y salen las notificaciones push solas.
   → Si no coincide o no se puede leer: queda "en revisión" para el admin.
5. Panel admin → Pagos: ve el comprobante (URL firmada), lo que leyó el OCR
   y el desglose; puede CONFIRMAR (genera payouts) o RECHAZAR (el pedido
   vuelve a "pendiente de pago" y el comprador re-sube el comprobante).
6. Baratito transfiere manualmente a cada vendedor su parte (payouts
   quedan registrados como pendientes).
```
El parser OCR está **calibrado con comprobantes reales del Banco de Loja** (ignora "Costo de transacción", tolera coma decimal).

### 3.10 Chat en tiempo real
- Conversaciones + mensajes en vivo (Supabase Realtime), doble check de leído; se abre desde "Contactar".

### 3.11 Perfil
- Editar nombre, usuario único, teléfono, bio y avatar. Accesos a Mis productos (En venta/Vendidos), Mis compras, tema oscuro y panel admin (si aplica).

### 3.12 Panel de administración
- **Resumen:** usuarios, % verificados, productos, órdenes, embudo de verificaciones, productos por categoría, top vendedores.
- **Verificaciones:** cola con filtros, fotos (cédula/selfie) por URL firmada, **% de match de DeepFace**, aprobar/rechazar con motivo.
- **Pagos:** comisión total ganada, ventas brutas, por pagar a vendedores; por cada pago: desglose (envío, comisión 8%, a vendedores), **monto leído por OCR** con indicador de coincidencia, ver comprobante, **Confirmar** o **Rechazar**.

### 3.13 🔔 Notificaciones push (FCM) — automáticas y con marca
- **Estilo Baratito:** ícono silueta del logo en la barra de estado (generado en 5 densidades), tinte verde de marca, logo a color en la notificación expandida. 4 canales Android con nombre propio (Mensajes / Compras y ventas / Tu cuenta / Actividad).
- **3 handlers:** foreground (se muestra visualmente), background y apertura desde notificación (app cerrada incluida).
- **Navegación inteligente por tipo** al tocarla:

| Evento (`tipo`) | Quién la recibe | Abre |
|---|---|---|
| `nuevo_mensaje` | el otro participante del chat | esa conversación |
| `venta_realizada` | el vendedor | Mis productos |
| `pago_confirmado` | el comprador | Mis compras |
| `pedido_enviado` | el comprador | Mis compras |
| `verificacion_aprobada/rechazada` | el usuario | Verificación |
| `nueva_verificacion` | **todos los admins** | Panel admin |

- **Envío automático (sin humanos):** trigger de Postgres en el evento → fila en `notifications` (historial in-app) → `pg_net` llama a la Edge Function `send-push` → FCM HTTP v1 (OAuth con la service account) → todos los **dispositivos activos** del usuario (`push_tokens`, multi-dispositivo). Tokens de apps desinstaladas se marcan inactivos automáticamente.
- Modelo de tokens: una fila por dispositivo con `is_active` (se desactiva al cerrar sesión), documentado en el README ("Decisiones técnicas S9").

### 3.14 🗺️ Mapas
- `flutter_map` + OpenStreetMap (decisión documentada: sin API key, sin facturación, licencia abierta) — mapa con marcador en el detalle del producto.

---

## 4. Estado de las tablas del esquema

| Tabla | Estado |
|---|---|
| `profiles`, `categories`, `products`, `product_images`, `favorites`, `conversations`, `messages`, `identity_verifications`, `admins`, `cart_items` | ✅ En uso |
| `checkouts` *(+ shipping_fee, ocr_amount, ocr_reference, auto_confirmed)* | ✅ En uso (pago único del comprador) |
| `payouts` | ✅ En uso (deuda de Baratito con cada vendedor) |
| `platform_settings` | ✅ En uso (comisión 8%, cuenta 2905730802, QR) |
| `push_tokens` | ✅ En uso (tokens FCM multi-dispositivo) |
| `notifications` | ✅ En uso (historial + disparador del push) |
| `orders` | ⚠️ Parcial: se crean con desglose de comisión; falta ciclo enviado/entregado/completado |
| `seller_stats`, `reviews`, `reports`, `audit_logs`, `addresses`, `delivery_agents`, `shipments`, `shipment_events`, `seller_payment_methods`, `payments` | ❌ Sin implementar (las 2 últimas quedaron obsoletas: se usa el modelo recaudador con `checkouts`/`payouts`) |

---

## 5. Lo que falta por hacer / mejorar (🚧)

### Prioridad alta
- **Desplegar el servicio de verificación (DeepFace) a la nube** (Hugging Face Spaces / Render / VPS): hoy corre en la PC del equipo; si está apagada, las verificaciones quedan pendientes (el admin igual puede aprobarlas a mano). Incluye: Dockerfile, secretos como variables de entorno y API key propia en el endpoint.
- **Ciclo de vida del pedido:** marcar producto como `sold` al confirmarse la venta, estados enviado/entregado (el trigger de push `pedido_enviado` ya está listo esperando ese flujo), y UI para que el admin marque los `payouts` como pagados.
- **Completar el dominio de correo** (`baratito.shop`): verificar en Resend y apuntar el remitente para que cualquier persona pueda registrarse.

### Prioridad media
- **Vista de ganancias del vendedor** (sus payouts y estados).
- **Reseñas y calificaciones** (`reviews` + `seller_stats`) tras la compra.
- **Editar/eliminar** productos propios; pestaña de moderación de productos en el admin (backend listo).
- Badge de mensajes no leídos en la pestaña Chats.

### Prioridad baja / endurecimiento
- OCR de la cédula (número/nombre) y liveness real en el selfie.
- Reportes/denuncias (`reports`) y auditoría (`audit_logs`).
- iOS: permisos de cámara/galería en Info.plist y APNs para push.
- Pruebas automatizadas (el plan de 7 casos de prueba manuales ya está definido); CI con `flutter analyze` (GitHub Actions, investigado en S9).
- A escala: migrar imágenes públicas a CDN (Cloudflare R2) — barato de hacer porque la BD solo guarda rutas.

---

## 6. Cómo correr el proyecto

### App Flutter
```bash
cd Frontend
flutter pub get
# Celular físico (mismo WiFi que la PC, para la verificación facial):
flutter run --dart-define=VERIFY_SERVICE_URL=http://<IP_DE_TU_PC>:8000
```
> Requiere `google-services.json` en `Frontend/android/app/` (ya está en el repo).

### Servicio de verificación (DeepFace)
```bash
conda activate baratito-verify   # entorno Python 3.11 ya creado
cd Backend/verification_service  # .env con SUPABASE_SERVICE_ROLE_KEY (no commiteado)
uvicorn main:app --host 0.0.0.0 --port 8000
```

### Notificaciones push (una sola vez)
```bash
cd <raíz del proyecto>
supabase login && supabase link --project-ref ddygpqkuxgfrjdipdvek
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat ruta/al/service-account.json)"
supabase functions deploy send-push
```

### Backend (Supabase)
Ejecutar los scripts SQL `00` → `11` en orden (sección 2).

---

## 7. Resumen ejecutivo

**Funciona hoy:** registro/login con OTP, verificación de identidad con reconocimiento facial (auto >70%, revisión humana el resto, probada end-to-end), catálogo con filtros y mapa, publicar con fotos, favoritos, carrito multi-vendedor con **envío** ($2 / $1×vendedor), **pagos por transferencia al Banco de Loja con QR y validación automática del comprobante por OCR** (comisión 8% para Baratito, payouts por vendedor), chat en tiempo real, **notificaciones push automáticas con la marca Baratito** (mensaje, venta, pago, verificación — generadas por el backend, sin tocar la consola de Firebase), perfil editable, tema oscuro persistente y panel de administración completo (métricas, verificaciones y pagos con aprobar/rechazar).

**Lo más importante por construir:** desplegar el servicio de verificación a la nube (quitar la dependencia de la PC local), cerrar el ciclo del pedido (enviado/entregado + payouts pagados + producto vendido), terminar el dominio de correo, y reseñas/reputación.
