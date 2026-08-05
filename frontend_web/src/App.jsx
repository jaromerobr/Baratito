import { useState } from 'react'
import { useDeck } from './hooks/useDeck'
import { SLIDES } from './data/content'
import TopBar from './components/TopBar'
import Rail from './components/Rail'
import Hero from './slides/Hero'
import Quienes from './slides/Quienes'
import ComoFunciona from './slides/ComoFunciona'
import Descarga from './slides/Descarga'
import './styles/deck.css'

const VIEWS = [Hero, Quienes, ComoFunciona, Descarga]

export default function App() {
  const { index, dir, goTo } = useDeck(SLIDES.length)
  const [palette, setPalette] = useState('amarillo')
  const tone = SLIDES[index].tone

  return (
    <div className="deck" data-palette={palette} data-tone={tone}>
      <TopBar onGo={goTo} palette={palette} onPalette={setPalette} />

      <div className="deck-stage">
        {VIEWS.map((View, i) => {
          const offset = i - index
          return (
            <section
              key={SLIDES[i].id}
              className="slide"
              data-state={offset === 0 ? 'active' : offset < 0 ? 'past' : 'future'}
              aria-hidden={offset !== 0}
              style={{ '--offset': offset, '--dir': dir }}
            >
              <View active={offset === 0} onGo={goTo} />
            </section>
          )
        })}
      </div>

      <Rail slides={SLIDES} active={index} onGo={goTo} />
    </div>
  )
}
