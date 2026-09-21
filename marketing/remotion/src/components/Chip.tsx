import React from 'react';
import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {c, FONT} from '../theme';

// A single soft-filled word chip — the reference's "escrow / amortisation /
// ARR" building blocks, here used for filenames, junk types, tag names, etc.
// No emoji, ever: real words carry the meaning.
export const Chip: React.FC<{
  label: string;
  from?: number;
  highlighted?: boolean;
  muted?: boolean;
  onDark?: boolean;
}> = ({label, from = 0, highlighted = false, muted = false, onDark = false}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 22, stiffness: 130, mass: 0.6}});
  const op = interpolate(s, [0, 1], [0, 1]) * (muted ? 0.4 : 1);
  const y = interpolate(s, [0, 1], [12, 0]);

  const bg = highlighted
    ? c.accentWash
    : onDark
      ? c.navyCard
      : c.card;
  const border = highlighted ? c.accentBright : onDark ? c.navyLine : c.line;
  const text = highlighted ? c.accent : onDark ? c.onNavy : c.ink;

  return (
    <div
      style={{
        opacity: op,
        transform: `translateY(${y}px)`,
        padding: '18px 30px',
        borderRadius: 16,
        background: bg,
        border: `1.5px solid ${border}`,
        color: text,
        fontFamily: FONT,
        fontWeight: highlighted ? 700 : 600,
        fontSize: 30,
        textAlign: 'center',
        boxShadow: onDark
          ? 'none'
          : highlighted
            ? `0 10px 30px ${c.accentBright}33`
            : '0 6px 18px rgba(15,22,38,0.05)',
        whiteSpace: 'nowrap',
      }}
    >
      {label}
    </div>
  );
};
