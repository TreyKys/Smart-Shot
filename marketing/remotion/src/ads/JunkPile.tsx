import React from 'react';
import {AbsoluteFill, Sequence, interpolate, useCurrentFrame} from 'remotion';
import {c, SEC} from '../theme';
import {Stage} from '../components/Stage';
import {Eyebrow, Headline, Body} from '../components/type';
import {Chip} from '../components/Chip';
import {Card} from '../components/cards';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 3 · "Clear the clutter" · 20s · 16:9
// The junk you saved once and never opened again. A grid of it fills the
// dark canvas, then a clean "review" card sorts keep/delete.
// ─────────────────────────────────────────────────────────────────────────

const JUNK = [
  'expired coupon',
  'a meme',
  'blurry photo',
  'old boarding pass',
  'a link, once',
  'someone\'s story',
  'blank screen',
  'a menu',
  'wifi password',
  'a meme, again',
  'sale, ended',
  'screenshot of a text',
];

const JunkGrid: React.FC = () => (
  <div
    style={{
      display: 'grid',
      gridTemplateColumns: 'repeat(4, 1fr)',
      gap: 20,
      width: 1400,
    }}
  >
    {JUNK.map((label, i) => (
      <Chip key={label + i} label={label} from={SEC(0.2) + i * 5} onDark />
    ))}
  </div>
);

const ReviewRow: React.FC<{
  from: number;
  label: string;
  action: string;
  color: string;
}> = ({from, label, action, color}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 12], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const x = interpolate(frame, [0, 12], [16, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        opacity: op,
        transform: `translateX(${x}px)`,
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '16px 22px',
        borderRadius: 16,
        background: c.paper,
        border: `1.5px solid ${c.line}`,
      }}
    >
      <span style={{fontSize: 27, fontWeight: 600, color: c.ink}}>{label}</span>
      <span
        style={{
          fontSize: 20,
          fontWeight: 700,
          color,
          letterSpacing: 1,
          textTransform: 'uppercase',
        }}
      >
        {action}
      </span>
    </div>
  );
};

// A tidy "review" card: a stack of rows, each resolving to Keep or Delete.
const ReviewCard: React.FC<{from: number}> = ({from}) => {
  const rows = [
    {label: 'expired coupon', action: 'Delete', color: c.danger},
    {label: 'a meme', action: 'Delete', color: c.danger},
    {label: 'wifi password', action: 'Keep', color: c.success},
    {label: 'blank screen', action: 'Delete', color: c.danger},
  ];
  return (
    <Card from={from} width={720}>
      <div style={{display: 'flex', flexDirection: 'column', gap: 14}}>
        {rows.map((r, i) => (
          <ReviewRow
            key={r.label}
            from={from + SEC(0.6) + i * 8}
            label={r.label}
            action={r.action}
            color={r.color}
          />
        ))}
      </div>
    </Card>
  );
};

export const JunkPile: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Beat 1 (0-3.5s) */}
      <Sequence from={0} durationInFrames={SEC(3.7)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 26}}>
            <Eyebrow from={SEC(0.2)}>saved once. opened never.</Eyebrow>
            <Headline from={SEC(0.5)}>your camera roll's basement.</Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Beat 2 (3.5-9.5s): the junk fills the dark canvas */}
      <Sequence from={SEC(3.5)} durationInFrames={SEC(6)}>
        <Stage dark pad={80}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 44}}>
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>
              hundreds of them, quietly piling up
            </Eyebrow>
            <JunkGrid />
          </div>
        </Stage>
      </Sequence>

      {/* Beat 3 (9.5-15.5s): review card sorts it */}
      <Sequence from={SEC(9.5)} durationInFrames={SEC(6)}>
        <Stage>
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              width: '100%',
              maxWidth: 1680,
              gap: 80,
            }}
          >
            <div style={{flexShrink: 0}}>
              <Eyebrow from={SEC(0.3)} align="left">one sitting</Eyebrow>
              <div style={{height: 18}} />
              <Headline from={SEC(0.5)} align="left" size={104} maxWidth={720}>
                clear it all in a coffee break.
              </Headline>
            </div>
            <ReviewCard from={SEC(1)} />
          </div>
        </Stage>
      </Sequence>

      {/* Beat 4 (15.5-20s) */}
      <Sequence from={SEC(15.5)} durationInFrames={SEC(4.5)}>
        <Stage>
          <EndCard from={SEC(0.3)} tagline="Review the junk. Keep what matters." />
        </Stage>
      </Sequence>
    </AbsoluteFill>
  );
};
