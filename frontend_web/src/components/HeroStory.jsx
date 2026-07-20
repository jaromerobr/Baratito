// HeroStory — la experiencia central de la landing.
//
// Concepto: el teléfono es el protagonista. La sección se FIJA (pin) durante
// ~6 pantallas de scroll y el usuario "explora la app" sin que el teléfono
// abandone su sitio: rota sutilmente (±12°, nunca más — premium, no feria),
// las pantallas se funden entre sí y las tarjetas glass de cada funcionalidad
// entran desde detrás del dispositivo.
//
// Decisiones de rendimiento:
// - Una sola timeline con scrub (el scroll ES la línea de tiempo): cero
//   listeners de scroll propios, GSAP+ScrollTrigger lo hacen en rAF.
// - Solo se animan transform y opacity (compositor de GPU, 60 FPS).
// - prefers-reduced-motion: la historia se desactiva y el contenido queda
//   legible en flujo normal (accesibilidad primero).
import { useLayoutEffect, useRef } from 'react';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import Phone from './phone/Phone.jsx';
import FloatCard from './FloatCard.jsx';

gsap.registerPlugin(ScrollTrigger);

/* Guion de la historia: una entrada por funcionalidad. */
const STEPS = [
  {
    kicker: 'Marketplace',
    title: 'Todo Loja en tu bolsillo',
    lead: 'Explora artículos de segunda mano cerca de ti, con fotos reales y precios honestos.',
    cards: [
      { icon: '❤️', text: '24 favoritos', pos: 'tl' },
      { icon: '📦', text: 'Vendido en 2 horas', pos: 'br' },
    ],
  },
  {
    kicker: 'Compra y venta',
    title: 'Vender es tomar una foto',
    lead: 'Publica en un minuto: fotos, precio y listo. Sin comisiones escondidas.',
    cards: [
      { icon: '📸', text: 'Hasta 6 fotos', pos: 'tr' },
      { icon: '⚡', text: 'Publicado en 1 min', pos: 'bl' },
    ],
  },
  {
    kicker: 'Chat integrado',
    title: 'Habla directo, cierra el trato',
    lead: 'Chat en tiempo real entre comprador y vendedor, dentro de la app.',
    cards: [
      { icon: '💬', text: 'Nuevo mensaje', pos: 'tl' },
      { icon: '🕐', text: 'Responde en minutos', pos: 'br' },
    ],
  },
  {
    kicker: 'Verificación de identidad',
    title: 'Gente real, verificada de verdad',
    lead: 'Cédula + reconocimiento facial: aquí nadie vende detrás de un perfil falso.',
    cards: [
      { icon: '✓', text: 'Identidad verificada', pos: 'tr' },
      { icon: '🪪', text: 'Cédula + rostro', pos: 'bl' },
    ],
  },
  {
    kicker: 'Pagos seguros',
    title: 'Tu dinero, protegido',
    lead: 'Pagas a Baratito, validamos tu comprobante al instante y el vendedor cobra al entregar.',
    cards: [
      { icon: '💳', text: 'Pago seguro', pos: 'tl' },
      { icon: '🏦', text: 'Banco de Loja', pos: 'br' },
    ],
  },
  {
    kicker: 'Perfil y reputación',
    title: 'Reputación que se gana',
    lead: 'Ventas, reseñas y verificación a la vista: confía antes de comprar.',
    cards: [
      { icon: '⭐', text: 'Vendedor 4.9', pos: 'tr' },
      { icon: '🏆', text: '32 ventas', pos: 'bl' },
    ],
  },
];

export default function HeroStory() {
  const rootRef = useRef(null);
  const phoneRef = useRef(null);
  const introRef = useRef(null);
  const screenRefs = useRef([]);
  const textRefs = useRef([]);
  const cardRefs = useRef(STEPS.map(() => []));

  useLayoutEffect(() => {
    const ctx = gsap.context(() => {
      const mm = gsap.matchMedia();

      mm.add('(prefers-reduced-motion: no-preference)', () => {
        const screens = screenRefs.current;
        const texts = textRefs.current;
        const cards = cardRefs.current;

        /* Estado inicial: solo la pantalla, el texto y las tarjetas del paso 0 */
        gsap.set(screens.slice(1), { autoAlpha: 0, y: 26 });
        gsap.set(texts.slice(1), { autoAlpha: 0, y: 46 });
        cards.slice(1).flat().forEach((c) => gsap.set(c, { autoAlpha: 0, scale: 0.55 }));

        /* ── 1. Entrada (al cargar): elegante, nada brusco ── */
        const intro = gsap.timeline({ defaults: { ease: 'power3.out' } });
        intro
          .from(phoneRef.current, {
            y: 150, scale: 0.8, rotateY: -20, autoAlpha: 0, duration: 1.15,
          })
          .to(phoneRef.current, { rotateY: -9, duration: 0.5, ease: 'power2.inOut' }, '-=0.25')
          .from('.intro-line', { y: 44, autoAlpha: 0, stagger: 0.09, duration: 0.7 }, '-=0.9')
          .from(texts[0], { y: 40, autoAlpha: 0, duration: 0.6 }, '-=0.4')
          .from(cards[0], {
            // las tarjetas nacen DETRÁS del teléfono y se despliegan
            x: 0, y: 0, xPercent: 0, scale: 0.4, autoAlpha: 0,
            transformOrigin: 'center', stagger: 0.14, duration: 0.75, ease: 'back.out(1.6)',
          }, '-=0.35');

        /* ── 2. La historia de scroll (sección fijada) ── */
        const story = gsap.timeline({
          defaults: { ease: 'none' },
          scrollTrigger: {
            trigger: rootRef.current,
            start: 'top top',
            end: `+=${STEPS.length * 90}%`, // ~90vh de scroll por funcionalidad
            scrub: 0.9,                      // inercia suave, sensación líquida
            pin: true,
            anticipatePin: 1,
          },
        });

        // El titular de bienvenida cede el escenario al primer avance
        story.to(introRef.current, { autoAlpha: 0, y: -60, duration: 0.5 }, 0);

        STEPS.forEach((_, i) => {
          if (i === 0) return;
          const at = i; // 1 unidad de timeline por paso
          const dir = i % 2 ? 1 : -1;

          story
            // el teléfono gira apenas (±9–12°) y respira en Y
            .to(phoneRef.current, {
              rotateY: dir * (9 + (i % 3) * 1.5),
              rotateZ: dir * 1.2,
              duration: 0.9,
            }, at)
            // pantalla saliente / entrante (crossfade con leve deriva)
            .to(screens[i - 1], { autoAlpha: 0, y: -26, duration: 0.35 }, at)
            .to(screens[i], { autoAlpha: 1, y: 0, duration: 0.4 }, at + 0.15)
            // texto lateral
            .to(texts[i - 1], { autoAlpha: 0, y: -46, duration: 0.3 }, at)
            .to(texts[i], { autoAlpha: 1, y: 0, duration: 0.4 }, at + 0.18)
            // tarjetas: las viejas se disuelven, las nuevas brotan del teléfono
            .to(cards[i - 1], { autoAlpha: 0, scale: 0.55, duration: 0.25, stagger: 0.05 }, at)
            .to(cards[i], { autoAlpha: 1, scale: 1, duration: 0.35, stagger: 0.1 }, at + 0.2);
        });

        // Pequeña pausa final para que el último paso respire antes de soltar el pin
        story.to({}, { duration: 0.6 });
      });

      /* Accesibilidad: sin animaciones → todo visible y en flujo */
      mm.add('(prefers-reduced-motion: reduce)', () => {
        gsap.set([phoneRef.current, ...textRefs.current.slice(0, 1)], { clearProps: 'all' });
      });
    }, rootRef);

    return () => ctx.revert();
  }, []);

  return (
    <header className="story" id="inicio" ref={rootRef}>
      <div className="story-viewport">
        {/* Titular de bienvenida (solo fase de carga) */}
        <div className="intro" ref={introRef}>
          <h1>
            <span className="intro-line">Baratito.</span>
          </h1>
          <p className="intro-line intro-tagline">
            Segunda mano, <strong>primera opción</strong>.
          </p>
          <p className="intro-line intro-hint">Desliza para explorar la app ↓</p>
        </div>

        {/* Textos de cada funcionalidad (apilados, GSAP los intercambia) */}
        <div className="story-texts">
          {STEPS.map((s, i) => (
            <div
              key={s.kicker}
              className="story-text"
              ref={(el) => { textRefs.current[i] = el; }}
            >
              <span className="story-kicker">{s.kicker}</span>
              <h2>{s.title}</h2>
              <p>{s.lead}</p>
            </div>
          ))}
        </div>

        {/* El protagonista */}
        <div className="story-phone">
          <Phone ref={phoneRef} screenRefs={screenRefs} />
          {STEPS.map((s, i) =>
            s.cards.map((c, j) => (
              <FloatCard
                key={`${i}-${j}`}
                icon={c.icon}
                text={c.text}
                pos={c.pos}
                drift={(i + j) * 0.7}
                refFn={(el) => { cardRefs.current[i][j] = el; }}
              />
            )),
          )}
        </div>

        {/* Progreso sutil de la historia */}
        <div className="story-progress" aria-hidden="true">
          {STEPS.map((s, i) => <i key={i} />)}
        </div>
      </div>
    </header>
  );
}
