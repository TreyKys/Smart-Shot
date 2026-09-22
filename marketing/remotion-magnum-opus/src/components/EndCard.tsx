import React from 'react';
import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {c, FONT} from '../theme';

// Magnum Opus end lockup. Same structure as Sift's end card (squircle icon,
// wordmark, tagline, Google Play badge, maker credit) but wordmark reads
// "Magnum Opus" with "Opus" set in Inter italic 800 — a callback to the
// existing HTML ads' Fraunces italic treatment, without introducing a
// separate serif font. Editorial palette, no gold.
export const EndCard: React.FC<{
  from?: number;
  tagline?: string;
}> = ({from = 0, tagline = 'Every page. Every time. Remembered.'}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 18, stiffness: 110, mass: 0.7}});
  const op = interpolate(s, [0, 1], [0, 1]);
  const sc = interpolate(s, [0, 1], [0.9, 1]);
  const badgeOp = interpolate(frame, [18, 32], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

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
      <AppIcon />
      <div
        style={{
          display: 'flex',
          alignItems: 'baseline',
          gap: 14,
          fontSize: 60,
          color: c.ink,
          letterSpacing: -1.5,
        }}
      >
        <span style={{fontWeight: 800}}>Magnum</span>
        <span style={{fontWeight: 800, fontStyle: 'italic'}}>Opus</span>
      </div>
      <div
        style={{
          fontSize: 24,
          fontWeight: 500,
          color: c.inkFaint,
          marginTop: -8,
          maxWidth: 680,
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
        <GooglePlayBadge />
        <span style={{fontSize: 18, letterSpacing: 3, color: c.inkFaint, fontWeight: 600}}>
          NEURODEV LABS
        </span>
      </div>
    </div>
  );
};

// Squircle icon — a stylized "page corner" mark for Magnum Opus (a folded
// page edge on an ink tile), so the icon isn't a generic square.
const AppIcon: React.FC<{size?: number}> = ({size = 116}) => {
  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: size * 0.28,
        background: c.ink,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        boxShadow: '0 16px 40px rgba(15,22,38,0.2)',
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      {/* A stylized folded page — a rectangle with a corner triangle */}
      <div
        style={{
          width: size * 0.46,
          height: size * 0.56,
          borderRadius: 6,
          border: `3px solid ${c.accentBright}`,
          position: 'relative',
        }}
      >
        {/* folded top-right corner */}
        <div
          style={{
            position: 'absolute',
            top: -3,
            right: -3,
            width: size * 0.16,
            height: size * 0.16,
            background: c.ink,
            borderLeft: `3px solid ${c.accentBright}`,
            borderBottom: `3px solid ${c.accentBright}`,
          }}
        />
      </div>
    </div>
  );
};

const GooglePlayBadge: React.FC = () => {
  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        padding: '12px 22px',
        borderRadius: 14,
        background: c.ink,
        border: `1.5px solid ${c.ink}`,
      }}
    >
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
