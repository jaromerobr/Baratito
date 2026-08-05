import './Ticker.css'

const WORDS = ['Compra', 'Vende', 'Ahorra', 'Repite']

/* Un "set" con las palabras repetidas lo suficiente para cubrir
   pantallas anchas. Luego el set se pinta DOS veces: la animacion
   desplaza exactamente -50%, o sea un set completo, y en ese punto
   el segundo ocupa el lugar del primero. Por eso el bucle no salta. */
const SET = Array.from({ length: 3 }, () => WORDS).flat()

function Track({ ghost }) {
  return (
    <div className={ghost ? 'ticker-track ticker-ghost' : 'ticker-track'}>
      {[0, 1].map((copy) => (
        <span
          className="ticker-set"
          key={copy}
          aria-hidden={copy === 1 || ghost || undefined}
        >
          {SET.map((word, i) => (
            <span className="ticker-item" key={`${word}-${i}`}>
              {word}
              <i className="ticker-dot" aria-hidden="true">
                •
              </i>
            </span>
          ))}
        </span>
      ))}
    </div>
  )
}

export default function Ticker() {
  return (
    <div className="ticker">
      {/* Capa de fondo: mismas palabras, mas grandes, desenfocadas y
          mas lentas. El desfase entre las dos capas es lo que da
          sensacion de profundidad y de movimiento continuo. */}
      <Track ghost />
      <Track />
    </div>
  )
}
