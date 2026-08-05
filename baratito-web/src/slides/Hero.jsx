import Phone from '../components/Phone'
import Floaters from '../components/Floaters'
import Logo from '../components/Logo'
import { FLOATERS } from '../data/content'
import './Hero.css'

export default function Hero({ onGo }) {
  return (
    <div className="slide-inner hero">
      <div className="hero-glow" aria-hidden="true" />

      <div className="measure hero-grid">
        <div className="hero-left">
          <div className="rise hero-lockup">
            <Logo size={66} />
            <span className="hero-lockup-line" aria-hidden="true" />
            <span className="mono hero-lockup-tag">Loja · Ecuador</span>
          </div>

          <h1 className="rise hero-title">
            Segunda mano,
            <br />
            <em className="mark">primera</em> opción.
          </h1>

          <p className="rise hero-lede">
            Lo que tu vecino ya no usa, a un precio que sí te cuadra.{' '}
            <em className="mark">Sin comisión</em> por publicar.
          </p>

          <div className="rise hero-actions bloom">
            <button type="button" className="btn-solid" onClick={() => onGo(3)}>
              Descargar la app
            </button>
            <button type="button" className="btn-ghost" onClick={() => onGo(2)}>
              Cómo funciona
            </button>
          </div>
        </div>

        <div className="hero-right">
          <div className="hero-phone">
            <Phone tilt={-13} />
            <Floaters items={FLOATERS} />
          </div>
        </div>
      </div>

      <div className="scroll-cue">
        <span className="mono">Desliza para pasar de página</span>
        <span className="scroll-cue-line" />
      </div>
    </div>
  )
}
