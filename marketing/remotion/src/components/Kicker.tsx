import React from 'react';
import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {theme, fonts} from '../theme';

/// The "punch line" text card that lands the beat. Every ad ends on one
/// of these. Slides up + fades in on a spring so the resolution feels
/// definitive rather than soft.
export const Kicker: React.FC<{
  eyebrow?: string;
  headline: string;
  sub?: string;
  align?: 'center' | 'left';
  color?: string;
  from?: number; // start frame (relative to whatever Sequence it's in)
}> = ({
  eyebrow,
  headline,
  sub,
  align = 'center',
  color = theme.textPrimary,
  from = 0,
}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 18, stiffness: 130, mass: 0.7}});
  const y = interpolate(s, [0, 1], [30, 0]);
  const op = interpolate(s, [0, 1], [0, 1]);
  return (
    <div
      style={{
        opacity: op,
        transform: `translateY(${y}px)`,
        textAlign: align,
        fontFamily: fonts.ui,
        color,
        display: 'flex',
        flexDirection: 'column',
        alignItems: align === 'center' ? 'center' : 'flex-start',
        gap: 10,
      }}
    >
      {eyebrow && (
        <div
          style={{
            fontSize: 22,
            fontWeight: 600,
            color: theme.textSecondary,
            letterSpacing: 2,
            textTransform: 'uppercase',
          }}
        >
          {eyebrow}
        </div>
      )}
      <div
        style={{
          fontSize: 84,
          fontWeight: 800,
          lineHeight: 1.05,
          letterSpacing: -1.5,
          maxWidth: 1400,
        }}
      >
        {headline}
      </div>
      {sub && (
        <div
          style={{
            fontSize: 30,
            fontWeight: 500,
            color: theme.textSecondary,
            marginTop: 8,
            maxWidth: 1000,
          }}
        >
          {sub}
        </div>
      )}
    </div>
  );
};
