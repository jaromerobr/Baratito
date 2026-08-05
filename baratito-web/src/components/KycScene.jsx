import './KycScene.css'

/* Malla facial: puntos y aristas de la animación de escaneo.
   Se generan desde datos para no repetir 36 <path> a mano. */
const NODES = [
  [176, 214], [206, 208], [240, 206], [268, 212],
  [166, 240], [196, 232], [228, 236], [262, 236],
  [172, 266], [200, 258], [216, 262], [250, 252], [272, 258],
  [186, 286], [214, 278], [246, 276], [268, 282],
  [200, 300], [232, 296], [256, 292],
]

const EDGES = [
  [0, 1], [1, 2], [2, 3],
  [0, 4], [1, 5], [2, 6], [3, 7],
  [4, 5], [5, 6], [6, 7],
  [4, 8], [5, 9], [5, 10], [6, 10], [6, 11], [7, 11], [7, 12],
  [8, 9], [9, 10], [10, 11], [11, 12],
  [8, 13], [9, 14], [10, 14], [14, 15], [11, 15], [12, 16], [15, 16],
  [13, 14], [13, 17], [14, 18], [15, 18], [15, 19], [16, 19],
  [17, 18], [18, 19],
]

const CYCLE = 6

export default function KycScene() {
  return (
    <figure className="kyc">
      <div className="kyc-stage">
        <svg
          className="kyc-svg"
          viewBox="0 0 460 500"
          role="img"
          aria-label="Una persona verifica su identidad con la cámara del teléfono: la app escanea su rostro y confirma la identidad."
        >
          <defs>
            <clipPath id="kycHead">
              <rect x="150" y="150" width="126" height="152" rx="56" />
            </clipPath>
            <filter id="kycShadow" x="-50%" y="-100%" width="200%" height="300%">
              <feGaussianBlur stdDeviation="7" />
            </filter>
          </defs>

          <ellipse
            className="kyc-shadow"
            cx="214"
            cy="484"
            rx="98"
            ry="14"
            filter="url(#kycShadow)"
          />

          <g className="kyc-float">
            {/* Cuerpo */}
            <rect x="192" y="278" width="46" height="82" rx="16" fill="#E8B080" />
            <rect x="138" y="344" width="152" height="120" rx="48" fill="#FFFFFF" />
            <rect x="196" y="340" width="38" height="15" rx="7.5" fill="#E8B080" />
            <text className="kyc-shirt" x="214" y="420" textAnchor="middle">
              B
            </text>

            {/* Cabeza */}
            <rect x="146" y="222" width="16" height="34" rx="8" fill="#E8B080" />
            <rect x="150" y="150" width="126" height="152" rx="56" fill="#F5C9A0" />
            <g clipPath="url(#kycHead)">
              <rect x="150" y="150" width="26" height="152" fill="#E8B080" />
              <path
                d="M 150,212 L 150,196 C 150,166 178,146 213,146 C 248,146 276,166 276,196 L 276,200 L 150,212 Z"
                fill="#2C1810"
              />
            </g>

            {/* Facciones */}
            <rect x="216" y="215" width="26" height="5.5" rx="2.75" fill="#2C1810" />
            <rect x="252" y="213" width="23" height="5.5" rx="2.75" fill="#2C1810" />
            <circle cx="229" cy="237" r="7" fill="#2C1810" />
            <circle cx="263" cy="236" r="7" fill="#2C1810" />
            <circle cx="231.5" cy="234" r="2.2" fill="#FFFFFF" />
            <circle cx="265.5" cy="233" r="2.2" fill="#FFFFFF" />
            <path
              d="M 250,252 L 250,264 L 242,264"
              fill="none"
              stroke="#E8B080"
              strokeWidth="4"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            <path
              d="M 236,276 Q 250,288 264,274"
              fill="none"
              stroke="#2C1810"
              strokeWidth="3.5"
              strokeLinecap="round"
            />

            {/* Malla de reconocimiento */}
            <g clipPath="url(#kycHead)">
              <g className="kyc-mesh" fill="none" strokeWidth="1.2" strokeLinecap="round" strokeDasharray="200">
                {EDGES.map(([a, b], i) => (
                  <path
                    key={`e${a}-${b}`}
                    d={`M ${NODES[a][0]},${NODES[a][1]} L ${NODES[b][0]},${NODES[b][1]}`}
                    style={{ animationDelay: `${(i % 6) * 0.06}s`, animationDuration: `${CYCLE}s` }}
                  />
                ))}
              </g>
              <g className="kyc-nodes">
                {NODES.map(([x, y], i) => (
                  <circle
                    key={`n${x}-${y}`}
                    cx={x}
                    cy={y}
                    r="3"
                    style={{ animationDelay: `${(i % 5) * 0.09}s`, animationDuration: `${CYCLE}s` }}
                  />
                ))}
              </g>
            </g>

            {/* Corchetes de encuadre */}
            <g
              className="kyc-brackets"
              fill="none"
              strokeWidth="2.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M 128,158 L 128,134 L 152,134" />
              <path d="M 274,134 L 298,134 L 298,158" />
              <path d="M 128,296 L 128,320 L 152,320" />
              <path d="M 274,320 L 298,320 L 298,296" />
            </g>

            {/* Teléfono en la mano */}
            <g className="kyc-phone-slide">
              <g className="kyc-phone-wobble">
                <rect x="286" y="170" width="110" height="200" rx="22" fill="#0F3D24" />
                <rect x="396" y="212" width="4" height="28" rx="2" fill="#0a2e1a" />
                <rect x="294" y="178" width="94" height="184" rx="16" fill="#F8F4EC" />
                <rect x="326" y="185" width="30" height="6" rx="3" fill="#000000" />

                {/* Estado: escaneando */}
                <g className="kyc-screen-scan">
                  <rect className="kyc-viewport" x="302" y="200" width="78" height="112" rx="12" />
                  <g fill="none" stroke="#FFFFFF" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M 310,220 L 310,208 L 322,208" />
                    <path d="M 360,208 L 372,208 L 372,220" />
                    <path d="M 310,292 L 310,304 L 322,304" />
                    <path d="M 360,304 L 372,304 L 372,292" />
                  </g>
                  <rect x="325" y="222" width="32" height="42" rx="14" fill="#E0E0E0" />
                  <rect x="316" y="272" width="50" height="34" rx="17" fill="#E0E0E0" />
                  <g className="kyc-crosshair" fill="none" strokeWidth="1.2">
                    <path d="M 327,238 L 356,236" />
                    <path d="M 328,250 L 356,249" />
                    <path d="M 341,224 L 341,262" />
                  </g>
                  <rect x="308" y="332" width="66" height="6" rx="3" fill="#DDDDCC" />
                  <rect className="kyc-progress" x="308" y="332" width="66" height="6" rx="3" />
                </g>

                {/* Estado: verificado */}
                <g className="kyc-screen-done">
                  <g className="kyc-check">
                    <circle className="kyc-check-ring" cx="341" cy="248" r="22" strokeWidth="2.5" />
                    <path
                      className="kyc-check-mark"
                      d="M 331,248 L 338,256 L 352,241"
                      fill="none"
                      strokeWidth="3"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </g>
                  <text className="kyc-done-label" x="341" y="292" textAnchor="middle">
                    Verificado
                  </text>
                  <text className="kyc-done-sub" x="341" y="306" textAnchor="middle">
                    Identidad confirmada
                  </text>
                </g>
              </g>
            </g>
          </g>
        </svg>

        <span className="kyc-badge kyc-badge-a">
          <svg width="13" height="13" viewBox="0 0 13 13" aria-hidden="true">
            <path
              d="M 3,7 L 5.4,9.4 L 10,4.4"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
          Verificado
        </span>
        <span className="kyc-badge kyc-badge-b">Identidad confirmada</span>
      </div>

      <figcaption className="kyc-caption mono">
        Cédula + selfie · antes de la primera publicación
      </figcaption>
    </figure>
  )
}
