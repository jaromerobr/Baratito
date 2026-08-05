import KycScene from '../components/KycScene'
import Ticker from '../components/Ticker'
import { PROMESAS } from '../data/content'
import './Quienes.css'

export default function Quienes() {
  return (
    <div className="slide-inner quienes">
      <Ticker />

      <div className="measure quienes-grid">
        <div className="quienes-left">
          <p className="rise mono quienes-eyebrow">Quiénes somos</p>

          <h2 className="rise quienes-title">
            Aquí nadie le compra a un desconocido.
          </h2>

          <p className="rise quienes-lede">
            Cada vendedor pasa por <em className="mark">verificación de identidad</em>{' '}
            —cédula y selfie— antes de poder publicar su primer artículo.
          </p>

          <ul className="rise promesas">
            {PROMESAS.map((p) => (
              <li key={p.k} className="promesa">
                <span className="promesa-k mono">{p.k}</span>
                <span className="promesa-t">{p.t}</span>
                <span className="promesa-d">{p.d}</span>
              </li>
            ))}
          </ul>
        </div>

        <div className="quienes-right rise">
          <KycScene />
        </div>
      </div>
    </div>
  )
}
