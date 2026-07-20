// Navbar minimalista: logo + 3 accesos. Fija, con vidrio sutil.
export default function Nav() {
  return (
    <nav className="nav">
      <a className="nav-brand" href="#inicio">
        <img src="/logo.png" alt="Logo de Baratito" />
        <span>BARATITO</span>
      </a>
      <div className="nav-links">
        <a href="#quienes-somos">Quiénes somos</a>
        <a href="#que-buscamos">Qué buscamos</a>
        <a href="#descargar" className="nav-cta">Descargar</a>
      </div>
    </nav>
  );
}
