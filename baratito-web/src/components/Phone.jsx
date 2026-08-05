import shot from '../../logo/capturaproductos.jpg'
import './Phone.css'

/**
 * Captura real de la app dentro de un marco CSS. El marco respeta
 * la proporcion exacta del archivo (738x1400) para que la pantalla
 * no se recorte por ningun lado.
 */
export default function Phone({ tilt = -12 }) {
  return (
    <div className="phone" style={{ '--tilt': `${tilt}deg` }}>
      {/* Sin muesca: la captura empieza en el header verde de la
          propia app, y una isla encima le tapaba el logo. */}
      <div className="phone-body">
        <div className="phone-screen">
          <img
            className="phone-shot"
            src={shot}
            alt="Pantalla de inicio de Baratito: publicaciones recientes de vecinos de Loja, con perfume, hoodie, laptop y zapatos deportivos."
            loading="eager"
            decoding="async"
          />
          <span className="phone-glare" aria-hidden="true" />
        </div>
      </div>
    </div>
  )
}
