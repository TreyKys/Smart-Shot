import React from 'react';
import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {c, FONT} from '../theme';

// ── Card container ───────────────────────────────────────────────────────
// The reference's floating white card with a soft shadow. Springs in with a
// slight lift + settle. Everything visual is built from this, so the ads
// read as one product — real UI, not clip-art.
export const Card: React.FC<{
  children: React.ReactNode;
  from?: number;
  width?: number;
  pad?: number;
  onDark?: boolean;
  tilt?: number;
}> = ({children, from = 0, width = 620, pad = 36, onDark = false, tilt = 0}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 22, stiffness: 110, mass: 0.9}});
  const op = interpolate(s, [0, 1], [0, 1]);
  const y = interpolate(s, [0, 1], [26, 0]);
  const sc = interpolate(s, [0, 1], [0.96, 1]);
  return (
    <div
      style={{
        opacity: op,
        transform: `translateY(${y}px) scale(${sc}) rotate(${tilt}deg)`,
        width,
        padding: pad,
        borderRadius: 28,
        background: onDark ? c.navyCard : c.card,
        border: `1.5px solid ${onDark ? c.navyLine : c.line}`,
        boxShadow: onDark
          ? '0 40px 80px rgba(0,0,0,0.5)'
          : '0 40px 90px rgba(15,22,38,0.12), 0 8px 24px rgba(15,22,38,0.06)',
        fontFamily: FONT,
      }}
    >
      {children}
    </div>
  );
};

// A line of "text" in a mock document — a filled bar. Width in %.
const Line: React.FC<{w: number; color?: string; h?: number}> = ({
  w,
  color = c.lineSoft,
  h = 14,
}) => (
  <div
    style={{
      width: `${w}%`,
      height: h,
      borderRadius: 999,
      background: color,
      marginBottom: 12,
    }}
  />
);

// ── Mock receipt ─────────────────────────────────────────────────────────
export const ReceiptCard: React.FC<{
  from?: number;
  width?: number;
  vendor?: string;
  total?: string;
  onDark?: boolean;
}> = ({from = 0, width = 300, vendor = 'UBER', total = '$24.80', onDark}) => {
  const faint = onDark ? c.navyLine : c.lineSoft;
  return (
    <Card from={from} width={width} pad={26} onDark={onDark}>
      <div
        style={{
          fontWeight: 700,
          fontSize: 26,
          color: onDark ? c.onNavy : c.ink,
          letterSpacing: 1,
          marginBottom: 18,
        }}
      >
        {vendor}
      </div>
      <Line w={80} color={faint} />
      <Line w={62} color={faint} />
      <Line w={72} color={faint} />
      <div
        style={{
          height: 1.5,
          background: onDark ? c.navyLine : c.line,
          margin: '16px 0',
        }}
      />
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'baseline',
        }}
      >
        <span style={{fontSize: 20, color: onDark ? c.onNavySoft : c.inkFaint, fontWeight: 600}}>
          TOTAL
        </span>
        <span style={{fontSize: 30, color: onDark ? c.onNavy : c.ink, fontWeight: 800}}>
          {total}
        </span>
      </div>
    </Card>
  );
};

// ── Mock chat / message thread ───────────────────────────────────────────
export const ChatCard: React.FC<{
  from?: number;
  width?: number;
  onDark?: boolean;
}> = ({from = 0, width = 300, onDark}) => {
  const them = onDark ? c.navyLine : c.lineSoft;
  return (
    <Card from={from} width={width} pad={22} onDark={onDark}>
      <div style={{display: 'flex', flexDirection: 'column', gap: 12}}>
        <Bubble w={70} align="left" color={them} />
        <Bubble w={55} align="right" color={c.accentBright} />
        <Bubble w={80} align="left" color={them} />
        <Bubble w={48} align="right" color={c.accentBright} />
      </div>
    </Card>
  );
};

const Bubble: React.FC<{w: number; align: 'left' | 'right'; color: string}> = ({
  w,
  align,
  color,
}) => (
  <div
    style={{
      alignSelf: align === 'left' ? 'flex-start' : 'flex-end',
      width: `${w}%`,
      height: 34,
      borderRadius: 18,
      background: color,
    }}
  />
);

// ── Photo / screenshot tile (abstract, no emoji) ─────────────────────────
// A soft gradient rectangle standing in for a screenshot. The gradient hue
// is the only differentiator — reads as "an image" without clip-art.
export const Tile: React.FC<{
  from?: number;
  hue?: string;
  w?: number;
  ratio?: number;
  onDark?: boolean;
}> = ({from = 0, hue = c.accentBright, w = 150, ratio = 1.5, onDark}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 22, stiffness: 130}});
  const op = interpolate(s, [0, 1], [0, 1]);
  const sc = interpolate(s, [0, 1], [0.9, 1]);
  return (
    <div
      style={{
        opacity: op,
        transform: `scale(${sc})`,
        width: w,
        height: w * ratio,
        borderRadius: 18,
        background: `linear-gradient(150deg, ${hue}26, ${hue}0d)`,
        border: `1.5px solid ${onDark ? c.navyLine : c.line}`,
      }}
    />
  );
};

// ── Search / ask result card ─────────────────────────────────────────────
// The hero interaction: a query line + a clean answer with one blue accent.
export const AskCard: React.FC<{
  from?: number;
  query: React.ReactNode;
  answer: React.ReactNode;
  width?: number;
  onDark?: boolean;
}> = ({from = 0, query, answer, width = 720, onDark}) => {
  const answerFrom = from + 22;
  const frame = useCurrentFrame();
  const answerOp = interpolate(frame, [answerFrom, answerFrom + 16], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <Card from={from} width={width} onDark={onDark}>
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 16,
          padding: '18px 22px',
          borderRadius: 18,
          background: onDark ? c.navy : c.paper,
          border: `1.5px solid ${onDark ? c.navyLine : c.line}`,
        }}
      >
        <div
          style={{
            width: 12,
            height: 12,
            borderRadius: 999,
            background: c.accentBright,
            flexShrink: 0,
          }}
        />
        <span
          style={{
            fontSize: 28,
            fontWeight: 500,
            color: onDark ? c.onNavy : c.ink,
          }}
        >
          {query}
        </span>
      </div>
      <div
        style={{
          opacity: answerOp,
          marginTop: 22,
          fontSize: 30,
          fontWeight: 600,
          lineHeight: 1.45,
          color: onDark ? c.onNavy : c.ink,
        }}
      >
        {answer}
      </div>
    </Card>
  );
};
