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