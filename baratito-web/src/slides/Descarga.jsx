import Chat from '../components/Chat'
import Floaters from '../components/Floaters'
import Logo from '../components/Logo'
import { DEALS } from '../data/content'
import './Descarga.css'

export default function Descarga({ active }) {
  return (
    <div className="slide-inner dl">
      <div className="dl-orb dl-orb-a" aria-hidden="true" />
      <div className="dl-orb dl-orb-b" aria-hidden="true" />

      <div className="measure dl-grid">
        <div className="dl-left">
          <div className="rise dl-badge">
            <Logo size={72} />
            <span className="dl-badge-words">
              <strong>Baratito</strong>
              <span className="mono">Android · 18 MB · Gratis</span>
            </span>
          </div>

          <h2 className="rise dl-title">
            Ya está en Loja.
            <br />
            <em className="mark">¿Y en tu bolsillo?</em>
          </h2>

          <div className="rise dl-buttons bloom">
            <a href="#" className="store store-live">
              <span className="store-ic" aria-hidden="true">
                ▶
              </span>
              <span className="store-labels">
                <span className="store-top mono">Disponible en</span>
                <span className="store-name">Google Play</span>
              </span>
            </a>

            <a href="#" className="store store-soon" aria-disabled="true">
              <span className="store-ic" aria-hidden="true">

              </span>
              <span className="store-labels">
                <span className="store-top mono">Próximamente en</span>
                <span className="store-name">App Store</span>
              </span>
            </a>
          </div>
        </div>

        <div className="dl-right">
          <div className="dl-chat">
            <Chat active={active} />
            <Floaters items={DEALS} />
          </div>
        </div>
      </div>

      <footer className="dl-footer mono">
        © 2026 Baratito · Loja, Ecuador · Para darle una segunda vida a tus cosas
      </footer>
    </div>
  )
}
