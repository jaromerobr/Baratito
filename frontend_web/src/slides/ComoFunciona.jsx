import Floaters from '../components/Floaters'
import { PASOS, ESTADOS } from '../data/content'
import './ComoFunciona.css'

export default function ComoFunciona() {
  return (
    <div className="slide-inner cf">
      <div className="cf-ring cf-ring-a" aria-hidden="true" />
      <div className="cf-ring cf-ring-b" aria-hidden="true" />

      <div className="cf-orbit" aria-hidden="true">
        <Floaters items={ESTADOS} />
      </div>

      <div className="measure">
        <div className="cf-head">
          <p className="rise mono cf-eyebrow">Cómo funciona</p>
          <h2 className="rise cf-title">
            Tu plata no se mueve hasta que el pedido llegue.
          </h2>
        </div>

        <ol className="rise cf-steps">
          {PASOS.map((p) => (
            <li key={p.n} className="cf-step">
              <span className="cf-node" aria-hidden="true">
                <span className="cf-icon">{p.icon}</span>
              </span>
              <span className="cf-num mono">{p.n}</span>
              <h3 className="cf-step-title">{p.t}</h3>
              <p className="cf-step-body">{p.d}</p>
            </li>
          ))}
        </ol>

        <p className="rise cf-foot mono">
          Publicar es gratis · Al vender se aplica una comisión · ¿Algo salió
          distinto? Lo revisamos contigo
        </p>
      </div>
    </div>
  )
}
