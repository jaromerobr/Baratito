# 🏷️ BARATITO — Marketplace de Segunda Mano

**Baratito** es una aplicación móvil moderna diseñada para facilitar la compra y venta de artículos de segunda mano. Enfocada en la simplicidad y la seguridad, conecta a vendedores locales con compradores interesados a través de una interfaz intuitiva y eficiente.

---

## 🚀 Características Principales

### ✅ Implementado (MVP Phase 1)
- **Autenticación Completa**: Registro e inicio de sesión integrados con Supabase Auth.
- **Dashboard Dinámico**: Visualización de categorías y productos destacados.
- **Gestión de Perfil**: Estructura base para perfiles de compradores y vendedores.
- **Navegación Fluida**: Implementación de `go_router` para una experiencia de usuario sin interrupciones.
- **Modo Oscuro/Claro**: Soporte nativo para temas visuales personalizados.
- **Componentes Premium**: Widgets personalizados como `ProductDetailCard` y `SearchFilterPanel`.

### 🛠️ En Desarrollo / Próximamente
- **Publicación de Artículos**: Flujo completo para subir productos con imágenes.
- **Chat en Tiempo Real**: Comunicación directa entre usuarios mediante WebSockets (Supabase).
- **Sistema de Filtros Avanzado**: Búsqueda por precio, categoría, estado y ubicación.
- **Notificaciones Push**: Alertas de nuevos mensajes y ofertas.
- **Integración de Pagos**: Soporte para transacciones seguras dentro de la app.

---

## 💻 Tech Stack

### Frontend (Móvil)
- **Framework**: [Flutter](https://flutter.dev/)
- **Estado (State Management)**: [Riverpod](https://riverpod.dev/) (Hooks Riverpod)
- **Navegación**: [GoRouter](https://pub.dev/packages/go_router)
- **Red**: [Dio](https://pub.dev/packages/dio)
- **Diseño**: Material 3 con fuentes de [Google Fonts](https://fonts.google.com/).

### Backend (BaaS)
- **Plataforma**: [Supabase](https://supabase.com/)
- **Base de Datos**: PostgreSQL
- **Seguridad**: Row Level Security (RLS) policies.
- **Automatización**: SQL Triggers para sincronización de perfiles.

---

## 📥 Instalación y Configuración

### Prerrequisitos
- Tener instalado [Flutter SDK](https://docs.flutter.dev/get-started/install).
- Cuenta activa en [Supabase](https://supabase.com/).

### Pasos
1. **Clonar el repositorio**:
   ```bash
   git clone https://github.com/tu-usuario/baratito.git
   cd baratito/Baratito/Frontend
   ```
2. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```
3. **Configurar el Backend**:
   - Ejecuta los scripts SQL de `Baratito/Backend` en el SQL Editor de tu proyecto Supabase.
4. **Ejecutar la App**:
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=TU_URL_DE_SUPABASE \
     --dart-define=SUPABASE_ANON_KEY=TU_ANON_KEY
   ```

---

## 📝 Planificación y Seguimiento
Para ver el estado detallado de las tareas y el roadmap técnico, consulta el archivo [PLANIFICACION.md](./PLANIFICACION.md).

---

## 📄 Licencia
Este proyecto está bajo la licencia MIT. Consulta el archivo `LICENSE` para más detalles.

---

# 🔔 Semana 9 — Notificaciones push (FCM)

## Configuración de Firebase (paso a paso)

> El `applicationId` de la app es **`ec.edu.uide.baratito`** — úsalo tal cual al registrar la app en Firebase.

1. **Crear proyecto:** https://console.firebase.google.com → *Agregar proyecto* → nombre `Baratito` → crear (Analytics opcional).
2. **Registrar app Android:** en el proyecto → ícono Android → **Nombre del paquete:** `ec.edu.uide.baratito` → *Registrar app*.
3. **Descargar `google-services.json`** y colocarlo en **`Frontend/android/app/google-services.json`**.
4. **Gradle:** ya está configurado en el repo (plugin `com.google.gms.google-services` en `settings.gradle.kts` y `app/build.gradle.kts`, desugaring y `minSdk 23`). No hay que tocar nada.
5. **Cloud Messaging** viene habilitado por defecto (API HTTP v1).
6. **Correr la app:** `flutter run`. En el primer arranque se pide el permiso de notificaciones (Android 13+) y el **token FCM** se guarda en `push_tokens` de Supabase. El token también se imprime en consola para pruebas.
7. **Enviar prueba:** Firebase Console → *Messaging* → *Enviar mensaje de prueba* → pega el token del dispositivo. Para navegación, en *Opciones adicionales → Datos personalizados* agrega:
   - `tipo` = `nuevo_mensaje` y `conversation_id` = `<id de una conversación>` → abre el chat.
   - `tipo` = `pago_confirmado` → abre "Mis compras".

> **Requisito Supabase:** ejecutar `Backend/09_push_tokens_setup.sql` (RLS de `push_tokens`).

## Decisiones técnicas S9

**1. ¿Qué eventos generarán notificaciones push? ¿Notification o Data messages?**
Definimos al menos dos, propios del negocio de Baratito:
- **`nuevo_mensaje`** — cuando un usuario recibe un mensaje de chat de otro (comprador ↔ vendedor). Navega a `/chat/:id`.
- **`pago_confirmado`** — cuando el admin confirma el pago de un pedido del comprador. Navega a `/purchases`.

Usamos mensajes **híbridos: `notification` + `data`**. El bloque `notification` (título/cuerpo) permite que **Android muestre la notificación solo** cuando la app está en background o cerrada; el bloque `data` (`tipo`, `conversation_id`) es el que usamos para la **navegación inteligente** al tocarla y para pintarla nosotros en foreground con `flutter_local_notifications`. Elegimos el híbrido y no *data-only* porque los mensajes solo-data no se muestran automáticamente y el SO puede retrasarlos/agruparlos en background; y no *notification-only* porque no garantiza los datos de ruteo.

**2. ¿Qué pasa si el usuario desinstala la app? ¿El token queda activo para siempre?**
El token **no** se borra solo al desinstalar (FCM no avisa a nuestra BD). Queda en `push_tokens` hasta que:
- Al **cerrar sesión** lo marcamos `is_active = false` (lo hace la app).
- Al **intentar enviar**, FCM responde `UNREGISTERED` / `NotRegistered` para tokens muertos; el backend debe entonces marcar ese token `is_active = false` (o borrarlo).

Si no se limpian: se acumulan **tokens fantasma**, se desperdicia cuota de envío, las métricas de alcance quedan infladas y se intenta notificar a dispositivos que ya no existen. Por eso el modelo es **multi-dispositivo** (una fila por token, no un `fcm_token` único en `profiles`) y con estado `is_active`.

**3. ¿Cómo enviaría el backend una notificación automáticamente (sin humano)?**
Flujo propuesto (descrito, no implementado aún):
1. Ocurre un evento en Postgres (ej. `INSERT` en `messages`, o `checkouts.status = 'paid'`).
2. Un **trigger** o un **webhook de base de datos** de Supabase dispara una **Edge Function**.
3. La función busca los `push_tokens` **activos** del usuario destinatario.
4. Con las credenciales de la **cuenta de servicio de Firebase**, llama a la **API HTTP v1 de FCM** enviando `notification` + `data` (`tipo`, ids).
5. FCM entrega la notificación a cada dispositivo del usuario.
6. Si FCM devuelve token inválido, la función marca ese token `is_active = false`.

Así la notificación se genera **automáticamente al ocurrir el evento**, sin que nadie use la consola de Firebase.

---

# 🗺️ Mapas — decisión y uso

**Decisión: OpenStreetMap con `flutter_map`** (no Google Maps).

Discutimos ambas opciones para Baratito y elegimos OpenStreetMap por:

| Criterio | Google Maps | **OpenStreetMap (flutter_map)** ✅ |
|---|---|---|
| **Costo** | Necesita API key + **cuenta de facturación** (tarjeta), aunque tenga capa gratis | **Gratis**, sin tarjeta ni cuota |
| **Configuración** | API key, habilitar SDK, restricciones de clave | **Sin API key**, funciona de inmediato |
| **Privacidad** | Uso y ubicaciones se comparten con Google | Más neutral; los tiles vienen de OSM, sin perfilado |
| **Licencia** | Términos comerciales de Google | Abierta — **ODbL** (datos libres) |

Para un proyecto local de segunda mano, sin presupuesto y donde no queremos exigir cuentas de facturación, **flutter_map/OSM es lo más apropiado**: cero costo, cero configuración de credenciales, y cubre nuestra necesidad (mostrar la ubicación de un producto).

**Dónde se usa:** en la **pantalla de detalle del producto**, sección *"Ubicación"*, se muestra un `FlutterMap` con un **marcador real** en la ciudad del producto (`products.location_city`, ej. *Loja*). Las coordenadas de las ciudades de Ecuador están en `product_location_map.dart`. Los tiles se cargan desde `tile.openstreetmap.org` con un `User-Agent` propio (`ec.edu.uide.baratito`), conforme a la política de uso de OSM.

> Mejora futura: guardar `latitude`/`longitude` exactos por producto (o punto de entrega usando la tabla `addresses`, que ya tiene esas columnas) para un marcador preciso en vez de aproximar por ciudad.