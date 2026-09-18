import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';

/// Common animation primitives so ad code reads as intent, not math.
/// Every one takes a "from" frame so a Sequence child can time its own
/// entrance from within its Sequence-local frame zero.

export function useSpringIn(from = 0, cfg = {damping: 18, stiffness: 130, mass: 0.7}) {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  return spring({frame, fps, config: cfg});
}

export function useFadeIn(from = 0, duration = 15) {
  const frame = useCurrentFrame() - from;
  return interpolate(frame, [0, duration], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
}

export function useFadeOut(from: number, duration = 15) {
  const frame = useCurrentFrame() - from;
  return interpolate(frame, [0, duration], [1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
}

/// Compose fade-in then fade-out into one opacity — useful for overlays
/// that appear, hold, then leave without needing two Sequences.
export function useFadeInOut(
  enterAt: number,
  leaveAt: number,
  fade = 12,
): number {
  const inOp = useFadeIn(enterAt, fade);
  const outOp = useFadeOut(leaveAt, fade);
  return Math.min(inOp, outOp);
}
