import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';
import {c, ensureFonts} from '../theme';

// Same canvas primitive Sift uses: light "paper" by default, `dark` flips
// to navy for full-bleed contrast beats. Registers the self-hosted Inter
// faces the first time any Stage renders.
export const Stage: React.FC<{
  children: React.ReactNode;
  dark?: boolean;
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
  if (darkenFrom !== undefined) {
    const t = interpolate(frame, [darkenFrom, darkenFrom + fadeDur], [0, 1], {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
    });
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
        background: dark ? c.navy : c.paper,
        justifyContent: justify,
        alignItems: align,
        padding: pad,
      }}
    >
      {children}
    </AbsoluteFill>
  );
};
