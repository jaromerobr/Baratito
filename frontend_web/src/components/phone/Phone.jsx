// Teléfono premium dibujado en CSS.
//
// Decisiones de diseño:
// - Las 6 pantallas viven APILADAS dentro del marco (position:absolute) y la
//   timeline de GSAP solo anima opacity/transform: nunca se desmonta ni se
//   re-renderiza nada durante el scroll → 60 FPS garantizados.
// - El marco usa capas de sombra + un borde con brillo ("edge light") y un
//   reflejo diagonal para el efecto de vidrio, todo sin imágenes.
import { forwardRef } from 'react';

/* ── Pantalla 1 · Marketplace ── */
function ScreenHome() {
  const products = [
    { emoji: '📱', name: 'iPhone 13 Pro', price: '$380', tag: 'Como nuevo' },
    { emoji: '🎮', name: 'PlayStation 5', price: '$520', tag: 'Negociable' },
    { emoji: '🧥', name: 'Chaqueta M', price: '$45', tag: 'Buen estado' },
    { emoji: '💡', name: 'Lámpara LED', price: '$18.50', tag: 'Usado' },
  ];
  return (
    <div className="scr">
      <div className="app-header">
        <div className="app-brand"><img src="/logo.png" alt="" /><b>BARATITO</b></div>
        <p className="app-hola">¡Hola, Eduardo!</p>
        <p className="app-sub">¿Qué buscas hoy?</p>
        <div className="app-search">🔍 Buscar artículos…</div>
      </div>
      <div className="app-chips">
        <span className="on">Todos</span><span>Electrónica</span><span>Ropa</span>
      </div>
      <div className="app-grid">
        {products.map((p) => (
          <div className="app-card" key={p.name}>
            <div className="app-card-img"><i>{p.emoji}</i><em>{p.tag}</em></div>
            <b>{p.name}</b><span>{p.price}</span>
          </div>
        ))}
      </div>
      <AppNav active={0} />
    </div>
  );
}

/* ── Pantalla 2 · Publicar producto ── */
function ScreenPublish() {
  return (
    <div className="scr">
      <div className="scr-bar">Publicar artículo</div>
      <div className="scr-body">
        <div className="pub-photos">
          <span className="pub-add">＋</span>
          <span>📷</span><span>📷</span>
        </div>
        <div className="pub-field"><small>Título</small>Bicicleta montañera aro 26</div>
        <div className="pub-row">
          <div className="pub-field"><small>Precio</small>$45.00</div>
          <div className="pub-field"><small>Estado</small>Buen estado</div>
        </div>
        <div className="pub-field"><small>Categoría</small>Deportes</div>
        <div className="scr-btn">Publicar artículo</div>
      </div>
      <AppNav active={-1} />
    </div>
  );
}

/* ── Pantalla 3 · Chat ── */
function ScreenChat() {
  return (
    <div className="scr">
      <div className="scr-bar">james romero <em>· sobre "Bicicleta"</em></div>
      <div className="scr-body chat-body">
        <div className="mini-bubble">¿Sigue disponible la bici? 🚲</div>
        <div className="mini-bubble own">¡Sí! Te la dejo en $45</div>
        <div className="mini-bubble">¡Trato hecho! 🤝</div>
        <div className="mini-bubble own">Perfecto, la aparto ✓</div>
      </div>
      <div className="chat-input">Escribe un mensaje… <b>➤</b></div>
      <AppNav active={3} />
    </div>
  );
}

/* ── Pantalla 4 · Verificación de identidad ── */
function ScreenVerify() {
  return (
    <div className="scr scr-dark">
      <div className="scr-bar bar-dark">Verificación</div>
      <div className="verify-cam">
        <div className="verify-oval" />
        <p>Ubica tu rostro dentro del óvalo</p>
      </div>
      <div className="verify-status">
        <span className="ok">✓</span> Identidad verificada
      </div>
    </div>
  );
}

/* ── Pantalla 5 · Pago seguro ── */
function ScreenPay() {
  return (
    <div className="scr">
      <div className="scr-bar">Pagar pedido</div>
      <div className="scr-body">
        <div className="pay-total"><small>Total a pagar</small>$47.00<em>Productos $45 · Envío $2</em></div>
        <div className="pay-qr" aria-hidden="true">
          {Array.from({ length: 25 }).map((_, i) => <b key={i} data-on={(i * 7) % 3 === 0 ? '' : undefined} />)}
        </div>
        <p className="pay-hint">Escanea con tu app del Banco de Loja</p>
        <div className="scr-btn">Subir comprobante</div>
      </div>
    </div>
  );
}

/* ── Pantalla 6 · Perfil y reputación ── */
function ScreenProfile() {
  return (
    <div className="scr">
      <div className="scr-bar">Mi perfil</div>
      <div className="scr-body profile-body">
        <div className="profile-avatar">E</div>
        <b className="profile-name">Eduardo D. <i>✓</i></b>
        <span className="profile-stars">★★★★★ <em>4.9</em></span>
        <div className="profile-stats">
          <div><b>32</b><small>ventas</small></div>
          <div><b>27</b><small>reseñas</small></div>
          <div><b>98%</b><small>respuesta</small></div>
        </div>
        <div className="profile-badge">🪪 Identidad verificada</div>
      </div>
      <AppNav active={4} />
    </div>
  );
}

function AppNav({ active }) {
  const items = ['⌂', '♡', '+', '💬', '👤'];
  return (
    <div className="app-nav">
      {items.map((it, i) =>
        i === 2
          ? <span key={i} className="app-fab">+</span>
          : <span key={i} className={i === active ? 'on' : ''}>{it}</span>,
      )}
    </div>
  );
}

export const SCREENS = [
  { id: 'home', el: <ScreenHome /> },
  { id: 'publish', el: <ScreenPublish /> },
  { id: 'chat', el: <ScreenChat /> },
  { id: 'verify', el: <ScreenVerify /> },
  { id: 'pay', el: <ScreenPay /> },
  { id: 'profile', el: <ScreenProfile /> },
];

/* ── Marco del teléfono ──
   forwardRef: GSAP necesita el nodo para rotarlo en 3D desde HeroStory. */
const Phone = forwardRef(function Phone({ screenRefs }, ref) {
  return (
    <div className="phone-stage">
      <div className="phone" ref={ref}>
        <div className="phone-notch" />
        <div className="phone-glare" aria-hidden="true" />
        <div className="phone-screen">
          {SCREENS.map((s, i) => (
            <div
              key={s.id}
              className="phone-layer"
              ref={(el) => { if (screenRefs) screenRefs.current[i] = el; }}
            >
              {s.el}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
});

export default Phone;
