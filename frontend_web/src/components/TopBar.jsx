import Logo from './Logo'
import ModeToggle from './ModeToggle'

export default function TopBar({ onGo, palette, onPalette }) {
  return (
    <header className="topbar">
      <button type="button" className="brand" onClick={() => onGo(0)}>
        <Logo size={42} />
        <span className="brand-mark">Baratito</span>
      </button>

      <div className="topbar-right">
        <ModeToggle value={palette} onChange={onPalette} />
        <button type="button" className="topbar-cta" onClick={() => onGo(3)}>
          Descargar
          <span aria-hidden="true">→</span>
        </button>
      </div>
    </header>
  )
}
