import './ModeToggle.css'

/**
 * Interruptor de modo, igual que un claro/oscuro pero entre los
 * dos colores de la marca: verde y amarillo.
 */
export default function ModeToggle({ value, onChange }) {
  const isVerde = value === 'verde'

  return (
    <button
      type="button"
      className="mode-toggle"
      role="switch"
      aria-checked={!isVerde}
      aria-label={
        isVerde ? 'Cambiar a modo amarillo' : 'Cambiar a modo verde'
      }
      title={isVerde ? 'Modo verde' : 'Modo amarillo'}
      onClick={() => onChange(isVerde ? 'amarillo' : 'verde')}
    >
      <span className="mode-track">
        <span className="mode-knob" aria-hidden="true" />
      </span>
      <span className="mode-label mono">{isVerde ? 'Verde' : 'Amarillo'}</span>
    </button>
  )
}
