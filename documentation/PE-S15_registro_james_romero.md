# Registro PE-S15 — James Romero — Grupo Baratito

**Proyecto:** Baratito — marketplace de productos de segunda mano
**Arquitectura:** Monolito modular (Flutter + Dart + Supabase/PostgreSQL)
**Fecha:** 11 de agosto de 2026

## Módulo/función auditada

- **Módulo:** Gestión de publicaciones + Gestión de cuentas (verificación de identidad)
- **Función principal auditada:** `verifyGateProvider` en
  `Frontend/lib/features/verification/presentation/providers/verification_provider.dart`
- **Código relacionado inspeccionado:**
  - `Frontend/lib/features/products/presentation/screens/main_shell.dart` → `_onPublishTap`
  - `Frontend/lib/features/products/data/product_repository.dart` → `createProduct`
  - `Frontend/lib/features/products/presentation/screens/publish_product_screen.dart` → `_submit` y validadores
  - `Backend/01_catalog_setup.sql` → política RLS `"Vendedor crea productos"`

## Diagnóstico

La regla de negocio central del módulo es **RN-1: "un vendedor debe tener su
identidad verificada y aprobada antes de poder publicar un artículo"**.

Al inspeccionar el repositorio encontré que esa regla vivía en **un solo punto y
en la capa equivocada**:

| Capa | Archivo | ¿Aplica RN-1? |
|---|---|---|
| UI (botón publicar) | `main_shell.dart:88` | Sí |
| Lógica del gate | `verification_provider.dart` | Sí |
| Repositorio (inserción real) | `product_repository.dart:97-100` | **No** — solo comprueba que exista sesión |
| Base de datos (RLS) | `01_catalog_setup.sql:49-53` | **No** — `with check (auth.uid() = seller_id)` |

Es decir: `createProduct` y la política RLS comprueban **autenticación**, no
**verificación de identidad**. Son cosas distintas y el proyecto las estaba
tratando como si fueran la misma. Cualquier ruta que no pase por el botón
(deep link de `go_router` hacia `/publish`, o una llamada directa a la API de
Supabase con el token del usuario) permitía publicar sin KYC aprobado.

Además, la cobertura de pruebas del proyecto era **cero**: el único archivo en
`Frontend/test/` era `widget_test.dart` con un placeholder `expect(1 + 1, 2)`.

Seleccioné `verifyGateProvider` porque es donde la regla realmente se decide y
porque es lógica pura de composición de providers: se puede probar con
`ProviderContainer(overrides: [...])` sin Supabase ni red. `createProduct`, en
cambio, construye su cliente en un campo (`final _client = SupabaseClientHelper.client`),
sin inyección de dependencias, por lo que no es testeable sin refactorizar la
capa de datos completa.

## Prompt usado

Prompt exacto entregado al asistente (Claude, en Claude Code), transcrito sin editar:

```
Quiero realizar la actividad PE-S15 de mi curso de Ingeniería de Software sobre mi
proyecto real "Baratito", un marketplace de productos de segunda mano.

IMPORTANTE:
No quiero que inventes código, archivos, funciones ni reglas de negocio. Primero
debes inspeccionar el repositorio actual y trabajar únicamente con el código que
realmente existe.

CONTEXTO DEL PROYECTO

Baratito es una aplicación marketplace de productos de segunda mano.
La arquitectura definida para el proyecto es un MONOLITO MODULAR.

Tecnologías principales: Flutter, Dart, Supabase, PostgreSQL mediante Supabase,
Git/GitHub.

Los principales módulos/bounded contexts son:
1. Gestión de cuentas
2. Gestión de publicaciones
3. Gestión de compras
4. Servicios compartidos

REGLAS DE NEGOCIO IMPORTANTES QUE DEBES TENER PRESENTES:
1. Un vendedor debe tener su identidad verificada y aprobada antes de poder
   publicar un artículo.
2. Un vendedor puede crear, editar y eliminar sus propias publicaciones.
3. Un comprador puede consultar los productos publicados.
4. Un comprador puede iniciar una conversación desde el detalle de un artículo.
5. Una compra debe estar asociada al producto y a los usuarios correspondientes.
6. La información de publicación y compra debe respetar las responsabilidades de
   cada módulo.
7. No debemos introducir microservicios ni cambiar la arquitectura de monolito
   modular.
8. No debes modificar reglas de negocio solamente para hacer pasar una prueba.

OBJETIVO DE ESTA ACTIVIDAD

Quiero realizar pair programming con IA y hacer una VERIFICACIÓN CRÍTICA sobre
código real del proyecto. Quiero trabajar específicamente sobre la funcionalidad
de publicación de productos, especialmente la regla:

"Un vendedor no puede publicar un artículo hasta que su identidad haya sido
verificada y aprobada."

PRIMER PASO — INSPECCIÓN
Antes de modificar cualquier archivo:
1. Inspecciona la estructura completa del proyecto.
2. Localiza el módulo relacionado con Gestión de Publicaciones.
3. Localiza la función, método, servicio, repository, controller o pantalla que
   realmente sea responsable de publicar un producto.
4. Identifica dónde se valida actualmente si el vendedor está autorizado para
   publicar.
5. Identifica las clases/modelos relacionados con usuario, perfil, vendedor,
   producto y verificación de identidad.
6. Identifica si ya existen pruebas relacionadas con esta funcionalidad.
7. No inventes nombres de archivos ni funciones.

Después de inspeccionar el código, explícame: archivo que consideras adecuado
para auditar, función/método que será auditado, qué hace actualmente, qué pruebas
existen actualmente, qué regla de negocio debería protegerse, qué problema o
riesgo de calidad detectas.

SEGUNDO PASO — PROPUESTA
Propón una estrategia de pruebas para esa funcionalidad. Quiero como mínimo
pruebas para:
1. Vendedor con identidad aprobada → puede publicar.
2. Vendedor sin identidad aprobada → no puede publicar.
3. Usuario que no cumple las condiciones necesarias → no puede publicar.
4. Datos inválidos del producto → deben rechazarse.
5. Si existe alguna otra condición importante en el código actual, inclúyela.
NO implementes todavía.

TERCER PASO — GENERACIÓN CON IA
Una vez identificada la función real, genera las pruebas correspondientes
utilizando las herramientas y framework de testing que ya utiliza el proyecto.
No introduzcas un framework de pruebas diferente sin justificarlo.
Las pruebas deben: ser legibles, tener nombres descriptivos, respetar la
arquitectura actual, no modificar la lógica de negocio solamente para que pasen,
no depender innecesariamente de servicios externos reales, utilizar mocks/fakes
cuando sea apropiado, mantener el código limpio.
Si detectas que la implementación actual NO cumple correctamente la regla de
negocio, no ocultes el problema. Explícalo y propón la modificación mínima
necesaria.

CUARTO PASO — VERIFICACIÓN CRÍTICA
Después de generar las pruebas, actúa como un revisor crítico. Para CADA
sugerencia o cambio que hayas realizado, crea una tabla con Sugerencia de IA /
Decisión / Justificación. La justificación debe estar basada en las reglas de
negocio reales de Baratito. Busca específicamente errores que una IA podría
cometer, por ejemplo: permitir publicar aunque el vendedor no esté verificado,
confundir autenticación con verificación de identidad, permitir que cualquier
usuario publique, validar solamente que exista un usuario sin comprobar su estado
de verificación, modificar una regla de negocio para hacer pasar una prueba,
crear dependencias entre módulos que rompan el monolito modular, probar solamente
el caso exitoso y olvidar los casos negativos, inventar campos que no existen,
hacer pruebas que no correspondan al código real.
No marques una sugerencia como incorrecta solamente para cumplir con la
actividad. Si la propuesta es correcta, indícalo. La revisión debe ser honesta.

QUINTO PASO — EJECUCIÓN
Implementa las pruebas acordadas. Ejecuta el conjunto de pruebas. Si alguna
prueba falla: explica exactamente por qué falla, determina si el problema está en
la prueba o en el código, no cambies arbitrariamente la prueba para hacerla
pasar, y si el código viola una regla de negocio propón la corrección mínima.

NO inventes resultados. NO inventes archivos. NO inventes funciones. NO digas que
las pruebas pasaron si no las ejecutaste. NO hagas commit todavía. NO modifiques
el código hasta terminar la inspección y mostrarme el diagnóstico.

Primero comienza únicamente con la INSPECCIÓN DEL REPOSITORIO.
```

## Sugerencia de la IA

Resumen fiel de lo que el asistente devolvió, sin maquillar:

1. **Inspección.** Localizó correctamente los cuatro puntos implicados en la
   publicación y **detectó por sí mismo que RN-1 solo estaba aplicada en la UI**,
   no en `createProduct` ni en la política RLS.
2. **Elección de la unidad a auditar.** Propuso auditar `verifyGateProvider` en
   lugar de `createProduct`, argumentando que el repositorio no es testeable sin
   inyección de dependencias.
3. **Framework.** Propuso usar solo `flutter_test` + `ProviderContainer` de
   Riverpod, sin añadir `mockito` ni `mocktail`, porque Riverpod ya permite
   sustituir providers.
4. **Refactor 1.** Mover el enum `VerifyGate` desde la capa `presentation` a
   `domain` y crear `PublishPermission.canPublish(gate, isAdmin)` como regla pura,
   reexportando los símbolos para no romper los imports existentes.
5. **Refactor 2.** Extraer los validadores del formulario (`title`, `price`,
   `hasEnoughPhotos`) desde el `State` del widget a
   `products/domain/publish_validation.dart`.
6. **Pruebas.** 26 pruebas nuevas en tres archivos, cubriendo el camino feliz y
   los casos negativos.
7. **Corrección del hueco de RN-1.** Propuso corregirlo en la capa RLS con una
   nueva migración SQL, no dentro de `createProduct`.
8. **Hallazgos reportados y NO corregidos** (para decisión del equipo): el
   validador de precio acepta `0`; la categoría no tiene validador; un error al
   cargar el perfil se reporta como `notSubmitted`.

## Verificación humana

### 1. Auditar `verifyGateProvider` en vez de `createProduct`

**DECISIÓN: ACEPTADO**

**JUSTIFICACIÓN:** Es donde RN-1 se decide realmente. `createProduct` construye
su cliente Supabase en un campo, sin inyección, así que probarlo exigiría
refactorizar la capa de datos — un cambio de arquitectura que choca con la
RN-7 (no alterar el monolito modular por conveniencia de las pruebas).

### 2. Usar solo `flutter_test` + `ProviderContainer`, sin mocks externos

**DECISIÓN: ACEPTADO**

**JUSTIFICACIÓN:** `pubspec.yaml` ya trae `flutter_test` y `flutter_riverpod
2.6.1`. Añadir `mocktail` sería introducir un framework nuevo sin necesidad,
justo lo que el tercer paso pedía evitar. Los overrides de Riverpod cumplen la
función de fake sin dependencias externas.

### 3. Mover `VerifyGate` a `domain` y crear `PublishPermission`

**DECISIÓN: ACEPTADO**

**JUSTIFICACIÓN:** El enum estaba declarado en la capa `presentation`, de modo
que la regla de negocio solo era accesible importando código de UI. Moverlo a
`domain` respeta RN-6 (cada módulo con sus responsabilidades) y permite probar
la regla sin árbol de widgets. El `export` mantiene compilando `main_shell.dart`
y `verification_screen.dart` sin tocarlos.

### 4. `canPublish` deniega explícitamente cuando `gate == notLoggedIn`, aunque sea admin

**DECISIÓN: MODIFICADO** (la lógica original era `isAdmin || gate == verified`)

**JUSTIFICACIÓN:** La condición literal de `main_shell.dart:88` daba `true` para
un admin sin sesión. En la práctica no ocurre porque `_onPublishTap` corta antes
si no hay sesión, pero al extraer la regla a una función pura ese guardia se
habría perdido. Sin sesión no hay `seller_id` que asociar al producto, lo que
violaría RN-5 ("una compra debe estar asociada al producto y a los usuarios
correspondientes", y su equivalente en la publicación: todo producto tiene
vendedor). El cambio **endurece** la regla, no la relaja, y no altera el
comportamiento observable de la app.

### 5. La exención de administradores forma parte de la regla

**DECISIÓN: ACEPTADO** (y probada explícitamente)

**JUSTIFICACIÓN:** Esta es información que la IA **no podía deducir** del
enunciado de RN-1: los admins de Baratito están exentos del KYC
(`main_shell.dart:80-84`), porque son quienes revisan las verificaciones ajenas
y exigirles verificarse a sí mismos crearía una dependencia circular. La IA solo
lo supo porque estaba escrito en el código; si hubiera generado la prueba desde
la regla de negocio "en limpio", habría afirmado que un admin no verificado no
puede publicar, y la prueba habría fallado contra el comportamiento correcto.

### 6. `VerifyStatus.unknown` se prueba como estado que DENIEGA

**DECISIÓN: ACEPTADO**

**JUSTIFICACIÓN:** Otra regla no evidente. `VerifyStatus.fromString` devuelve
`unknown` cuando la base de datos trae un estado que la app no reconoce
(`verification_model.dart:23`), y el gate lo agrupa con `pending`. Es una
decisión *fail-closed* deliberada: ante un estado ambiguo, RN-1 exige no
publicar. Una IA razonando de forma ingenua podría haber tratado `unknown` como
"sin información" y dejado pasar la publicación.

### 7. Corregir el hueco de RN-1 dentro de `createProduct`

**DECISIÓN: RECHAZADO**

**JUSTIFICACIÓN:** Es la solución que parece obvia y es la que una IA sugeriría
por defecto, pero es incorrecta para Baratito por dos motivos. Primero, obligaría
al módulo de **Gestión de publicaciones** a consultar `profiles` /
`identity_verifications`, que pertenecen al módulo de **Gestión de cuentas**,
creando un acoplamiento entre módulos que rompe RN-6. Segundo, y más importante:
una comprobación en el cliente Flutter **sigue siendo evitable**, porque
cualquiera con el token del usuario puede llamar a la API de Supabase
directamente. Sería seguridad de fachada.

### 8. Corregir el hueco de RN-1 en la política RLS (`Backend/12_publish_requires_verification.sql`)

**DECISIÓN: ACEPTADO CON RESERVA**

**JUSTIFICACIÓN:** RLS es la única capa que ningún cliente puede saltarse, y
además mantiene la separación de módulos: el código de productos no necesita
saber nada de verificación. La reserva es honesta y debe constar: **esta
migración está escrita y commiteada pero NO ha sido ejecutada todavía en la
instancia de Supabase del grupo**, y por tanto **no está cubierta por ninguna
prueba automatizada**. Hasta que el equipo la ejecute, RN-1 sigue aplicándose
únicamente en el cliente.

### 9. Extraer los validadores del formulario a `PublishValidation`

**DECISIÓN: ACEPTADO**

**JUSTIFICACIÓN:** La validación estaba embebida en el `State` del widget, así
que "datos inválidos del producto deben rechazarse" no era comprobable sin
montar toda la pantalla (que a su vez necesita Supabase para las categorías).
La extracción es un movimiento literal: los mensajes al usuario y el
comportamiento son idénticos.

### 10. NO cambiar el validador de precio para rechazar `0`

**DECISIÓN: RECHAZADO** (se documenta, no se corrige)

**JUSTIFICACIÓN:** El validador actual solo rechaza precios negativos, de modo
que se puede publicar un artículo en $0.00. Es un hallazgo real, pero decidir si
Baratito admite artículos regalados o exige precio mayor que cero **es una regla
de negocio que le corresponde al equipo**, no a la IA ni a mí en solitario. Por
eso la prueba `DOCUMENTA el comportamiento actual: acepta precio 0` afirma lo que
el código hace hoy y deja constancia escrita del hueco, en lugar de cambiar la
regla para que la prueba quede bonita (RN-8).

### 11. Las pruebas cubren estados de carga, no solo éxito/fracaso

**DECISIÓN: ACEPTADO**

**JUSTIFICACIÓN:** `verifyGateProvider` puede devolver `loading` mientras el
perfil o la solicitud aún se están cargando. Sin esas dos pruebas, un cambio
futuro que tratara `loading` como "verificado por defecto" pasaría desapercibido
y violaría RN-1 durante los primeros milisegundos de cada arranque.

## Archivos afectados

**Nuevos:**
- `Frontend/lib/features/verification/domain/publish_permission.dart`
- `Frontend/lib/features/products/domain/publish_validation.dart`
- `Frontend/test/features/verification/verify_gate_provider_test.dart` (11 pruebas)
- `Frontend/test/features/verification/publish_permission_test.dart` (4 pruebas)
- `Frontend/test/features/products/publish_validation_test.dart` (11 pruebas)
- `Backend/12_publish_requires_verification.sql` (**no ejecutada aún**)
- `documentation/PE-S15_registro_james_romero.md` (este documento)

**Modificados:**
- `Frontend/lib/features/verification/presentation/providers/verification_provider.dart`
  — enum movido a `domain` y reexportado
- `Frontend/lib/features/products/presentation/screens/main_shell.dart`
  — usa `PublishPermission.canPublish`
- `Frontend/lib/features/products/presentation/screens/publish_product_screen.dart`
  — usa `PublishValidation`

Ninguna regla de negocio fue modificada para hacer pasar una prueba.

## Resultado de las pruebas

Comando ejecutado: `flutter test` (Flutter 3.41.9, Dart 3.11.5)

```
00:02 +27: All tests passed!
```

27 pruebas ejecutadas, 27 en verde (26 nuevas + el placeholder preexistente).
`flutter analyze`: 1 aviso, preexistente y ajeno a este cambio
(`anonKey` deprecado en `core/supabase_client.dart`).

### Qué regla protege cada prueba

| Prueba | Regla protegida |
|---|---|
| `perfil con is_verified = true habilita la publicación` | RN-1, camino aprobado |
| `perfil aún sin el flag pero con solicitud aprobada...` | RN-1 vía el trigger de `04_verification_setup.sql` |
| `solicitud en revisión NO habilita la publicación` | RN-1, caso negativo |
| `solicitud rechazada NO habilita la publicación` | RN-1, caso negativo |
| `usuario sin solicitud de verificación NO habilita...` | RN-1, caso negativo |
| `estado desconocido se trata como pendiente` | RN-1 fail-closed |
| `usuario sin sesión NO habilita la publicación` | Autenticación previa a RN-1 |
| `perfil cargando` / `verificación aún cargando` | RN-1 durante estados transitorios |
| `error al cargar el perfil deniega la publicación` | RN-1 ante fallo de red |
| `admin sin verificación puede publicar` | Excepción documentada de RN-1 |
| `admin sin sesión NO puede publicar` | Todo producto necesita `seller_id` (RN-5) |
| Suite `PublishValidation` (11) | Datos válidos del artículo antes de crearlo |

## Pendiente para el equipo

1. Ejecutar `Backend/12_publish_requires_verification.sql` en Supabase. Mientras
   no se ejecute, RN-1 solo se aplica en el cliente.
2. Decidir si el precio mínimo de un artículo debe ser mayor que cero.
3. La categoría del producto no tiene validador: se puede publicar con
   `category_id` nulo.
4. `verifyGateProvider` reporta un error de carga del perfil como
   `notSubmitted`; deniega correctamente, pero el mensaje al usuario es
   engañoso.

## Commit

Rama: `feat/publish-rules-tests`

- Refactor a `domain` + 26 pruebas:
  https://github.com/jaromerobr/Baratito/commit/8476eda
- Migración RLS y este registro:
  https://github.com/jaromerobr/Baratito/commits/feat/publish-rules-tests
