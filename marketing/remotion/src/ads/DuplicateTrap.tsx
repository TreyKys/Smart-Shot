import React from 'react';
import {AbsoluteFill, Sequence, interpolate, useCurrentFrame} from 'remotion';
import {c, SEC, FONT} from '../theme';
import {Stage} from '../components/Stage';
import {Eyebrow, Headline} from '../components/type';
import {Card, Tile} from '../components/cards';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 2 · "Keep the best, lose the rest" · 20s · 16:9
// "Just one more, in case it's blurry" → five near-identical shots →
// storage bloat → Sift finds the set, keeps one.
// ─────────────────────────────────────────────────────────────────────────

const Counter: React.FC<{from: number; to: number; suffix: string; color: string; size: number}> = ({
  from,
  to,
  suffix,
  color,
  size,
}) => {
  const frame = useCurrentFrame() - from;
  const v = interpolate(frame, [0, SEC(1.6)], [0, to], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <span style={{fontFamily: FONT, fontWeight: 800, fontSize: size, color, fontVariantNumeric: 'tabular-nums', letterSpacing: -size * 0.03}}>
      {Math.round(v)}
      {suffix}
    </span>
  );
};

const IdenticalRow: React.FC<{from: number}> = ({from}) => {
  return (
    <div style={{display: 'flex', gap: 18}}>
      {[0, 1, 2, 3, 4].map((i) => (
        <Tile key={i} from={from + i * 5} hue={c.accentBright} w={150} ratio={1.4} onDark />
      ))}
    </div>
  );
};

const CleanupRow: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  // 4 of 5 fade at ~1.5s, one remains with a check.
  const kill = interpolate(frame, [SEC(1.5), SEC(2.2)], [1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div style={{display: 'flex', gap: 18, alignItems: 'center'}}>
      {[0, 1, 2, 3, 4].map((i) => (
        <div
          key={i}
          style={{
            opacity: i === 0 ? 1 : kill,
            position: 'relative',
            borderRadius: 20,
            padding: 5,
            border: `2px solid ${i === 0 ? c.success : c.danger}`,
          }}
        >
          <Tile from={from + i * 4} hue={i === 0 ? c.success : c.accentBright} w={150} ratio={1.4} />
        </div>
      ))}
    </div>
  );
};

export const DuplicateTrap: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Beat 1 (0-3.5s) */}
      <Sequence from={0} durationInFrames={SEC(3.7)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 26}}>
            <Eyebrow from={SEC(0.2)}>you, taking "just one more"</Eyebrow>
            <Headline from={SEC(0.5)}>did it come out blurry?</Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Beat 2 (3.5-9.5s): five identical + storage climbing (dark) */}
      <Sequence from={SEC(3.5)} durationInFrames={SEC(6)}>
        <Stage dark>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 44}}>
            <IdenticalRow from={SEC(0.3)} />
            <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8}}>
              <Counter from={SEC(1.6)} to={27} suffix=" GB" color={c.danger} size={130} />
              <Eyebrow from={SEC(1.8)} color={c.onNavySoft}>
                wasted on duplicates
              </Eyebrow>
            </div>
          </div>
        </Stage>
      </Sequence>

      {/* Beat 3 (9.5-15.5s): headline + cleanup (light) */}
      <Sequence from={SEC(9.5)} durationInFrames={SEC(6)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 40}}>
            <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14}}>
              <Eyebrow from={SEC(0.2)}>sift found the set</Eyebrow>
              <Headline from={SEC(0.4)} size={110}>keep the best. lose the rest.</Headline>
            </div>
            <CleanupRow from={SEC(1.2)} />
          </div>
        </Stage>
      </Sequence>

      {/* Beat 4 (15.5-20s) */}
      <Sequence from={SEC(15.5)} durationInFrames={SEC(4.5)}>
        <Stage>
          <EndCard from={SEC(0.3)} tagline="Spot duplicates. Reclaim your storage." />
        </Stage>
      </Sequence>
    </AbsoluteFill>
  );
};
