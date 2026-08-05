import logoSrc from '../../logo/logobaratito.jpg'
import './Logo.css'

export default function Logo({ size = 44 }) {
  return (
    <img
      className="logo-tile"
      src={logoSrc}
      alt="Baratito"
      style={{ '--logo-size': `${size}px` }}
    />
  )
}
