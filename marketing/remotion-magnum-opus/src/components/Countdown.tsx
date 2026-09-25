import React from 'react';
import {interpolate, useCurrentFrame} from 'remotion';
import {c, FONT} from '../theme';

// A live countdown clock — mm:ss counting down from a start value. The
// digits change roughly every 10 frames of screen time so the tick reads
// as "the seconds are really moving" not "static image with a fake time".
//
// Extracted here rather than left inline in one ad so The Night Before can
// use the same tick. MeetingPanic's own copy will fold into this one when
// touched next — for now they're byte-identical and the ad already reads
// the way it did, so there's no reason to churn its file.
export const Countdown: React.FC<{
  from: number;
  startSec: number;
  color?: string;
  size?: number;
}> = ({from, startSec, color = c.danger, size = 260}) => {
  const frame = useCurrentFrame() - from;
  const t = Math.max(0, startSec - Math.floor(frame / 10));
  const mm = Math.floor(t / 60)
    .toString()
    .padStart(2, '0');
  const ss = (t % 60).toString().padStart(2, '0');
  const op = interpolate(frame, [0, 14], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        opacity: op,
        fontFamily: FONT,
        fontVariantNumeric: 'tabular-nums',
        fontSize: size,
        fontWeight: 800,
        color,
        letterSpacing: -size * 0.038,
        lineHeight: 1,
      }}
    >
      {mm}:{ss}
    </div>
  );
};

// A live wall-clock (HH:MM) counting UP from a start hour/minute. Used
// where "how far into the night are you" is the emotional beat — the
// timestamp itself is the punch, not a countdown to a deadline.
export const WallClock: React.FC<{
  from: number;
  startHour: number;
  startMinute: number;
  advanceEvery?: number;
  color?: string;
  size?: number;
}> = ({
  from,
  startHour,
  startMinute,
  advanceEvery = 10,
  color = c.ink,
  size = 220,
}) => {
  const frame = useCurrentFrame() - from;
  const ticks = Math.max(0, Math.floor(frame / advanceEvery));
  const total = startHour * 60 + startMinute + ticks;
  const hh = Math.floor(total / 60) % 24;
  const mm = total % 60;
  const op = interpolate(frame, [0, 14], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        opacity: op,
        fontFamily: FONT,
        fontVariantNumeric: 'tabular-nums',
        fontSize: size,
        fontWeight: 800,
        color,
        letterSpacing: -size * 0.038,
        lineHeight: 1,
      }}
    >
      {hh.toString().padStart(2, '0')}:{mm.toString().padStart(2, '0')}
    </div>
  );
};
