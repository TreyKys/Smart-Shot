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
import {SEC, FONT, ensureFonts} from '../theme';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 18 · "The Address / POSTER" · 24s · 9:16
// Taxi-late-to-interview scenario, re-shot as a warm vintage magazine /
// travel-poster piece. Cream paper background with heavy grain. Decorative
// serif chapter headings. Hand-drawn SVG arrows and circles. Different
// from the kinetic remix in every way — slower pacing, warmer palette,
// deliberate reveals rather than slammed cuts.
// ─────────────────────────────────────────────────────────────────────────

const C = {
  paper: '#F0E6D2',
  paperDark: '#D9CAA8',
  ink: '#2B1D0E',
  inkSoft: '#5A4328',
  red: '#B23A1E',
  teal: '#2A6670',
  gold: '#C8912C',
  shadow: 'rgba(43,29,14,0.15)',
};

// ── Paper background with faint grain ──
const Paper: React.FC<{children: React.ReactNode}> = ({children}) => {
  ensureFonts();
  return (
    <AbsoluteFill
      style={{
        background: C.paper,
        overflow: 'hidden',
      }}
    >
      {/* Grain overlay via radial-gradient noise */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          backgroundImage: `
            radial-gradient(circle at 20% 30%, ${C.paperDark}22 0%, transparent 50%),
            radial-gradient(circle at 80% 70%, ${C.paperDark}22 0%, transparent 50%),
            radial-gradient(circle at 50% 50%, transparent 30%, ${C.paperDark}11 100%)
          `,
          pointerEvents: 'none',
        }}
      />
      {children}
    </AbsoluteFill>
  );
};

// ── Chapter heading with ornamental rules ──
const Chapter: React.FC<{num: string; title: string; from: number}> = ({num, title, from}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 20], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const y = interpolate(frame, [0, 20], [20, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        opacity: op,
        transform: `translateY(${y}px)`,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 20,
      }}
    >
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 24,
          fontFamily: 'serif',
          fontSize: 28,
          color: C.inkSoft,
          fontStyle: 'italic',
          letterSpacing: 4,
          textTransform: 'uppercase',
        }}
      >
        <div style={{width: 80, height: 2, background: C.inkSoft}} />
        {num}
        <div style={{width: 80, height: 2, background: C.inkSoft}} />
      </div>
      <div
        style={{
          fontFamily: 'serif',
          fontSize: 110,
          color: C.ink,
          fontWeight: 900,
          lineHeight: 1,
          letterSpacing: -3,
          textAlign: 'center',
          maxWidth: 900,
        }}
      >
        {title}
      </div>
    </div>
  );
};

// ── Big serif pull quote ──
const PullQuote: React.FC<{text: string; attribution?: string; from: number}> = ({
  text,
  attribution,
  from,
}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 20], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        opacity: op,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 30,
        maxWidth: 900,
      }}
    >
      <div
        style={{
          fontFamily: 'serif',
          fontSize: 300,
          color: C.red,
          fontWeight: 900,
          lineHeight: 0.6,
          marginBottom: -40,
        }}
      >
        &ldquo;
      </div>
      <div
        style={{
          fontFamily: 'serif',
          fontSize: 76,
          fontStyle: 'italic',
          color: C.ink,
          lineHeight: 1.2,
          textAlign: 'center',
          fontWeight: 500,
        }}
      >
        {text}
      </div>
      {attribution && (
        <div
          style={{
            fontFamily: FONT,
            fontSize: 26,
            color: C.inkSoft,
            fontWeight: 700,
            letterSpacing: 3,
            textTransform: 'uppercase',
          }}
        >
          — {attribution}
        </div>
      )}
    </div>
  );
};

// ── Hand-drawn SVG arrow (curved, scribbled) ──
const HandArrow: React.FC<{
  from: number;
  path: string;
  color?: string;
  strokeWidth?: number;
  arrowAt?: {x: number; y: number; rotate: number};
}> = ({from, path, color = C.red, strokeWidth = 6, arrowAt}) => {
  const frame = useCurrentFrame() - from;
  const draw = interpolate(frame, [0, 30], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <svg
      style={{position: 'absolute', inset: 0, pointerEvents: 'none'}}
      width="100%"
      height="100%"
      viewBox="0 0 1080 1920"
      preserveAspectRatio="none"
    >
      <path
        d={path}
        stroke={color}
        strokeWidth={strokeWidth}
        fill="none"
        strokeLinecap="round"
        strokeDasharray="2000"
        strokeDashoffset={2000 - draw * 2000}
      />
      {arrowAt && draw > 0.9 && (
        <g transform={`translate(${arrowAt.x} ${arrowAt.y}) rotate(${arrowAt.rotate})`}>
          <line x1="0" y1="0" x2="-24" y2="-12" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" />
          <line x1="0" y1="0" x2="-24" y2="12" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" />
        </g>
      )}
    </svg>
  );
};

// ── Hand-drawn circle around a word ──
const HandCircle: React.FC<{
  from: number;
  cx: number;
  cy: number;
  rx: number;
  ry: number;
  color?: string;
}> = ({from, cx, cy, rx, ry, color = C.red}) => {
  const frame = useCurrentFrame() - from;
  const draw = interpolate(frame, [0, 24], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const perimeter = 2 * Math.PI * ((rx + ry) / 2);
  return (
    <svg
      style={{position: 'absolute', inset: 0, pointerEvents: 'none'}}
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
        stroke={color}
        strokeWidth={7}
        fill="none"
        strokeDasharray={perimeter}
        strokeDashoffset={perimeter - draw * perimeter}
        transform={`rotate(-4 ${cx} ${cy})`}
      />
    </svg>
  );
};

// ── A labeled sidebar / caption, like a magazine margin ──
const MarginNote: React.FC<{
  from: number;
  pos: 'top-right' | 'bottom-left' | 'top-left' | 'bottom-right';
  label: string;
  text: string;
}> = ({from, pos, label, text}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 16], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const style: React.CSSProperties = {
    position: 'absolute',
    opacity: op,
    maxWidth: 300,
    padding: '14px 18px',
    background: C.paperDark,
    border: `2px solid ${C.ink}`,
    fontFamily: 'serif',
  };
  if (pos === 'top-right') Object.assign(style, {top: 120, right: 40, transform: 'rotate(2deg)'});
  if (pos === 'bottom-left') Object.assign(style, {bottom: 120, left: 40, transform: 'rotate(-2deg)'});
  if (pos === 'top-left') Object.assign(style, {top: 120, left: 40, transform: 'rotate(-1deg)'});
  if (pos === 'bottom-right') Object.assign(style, {bottom: 120, right: 40, transform: 'rotate(1deg)'});
  return (
    <div style={style}>
      <div
        style={{
          fontFamily: FONT,
          fontSize: 16,
          color: C.red,
          fontWeight: 900,
          letterSpacing: 3,
          marginBottom: 6,
        }}
      >
        {label}
      </div>
      <div style={{fontSize: 24, fontStyle: 'italic', color: C.ink, lineHeight: 1.3}}>{text}</div>
    </div>
  );
};

// ── A tall decorative numeral (the issue number / chapter number style) ──
const BigNumeral: React.FC<{num: string; from: number; color?: string; size?: number}> = ({
  num,
  from,
  color = C.red,
  size = 600,
}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 20], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const sc = interpolate(frame, [0, 20], [0.9, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        opacity: op,
        transform: `scale(${sc})`,
        fontFamily: 'serif',
        fontSize: size,
        fontWeight: 900,
        color,
        lineHeight: 0.8,
        letterSpacing: -size * 0.08,
      }}
    >
      {num}
    </div>
  );
};

export const TheAddressPoster: React.FC = () => {
  return (
    <AbsoluteFill>
      <Sequence from={0} durationInFrames={SEC(24)}>
        <Audio src={staticFile('sfx/music-bed.mp3')} volume={0.2} />
      </Sequence>

      {/* Act 1 (0-3s): Chapter one — "The Interview" */}
      <Sequence from={0} durationInFrames={SEC(3)}>
        <Paper>
          <div style={{position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: 60}}>
            <Chapter num="CHAPTER ONE" title="The Appointment" from={SEC(0.3)} />
          </div>
          <MarginNote
            from={SEC(1.6)}
            pos="bottom-left"
            label="LOCATION"
            text="Lagos, Nigeria. A hired cab in traffic. The meter runs."
          />
        </Paper>
        <Audio src={staticFile('sfx/pop.mp3')} />
      </Sequence>

      {/* Act 2 (3-5s): "13 minutes" big numeral */}
      <Sequence from={SEC(3)} durationInFrames={SEC(2)}>
        <Paper>
          <div style={{position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: 60, gap: 10}}>
            <div style={{fontFamily: 'serif', fontSize: 36, fontStyle: 'italic', color: C.inkSoft, letterSpacing: 3, marginBottom: 10}}>
              you have, in total,
            </div>
            <BigNumeral num="13" from={SEC(0.2)} color={C.red} size={700} />
            <div style={{fontFamily: FONT, fontSize: 44, color: C.ink, fontWeight: 900, letterSpacing: 6, marginTop: 10}}>
              MINUTES
            </div>
          </div>
        </Paper>
        <Audio src={staticFile('sfx/slam.mp3')} />
      </Sequence>

      {/* Act 3 (5-8s): the quote — "I sent you three days ago" */}
      <Sequence from={SEC(5)} durationInFrames={SEC(3)}>
        <Paper>
          <div style={{position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: 60}}>
            <PullQuote
              from={SEC(0.3)}
              text="I sent you the address three days ago."
              attribution="Mrs. Adebayo"
            />
          </div>
        </Paper>
        <Audio src={staticFile('sfx/ding.mp3')} />
      </Sequence>

      {/* Act 4 (8-10.5s): "Chapter Two — The Search" with hand-drawn circle */}
      <Sequence from={SEC(8)} durationInFrames={SEC(2.5)}>
        <Paper>
          <div style={{position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: 60}}>
            <Chapter num="CHAPTER TWO" title="The Search" from={SEC(0.2)} />
          </div>
          <HandCircle from={SEC(1.2)} cx={540} cy={1050} rx={360} ry={110} color={C.red} />
        </Paper>
      </Sequence>

      {/* Act 5 (10.5-12.5s): the gallery count — "3,247 photos" with arrow */}
      <Sequence from={SEC(10.5)} durationInFrames={SEC(2)}>
        <Paper>
          <div style={{position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: 60, gap: 24}}>
            <BigNumeral num="3,247" from={SEC(0.2)} color={C.ink} size={360} />
            <div style={{fontFamily: 'serif', fontSize: 60, fontStyle: 'italic', color: C.inkSoft, marginTop: -40}}>
              photographs.
            </div>
            <div style={{fontFamily: FONT, fontSize: 36, color: C.red, fontWeight: 700, letterSpacing: 2, marginTop: 20}}>
              NONE OF THEM THE ADDRESS.
            </div>
          </div>
          <HandArrow
            from={SEC(1.0)}
            path="M 850 1200 Q 700 1400, 540 1550"
            color={C.red}
            arrowAt={{x: 540, y: 1550, rotate: 115}}
          />
        </Paper>
        <Audio src={staticFile('sfx/nope.mp3')} />
      </Sequence>

      {/* Act 6 (12.5-15s): Chapter Three — Sift arrives */}
      <Sequence from={SEC(12.5)} durationInFrames={SEC(2.5)}>
        <Paper>
          <div style={{position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: 60, gap: 20}}>
            <div style={{fontFamily: 'serif', fontSize: 28, color: C.inkSoft, fontStyle: 'italic', letterSpacing: 4}}>
              — CHAPTER THREE —
            </div>
            <div
              style={{
                fontFamily: 'serif',
                fontSize: 200,
                color: C.teal,
                fontWeight: 900,
                lineHeight: 1,
                letterSpacing: -6,
                textAlign: 'center',
              }}
            >
              A Resolution.
            </div>
            <div style={{fontFamily: FONT, fontSize: 32, color: C.inkSoft, fontWeight: 500, fontStyle: 'italic', marginTop: 10}}>
              Enter: Sift.
            </div>
          </div>
        </Paper>
        <Audio src={staticFile('sfx/whoosh.mp3')} />
      </Sequence>

      {/* Act 7 (15-18s): the address, revealed — with hand-drawn underline */}
      <Sequence from={SEC(15)} durationInFrames={SEC(3)}>
        <Paper>
          <div style={{position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: 60, gap: 30}}>
            <div
              style={{
                fontFamily: FONT,
                fontSize: 28,
                color: C.inkSoft,
                fontWeight: 700,
                letterSpacing: 4,
              }}
            >
              RECOVERED FROM YOUR GALLERY
            </div>
            <div
              style={{
                fontFamily: 'serif',
                fontSize: 120,
                color: C.ink,
                fontWeight: 900,
                lineHeight: 1,
                letterSpacing: -3,
                textAlign: 'center',
              }}
            >
              14b Allen Avenue,
              <br />
              <span style={{color: C.red}}>Ikeja.</span>
            </div>
            <div style={{fontFamily: 'serif', fontSize: 40, fontStyle: 'italic', color: C.teal, textAlign: 'center'}}>
              opposite GTBank &middot; blue gate
            </div>
          </div>
          <HandArrow
            from={SEC(1.5)}
            path="M 180 1300 Q 400 1400, 540 1420"
            color={C.gold}
            arrowAt={{x: 540, y: 1420, rotate: 15}}
          />
          <MarginNote
            from={SEC(0.8)}
            pos="top-right"
            label="LANDMARK"
            text="The blue gate. You screenshot ted it. You forgot."
          />
        </Paper>
        <Audio src={staticFile('sfx/chime-win.mp3')} />
      </Sequence>

      {/* Act 8 (18-21s): "Six minute route" */}
      <Sequence from={SEC(18)} durationInFrames={SEC(3)}>
        <Paper>
          <div style={{position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: 60, gap: 10}}>
            <div style={{fontFamily: 'serif', fontSize: 44, fontStyle: 'italic', color: C.inkSoft, letterSpacing: 2}}>
              route set &middot; a mere
            </div>
            <BigNumeral num="6" from={SEC(0.2)} color={C.teal} size={600} />
            <div style={{fontFamily: FONT, fontSize: 48, color: C.ink, fontWeight: 900, letterSpacing: 6, marginTop: 10}}>
              MINUTES AWAY
            </div>
          </div>
          <MarginNote
            from={SEC(0.6)}
            pos="bottom-right"
            label="OUTCOME"
            text="You arrive. On time. Mrs. Adebayo smiles."
          />
        </Paper>
        <Audio src={staticFile('sfx/pop.mp3')} />
      </Sequence>

      {/* Act 9 (21-24s): end lockup */}
      <Sequence from={SEC(21)} durationInFrames={SEC(3)}>
        <Paper>
          <div style={{position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: 60}}>
            <EndCard tagline="They sent it. Just ask Sift." />
          </div>
        </Paper>
        <Audio src={staticFile('sfx/chime-win.mp3')} />
      </Sequence>
    </AbsoluteFill>
  );
};
