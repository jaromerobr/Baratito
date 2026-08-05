export default function Floaters({ items }) {
  return items.map((f) => (
    <span key={f.text} className="floater" data-pos={f.pos} data-style={f.style}>
      <span aria-hidden="true">{f.icon}</span>
      {f.text}
    </span>
  ))
}
