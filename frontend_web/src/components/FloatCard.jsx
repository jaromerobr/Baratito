// Tarjeta flotante glassmorphism (estilo Apple).
//
// Decisiones:
// - backdrop-filter + borde translúcido = vidrio real, no simulado.
// - La deriva ("drift") es una animación CSS infinita con delay aleatorio
//   por tarjeta: GSAP controla CUÁNDO aparecen, el CSS las mantiene vivas
//   sin ocupar el hilo principal.
export default function FloatCard({ icon, text, pos, drift = 0, refFn }) {
  return (
    <div
      ref={refFn}
      className={`fcard fcard-${pos}`}
      style={{ animationDelay: `${drift}s` }}
    >
      <span className="fcard-icon">{icon}</span>
      <span>{text}</span>
    </div>
  );
}
