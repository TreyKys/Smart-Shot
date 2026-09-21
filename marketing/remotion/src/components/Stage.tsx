import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';
import {c, ensureFonts} from '../theme';

// The canvas every beat sits on. Light "paper" by default; `dark` flips to
// the navy brand for full-bleed contrast beats. An optional crossfade lets a
// beat transition its own background from light→dark without a hard cut.
export const Stage: React.FC<{
  children: React.ReactNode;
  dark?: boolean;
  // If set, background crossfades from light to dark starting at this
  // Sequence-local frame over `fadeDur` frames.
  darkenFrom?: number;
  fadeDur?: number;
  pad?: number;
  justify?: React.CSSProperties['justifyContent'];
  align?: React.CSSProperties['alignItems'];
}> = ({
  children,
  dark = false,
  darkenFrom,
  fadeDur = 20,
  pad = 120,
  justify = 'center',
  align = 'center',
}) => {
  ensureFonts();
  const frame = useCurrentFrame();
  let bg = dark ? c.navy : c.paper;
  if (darkenFrom !== undefined) {
    const t = interpolate(frame, [darkenFrom, darkenFrom + fadeDur], [0, 1], {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
    });
    bg = t < 0.5 ? c.paper : c.navy; // hard-ish swap; content handles its own colors
    // Smooth blend via layering instead of color mixing:
    return (
      <AbsoluteFill>
        <AbsoluteFill style={{background: c.paper}} />
        <AbsoluteFill style={{background: c.navy, opacity: t}} />
        <AbsoluteFill
          style={{
            justifyContent: justify,
            alignItems: align,
            padding: pad,
          }}
        >
          {children}
        </AbsoluteFill>
      </AbsoluteFill>
    );
  }
  return (
    <AbsoluteFill
      style={{
        background: bg,
        justifyContent: justify,
        alignItems: align,
        padding: pad,
      }}
    >
      {children}
    </AbsoluteFill>
  );
};
