import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
/* index.css va PRIMERO a proposito: define los tokens base, y
   todo lo demas (deck, slides, componentes) los sobrescribe.
   Al reves, sus :root de escritorio ganaban por orden de carga a
   las media queries de movil, que tienen la misma especificidad. */
import './styles/index.css'
import App from './App.jsx'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
