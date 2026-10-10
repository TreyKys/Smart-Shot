import React from 'react';
import {
  AbsoluteFill,
  Audio,
  Sequence,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import {SEC, FONT} from '../theme';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 13 · "The Charge / EVIDENCE" · 24s · 9:16
// Hospital-bill mystery-fee scenario, re-shot as a detective's evidence
// board — corkboard background, documents pinned at angles, torn
// receipts, sticky notes, red yarn connecting clues, hand-written
// annotations in marker. Different from the kinetic remix in every way:
// warm earth palette (vs cold neon), additive layering (vs cut-and-
// replace), mixed fonts (vs single-font kinetic).
// ─────────────────────────────────────────────────────────────────────────

const C = {
  cork: '#B98B4F',
  corkDark: '#8E6734',
  pin: '#D62828',
  paper: '#F5F0E1',
  paperAged: '#E8DFC5',
  receipt: '#FFFDF5',
  stickyYellow: '#FBE38E',
  stickyPink: '#FBB1BD',
  marker: '#C1121F',
  markerDark: '#780000',
  ink: '#1A1A1A',
  pencil: '#555',
  teal: '#277DA1',
};

// ── Corkboard background with pinned-paper feel ──
const Board: React.FC<{children: React.ReactNode}> = ({children}) => (
  <AbsoluteFill style={{background: C.cork, overflow: 'hidden'}}>
    {/* Cork texture noise */}
    <div
      style={{
        position: 'absolute',
        inset: 0,
        backgroundImage: `
          radial-gradient(circle at 10% 20%, ${C.corkDark}66 1px, transparent 2px),
          radial-gradient(circle at 50% 40%, ${C.corkDark}44 1px, transparent 2px),
          radial-gradient(circle at 80% 10%, ${C.corkDark}66 1px, transparent 2px),
          radial-gradient(circle at 30% 70%, ${C.corkDark}55 1px, transparent 2px),
          radial-gradient(circle at 70% 90%, ${C.corkDark}66 1px, transparent 2px),
          radial-gradient(circle at 15% 50%, ${C.corkDark}44 1px, transparent 2px),
          radial-gradient(circle at 90% 60%, ${C.corkDark}66 1px, transparent 2px)
        `,
        backgroundSize: '100px 100px',
      }}
    />
    {/* Darker vignette edges */}
    <div
      style={{
        position: 'absolute',
        inset: 0,
        background: `radial-gradient(circle at center, transparent 40%, rgba(0,0,0,0.3) 100%)`,
      }}
    />
    {children}
  </AbsoluteFill>
);

// ── A red thumbtack pin ──
const Pin: React.FC<{top: number; left: number; color?: string}> = ({top, left, color = C.pin}) => (
  <div
    style={{
      position: 'absolute',
      top,
      left,
      width: 28,
      height: 28,
      borderRadius: '50%',
      background: `radial-gradient(circle at 35% 30%, ${color}CC, ${color} 60%, ${C.corkDark} 100%)`,
      boxShadow: '0 4px 10px rgba(0,0,0,0.5)',
      zIndex: 10,
    }}
  />
);

// ── A piece of paper (document / receipt / sticky), pinned ──
const Pinned: React.FC<{
  children: React.ReactNode;
  from: number;
  top: number;
  left?: number;
  right?: number;
  width: number;
  rotate: number;
  bg?: string;
  pinColor?: string;
  shadow?: boolean;
}> = ({
  children,
  from,
  top,
  left,
  right,
  width,
  rotate,
  bg = C.paper,
  pinColor = C.pin,
  shadow = true,
}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 14, stiffness: 180, mass: 0.5}});
  const op = interpolate(s, [0, 1], [0, 1]);
  const sc = interpolate(s, [0, 1], [0.85, 1]);
  const style: React.CSSProperties = {
    position: 'absolute',
    top,
    width,
    transform: `rotate(${rotate}deg) scale(${sc})`,
    opacity: op,
    background: bg,
    padding: 24,
    boxShadow: shadow ? '0 20px 40px rgba(0,0,0,0.4)' : 'none',
    fontFamily: 'serif',
    color: C.ink,
  };
  if (left !== undefined) style.left = left;
  if (right !== undefined) style.right = right;
  return (
    <>
      <Pin top={top - 10} left={(left ?? 1080 - (right ?? 0) - width) + width / 2 - 14} color={pinColor} />
      <div style={style}>{children}</div>
    </>
  );
};

// ── Hospital bill (document card) ──
const HospitalBill: React.FC = () => (
  <div style={{display: 'flex', flexDirection: 'column', gap: 10, fontFamily: 'serif'}}>
    <div style={{fontSize: 26, fontWeight: 900, color: C.ink, textAlign: 'center', letterSpacing: 2, borderBottom: `2px solid ${C.ink}`, paddingBottom: 10}}>
      LAGOON PRIVATE HOSPITAL
    </div>
    <div style={{fontSize: 18, color: C.pencil, textAlign: 'center', fontFamily: 'monospace'}}>
      Discharge Invoice #DH-28491
    </div>
    <div style={{marginTop: 10, display: 'flex', flexDirection: 'column', gap: 6, fontFamily: 'monospace', fontSize: 18}}>
      <div style={{display: 'flex', justifyContent: 'space-between'}}>
        <span>Consultation</span>
        <span>₦5,000</span>
      </div>
      <div style={{display: 'flex', justifyContent: 'space-between'}}>
        <span>Blood tests (2)</span>
        <span>₦11,700</span>
      </div>
      <div style={{display: 'flex', justifyContent: 'space-between'}}>
        <span>IV + drugs</span>
        <span>₦11,300</span>
      </div>
      <div style={{display: 'flex', justifyContent: 'space-between'}}>
        <span>Overnight obs</span>
        <span>₦18,000</span>
      </div>
      <div style={{display: 'flex', justifyContent: 'space-between'}}>
        <span>Nurse / oxygen</span>
        <span>₦7,250</span>
      </div>
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          background: C.stickyYellow,
          padding: '4px 6px',
          borderRadius: 2,
          color: C.markerDark,
          fontWeight: 900,
        }}
      >
        <span>MISC. SERVICE FEE</span>
        <span>₦25,000</span>
      </div>
      <div style={{display: 'flex', justifyContent: 'space-between'}}>
        <span>VAT</span>
        <span>₦6,000</span>
      </div>
      <div
        style={{
          marginTop: 8,
          paddingTop: 8,
          borderTop: `2px solid ${C.ink}`,
          display: 'flex',
          justifyContent: 'space-between',
          fontSize: 22,
          fontWeight: 900,
        }}
      >
        <span>TOTAL</span>
        <span>₦84,250</span>
      </div>
    </div>
  </div>
);

// ── Sticky note ──
const StickyNote: React.FC<{text: string; color?: string; fontSize?: number}> = ({
  text,
  color = C.stickyYellow,
  fontSize = 32,
}) => (
  <div
    style={{
      fontFamily: 'serif',
      fontSize,
      color: C.ink,
      fontStyle: 'italic',
      fontWeight: 600,
      textAlign: 'center',
      lineHeight: 1.3,
    }}
  >
    {text}
  </div>
);

// ── Red marker annotation (hand-drawn question mark / circle / arrow via SVG) ──
const RedMarker: React.FC<{
  from: number;
  path: string;
  strokeWidth?: number;
  dashLength?: number;
}> = ({from, path, strokeWidth = 10, dashLength = 2000}) => {
  const frame = useCurrentFrame() - from;
  const draw = interpolate(frame, [0, 25], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <svg
      style={{position: 'absolute', inset: 0, pointerEvents: 'none', zIndex: 20}}
      width="100%"
      height="100%"
      viewBox="0 0 1080 1920"
      preserveAspectRatio="none"
    >
      <path
        d={path}
        stroke={C.marker}
        strokeWidth={strokeWidth}
        fill="none"
        strokeLinecap="round"
        strokeDasharray={dashLength}
        strokeDashoffset={dashLength - draw * dashLength}
      />
    </svg>
  );
};

// ── A hand-drawn circle around something ──
const MarkerCircle: React.FC<{
  from: number;
  cx: number;
  cy: number;
  rx: number;
  ry: number;
}> = ({from, cx, cy, rx, ry}) => {
  const frame = useCurrentFrame() - from;
  const draw = interpolate(frame, [0, 24], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const perimeter = 2 * Math.PI * ((rx + ry) / 2);
  return (
    <svg
      style={{position: 'absolute', inset: 0, pointerEvents: 'none', zIndex: 20}}
      width="100%"
      height="100%"
      viewBox="0 0 1080 1920"
      preserveAspectRatio="none"
    >
      <ellipse
        cx={cx}
        cy={cy}
        rx={rx}
        ry={ry}
        stroke={C.marker}
        strokeWidth={10}
        fill="none"
        strokeDasharray={perimeter}
        strokeDashoffset={perimeter - draw * perimeter}
        transform={`rotate(-5 ${cx} ${cy})`}
      />
    </svg>
  );
};

// ── Red yarn connecting two points ──
const Yarn: React.FC<{from: number; x1: number; y1: number; x2: number; y2: number}> = ({
  from,
  x1,
  y1,
  x2,
  y2,
}) => {
  const frame = useCurrentFrame() - from;
  const draw = interpolate(frame, [0, 20], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const dx = x2 - x1;
  const dy = y2 - y1;
  const length = Math.sqrt(dx * dx + dy * dy);
  return (
    <svg
      style={{position: 'absolute', inset: 0, pointerEvents: 'none', zIndex: 5}}
      width="100%"
      height="100%"
      viewBox="0 0 1080 1920"
      preserveAspectRatio="none"
    >
      <line
        x1={x1}
        y1={y1}
        x2={x2}
        y2={y2}
        stroke={C.pin}
        strokeWidth={5}
        strokeDasharray={length}
        strokeDashoffset={length - draw * length}
      />
    </svg>
  );
};

// ── A big centered banner — "FOR WHAT?!" marker-style ──
const Banner: React.FC<{text: string; from: number; color?: string; size?: number}> = ({
  text,
  from,
  color = C.marker,
  size = 220,
}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 12, stiffness: 180, mass: 0.5}});
  const op = interpolate(s, [0, 1], [0, 1]);
  const sc = interpolate(s, [0, 1], [0.9, 1]);
  const rot = interpolate(s, [0, 1], [-3, -1]);
  return (
    <div
      style={{
        position: 'absolute',
        inset: 0,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <div
        style={{
          opacity: op,
          transform: `scale(${sc}) rotate(${rot}deg)`,
          fontFamily: 'serif',
          fontSize: size,
          fontWeight: 900,
          color,
          fontStyle: 'italic',
          textAlign: 'center',
          lineHeight: 0.95,
          textShadow: '4px 4px 0 rgba(0,0,0,0.3)',
        }}
      >
        {text}
      </div>
    </div>
  );
};

export const TheChargeEvidence: React.FC = () => {
  return (
    <AbsoluteFill>
      <Sequence from={0} durationInFrames={SEC(24)}>
        <Audio src={staticFile('sfx/music-bed.mp3')} volume={0.2} />
      </Sequence>

      {/* Act 1 (0-3s): bill goes up on the board, pinned */}
      <Sequence from={0} durationInFrames={SEC(3)}>
        <Board>
          <Pinned from={SEC(0.3)} top={240} left={240} width={620} rotate={-3}>
            <HospitalBill />
          </Pinned>
        </Board>
        <Audio src={staticFile('sfx/pop.mp3')} />
      </Sequence>

      {/* Act 2 (3-5.5s): red marker circles the mystery line */}
      <Sequence from={SEC(3)} durationInFrames={SEC(2.5)}>
        <Board>
          <Pinned from={-100} top={240} left={240} width={620} rotate={-3}>
            <HospitalBill />
          </Pinned>
          <MarkerCircle from={SEC(0.3)} cx={540} cy={830} rx={330} ry={50} />
        </Board>
        <Audio src={staticFile('sfx/whoosh.mp3')} />
      </Sequence>

      {/* Act 3 (5.5-7.5s): yellow sticky note "WHAT IS THIS?" slaps on */}
      <Sequence from={SEC(5.5)} durationInFrames={SEC(2)}>
        <Board>
          <Pinned from={-100} top={240} left={240} width={620} rotate={-3}>
            <HospitalBill />
          </Pinned>
          <MarkerCircle from={-100} cx={540} cy={830} rx={330} ry={50} />
          <Pinned
            from={SEC(0.2)}
            top={900}
            right={60}
            width={320}
            rotate={6}
            bg={C.stickyYellow}
            pinColor={C.marker}
          >
            <StickyNote text='"WHAT IS THIS?"' fontSize={38} />
          </Pinned>
        </Board>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* Act 4 (7.5-10s): pink sticky — "the cashier doesn't know" */}
      <Sequence from={SEC(7.5)} durationInFrames={SEC(2.5)}>
        <Board>
          <Pinned from={-100} top={240} left={240} width={620} rotate={-3}>
            <HospitalBill />
          </Pinned>
          <MarkerCircle from={-100} cx={540} cy={830} rx={330} ry={50} />
          <Pinned from={-100} top={900} right={60} width={320} rotate={6} bg={C.stickyYellow} pinColor={C.marker}>
            <StickyNote text='"WHAT IS THIS?"' fontSize={38} />
          </Pinned>
          <Pinned from={SEC(0.2)} top={1250} left={80} width={380} rotate={-5} bg={C.stickyPink} pinColor={C.marker}>
            <StickyNote text={`"that's just what the system says."`} fontSize={28} />
            <div style={{fontSize: 20, color: C.pencil, marginTop: 10, fontStyle: 'italic', textAlign: 'center'}}>
              — the cashier
            </div>
          </Pinned>
          <Yarn from={SEC(0.5)} x1={540} y1={880} x2={240} y2={1340} />
        </Board>
        <Audio src={staticFile('sfx/nope.mp3')} />
      </Sequence>

      {/* Act 5 (10-12.5s): "FOR WHAT?!" banner in red marker */}
      <Sequence from={SEC(10)} durationInFrames={SEC(2.5)}>
        <Board>
          <Banner text="FOR WHAT?!" from={SEC(0.2)} color={C.marker} size={300} />
        </Board>
        <Audio src={staticFile('sfx/slam.mp3')} />
      </Sequence>

      {/* Act 6 (12.5-15s): the consent form appears, highlighted */}
      <Sequence from={SEC(12.5)} durationInFrames={SEC(2.5)}>
        <Board>
          <Pinned
            from={SEC(0.3)}
            top={280}
            left={120}
            width={840}
            rotate={1}
            bg={C.paperAged}
          >
            <div style={{fontFamily: 'serif', color: C.ink}}>
              <div style={{fontSize: 22, fontWeight: 900, letterSpacing: 2, color: C.markerDark, borderBottom: `2px solid ${C.markerDark}`, paddingBottom: 10, marginBottom: 20}}>
                CONSENT FORM — SIGNED ON ADMISSION
              </div>
              <div style={{fontSize: 20, fontWeight: 700, color: C.pencil, letterSpacing: 2, marginBottom: 14}}>
                § 4.2 — SERVICE CHARGES
              </div>
              <div style={{fontSize: 30, lineHeight: 1.4, fontStyle: 'italic'}}>
                The Patient agrees to a miscellaneous service fee, covering:
              </div>
              <ul style={{fontSize: 28, lineHeight: 1.5, marginTop: 14, paddingLeft: 30}}>
                <li>bed-sheet laundry</li>
                <li>equipment sterilisation</li>
                <li>
                  <span style={{background: C.stickyYellow, padding: '2px 6px'}}>
                    administrative handling
                  </span>
                </li>
              </ul>
              <div style={{fontSize: 24, color: C.markerDark, marginTop: 20, fontWeight: 700, fontStyle: 'italic', textAlign: 'right'}}>
                standard range: ₦8,000 – ₦12,000
              </div>
            </div>
          </Pinned>
        </Board>
        <Audio src={staticFile('sfx/pop.mp3')} />
      </Sequence>

      {/* Act 7 (15-17.5s): red marker arrow + sticky — "YOU PAID ₦25K" */}
      <Sequence from={SEC(15)} durationInFrames={SEC(2.5)}>
        <Board>
          <Pinned from={-100} top={280} left={120} width={840} rotate={1} bg={C.paperAged}>
            <div style={{fontFamily: 'serif', color: C.ink}}>
              <div style={{fontSize: 22, fontWeight: 900, letterSpacing: 2, color: C.markerDark, borderBottom: `2px solid ${C.markerDark}`, paddingBottom: 10, marginBottom: 20}}>
                CONSENT FORM — SIGNED ON ADMISSION
              </div>
              <div style={{fontSize: 20, fontWeight: 700, color: C.pencil, letterSpacing: 2, marginBottom: 14}}>
                § 4.2 — SERVICE CHARGES
              </div>
              <div style={{fontSize: 30, lineHeight: 1.4, fontStyle: 'italic'}}>
                The Patient agrees to a miscellaneous service fee, covering:
              </div>
              <ul style={{fontSize: 28, lineHeight: 1.5, marginTop: 14, paddingLeft: 30}}>
                <li>bed-sheet laundry</li>
                <li>equipment sterilisation</li>
                <li>
                  <span style={{background: C.stickyYellow, padding: '2px 6px'}}>
                    administrative handling
                  </span>
                </li>
              </ul>
              <div style={{fontSize: 24, color: C.markerDark, marginTop: 20, fontWeight: 700, fontStyle: 'italic', textAlign: 'right'}}>
                standard range: ₦8,000 – ₦12,000
              </div>
            </div>
          </Pinned>
          <Pinned
            from={SEC(0.3)}
            top={1250}
            left={240}
            width={620}
            rotate={-4}
            bg={C.stickyPink}
            pinColor={C.marker}
          >
            <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10, padding: 10}}>
              <div style={{fontFamily: 'serif', fontSize: 36, color: C.ink, fontWeight: 700, fontStyle: 'italic'}}>
                they charged you
              </div>
              <div style={{fontFamily: 'monospace', fontSize: 100, color: C.markerDark, fontWeight: 900, lineHeight: 1}}>
                ₦25,000
              </div>
              <div style={{fontFamily: 'serif', fontSize: 30, color: C.ink, fontWeight: 700, fontStyle: 'italic'}}>
                argue it.
              </div>
            </div>
          </Pinned>
          <Yarn from={SEC(0.6)} x1={540} y1={1150} x2={540} y2={1220} />
        </Board>
        <Audio src={staticFile('sfx/chime-win.mp3')} />
      </Sequence>

      {/* Act 8 (17.5-20s): the method — "ASK MAGNUM OPUS" sticky */}
      <Sequence from={SEC(17.5)} durationInFrames={SEC(2.5)}>
        <Board>
          <Banner text="ask it. everything." from={SEC(0.2)} color={C.markerDark} size={160} />
          <RedMarker
            from={SEC(0.6)}
            path="M 300 1200 Q 540 1300, 780 1200"
            strokeWidth={14}
            dashLength={800}
          />
        </Board>
        <Audio src={staticFile('sfx/whoosh.mp3')} />
      </Sequence>

      {/* Act 9 (20-24s): end lockup */}
      <Sequence from={SEC(20)} durationInFrames={SEC(4)}>
        <Board>
          <div
            style={{
              position: 'absolute',
              inset: 0,
              background: '#F6F3E8',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              padding: 60,
            }}
          >
            <EndCard tagline="Know what you paid for." />
          </div>
        </Board>
        <Audio src={staticFile('sfx/chime-win.mp3')} />
      </Sequence>
    </AbsoluteFill>
  );
};
