# Baratito — Contexto completo para landing page

> Entrega: un único `index.html` autocontenido.
> Sin frameworks. Sin npm. Sin imágenes externas. Solo HTML + CSS + JS vanilla + Google Fonts.

---

## Qué es Baratito

Marketplace de segunda mano exclusivo para **Loja, Ecuador**.
Los vecinos publican lo que ya no usan — ropa, electrónica, muebles, libros — y otros vecinos lo compran o hacen pujas en tiempo real.
Diferencial: verificación de identidad con cédula + selfie (DeepFace), pagos protegidos con OCR de comprobantes, chat en tiempo real con Supabase Realtime.
La app ya existe en Flutter + Supabase. Esta página la promociona. No hay backend aquí.

**Tagline:** _Segunda mano, primera opción._
**Audiencia:** jóvenes y familias de Loja, 16–35 años, usuarios de smartphone Android.
**Tono:** directo, local, cercano — como habla la gente de Loja, no como una startup de Silicon Valley.

---

## Sistema de color

```
--gold:         #FFC107   ← amarillo dorado, color primario de marca
--gold-light:   #FFD040   ← hover del gold
--green:        #1A5C36   ← verde oscuro, color secundario
--green-dark:   #0F3D24   ← verde más oscuro, fondos de sección
--green-mid:    #2E7D52   ← verde medio, acentos
--white:        #FFFFFF
--cream:        #FFFBF0   ← crema cálido, sección contraste
--text-on-gold: #1A5C36   ← texto sobre fondo gold
--text-on-green:#FFFFFF   ← texto sobre fondo verde
```

Nunca usar grises genéricos. Nunca negro puro. Todo debe respirar dentro de esta paleta.

---

## Tipografía

```
Font: 'Nunito' (Google Fonts)
Pesos: 700 · 800 · 900
```

```
Heading XL:  clamp(4rem, 9vw, 8rem) weight 900 — titulares de sección
Heading L:   clamp(2rem, 4vw, 3.5rem) weight 900 — subtítulos
Body:        0.95rem weight 700 — textos de apoyo
Small:       0.8rem weight 700 — labels, badges, pills
Mono:        'Courier New' — solo para fragmentos de código si aplica
```

Máximo 1 línea de texto de apoyo por sección. El espacio vacío es parte del diseño.

---

## Comportamiento global — slide por slide

```css
html {
  scroll-snap-type: y mandatory;
  overflow-y: scroll;
  scroll-behavior: smooth;
}
section {
  scroll-snap-align: start;
  height: 100vh;
  min-height: 100vh;
  overflow: hidden;
  position: relative;
}
```

Cada sección ocupa exactamente 100vh.
El usuario scrollea y la página snappea de sección en sección como slides.
No hay scroll intermedio visible. Cada sección es un mundo completo.

---

## Estructura de secciones

### Sección 1 · Hero
**Fondo:** `#FFC107`
**Layout:** dos columnas 50/50, centradas verticalmente

**Columna izquierda:**
```
h1  →  "Baratito"                    (Heading XL, color #1A5C36)
p   →  "Segunda mano, primera opción."   (1.3rem, weight 800, #1A5C36)
p   →  "Compra y vende entre gente real de Loja."  (0.95rem, #0F3D24, opacity 0.75)
a   →  "Consíguela pronto ↓"         (botón pill, bg #1A5C36, color #fff, href="#descarga")
```

**Columna derecha:**
Teléfono CSS 3D flotando (ver spec de teléfono abajo).
Cuatro badges flotantes alrededor del teléfono con animación independiente:
```
badge-1 (top-left):     "❤️ 24 guardados"          bg #fff, color #1A5C36
badge-2 (bottom-left):  "✅ Vendido en 2 horas"    bg #1A5C36, color #fff
badge-3 (top-right):    "💬 ¿Sigue disponible?"    bg #fff, color #1A5C36
badge-4 (bottom-right): "🛡️ Vendedor verificado"   bg #0F3D24, color #fff
```

**Indicador de scroll:** flecha animada abajo centrada, opacidad 0.5.

---

### Sección 2 · Quiénes somos
**Fondo:** `#1A5C36`
**Layout:** ticker arriba + dos columnas abajo

**Ticker (franja amarilla, altura 40px):**
Texto en loop infinito a la izquierda:
```
· COMPRA · VENDE · AHORRA · REPITE · COMPRA · VENDE · AHORRA · REPITE ·
```
Fondo `#FFC107`, texto `#1A5C36`, font-size 11px, weight 800, letter-spacing 0.05em.
Velocidad: 18s linear infinite. Contenido duplicado para loop sin corte.

**Columna izquierda (55%):**
```
h2  →  "Quiénes somos"              (Heading L, color #fff)
p   →  "Un marketplace hecho en Loja para darle segunda vida a las cosas."
        (una sola línea, color rgba(255,255,255,0.85), weight 700)
```
Cuatro pills con borde:
```
🛡️ Comunidad verificada
💬 Chat en tiempo real
🚚 Entregas coordinadas
🔒 Pagos protegidos
```
Pills: border 1.5px solid rgba(255,255,255,0.3), border-radius 100px, color #fff, padding 5px 12px, font-size 11px weight 700.

**Columna derecha (40%):**
Mockup de chat (ver spec de chat abajo).

---

### Sección 3 · Qué buscamos
**Fondo:** `#FFFBF0`
**Layout:** centrado verticalmente, contenido al centro

```
h2  →  "Qué buscamos"               (Heading L, color #1A5C36, text-align center)
p   →  "Más que un marketplace — un movimiento."
        (color #999, font-size 0.9rem, text-align center, margin-bottom 2.5rem)
```

**3 tarjetas en grid horizontal:**
```
Tarjeta 1:
  icon   ♻️ (font-size 2.5rem)
  h3     "Menos desperdicio"
  p      "Que las cosas circulen, no se acumulen."

Tarjeta 2:
  icon   🤝
  h3     "Confianza real"
  p      "Verificamos identidad. Protegemos cada pago."

Tarjeta 3:
  icon   🏙️
  h3     "Economía local"
  p      "El dinero se queda en Loja."
```

Tarjetas: bg #fff, border-radius 20px, padding 2rem 1.6rem, border 1.5px solid transparent.
En hover: border-color #FFC107, transform translateY(-8px), transition 0.3s ease.

---

### Sección 4 · Descarga
**Fondo:** `#0F3D24`
**Layout:** columna central, elementos apilados con flex-direction column

**Fondo animado:**
Dos orbes circulares grandes, `background: rgba(255,255,255,0.03)`, `border-radius: 50%`, `position: absolute`, animación de scale pulsante lenta.

**Headline:**
```
h2  →  "Ya está en"  [salto de línea]  "Loja."
        "Ya está en" color #fff
        "Loja." color #FFC107
        font-size: clamp(3rem, 8vw, 6rem), weight 900, line-height 1
p   →  "¿Y en tu bolsillo?"
        color rgba(255,255,255,0.6), font-size 1.1rem, weight 700
```

**Centro — teléfono + botones:**
Layout horizontal: botones a la izquierda, teléfono al centro.

Teléfono CSS 3D rotado al lado contrario del hero (rotateY positivo).
Cuatro tarjetas flotantes alrededor del teléfono:
```
fc-1 (top-left):     "📱 iPhone 13 Pro · $380"     bg #FFC107, color #1A5C36
fc-2 (bottom-left):  "✅ Vendido · San Cayetano"    bg rgba(255,255,255,0.1), color #fff, border glass
fc-3 (top-right):    "🎮 PS5 · $520 · Negociable"   bg rgba(255,255,255,0.1), color #fff, border glass
fc-4 (bottom-right): "🤝 Trato hecho"               bg #FFC107, color #1A5C36
```

**Botones de descarga (glassmorphism):**
```
Botón 1 — Google Play (DISPONIBLE):
  bg: #FFC107, color: #0F3D24, sin borde
  icon: ▶️
  label arriba: "Disponible en" (9px, opacity 0.7)
  label abajo: "Google Play" (14px, weight 900)

Botón 2 — App Store (PRÓXIMAMENTE):
  bg: rgba(255,255,255,0.08), border: 1.5px solid rgba(255,255,255,0.2), color: #fff
  icon: 🍎
  label arriba: "Próximamente en" (9px, opacity 0.7)
  label abajo: "App Store" (14px, weight 900)
```
Botones: border-radius 16px, padding 14px 20px, display flex, align-items center, gap 12px.
Hover: transform translateY(-3px), background más claro, transition 0.3s.

**Nota inferior:** `"Tu vecino ya la tiene · Loja, Ecuador · Gratis"` — color rgba(255,255,255,0.3), font-size 11px.

**Footer dentro de esta sección (absolute bottom):**
```
"© 2026 Baratito · Loja, Ecuador · Hecho con cariño para darle una segunda vida a tus cosas."
color rgba(255,255,255,0.3), font-size 10px, centrado
```

---

## Componente: Teléfono CSS 3D

```css
.phone {
  width: 220px;
  height: 450px;
  background: #0a0a0a;
  border-radius: 38px;
  border: 5px solid #1a1a1a;
  position: relative;
  overflow: hidden;
  box-shadow:
    -20px 30px 70px rgba(0,0,0,0.4),
    0 10px 30px rgba(0,0,0,0.2);
  transform: perspective(1000px) rotateY(-12deg) rotateX(4deg);
}

/* Dynamic island */
.phone::before {
  content: '';
  position: absolute;
  top: 10px; left: 50%;
  transform: translateX(-50%);
  width: 70px; height: 18px;
  background: #0a0a0a;
  border-radius: 100px;
  z-index: 20;
}

/* Wrapper con animación float */
.phone-wrap {
  animation: phoneBob 4s ease-in-out infinite;
}
@keyframes phoneBob {
  0%, 100% { transform: translateY(0); }
  50%       { transform: translateY(-18px); }
}
```

**Pantalla del teléfono (divs CSS simulando la app):**

```
Header verde (#1A5C36), padding-top extra para la dynamic island:
  - "¿Qué buscas hoy?"  (9px, opacity 0.75)
  - "¡Hola, Eduardo! 👋" (13px, weight 900)
  - Barra de búsqueda: bg rgba(255,255,255,0.15), "🔍 Buscar artículos..." (8px)

Chips de categoría (fondo blanco, padding 4px 6px):
  - "Todos" → activo: bg #1A5C36 color #fff
  - "Electrónica"
  - "Ropa"

Grid 2x2 de productos (gap 4px, padding 4px 6px):
  Producto 1: emoji 📱 · badge "Como nuevo" (#FFC107) · "iPhone 13 Pro" · "$380"
  Producto 2: emoji 🎮 · badge "Negociable" (#1A5C36) · "PlayStation 5" · "$520"
  Producto 3: emoji 🧥 · badge "Buen estado" (verde claro) · "Chaqueta M" · "$45"
  Producto 4: emoji 💡 · badge "Usado" (gris) · "Lámpara LED" · "$18.50"

Bottom nav (fondo #fff, border-top):
  ⌂  ♡  [botón + circular #1A5C36 con margen negativo arriba]  💬  👤
```

---

## Componente: Mockup de chat

```
Caja: bg rgba(255,255,255,0.08), border 1px solid rgba(255,255,255,0.15),
      border-radius 18px, padding 18px, misma animación phoneBob con delay 1s

Burbujas (cada una con animation-delay escalonado para que aparezcan en secuencia):
  delay 0s   → incoming: "¿Sigue disponible la bici? 🚴"
  delay 0.4s → outgoing: "¡Sí! Te la dejo en $45 🤝"
  delay 0.8s → incoming: "¡Perfecto! ¿Dónde nos vemos?"
  delay 1.2s → outgoing: "Parque La Argelia, hoy a las 5pm"
  delay 1.6s → sistema: "✅ Trato hecho · Pago protegido por Baratito"
  delay 2s   → sistema: "🚲 Vendida ✓"

incoming: bg rgba(255,255,255,0.15), color #fff, border-bottom-left-radius 3px
outgoing: bg #FFC107, color #1A5C36, margin-left auto, border-bottom-right-radius 3px, weight 800
sistema:  bg rgba(255,255,255,0.07), color rgba(255,255,255,0.6), text-align center, font-size 10px
```

---

## Animaciones — spec completo

```css
/* Teléfono flotando */
@keyframes phoneBob {
  0%, 100% { transform: translateY(0); }
  50%       { transform: translateY(-18px); }
}
/* duración 4s, delay diferente en hero vs descarga */

/* Badges flotantes — 4 variantes con rotate distinto */
@keyframes floatA { 0%,100%{transform:translateY(0) rotate(-3deg)} 50%{transform:translateY(-12px) rotate(-3deg)} }
@keyframes floatB { 0%,100%{transform:translateY(0) rotate(2deg)}  50%{transform:translateY(-16px) rotate(2deg)}  }
@keyframes floatC { 0%,100%{transform:translateY(0) rotate(-2deg)} 50%{transform:translateY(-10px) rotate(-2deg)} }
@keyframes floatD { 0%,100%{transform:translateY(0) rotate(3deg)}  50%{transform:translateY(-14px) rotate(3deg)}  }
/* Asignar delays: 0s · 0.5s · 1s · 1.5s */

/* Ticker horizontal */
@keyframes ticker {
  from { transform: translateX(0); }
  to   { transform: translateX(-50%); }
}
/* El contenido del ticker debe estar duplicado en el HTML para que el loop sea continuo */

/* Orbes de fondo en sección descarga */
@keyframes orbPulse {
  0%, 100% { transform: scale(1);    opacity: 0.5; }
  50%       { transform: scale(1.12); opacity: 1;   }
}
/* Orbe 1: 400px, top-right, 10s · Orbe 2: 300px, bottom-left, 12s delay 4s */

/* Entrada de secciones al hacer scroll */
/* Usar IntersectionObserver: cuando section entra en viewport, agregar clase .visible */
.section-content { opacity: 0; transform: translateY(30px); transition: opacity 0.7s ease, transform 0.7s ease; }
.section-content.visible { opacity: 1; transform: translateY(0); }

/* Burbujas del chat */
.chat-msg { opacity: 0; transform: translateY(10px); animation: bubbleIn 0.4s ease forwards; }
@keyframes bubbleIn {
  to { opacity: 1; transform: translateY(0); }
}
/* Cada burbuja con animation-delay escalonado: 0.3s · 0.7s · 1.1s · 1.5s · 1.9s · 2.3s */

/* Hover en tarjetas qué buscamos */
.que-card { transition: transform 0.3s ease, border-color 0.3s ease; }
.que-card:hover { transform: translateY(-8px); border-color: #FFC107; }

/* Botones de descarga */
.dl-btn { transition: transform 0.3s ease, background 0.3s ease; }
.dl-btn:hover { transform: translateY(-3px); }
```

---

## Nav

```
Fixed top, z-index 1000
Altura: 56px
Padding: 0 32px
Display: flex, align-items center, justify-content space-between
Transición de color según sección activa (IntersectionObserver)
```

**Estado sobre secciones gold/cream:**
```
background: rgba(255,193,7,0.95)
backdrop-filter: blur(10px)
Logo box: bg #1A5C36, icon color #FFC107
Logo text: #1A5C36
Links: color #1A5C36
Botón CTA: bg #1A5C36, color #fff
```

**Estado sobre secciones verdes:**
```
background: rgba(15,61,36,0.95)
backdrop-filter: blur(10px)
Logo box: bg #FFC107, icon color #1A5C36
Logo text: #fff
Links: color rgba(255,255,255,0.85)
Botón CTA: bg #FFC107, color #0F3D24
```

**Logo:**
```html
<div class="logo-box">B</div>
<span class="logo-text">BARATITO</span>
<!-- logo-box: 32px × 32px, border-radius 7px -->
```

**Links:**
- "Quiénes somos" → href #quienes
- "Qué buscamos"  → href #que-buscamos
- "Descargar"     → href #descarga, estilo pill

---

## Nav dots (puntos de navegación lateral)

```
position: fixed
right: 20px
top: 50%
transform: translateY(-50%)
z-index: 999
display: flex, flex-direction: column, gap: 8px
```

4 puntos. El punto activo: background #FFC107, scale 1.4.
Los inactivos: background rgba(255,255,255,0.35).
Clic en punto → scroll suave a la sección correspondiente.
El dot activo cambia con IntersectionObserver (threshold 0.6).

---

## JavaScript requerido

```javascript
// 1. Nav + dots: cambio de color según sección visible
const sections = document.querySelectorAll('section');
const nav = document.getElementById('main-nav');
const dots = document.querySelectorAll('.nav-dot');
const goldSections = ['hero', 'que-buscamos']; // fondos claros

const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting && entry.intersectionRatio > 0.6) {
      const id = entry.target.id;
      nav.className = goldSections.includes(id) ? 'nav-light' : 'nav-dark';
      dots.forEach(d => d.classList.toggle('active', d.dataset.section === id));
    }
  });
}, { threshold: 0.6 });
sections.forEach(s => observer.observe(s));

// 2. Entrada de contenido al scrollear
const contentObserver = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting) e.target.classList.add('visible');
  });
}, { threshold: 0.2 });
document.querySelectorAll('.section-content').forEach(el => contentObserver.observe(el));

// 3. Clic en nav dots
dots.forEach(dot => {
  dot.addEventListener('click', () => {
    document.getElementById(dot.dataset.section).scrollIntoView({ behavior: 'smooth' });
  });
});
```

---

## Reglas de diseño — lo que nunca se hace

- NO párrafos. Máximo una oración de apoyo por sección.
- NO grises neutros — todo dentro de la paleta de marca.
- NO sombras genéricas — solo las sombras definidas arriba.
- NO Navigator.push ni JS externo — todo vanilla.
- NO imágenes externas — todo CSS + emojis.
- NO scroll visible entre secciones — el snap lo maneja.
- NO más de 4 elementos flotantes por sección.
- NO texto sobre fondos si el contraste no pasa AA.
- El espacio vacío es parte del diseño — no hay que llenarlo todo.

---

## IDs de secciones (para href internos y JS)

```
#hero
#quienes
#que-buscamos
#descarga
```

---

## Entrega esperada

Un único archivo `index.html` que:
1. Abre sin servidor (doble clic en el archivo)
2. Funciona en Chrome / Firefox / Safari modernos
3. No carga nada de internet excepto Google Fonts
4. Pesa menos de 50kb
5. Se ve bien en viewport de 1280px de ancho mínimo