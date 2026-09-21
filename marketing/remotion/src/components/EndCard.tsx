import React from 'react';
import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {c, FONT} from '../theme';

// Closing lockup, modeled on the reference's end frame: squircle app icon,
// product name, then a Google Play badge beside a tiny letter-spaced maker
// credit. Works on light or dark.
export const EndCard: React.FC<{
  from?: number;
  onDark?: boolean;
  tagline?: string;
}> = ({from = 0, onDark = false, tagline = 'The Context Dictionary for your screenshots'}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 18, stiffness: 110, mass: 0.7}});
  const op = interpolate(s, [0, 1], [0, 1]);
  const sc = interpolate(s, [0, 1], [0.9, 1]);
  const badgeOp = interpolate(frame, [18, 32], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const ink = onDark ? c.onNavy : c.ink;
  const faint = onDark ? c.onNavySoft : c.inkFaint;

  return (
    <div
      style={{
        opacity: op,
        transform: `scale(${sc})`,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 22,
        fontFamily: FONT,
      }}
    >
      <AppIcon onDark={onDark} />
      <div style={{fontSize: 52, fontWeight: 800, color: ink, letterSpacing: -1}}>
        Sift
      </div>
      <div
        style={{
          fontSize: 24,
          fontWeight: 500,
          color: faint,
          marginTop: -8,
          maxWidth: 640,
          textAlign: 'center',
          lineHeight: 1.35,
        }}
      >
        {tagline}
      </div>
      <div
        style={{
          opacity: badgeOp,
          display: 'flex',
          alignItems: 'center',
          gap: 20,
          marginTop: 10,
        }}
      >
        <GooglePlayBadge onDark={onDark} />
        <span style={{fontSize: 18, letterSpacing: 3, color: faint, fontWeight: 600}}>
          NEURODEV LABS
        </span>
      </div>
    </div>
  );
};

// Squircle icon — the Sift mark (a stylized lens/aperture ring) on a soft
// tile, echoing the reference's "C" tile but in Sift's own identity.
export const AppIcon: React.FC<{size?: number; onDark?: boolean}> = ({
  size = 108,
  onDark = false,
}) => {
  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: size * 0.28,
        background: onDark
          ? `linear-gradient(140deg, ${c.accentBright}, ${c.accent})`
          : c.ink,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        boxShadow: onDark ? 'none' : '0 16px 40px rgba(15,22,38,0.2)',
        position: 'relative',
      }}
    >
      <div
        style={{
          width: size * 0.42,
          height: size * 0.42,
          borderRadius: '50%',
          border: `${size * 0.07}px solid ${onDark ? '#fff' : c.accentBright}`,
          borderTopColor: 'transparent',
          transform: 'rotate(45deg)',
        }}
      />
    </div>
  );
};

const GooglePlayBadge: React.FC<{onDark?: boolean}> = ({onDark}) => {
  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        padding: '12px 22px',
        borderRadius: 14,
        background: onDark ? c.navyCard : c.ink,
        border: `1.5px solid ${onDark ? c.navyLine : c.ink}`,
      }}
    >
      {/* Play triangle */}
      <div
        style={{
          width: 0,
          height: 0,
          borderTop: '11px solid transparent',
          borderBottom: '11px solid transparent',
          borderLeft: `18px solid ${c.accentBright}`,
          marginRight: 2,
        }}
      />
      <div style={{display: 'flex', flexDirection: 'column', lineHeight: 1}}>
        <span style={{fontSize: 12, color: '#B9C2D4', letterSpacing: 1}}>GET IT ON</span>
        <span style={{fontSize: 22, color: '#fff', fontWeight: 700}}>Google Play</span>
      </div>
    </div>
  );
};
