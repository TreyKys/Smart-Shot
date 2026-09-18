import React from 'react';
import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {theme, fonts} from '../theme';

/// Sift wordmark — a springed-in logo lockup for CTA / end frames. Simple
/// on purpose; a logo that has to prove it's sophisticated with animation
/// tricks stops being a logo.
export const Logo: React.FC<{
  size?: number;
  from?: number;
  tagline?: string;
}> = ({size = 120, from = 0, tagline}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 14, stiffness: 100, mass: 0.6}});
  const scale = interpolate(s, [0, 1], [0.7, 1]);
  const op = interpolate(s, [0, 1], [0, 1]);
  return (
    <div
      style={{
        opacity: op,
        transform: `scale(${scale})`,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 16,
      }}
    >
      <div style={{display: 'flex', alignItems: 'center', gap: 18}}>
        <div
          style={{
            width: size * 0.75,
            height: size * 0.75,
            borderRadius: size * 0.2,
            background: `linear-gradient(135deg, ${theme.accent}, ${theme.accentDim})`,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: `0 12px 30px ${theme.accent}55`,
          }}
        >
          <div
            style={{
              width: size * 0.35,
              height: size * 0.35,
              borderRadius: '50%',
              border: `${Math.max(3, size * 0.05)}px solid #fff`,
              borderTopColor: 'transparent',
              transform: 'rotate(45deg)',
            }}
          />
        </div>
        <div
          style={{
            fontFamily: fonts.ui,
            fontSize: size,
            fontWeight: 800,
            color: theme.textPrimary,
            letterSpacing: -3,
            lineHeight: 1,
          }}
        >
          Sift
        </div>
      </div>
      {tagline && (
        <div
          style={{
            fontFamily: fonts.ui,
            fontSize: size * 0.28,
            color: theme.textSecondary,
            fontWeight: 500,
            letterSpacing: 1,
          }}
        >
          {tagline}
        </div>
      )}
    </div>
  );
};
