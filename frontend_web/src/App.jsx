// Landing de Baratito — composición de la página.
//
// La experiencia:
//   1. HeroStory: el teléfono protagonista, fijado durante 6 funcionalidades
//      de scroll (GSAP ScrollTrigger).
//   2. Cinta de marca + secciones informativas con reveals ligeros.
//   3. Descarga (iOS / Android) y footer.
import Nav from './components/Nav.jsx';
import HeroStory from './components/HeroStory.jsx';
import {
  Marquee,
  QuienesSomos,
  QueBuscamos,
  Descargar,
  Footer,
} from './components/Sections.jsx';

export default function App() {
  return (
    <>
      <Nav />
      <HeroStory />
      <Marquee />
      <QuienesSomos />
      <QueBuscamos />
      <Descargar />
      <Footer />
    </>
  );
}
