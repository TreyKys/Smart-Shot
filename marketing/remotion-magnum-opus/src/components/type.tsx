import React from 'react';
import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {c, FONT} from '../theme';

// Same typographic primitives Sift uses — deliberately identical so both
// apps' ads read as one design system.

export const Eyebrow: React.FC<{
  children: React.ReactNode;
  from?: number;
  color?: string;
  align?: 'center' | 'left';
}> = ({children, from = 0, color = c.inkFaint, align = 'center'}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 14], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        opacity: op,
        fontFamily: FONT,
        fontWeight: 600,
        fontSize: 22,
        letterSpacing: 4,
        textTransform: 'uppercase',
        color,
        textAlign: align,
      }}
    >
      {children}
    </div>
  );
};

export const Headline: React.FC<{
  children: React.ReactNode;
  from?: number;
  size?: number;
  color?: string;
  align?: 'center' | 'left';
  maxWidth?: number;
  weight?: number;
}> = ({
  children,
  from = 0,
  size = 130,
  color = c.ink,
  align = 'center',
  maxWidth = 1500,
  weight = 800,
}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 20, stiffness: 120, mass: 0.8}});
  const y = interpolate(s, [0, 1], [26, 0]);
  const op = interpolate(s, [0, 1], [0, 1]);
  return (
    <div
      style={{
        opacity: op,
        transform: `translateY(${y}px)`,
        fontFamily: FONT,
        fontWeight: weight,
        fontSize: size,
        lineHeight: 1.02,
        letterSpacing: -size * 0.03,
        color,
        textAlign: align,
        maxWidth,
      }}
    >
      {children}
    </div>
  );
};

export const Body: React.FC<{
  children: React.ReactNode;
  from?: number;
  size?: number;
  color?: string;
  align?: 'center' | 'left';
  maxWidth?: number;
  weight?: number;
}> = ({
  children,
  from = 0,
  size = 34,
  color = c.inkSoft,
  align = 'center',
  maxWidth = 1100,
  weight = 500,
}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 16], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const y = interpolate(frame, [0, 16], [14, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        opacity: op,
        transform: `translateY(${y}px)`,
        fontFamily: FONT,
        fontWeight: weight,
        fontSize: size,
        lineHeight: 1.4,
        color,
        textAlign: align,
        maxWidth,
      }}
    >
      {children}
    </div>
  );
};
