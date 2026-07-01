# Baratito — Estado del Proyecto

Marketplace de compra-venta de segunda mano para **Loja, Ecuador** (estilo Depop/Wallapop).
Documento de estado: **qué está hecho, qué funciona, y qué falta por hacer/mejorar**, explicado desde el login hasta lo último implementado.

> Última actualización: 2026-06-28 · Rama de trabajo: `Eduardo`

---

## 1. Stack y arquitectura

| Capa | Tecnología |
|---|---|
| **App móvil** | Flutter (Dart) · Material 3 · fuente Poppins |
| **Estado** | Riverpod (features nuevas) + Provider/ChangeNotifier (auth y tema) |
| **Navegación** | go_router |
| **Backend** | Supabase (Postgres + Auth + Storage + Realtime + RPC) |
| **Verificación facial** | Servicio aparte en Python (FastAPI + DeepFace) |
| **Correo** | SMTP propio vía Resend |

**Identidad visual:** verde bosque `#2D6A4F` (primario) + amarillo mostaza `#D4A017` (acento). Tema claro y oscuro.

### Arquitectura del código (Flutter)
Organización por **features** en `Frontend/lib/features/`:

```
features/
├── auth/          # providers/repos Riverpod de sesión y perfil
├── products/      # catálogo, detalle, publicar, "mis productos", home shell
├── verification/  # KYC: subir cédula + selfie, estado
├── favorites/     # guardados (corazón)
├── cart/          # carrito + checkout
├── payments/      # pago del pedido (transferencia a Baratito)
├── orders/        # historial de compras
├── chat/          # conversaciones y mensajes en tiempo real
├── profile/       # editar perfil + avatar
└── admin/         # panel: métricas, verificaciones, pagos
```

Núcleo en `Frontend/lib/core/` (cliente Supabase, tema, paleta, rutas) y la capa de auth "clásica" en `lib/screens/auth/`, `lib/providers/`, `lib/services/`, `lib/router/`.

---

## 2. Configuración del backend (orden de ejecución)

Los scripts SQL están en `Backend/` y deben correrse **en orden** en el SQL Editor de Supabase:

| Script | Qué hace |
|---|---|
| `00_setup_auth_profiles.sql` | Trigger que crea `profiles` al registrarse + RLS + backfill |
| `01_catalog_setup.sql` | RLS de catálogo, bucket `product-images`, categorías base |
| `02_seed_products.sql` | Productos de ejemplo (opcional) |
| `03_fix_permissions.sql` | Restaura permisos estándar de Supabase (schema public) |
| `04_verification_setup.sql` | Bucket privado `verification-docs`, RLS KYC, trigger `is_verified` |
| `05_admin_setup.sql` | `is_admin()`, RLS de admin, RPC `admin_overview()` |
| `06_profile_chat_setup.sql` | Bucket `avatars`, RLS órdenes/conversaciones/mensajes, Realtime |
| `07_cart_favorites_checkout.sql` | RLS favoritos, tabla `cart_items`, RPC `checkout_cart()` |
| `08_commission_payments.sql` | Comisión: `platform_settings`, `checkouts`, `payouts`, RPCs |

**Buckets de Storage:**
- `product-images` (público) — fotos de productos
- `avatars` (público) — fotos de perfil
- `verification-docs` (privado) — cédula y selfie (datos sensibles)
- `payment-proofs` (privado) — comprobantes de transferencia

**Servicio Python (verificación facial):** `Backend/verification_service/` (FastAPI + DeepFace). Ver su `README.md` para instalarlo y correrlo. La app lo llama por HTTP (`10.0.2.2:8000` en emulador; IP LAN en dispositivo físico).

**Configuración manual pendiente del admin:**
```sql
-- Datos de cobro de Baratito y % de comisión
update public.platform_settings
  set commission_percent = 10,
      payout_account_number = 'TU_CUENTA',
      payout_account_name = 'Baratito',
      payout_bank = 'Banco de Loja'
  where id = 1;

-- Crear el primer admin
insert into public.admins (user_id)
select id from public.profiles where email = 'TU_CORREO' on conflict do nothing;
```

---

## 3. Funcionalidades implementadas (✅ funciona)

### 3.1 Autenticación
- **Registro** con nombre, correo y contraseña (mín. 8 caracteres y 1 número).
- **Confirmación por código OTP de 6 dígitos** enviado al correo (sin deep links).
- **Login** con correo y contraseña; redirección automática según sesión (go_router).
- **Recuperación de contraseña** por código OTP (enviar código → verificar → nueva contraseña).
- **Modo invitado** ("Ver como invitado"): navegar el catálogo sin sesión.
- Al registrarse, un **trigger** crea automáticamente la fila en `profiles`.
- Mensajes de error traducidos al español.

> **Correo:** se configuró **Resend** como SMTP propio en Supabase. En modo prueba (sin dominio verificado) el código solo llega al correo de la cuenta Resend; para producción se debe verificar un dominio.

### 3.2 Tema claro/oscuro (persistente)
- Botón de tema en el **header del Home**, switch en **Perfil** y en el **login**.
- `AppPalette` (ThemeExtension) con paletas clara/oscura para fondos, superficies, textos, divisores. Toda la app responde al tema.
- La preferencia **se guarda** (shared_preferences) y se restaura al reabrir la app.

### 3.3 Catálogo / Home
- Lista de **productos publicados** consumidos desde Supabase (con imágenes, vendedor y categoría).
- **Búsqueda** por título.
- **Botón de filtros** junto al buscador (panel desplegable): filtrar por **categoría** y **estado del producto** (Nuevo, Como nuevo, Buen estado, Usado). Chips de filtros activos removibles.
- Estados de carga, error y vacío. Pull-to-refresh.
- Saludo personalizado con el nombre del usuario.

### 3.4 Detalle de producto
- Carrusel de imágenes, precio, badge "Negociable", condición, ubicación, marca, descripción.
- Tarjeta del vendedor.
- Acciones: **guardar en favoritos** (corazón), **contactar** (abre chat), **agregar al carrito**.

### 3.5 Publicar producto
- Formulario: fotos (hasta 6), título, descripción, precio, categoría, condición, marca, "negociable".
- Sube las fotos a `product-images` y crea el producto como `active`.
- **Bloqueado por verificación:** solo usuarios verificados pueden publicar (si no, se redirige a la verificación).

### 3.6 Verificación de identidad (KYC con DeepFace)
- Flujo: subir **cédula frontal + posterior** y **selfie en vivo con cámara frontal** (no permite galería).
- Las imágenes van al bucket **privado** `verification-docs`.
- El **servicio Python (DeepFace)** compara el selfie con la cédula y calcula un `face_match_score` (0–1).
- **Regla (configuración interna, no visible al usuario):** coincidencia **> 80% → aprobación automática**; cualquier otro caso → **revisión manual** por una persona del equipo.
- Mensaje al usuario: la revisión manual tarda **máximo 2 horas**, en horario **8:00 a.m. – 12:00 a.m.**
- Al aprobar (auto o admin), un **trigger** marca `profiles.is_verified = true` y se desbloquea publicar/comprar.
- Estados en la app: sin enviar / en revisión / verificado / rechazado (con motivo).

### 3.7 Favoritos (Guardados)
- Corazón en la tarjeta de producto y en el detalle.
- Pestaña **"Guardados"** muestra los productos favoritos.
- Persistente en la tabla `favorites`.

### 3.8 Carrito y checkout (dividido por vendedor)
- **Agregar/quitar** productos; carrito **persistente** (tabla `cart_items`).
- Ícono de carrito con **contador** en el header.
- Pantalla de carrito: items **agrupados por vendedor**, subtotal por vendedor y total.
- **Checkout (`checkout_cart()` RPC, atómico):** un solo pedido del usuario se **divide en una orden por producto**, cada una con su `seller_id`, unidas por un `checkout_id`. Vacía el carrito.

### 3.9 Comisión — Modelo "Baratito recaudador" (✅ backend completo)
- El **comprador paga el total a Baratito** (transferencia), no a cada vendedor.
- En el checkout se calcula y guarda por orden: `platform_fee` (comisión, % configurable, default **10%**) y `seller_payout` (precio − comisión).
- **Pantalla de pago** del comprador: muestra los datos de cobro de Baratito y permite **subir el comprobante**.
- **Admin confirma el pago** → se generan los **payouts** (lo que Baratito debe a cada vendedor) y la **comisión queda con Baratito**.
- El comprador **no paga de más**: la comisión sale de la parte del vendedor.

### 3.10 Chat en tiempo real
- **Lista de conversaciones** (pestaña "Chats") y **pantalla de chat** con burbujas.
- **Mensajes en tiempo real** vía Supabase Realtime; doble check de leído.
- Se abre desde "Contactar" en el detalle del producto (crea/recupera la conversación).
- RLS: solo los dos participantes ven y escriben en la conversación.

### 3.11 Perfil
- **Editar perfil:** nombre, usuario (`username` único), teléfono, biografía y **foto de avatar** (sube a `avatars`).
- Pestaña de perfil con avatar, datos y accesos a: **Mis productos** (En venta / Vendidos), **Mis compras** (historial), **Editar perfil**, tema oscuro y cerrar sesión.

### 3.12 Panel de administración
- Acceso solo para usuarios en la tabla `admins` (entrada visible en Perfil).
- **Resumen (métricas):** usuarios, % verificados, productos activos/vendidos, órdenes, embudo de verificaciones, **productos por categoría** y **top vendedores** (vía RPC `admin_overview()`).
- **Verificaciones:** cola filtrable (pendientes/aprobadas/rechazadas), ver cédula + selfie (URLs firmadas), score de DeepFace y **aprobar/rechazar**.
- **Pagos:** **comisión total ganada por Baratito**, ventas brutas, por pagar a vendedores; lista de pagos por confirmar con comprobante y botón **Confirmar** (genera payouts).

---

## 4. Estado de las tablas del esquema

| Tabla | Estado |
|---|---|
| `profiles` | ✅ En uso (perfil, verificación, avatar) |
| `categories`, `products`, `product_images` | ✅ En uso (catálogo) |
| `favorites` | ✅ En uso |
| `conversations`, `messages` | ✅ En uso (chat) |
| `orders` | ⚠️ Parcial: se crean en checkout y se leen en "mis compras"; falta ciclo de vida (envío/entrega/completado) |
| `identity_verifications` | ✅ En uso (KYC) |
| `admins` | ✅ En uso |
| `cart_items` *(nueva)* | ✅ En uso (carrito) |
| `platform_settings`, `checkouts`, `payouts` *(nuevas)* | ✅ En uso (comisión) |
| `seller_stats` | ❌ Existe, no se actualiza/usa (estadísticas de vendedor) |
| `reviews` | ❌ Sin implementar (reseñas/calificaciones) |
| `notifications`, `push_tokens` | ❌ Sin implementar (notificaciones push) |
| `reports` | ❌ Sin implementar (reportes/denuncias) |
| `audit_logs` | ❌ Sin implementar (auditoría de acciones admin) |
| `addresses` | ❌ Sin implementar (direcciones de entrega) |
| `delivery_agents`, `shipments`, `shipment_events` | ❌ Sin implementar (logística/envíos) |
| `seller_payment_methods`, `payments` | ❌ No usados: se optó por el modelo "Baratito recaudador" con `checkouts`/`payouts` |

---

## 5. Lo que falta por hacer / mejorar (🚧)

### 5.1 Pagos y comisión (prioridad alta)
- **Marcar payouts como pagados:** UI en el admin para registrar cuándo Baratito ya transfirió a cada vendedor (`payouts.status = 'paid'`).
- **Vista de ganancias del vendedor:** que el vendedor vea cuánto le toca y el estado de sus pagos (`seller_payout` / `payouts`).
- **Pasarela automática:** integrar **PayPhone** (Ecuador) para cobro con tarjeta y, a futuro, **split automático** (Kushki/PayPhone marketplace) que evite el pago manual.
- **Datos de cobro de Baratito:** falta cargarlos en `platform_settings` (cuenta/QR).

### 5.2 Ciclo de vida del pedido (prioridad alta)
- Al confirmar la venta, **marcar el producto como `sold`** (hoy queda `active`).
- **Reservar** el producto al agregarlo al carrito/checkout para evitar doble venta (no hay estado "reservado" en el enum actual).
- Estados de orden completos (pendiente → pagado → entregado → completado / cancelado) y su UI.
- **Entrega/envíos:** usar `addresses`, `delivery_agents`, `shipments` (recogida vs. delivery).

### 5.3 Productos
- **Editar y eliminar** los productos propios.
- **Pestaña de moderación de productos en el admin** (el backend ya permite ver/ocultar/eliminar; falta la UI).
- Marcar/cobrar **destacados** (`is_featured`) como fuente extra de ingresos.

### 5.4 Reputación y confianza
- **Reseñas y calificaciones** (`reviews`) tras una compra; actualizar `seller_stats` (ventas, rating).
- Mostrar `trust_score` y verificación en el perfil público del vendedor.

### 5.5 Notificaciones
- **Push** (FCM) usando `push_tokens` y `notifications`: nuevo mensaje, venta, verificación aprobada/rechazada, pago confirmado.
- Indicador de **mensajes no leídos** en la pestaña de chats.

### 5.6 Verificación (KYC)
- **OCR de la cédula** para llenar `cedula_number` y `ocr_extracted_name` y compararlos con el nombre del perfil.
- **Liveness real** (anti-spoofing) en el selfie; hoy solo se fuerza cámara (no foto de galería).
- **Desplegar el servicio Python** a la nube (Hugging Face Spaces / Render) en vez de local.

### 5.7 Reportes y moderación
- **Reportar** productos/usuarios (`reports`) y bandeja de reportes en el admin.
- **Auditoría** de acciones de admin (`audit_logs`).

### 5.8 Seguridad y producción
- **Dominio propio en Resend** para que los correos lleguen a cualquier usuario.
- Mover la **`service_role key`** del servicio Python a variables de entorno seguras (ya está en `.env`, no commitear) y **no exponerla** nunca en la app.
- Reemplazar HTTP local por **HTTPS** en producción (hoy `usesCleartextTraffic=true` solo para desarrollo).
- Revisar/rotar la **anon key** si fuera necesario y endurecer RLS.

### 5.9 Calidad / plataforma
- **iOS:** agregar `NSCameraUsageDescription` y `NSPhotoLibraryUsageDescription` al `Info.plist` (image_picker).
- **Manejo de errores** y reintentos más consistente; estados offline.
- **Pruebas** (unitarias y de widget) — actualmente mínimas.
- **Internacionalización** si se quisiera más allá de español.

---

## 6. Cómo correr el proyecto

### App Flutter
```bash
cd Frontend
flutter pub get
flutter run
# Dispositivo físico + servicio de verificación local:
flutter run --dart-define=VERIFY_SERVICE_URL=http://TU_IP_LAN:8000
```

### Servicio de verificación (DeepFace)
```bash
cd Backend/verification_service
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env     # pega tu SUPABASE_SERVICE_ROLE_KEY
uvicorn main:app --host 0.0.0.0 --port 8000
```

### Backend (Supabase)
Ejecutar los scripts SQL `00` → `08` en orden en el SQL Editor (ver sección 2).

---

## 7. Resumen ejecutivo

**Funciona hoy:** registro/login con verificación por correo, recuperación de contraseña, tema claro/oscuro persistente, catálogo con filtros y búsqueda, publicar productos, **verificación de identidad KYC con DeepFace**, favoritos, carrito con **checkout dividido por vendedor**, **comisión para Baratito** (modelo recaudador) con pantalla de pago y confirmación admin, **chat en tiempo real**, perfil editable con avatar, "mis productos / mis compras", y un **panel de administración** con métricas, verificaciones y pagos.

**Lo más importante por construir:** cerrar el **ciclo de pago** (payouts pagados + pasarela automática), el **ciclo del pedido** (marcar vendido, envíos, estados), **reseñas/reputación**, **notificaciones push**, y endurecer **seguridad para producción**.
