import { useCallback, useEffect, useRef, useState } from 'react'

/**
 * Controla un deck de slides a pantalla completa.
 * Una rueda de scroll = una slide. Nada de scroll intermedio.
 *
 * El indice vive tambien en un ref porque las decisiones (¿estoy
 * bloqueado?, ¿a donde voy?) se toman ANTES de tocar el estado.
 * Meterlas dentro del updater de setIndex era el bug: React invoca
 * los updaters dos veces en desarrollo para detectar impurezas, y
 * la segunda pasada veia el candado que habia puesto la primera y
 * devolvia el indice viejo. El clic se perdia.
 */
export function useDeck(count, lockMs = 900) {
  const [index, setIndex] = useState(0)
  const [dir, setDir] = useState(1)
  const indexRef = useRef(0)
  const locked = useRef(false)
  const timer = useRef(null)
  const touchY = useRef(null)

  const lock = useCallback(() => {
    locked.current = true
    clearTimeout(timer.current)
    timer.current = setTimeout(() => {
      locked.current = false
    }, lockMs)
  }, [lockMs])

  /** Navegacion explicita: el usuario senala un destino concreto
   *  (logo, boton Descargar, punto del riel). No respeta el candado
   *  a proposito: si hay una transicion en curso, el clic manda. */
  const goTo = useCallback(
    (next) => {
      if (next < 0 || next > count - 1) return
      const current = indexRef.current
      if (next === current) return

      indexRef.current = next
      setDir(next > current ? 1 : -1)
      setIndex(next)
      lock()
    },
    [count, lock],
  )

  /** Navegacion relativa: rueda, teclas, swipe. Si respeta el
   *  candado, o un solo gesto de trackpad saltaria varias slides. */
  const step = useCallback(
    (delta) => {
      if (locked.current) return
      goTo(indexRef.current + delta)
    },
    [goTo],
  )

  useEffect(() => {
    const onWheel = (e) => {
      e.preventDefault()
      if (Math.abs(e.deltaY) < 12) return
      step(e.deltaY > 0 ? 1 : -1)
    }

    const onKey = (e) => {
      const forward = ['ArrowDown', 'PageDown', ' ']
      const back = ['ArrowUp', 'PageUp']
      if (forward.includes(e.key)) {
        e.preventDefault()
        step(1)
      } else if (back.includes(e.key)) {
        e.preventDefault()
        step(-1)
      } else if (e.key === 'Home') {
        e.preventDefault()
        goTo(0)
      } else if (e.key === 'End') {
        e.preventDefault()
        goTo(count - 1)
      }
    }

    const onTouchStart = (e) => {
      touchY.current = e.touches[0].clientY
    }
    const onTouchEnd = (e) => {
      if (touchY.current === null) return
      const delta = touchY.current - e.changedTouches[0].clientY
      if (Math.abs(delta) > 55) step(delta > 0 ? 1 : -1)
      touchY.current = null
    }

    window.addEventListener('wheel', onWheel, { passive: false })
    window.addEventListener('keydown', onKey)
    window.addEventListener('touchstart', onTouchStart, { passive: true })
    window.addEventListener('touchend', onTouchEnd, { passive: true })

    return () => {
      window.removeEventListener('wheel', onWheel)
      window.removeEventListener('keydown', onKey)
      window.removeEventListener('touchstart', onTouchStart)
      window.removeEventListener('touchend', onTouchEnd)
    }
  }, [step, goTo, count])

  useEffect(() => () => clearTimeout(timer.current), [])

  return { index, dir, goTo }
}
