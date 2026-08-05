export default function Rail({ slides, active, onGo }) {
  return (
    <nav className="rail" aria-label="Secciones">
      {slides.map((slide, i) => (
        <button
          key={slide.id}
          type="button"
          className="rail-item"
          aria-current={i === active}
          aria-label={slide.label}
          onClick={() => onGo(i)}
        >
          <span className="rail-num">{String(i + 1).padStart(2, '0')}</span>
          <span className="rail-tick" />
        </button>
      ))}
    </nav>
  )
}
