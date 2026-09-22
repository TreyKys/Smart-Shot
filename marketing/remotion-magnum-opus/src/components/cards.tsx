import React from 'react';
import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {c, FONT} from '../theme';

// ── Card base ────────────────────────────────────────────────────────────
export const Card: React.FC<{
  children: React.ReactNode;
  from?: number;
  width?: number;
  pad?: number;
  onDark?: boolean;
  tilt?: number;
}> = ({children, from = 0, width = 720, pad = 40, onDark = false, tilt = 0}) => {
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

// ── DocumentPage ─────────────────────────────────────────────────────────
// A rendered "page" — a mini page mock with a header, filled body lines,
// and a "Page N" footer. Used when a beat needs to look like a document.
export const DocumentPage: React.FC<{
  from?: number;
  pageNum: number;
  title?: string;
  lines?: number;
  width?: number;
  onDark?: boolean;
  highlight?: {line: number; text: string};
}> = ({from = 0, pageNum, title, lines = 8, width = 380, onDark, highlight}) => {
  const faint = onDark ? c.navyLine : c.lineSoft;
  return (
    <Card from={from} width={width} pad={26} onDark={onDark}>
      {title && (
        <div
          style={{
            fontWeight: 700,
            fontSize: 26,
            color: onDark ? c.onNavy : c.ink,
            marginBottom: 16,
          }}
        >
          {title}
        </div>
      )}
      <div style={{display: 'flex', flexDirection: 'column', gap: 10}}>
        {Array.from({length: lines}).map((_, i) => {
          const isHi = highlight?.line === i;
          return (
            <div key={i} style={{display: 'flex', flexDirection: 'column'}}>
              {isHi && highlight ? (
                <div
                  style={{
                    padding: '6px 8px',
                    borderRadius: 6,
                    background: c.accentWash,
                    color: c.accent,
                    fontSize: 15,
                    fontWeight: 700,
                    lineHeight: 1.35,
                  }}
                >
                  {highlight.text}
                </div>
              ) : (
                <div
                  style={{
                    height: 12,
                    borderRadius: 999,
                    background: faint,
                    width: `${60 + ((i * 17) % 40)}%`,
                  }}
                />
              )}
            </div>
          );
        })}
      </div>
      <div
        style={{
          marginTop: 24,
          paddingTop: 14,
          borderTop: `1.5px solid ${onDark ? c.navyLine : c.line}`,
          fontSize: 16,
          fontWeight: 700,
          letterSpacing: 2,
          textTransform: 'uppercase',
          color: onDark ? c.onNavySoft : c.inkFaint,
          textAlign: 'right',
        }}
      >
        Page {pageNum}
      </div>
    </Card>
  );
};

// ── CitedAnswer ──────────────────────────────────────────────────────────
// The hero card for Magnum Opus. A user question, an answer, and a cited
// page chip — the differentiator the existing HTML ads already lean on
// (see the .cite-chip class in marketing/ad_v3_context/index.html).
export const CitedAnswer: React.FC<{
  from?: number;
  query: React.ReactNode;
  answer: React.ReactNode;
  cite?: string;
  width?: number;
  onDark?: boolean;
}> = ({from = 0, query, answer, cite, width = 800, onDark}) => {
  const frame = useCurrentFrame();
  const answerAt = from + 22;
  const answerOp = interpolate(frame, [answerAt, answerAt + 16], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const chipAt = from + 44;
  const chipOp = interpolate(frame, [chipAt, chipAt + 14], [0, 1], {
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
        <span style={{fontSize: 28, fontWeight: 500, color: onDark ? c.onNavy : c.ink}}>
          {query}
        </span>
      </div>
      <div
        style={{
          opacity: answerOp,
          marginTop: 22,
          fontSize: 32,
          fontWeight: 600,
          lineHeight: 1.45,
          color: onDark ? c.onNavy : c.ink,
        }}
      >
        {answer}
      </div>
      {cite && (
        <div style={{opacity: chipOp, marginTop: 18}}>
          <span
            style={{
              display: 'inline-block',
              padding: '8px 18px',
              borderRadius: 999,
              background: c.accentWash,
              color: c.accent,
              fontSize: 20,
              fontWeight: 700,
              letterSpacing: 0.5,
            }}
          >
            {cite}
          </span>
        </div>
      )}
    </Card>
  );
};

// ── Compact chip (used in "wrong-word" moment beats) ────────────────────
export const Chip: React.FC<{
  label: string;
  from?: number;
  wrong?: boolean;
  onDark?: boolean;
}> = ({label, from = 0, wrong = false, onDark = false}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 22, stiffness: 130, mass: 0.6}});
  const op = interpolate(s, [0, 1], [0, 1]);
  const y = interpolate(s, [0, 1], [12, 0]);
  return (
    <div
      style={{
        opacity: op,
        transform: `translateY(${y}px)`,
        padding: '16px 26px',
        borderRadius: 14,
        background: onDark ? c.navyCard : c.card,
        border: `1.5px solid ${wrong ? c.danger : onDark ? c.navyLine : c.line}`,
        color: wrong ? c.danger : onDark ? c.onNavy : c.ink,
        fontFamily: FONT,
        fontWeight: 600,
        fontSize: 26,
        textAlign: 'center',
        display: 'inline-flex',
        alignItems: 'center',
        gap: 12,
      }}
    >
      {label}
      {wrong && (
        <span style={{fontSize: 22, color: c.danger, fontWeight: 800}}>×</span>
      )}
    </div>
  );
};
