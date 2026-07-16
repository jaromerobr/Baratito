// Landing page de Baratito — estilo bereal.com con animaciones:
// teléfono con la app dibujado en CSS, chips flotantes, cinta deslizante,
// y secciones que se revelan al hacer scroll (IntersectionObserver).
import { useEffect, useRef, useState } from 'react';

/* ═══ Hook: revela el elemento cuando entra al viewport ═══ */
function useReveal(threshold = 0.2) {
  const ref = useRef(null);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const obs = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setVisible(true);
          obs.disconnect();
        }
      },
      { threshold },
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, [threshold]);

  return [ref, visible];
}

/* Envoltorio animado: from = 'up' | 'left' | 'right' | 'zoom' */
function Reveal({ children, from = 'up', delay = 0, className = '' }) {
  const [ref, visible] = useReveal();
  return (
    <div
      ref={ref}
      className={`reveal reveal-${from} ${visible ? 'is-visible' : ''} ${className}`}
      style={{ transitionDelay: `${delay}ms` }}
    >
      {children}
    </div>
  );
}

/* ═══ Teléfono con la app de Baratito (100% CSS, sin imágenes) ═══ */
function PhoneMock({ className = '' }) {
  const products = [
    { emoji: '📱', name: 'iPhone 13 Pro', price: '$380', tag: 'Como nuevo' },
    { emoji: '🎮', name: 'PlayStation 5', price: '$520', tag: 'Negociable' },
    { emoji: '🧥', name: 'Chaqueta M', price: '$45', tag: 'Buen estado' },
    { emoji: '💡', name: 'Lámpara LED', price: '$18.50', tag: 'Usado' },
  ];

  return (
    <div className={`phone ${className}`}>
      <div className="phone-notch" />
      <div className="phone-screen">
        <div className="app-header">
          <div className="app-brand">
            <img src="/logo.png" alt="" />
            <b>BARATITO</b>
          </div>
          <p className="app-hola">¡Hola, Eduardo!</p>
          <p className="app-sub">¿Qué buscas hoy?</p>
          <div className="app-search">🔍 Buscar artículos…</div>
        </div>
        <div className="app-chips">
          <span className="on">Todos</span>
          <span>Electrónica</span>
          <span>Ropa</span>
        </div>
        <div className="app-grid">
          {products.map((p) => (
            <div className="app-card" key={p.name}>
              <div className="app-card-img">
                <i>{p.emoji}</i>
                <em>{p.tag}</em>
              </div>
              <b>{p.name}</b>
              <span>{p.price}</span>
            </div>
          ))}
        </div>
        <div className="app-nav">
          <span className="on">⌂</span>
          <span>♡</span>
          <span className="app-fab">+</span>
          <span>💬</span>
          <span>👤</span>
        </div>
      </div>
    </div>
  );
}

/* Chips que flotan alrededor del teléfono */
function FloatingChips() {
  return (
    <>
      <div className="chip chip-1">❤️ 24 guardados</div>
      <div className="chip chip-2">💬 "¿Sigue disponible?"</div>
      <div className="chip chip-3">✅ Vendido en 2 horas</div>
      <div className="chip chip-4">🪪 Vendedor verificado</div>
    </>
  );
}

/* Cinta deslizante estilo BeReal */
function Marquee() {
  const words = 'COMPRA · VENDE · AHORRA · REPITE · ';
  return (
    <div className="marquee" aria-hidden="true">
      <div className="marquee-track">
        <span>{words.repeat(4)}</span>
        <span>{words.repeat(4)}</span>
      </div>
    </div>
  );
}

const APPLE_ICON = (
  <svg viewBox="0 0 384 512" width="26" height="26" fill="currentColor" aria-hidden="true">
    <path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5q0 39.3 14.4 81.2c12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-61.9 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z" />
  </svg>
);

const PLAY_ICON = (
  <svg viewBox="0 0 512 512" width="24" height="24" fill="currentColor" aria-hidden="true">
    <path d="M325.3 234.3 104.6 13l280.8 161.2-60.1 60.1zM47 0C34 6.8 25.3 19.2 25.3 35.3v441.3c0 16.1 8.7 28.5 21.7 35.3l256.6-256L47 0zm425.2 225.6-58.9-34.1-65.7 64.5 65.7 64.5 60.1-34.1c18-14.3 18-46.5-1.2-60.8zM104.6 499l280.8-161.2-60.1-60.1L104.6 499z" />
  </svg>
);

function Nav() {
  return (
    <nav className="nav">
      <a className="nav-brand" href="#inicio">
        <img src="/logo.png" alt="Logo de Baratito" />
        <span>BARATITO</span>
      </a>
      <div className="nav-links">
        <a href="#quienes-somos">Quiénes somos</a>
        <a href="#que-buscamos">Qué buscamos</a>
        <a href="#descargar" className="nav-cta">Descargar</a>
      </div>
    </nav>
  );
}

function Hero() {
  // Parallax sutil: el teléfono rota y se desplaza con el scroll.
  const phoneRef = useRef(null);
  useEffect(() => {
    let raf = 0;
    const onScroll = () => {
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => {
        const y = window.scrollY;
        if (phoneRef.current) {
          phoneRef.current.style.transform =
            `translateY(${y * 0.08}px) rotate(${-6 + y * 0.012}deg)`;
        }
      });
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => {
      window.removeEventListener('scroll', onScroll);
      cancelAnimationFrame(raf);
    };
  }, []);

  return (
    <header className="hero" id="inicio">
      <div className="hero-text">
        <h1>Baratito</h1>
        <p className="hero-tagline">
          Segunda mano, <strong>primera opción</strong>.
        </p>
        <p className="hero-sub">
          Compra y vende lo que ya no usas, entre gente real de Loja.
        </p>
        <a className="hero-btn" href="#descargar">Consíguela pronto ↓</a>
      </div>
      <div className="hero-phone" ref={phoneRef}>
        <PhoneMock />
        <FloatingChips />
      </div>
      <a className="hero-arrow" href="#quienes-somos" aria-label="Bajar">↓</a>
    </header>
  );
}

function QuienesSomos() {
  const mensajes = [
    { own: false, text: '¿Sigue disponible la bici? 🚲' },
    { own: true, text: '¡Sí! Te la dejo en $45' },
    { own: false, text: '¡Trato hecho! 🤝' },
    { own: true, text: 'Vendida ✓', sold: true },
  ];

  return (
    <section className="section section-green" id="quienes-somos">
      <div className="split">
        <div className="split-text">
          <Reveal from="left">
            <h2>Quiénes somos</h2>
          </Reveal>
          <Reveal from="left" delay={120}>
            <p className="section-lead">
              Somos <strong>Baratito</strong>, un marketplace hecho en Loja para
              darle una segunda vida a las cosas.
            </p>
          </Reveal>
          <Reveal from="left" delay={240}>
            <p>
              Lo que tú ya no usas puede ser justo lo que otra persona busca.
              Vender es tan fácil como tomar una foto, y comprar es seguro: cada
              vendedor verifica su identidad con su cédula y su rostro, los pagos
              pasan por Baratito y nosotros hacemos que tu pedido llegue.
            </p>
          </Reveal>
          <Reveal from="up" delay={360}>
            <div className="pills">
              <span>🪪 Comunidad verificada</span>
              <span>💬 Chat en tiempo real</span>
              <span>🛵 Entregas coordinadas</span>
              <span>💳 Pagos protegidos</span>
            </div>
          </Reveal>
        </div>
        <div className="split-visual">
          <div className="chat-demo">
            {mensajes.map((m, i) => (
              <Reveal key={i} from={m.own ? 'right' : 'left'} delay={200 + i * 250}>
                <div className={`bubble ${m.own ? 'own' : ''} ${m.sold ? 'sold' : ''}`}>
                  {m.text}
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

function QueBuscamos() {
  const goals = [
    {
      icon: '♻️',
      title: 'Menos desperdicio',
      text: 'Que las cosas circulen en vez de acumularse. Cada compra de segunda mano es un objeto que no termina en la basura.',
    },
    {
      icon: '🤝',
      title: 'Confianza real',
      text: 'Comprar a desconocidos no debería dar miedo. Verificamos la identidad de quienes venden y protegemos cada pago hasta que recibes tu pedido.',
    },
    {
      icon: '🏙️',
      title: 'Economía local',
      text: 'El dinero se queda en Loja. Conectamos a vecinos, estudiantes y familias para que comprar barato y vender rápido sea cosa de todos los días.',
    },
  ];

  return (
    <section className="section section-cream" id="que-buscamos">
      <Reveal from="up">
        <h2>Qué buscamos</h2>
      </Reveal>
      <div className="goals">
        {goals.map((g, i) => (
          <Reveal key={g.title} from="up" delay={i * 180}>
            <article>
              <div className="goal-icon">{g.icon}</div>
              <h3>{g.title}</h3>
              <p>{g.text}</p>
            </article>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

function Descargar() {
  return (
    <section className="section section-dark" id="descargar">
      <div className="split">
        <div className="split-visual">
          <Reveal from="zoom">
            <PhoneMock className="phone-tilt" />
          </Reveal>
        </div>
        <div className="split-text">
          <Reveal from="right">
            <h2>Llévala en tu bolsillo</h2>
          </Reveal>
          <Reveal from="right" delay={140}>
            <p className="section-lead">Muy pronto en tu tienda de aplicaciones.</p>
          </Reveal>
          <div className="stores">
            <Reveal from="up" delay={280}>
              <div className="store-card">
                <div className="store-btn" role="img" aria-label="App Store — próximamente">
                  {APPLE_ICON}
                  <span>
                    <small>Próximamente en</small>
                    App Store
                  </span>
                </div>
                <p>iPhone y iPad</p>
              </div>
            </Reveal>
            <Reveal from="up" delay={420}>
              <div className="store-card">
                <div className="store-btn" role="img" aria-label="Google Play — próximamente">
                  {PLAY_ICON}
                  <span>
                    <small>Próximamente en</small>
                    Google Play
                  </span>
                </div>
                <p>Teléfonos y tablets Android</p>
              </div>
            </Reveal>
          </div>
        </div>
      </div>
    </section>
  );
}

function Footer() {
  return (
    <footer className="footer">
      <img src="/logo.png" alt="" />
      <p>Baratito · Loja, Ecuador</p>
      <p className="footer-small">
        © {new Date().getFullYear()} Baratito. Hecho con cariño para darle una
        segunda vida a tus cosas.
      </p>
    </footer>
  );
}

export default function App() {
  return (
    <>
      <Nav />
      <Hero />
      <Marquee />
      <QuienesSomos />
      <QueBuscamos />
      <Descargar />
      <Footer />
    </>
  );
}
