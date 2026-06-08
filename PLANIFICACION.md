# Planificación del Proyecto BARATITO

Este documento detalla el estado actual del desarrollo, las tareas completadas y los próximos hitos para alcanzar una versión estable de la aplicación.

---

##  Estado Actual: MVP Phase 1 (Core Architecture)
El proyecto ha establecido su base técnica, arquitectura de carpetas e integración con el backend.

###  Hitos Completados

#### Infraestructura y Backend
- [x] Configuración inicial del proyecto Flutter con arquitectura por capas (Data/Domain/Presentation).
- [x] Integración de **Supabase** (Auth y Database).
- [x] Creación de Triggers en SQL para sincronizar `auth.users` con la tabla `public.users`.
- [x] Implementación de **Row Level Security (RLS)** para proteger los datos de usuario.
- [x] Configuración del cliente de red **Dio** (Singleton pattern).

####  Interfaz y Core de Frontend
- [x] Sistema de navegación con **GoRouter**.
- [x] Gestión de estado global con **Riverpod**.
- [x] Configuración de temas (AppTheme) con soporte para Dark Mode.
- [x] Login y Register UI flows.
- [x] Widgets de UI especializados:
  - `ProductDetailCard`: Tarjeta optimizada para mostrar productos.
  - `SearchFilterPanel`: Panel interactivo para filtrado de búsquedas.

---

##  Próximos Pasos y Requisitos Pendientes

###  Hito 2: Funcionalidad de Marketplace (En Progreso)
- [ ] **Publicación de Artículos**:
  - Implementar formulario con validación.
  - Integrar Supabase Storage para carga de imágenes.
  - Endpoint/Logic para guardar en la tabla `posts` (inventario).
- [ ] **Lógica de Búsqueda y Filtrado**:
  - Conectar el `SearchFilterPanel` con la base de datos.
  - Implementar búsqueda por texto y filtros dinámicos.
- [ ] **Dashboard en Tiempo Real**:
  - Cargar productos reales desde la base de datos en lugar de mocks.
  - Implementar scroll infinito o paginación.

### Hito 3: Experiencia de Usuario y Comunicación
- [ ] **Sistema de Mensajería**:
  - Chat básico entre comprador y vendedor.
  - Notificaciones de mensajes nuevos.
- [ ] **Gestión de Perfil Avanzada**:
  - Editar información de usuario (Avatar, teléfono, ubicación).
  - Ver historial de compras y ventas.
- [ ] **Validaciones de Seguridad**:
  - Verificación de correo electrónico.
  - Reporte de usuarios o artículos fraudulentos.

###  Hito 4: Lanzamiento y Pulido
- [ ] Implementación de Tests Unitarios y de Widget.
- [ ] Optimización de rendimiento (Lazy loading de imágenes).
- [ ] Preparación para despliegue (Play Store / App Store).

---

## Requisitos Técnicos a Mantener
- **Clean Architecture**: Mantener la separación de responsabilidades en cada feature.
- **Seguridad**: Asegurar que cada nueva tabla tenga sus correspondientes políticas RLS.
- **Rendimiento**: Minimizar las peticiones innecesarias al backend usando caché de Riverpod.
