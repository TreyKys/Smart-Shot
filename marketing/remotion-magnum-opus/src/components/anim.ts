import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';

// Same tiny animation primitives Sift's ads use. `from` is Sequence-local
// throughout — do not pass composition-absolute frames.

export function useSpringIn(from = 0, cfg = {damping: 20, stiffness: 120, mass: 0.7}) {
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

export function useFadeInOut(enterAt: number, leaveAt: number, fade = 12): number {
  const inOp = useFadeIn(enterAt, fade);
  const outOp = useFadeOut(leaveAt, fade);
  return Math.min(inOp, outOp);
}
