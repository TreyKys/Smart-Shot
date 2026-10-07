import React from 'react';
import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {FONT} from '../theme';

// ─────────────────────────────────────────────────────────────────────────
// KINETIC PRIMITIVES
// ─────────────────────────────────────────────────────────────────────────
// Shared building blocks for the fast-cut, kinetic-typography ads
// (TheAlertRemix etc.) — distinct from the editorial Headline/Body
// primitives in type.tsx. These are built for 1-second-and-under beats:
// pop in hard, read in 500ms, cut away. No restraint.
// ─────────────────────────────────────────────────────────────────────────

/// Full-bleed vibrant background, optionally with a subtle grain overlay
/// via a stacked radial gradient. Children render centered on top.
export const Block: React.FC<{
  color: string;
  children?: React.ReactNode;
  justify?: React.CSSProperties['justifyContent'];
  align?: React.CSSProperties['alignItems'];
}> = ({color, children, justify = 'center', align = 'center'}) => (
  <div
    style={{
      position: 'absolute',
      inset: 0,
      background: color,
      display: 'flex',
      justifyContent: justify,
      alignItems: align,
      padding: 60,
      overflow: 'hidden',
    }}
  >
    {children}
  </div>
);

/// Massive single-word stab — scales from 0 with overshoot, slight rotate.
export const Stab: React.FC<{
  children: React.ReactNode;
  from?: number;
  size?: number;
  color?: string;
  weight?: number;
  italic?: boolean;
  rotate?: number;
  mono?: boolean;
}> = ({
  children,
  from = 0,
  size = 300,
  color = '#000',
  weight = 900,
  italic = false,
  rotate = 0,
  mono = false,
}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 11, stiffness: 180, mass: 0.5}});
  const sc = interpolate(s, [0, 1], [0.3, 1]);
  const op = interpolate(s, [0, 1], [0, 1]);
  return (
    <div
      style={{
        opacity: op,
        transform: `scale(${sc}) rotate(${rotate}deg)`,
        fontFamily: mono ? 'monospace' : FONT,
        fontSize: size,
        fontWeight: weight,
        fontStyle: italic ? 'italic' : 'normal',
        color,
        lineHeight: 0.9,
        letterSpacing: size > 200 ? -size * 0.04 : -size * 0.02,
        textAlign: 'center',
        textTransform: 'none',
      }}
    >
      {children}
    </div>
  );
};

/// Letter-by-letter cascading enter — fires one letter every `each` frames.
export const Cascade: React.FC<{
  text: string;
  from?: number;
  size?: number;
  color?: string;
  weight?: number;
  each?: number;
  letterSpacing?: number;
}> = ({
  text,
  from = 0,
  size = 220,
  color = '#000',
  weight = 900,
  each = 2,
  letterSpacing,
}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  return (
    <div
      style={{
        display: 'flex',
        gap: 0,
        fontFamily: FONT,
        justifyContent: 'center',
        letterSpacing: letterSpacing ?? -size * 0.03,
      }}
    >
      {text.split('').map((ch, i) => {
        const s = spring({
          frame: frame - i * each,
          fps,
          config: {damping: 10, stiffness: 220, mass: 0.4},
        });
        const op = interpolate(s, [0, 1], [0, 1]);
        const y = interpolate(s, [0, 1], [40, 0]);
        return (
          <span
            key={i}
            style={{
              opacity: op,
              transform: `translateY(${y}px)`,
              fontSize: size,
              fontWeight: weight,
              color,
              lineHeight: 0.9,
              display: 'inline-block',
            }}
          >
            {ch === ' ' ? ' ' : ch}
          </span>
        );
      })}
    </div>
  );
};

/// Tabular-nums big-number display with a slam-in.
export const Slam: React.FC<{
  children: React.ReactNode;
  from?: number;
  size?: number;
  color?: string;
  mono?: boolean;
}> = ({children, from = 0, size = 400, color = '#000', mono = true}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 8, stiffness: 240, mass: 0.6}});
  const sc = interpolate(s, [0, 1], [1.6, 1]);
  const op = interpolate(s, [0, 1], [0, 1]);
  const blur = interpolate(s, [0, 0.6, 1], [20, 2, 0]);
  return (
    <div
      style={{
        opacity: op,
        transform: `scale(${sc})`,
        filter: `blur(${blur}px)`,
        fontFamily: mono ? 'monospace' : FONT,
        fontVariantNumeric: 'tabular-nums',
        fontSize: size,
        fontWeight: 900,
        color,
        letterSpacing: -size * 0.04,
        lineHeight: 0.9,
      }}
    >
      {children}
    </div>
  );
};

/// Horizontal highlighter sweep across text — used for emphasis beats.
export const Highlight: React.FC<{
  children: React.ReactNode;
  from?: number;
  size?: number;
  color?: string;
  bgColor?: string;
  weight?: number;
}> = ({
  children,
  from = 0,
  size = 120,
  color = '#000',
  bgColor = '#FFEB3B',
  weight = 700,
}) => {
  const frame = useCurrentFrame() - from;
  const draw = interpolate(frame, [0, 20], [0, 100], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <span
      style={{
        fontFamily: FONT,
        fontSize: size,
        fontWeight: weight,
        color,
        background: `linear-gradient(to right, ${bgColor} ${draw}%, transparent ${draw}%)`,
        padding: '0 8px',
        letterSpacing: -size * 0.02,
      }}
    >
      {children}
    </span>
  );
};

/// Short-lived flash — a solid-color frame between cuts.
/// Child Sequence should be 2-4 frames at most.
export const Flash: React.FC<{color?: string}> = ({color = '#fff'}) => (
  <div style={{position: 'absolute', inset: 0, background: color}} />
);

/// Half-and-half color-block split — top/bottom with hard edge.
export const Split: React.FC<{
  topColor: string;
  bottomColor: string;
  topChildren?: React.ReactNode;
  bottomChildren?: React.ReactNode;
}> = ({topColor, bottomColor, topChildren, bottomChildren}) => (
  <div style={{position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column'}}>
    <div
      style={{
        flex: 1,
        background: topColor,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 40,
      }}
    >
      {topChildren}
    </div>
    <div
      style={{
        flex: 1,
        background: bottomColor,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 40,
      }}
    >
      {bottomChildren}
    </div>
  </div>
);

/// Ransom-note style word collection — each word on its own line with wildly
/// varying size/weight/rotation.
export const Ransom: React.FC<{
  words: Array<{text: string; size: number; weight?: number; italic?: boolean; color?: string; rotate?: number}>;
  from?: number;
  each?: number;
}> = ({words, from = 0, each = 4}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  return (
    <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10}}>
      {words.map((w, i) => {
        const s = spring({
          frame: frame - i * each,
          fps,
          config: {damping: 10, stiffness: 220, mass: 0.5},
        });
        const op = interpolate(s, [0, 1], [0, 1]);
        const sc = interpolate(s, [0, 1], [0.5, 1]);
        return (
          <div
            key={i}
            style={{
              opacity: op,
              transform: `scale(${sc}) rotate(${w.rotate ?? 0}deg)`,
              fontFamily: FONT,
              fontSize: w.size,
              fontWeight: w.weight ?? 900,
              fontStyle: w.italic ? 'italic' : 'normal',
              color: w.color ?? '#000',
              lineHeight: 0.95,
              letterSpacing: -w.size * 0.03,
            }}
          >
            {w.text}
          </div>
        );
      })}
    </div>
  );
};

/// Mask-reveal — a solid color wipe horizontally across the children.
export const WipeIn: React.FC<{
  children: React.ReactNode;
  from?: number;
  direction?: 'ltr' | 'rtl';
  duration?: number;
}> = ({children, from = 0, direction = 'ltr', duration = 18}) => {
  const frame = useCurrentFrame() - from;
  const p = interpolate(frame, [0, duration], [0, 100], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const clipPath =
    direction === 'ltr' ? `inset(0 ${100 - p}% 0 0)` : `inset(0 0 0 ${100 - p}%)`;
  return <div style={{clipPath}}>{children}</div>;
};

/// Grid of pulsing noise squares — kinetic texture background.
export const DotGrid: React.FC<{color?: string; cells?: number}> = ({
  color = 'rgba(255,255,255,0.1)',
  cells = 10,
}) => {
  const frame = useCurrentFrame();
  return (
    <div
      style={{
        position: 'absolute',
        inset: 0,
        display: 'grid',
        gridTemplateColumns: `repeat(${cells}, 1fr)`,
        gridTemplateRows: `repeat(${cells * 2}, 1fr)`,
        gap: 20,
        padding: 40,
      }}
    >
      {Array.from({length: cells * cells * 2}).map((_, i) => {
        const t = ((frame + i * 2) % 60) / 60;
        const op = 0.1 + 0.3 * Math.abs(Math.sin(t * Math.PI));
        return (
          <div
            key={i}
            style={{
              background: color,
              borderRadius: '50%',
              opacity: op,
            }}
          />
        );
      })}
    </div>
  );
};

/// Palette — vibrant backgrounds the kinetic ads rotate through.
export const K = {
  // Signals
  acid: '#B8FF00',
  pink: '#FF2E88',
  blood: '#FF2D2D',
  cobalt: '#0040FF',
  tangerine: '#FF6B1A',
  violet: '#8B2FE0',
  limeNeon: '#DEFF2B',
  teal: '#00D4C8',
  // Base
  paperOff: '#F6F3E8',
  blackMatte: '#111111',
  // Accents
  yellow: '#FFEB3B',
  deepRed: '#9F1A1A',
};
