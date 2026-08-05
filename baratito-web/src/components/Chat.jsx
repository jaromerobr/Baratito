import { CHAT } from '../data/content'
import './Chat.css'

export default function Chat({ active }) {
  return (
    <div className="chat" data-play={active}>
      <div className="chat-head">
        <span className="chat-avatar" aria-hidden="true">
          🚴
        </span>
        <span className="chat-who">
          <strong>Mateo V.</strong>
          <span className="chat-status mono">Verificado · en línea</span>
        </span>
      </div>

      <div className="chat-log">
        {CHAT.map((m, i) => (
          <p
            key={m.text}
            className="chat-msg"
            data-kind={m.kind}
            style={{ '--i': i }}
          >
            {m.text}
          </p>
        ))}
      </div>
    </div>
  )
}
