import {AbsoluteFill, useCurrentFrame, interpolate} from 'remotion';
import {theme} from '../theme';

/// A subtle animated radial gradient behind every ad — drifts slowly enough
/// to feel alive without stealing attention from the copy on top. Two
/// tunable "hot spots" so an ad can dial in a color story (accent-only,
/// gold-tinged, danger-flare) without a bespoke background per ad.
export const BgGradient: React.FC<{
  from?: string;
  to?: string;
  intensity?: number;
}> = ({from = theme.accent, to = theme.bg, intensity = 0.35}) => {
  const frame = useCurrentFrame();
  const x = interpolate(frame, [0, 300], [30, 70]) % 100;
  const y = interpolate(frame, [0, 300], [40, 60]) % 100;
  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(circle at ${x}% ${y}%, ${from}${alpha(intensity)} 0%, ${to} 60%)`,
      }}
    />
  );
};

// Convert 0..1 intensity to a 2-digit hex alpha suffix for CSS 8-digit hex.
function alpha(v: number) {
  const clamped = Math.max(0, Math.min(1, v));
  const byte = Math.round(clamped * 255)
    .toString(16)
    .padStart(2, '0');
  return byte;
}
