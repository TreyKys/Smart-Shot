import React from 'react';
import {AbsoluteFill, Sequence} from 'remotion';
import {c, SEC} from '../theme';
import {Stage} from '../components/Stage';
import {Eyebrow, Headline, Body} from '../components/type';
import {Card, Tile} from '../components/cards';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 4 · "On this day" · 20s · 16:9
// The warm one. Screenshots you forgot you saved, resurfaced on the day
// they matter. Softer motion, gold accent instead of blue for warmth.
// ─────────────────────────────────────────────────────────────────────────

const MemoryCard: React.FC<{from: number; label: string; sub: string; hue: string}> = ({
  from,
  label,
  sub,
  hue,
}) => (
  <Card from={from} width={340} pad={0}>
    <div style={{padding: 0}}>
      <Tile from={from + 4} hue={hue} w={340 - 3} ratio={0.7} />
      <div style={{padding: '20px 24px'}}>
        <div
          style={{
            fontSize: 18,
            fontWeight: 700,
            letterSpacing: 2,
            textTransform: 'uppercase',
            color: c.gold,
            marginBottom: 8,
          }}
        >
          {sub}
        </div>
        <div style={{fontSize: 28, fontWeight: 700, color: c.ink}}>{label}</div>
      </div>
    </div>
  </Card>
);

export const MemoryLane: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Beat 1 (0-4s) */}
      <Sequence from={0} durationInFrames={SEC(4.2)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 26}}>
            <Eyebrow from={SEC(0.2)} color={c.gold}>two years ago today</Eyebrow>
            <Headline from={SEC(0.5)}>you forgot you saved this.</Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Beat 2 (4-14s): a row of resurfaced memories */}
      <Sequence from={SEC(4)} durationInFrames={SEC(10)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 44}}>
            <Eyebrow from={SEC(0.2)} color={c.gold}>on this day</Eyebrow>
            <div style={{display: 'flex', gap: 28}}>
              <MemoryCard from={SEC(0.6)} sub="3 years ago" label="A concert ticket" hue={c.accentBright} />
              <MemoryCard from={SEC(1.3)} sub="2 years ago" label="A note from a friend" hue={c.gold} />
              <MemoryCard from={SEC(2)} sub="4 years ago" label="A trip you took" hue={c.success} />
            </div>
          </div>
        </Stage>
      </Sequence>

      {/* Beat 3 (14-15.5s): the line */}
      <Sequence from={SEC(14)} durationInFrames={SEC(1.7)}>
        <Stage>
          <Headline from={SEC(0.2)} size={116}>Sift brings them back.</Headline>
        </Stage>
      </Sequence>

      {/* Beat 4 (15.5-20s) */}
      <Sequence from={SEC(15.5)} durationInFrames={SEC(4.5)}>
        <Stage>
          <EndCard from={SEC(0.3)} tagline="Every screenshot, remembered." />
        </Stage>
      </Sequence>
    </AbsoluteFill>
  );
};
