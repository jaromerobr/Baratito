# Estrategia de Ramas — Baratito
## 1. Convención de Nombres
### Patrón general
`<tipo>/<descripcion-en-kebab-case>`
### Tipos permitidos
- `feature/` — Nuevas funcionalidades del SRS (RF-XX)
- `fix/` — Corrección de bugs encontrados en pruebas
- `refactor/` — Mejoras de código sin cambio de comportamiento
- `chore/` — Actualizaciones de dependencias, configuración Git, docs
- `hotfix/` — Fixes críticos que deben ir directo a main
### Ejemplos reales de Baratito
1. **`feature/rf-12-publicar-producto`**
 - Implementa RF-12: Vendedor puede publicar artículo con título, descripción, precio, categoría e imágenes
 - Autor: @StormXiz (implementó PublishProductScreen)
2. **`fix/validar-precio-negativo`**
 - Bug encontrado en pruebas: el sistema aceptaba precios menores a $0.50
 - Autor: @Eduardopard
3. **`feature/rf-17-detalle-producto`**
 - Implementa RF-17: Pantalla de detalle mostrando todas las fotos, datos del vendedor, TrustScore
 - Autor: @StormXiz (implementó ProductDetailScreen)
4. **`refactor/consolidar-validaciones-producto`**
 - Consolidar funciones de validación repetidas entre PublishProductScreen y ProductDetailScreen
 - Autor: @jaromerobr
---
## 2. Tiempo Máximo de Vida
**Máximo: 7 días de vida útil**
### Justificación
- Baratito tiene commits 3-4 veces por semana en promedio (vimos en las últimas 2 semanas)
- Una rama más vieja que 7 días indica: trabajo bloqueado, merge olvidado, o falta de comunicación
- Semana 9 de 16 — estamos en sprint final, necesitamos integrar constantemente
- 7 días = 1 semana de trabajo, tiempo razonable para una funcionalidad pequeña-mediana (una HU)
### Evidencia
- Feature rf-12-publicar-producto: 4 días (commiteado 3 veces)
- Feature rf-17-detalle-producto: 5 días (commiteado 2 veces)
- Fix validar-precio-negativo: 1 día (hotfix)
---
## 3. Qué Hacer si Supera los 7 Días
### Acción 1: Reunión de equipo (15 minutos)
- Diagnosticar por qué la rama está vieja
- ¿Bloqueado esperando feedback? → Pedir revisión ahora
- ¿Incompleto? → Decidir qué hacer
### Acción 2a: Si está 80%+ funcional
- **Merge a main** aunque falten detalles menores
- Crear nueva rama `refactor/mejorar-rf-12` para pulir en siguiente sprint
- **Justificación**: Integración temprana, feedback en main, no bifurcación de código
### Acción 2b: Si está menos del 80% listo
- **Cerrar rama** sin merge
- Crear nueva rama con histórias más pequeñas
- Replanificar en próximo sprint
- **Justificación**: Si lleva más de 7 días, es que es demasiado grande
### Acción 3: Nunca convertir a rama de larga duración
- No hacemos "rama de desarrollo" o "rama de features" que viva meses
- **Por qué**: Acabas con conflictos enormes, pérdida de sincronización, código muerto
- La solución es hacer historias pequeñas y mergear cada 3-7 días
---
## 4. Quién Aprueba el Merge

### Regla General
- Todo Pull Request debe ser revisado por al menos **1 integrante del equipo** antes de hacer merge.
- Cualquier miembro del equipo puede revisar cambios, independientemente del módulo modificado.
- El reviewer debe verificar:
  - Que el código compile correctamente.
  - Que la funcionalidad cumpla con el requerimiento.
  - Que no introduzca errores evidentes.
  - Que siga el estilo de código del proyecto.

### Excepciones
- **Hotfixes críticos** (la aplicación falla o existe un error que impide su uso): 1 reviewer y merge inmediato.
- **Cambios en `.github/`** (GitHub Actions, CODEOWNERS, plantillas): se recomienda la revisión de **2 integrantes**.
- **README o documentación**: 1 reviewer.
- **Cambios en `pubspec.yaml`** o dependencias: mínimo 1 reviewer para verificar compatibilidad.

---
---
## 5. Workflow Típico en Baratito
1. Crear rama: `git checkout -b feature/rf-12-publicar-producto`
2. Trabajar 2-3 días, commitear frecuentemente
3. Día 3-4: Abrir PR con plantilla completa (ver PULL_REQUEST_TEMPLATE.md)
4. Reviewer aprueba en 24-48h
5. Mergear a main
6. Deletear rama local y remota
7. Comenzar nueva rama
---
## 6. Reintentos y Rollbacks
Si descubrimos un bug en main después del merge:
- Si es menor (UI, typo): fix en nueva rama `fix/nombre-bug`
- Si es crítico (app crashea): `hotfix/nombre` con merge directo
- Si es arquitectónico (cambia significativamente la lógica): considerar revert + nueva rama
