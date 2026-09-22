import React from 'react';
import {AbsoluteFill, Sequence, interpolate, useCurrentFrame, useVideoConfig, spring} from 'remotion';
import {c, FONT, SEC} from '../theme';
import {Stage} from '../components/Stage';
import {Eyebrow, Headline, Body} from '../components/type';
import {Card, CitedAnswer} from '../components/cards';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 3 · "Stop reading it. Ask it." · 20s · 9:16
// The reframe: every dense doc you've ever needed to reference — the
// lease, the tax form, the manual, the syllabus — you don't have to reread
// them. You can just ask. Angle NOT covered by the existing 3 ads.
// ─────────────────────────────────────────────────────────────────────────

const DOCS = [
  'your lease',
  'the tax form',
  'the manual',
  'the syllabus',
  'the meeting notes',
  'the whitepaper',
  'the recipe book',
  'the medical form',
];

// A grid of "documents you've had to reread" — labeled cards, no icons,
// no emoji. Springs in staggered so it feels like a montage rather than
// a static slide.
const DocsGrid: React.FC<{from: number}> = ({from}) => {
  return (
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(2, 1fr)',
        gap: 20,
        width: 780,
      }}
    >
      {DOCS.map((label, i) => (
        <DocTile key={label} from={from + i * 5} label={label} />
      ))}
    </div>
  );
};

const DocTile: React.FC<{from: number; label: string}> = ({from, label}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 22, stiffness: 120, mass: 0.7}});
  const op = interpolate(s, [0, 1], [0, 1]);
  const y = interpolate(s, [0, 1], [14, 0]);
  return (
    <div
      style={{
        opacity: op,
        transform: `translateY(${y}px)`,
        display: 'flex',
        alignItems: 'center',
        gap: 18,
        padding: '22px 26px',
        background: c.card,
        border: `1.5px solid ${c.line}`,
        borderRadius: 18,
        boxShadow: '0 8px 22px rgba(15,22,38,0.06)',
        fontFamily: FONT,
      }}
    >
      {/* mini "page" mark — a folded corner, no emoji */}
      <div
        style={{
          width: 32,
          height: 40,
          borderRadius: 4,
          border: `2px solid ${c.accentBright}`,
          position: 'relative',
          flexShrink: 0,
        }}
      >
        <div
          style={{
            position: 'absolute',
            top: -2,
            right: -2,
            width: 12,
            height: 12,
            background: c.card,
            borderLeft: `2px solid ${c.accentBright}`,
            borderBottom: `2px solid ${c.accentBright}`,
          }}
        />
      </div>
      <span style={{fontSize: 30, fontWeight: 600, color: c.ink}}>{label}</span>
    </div>
  );
};

export const StopReading: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Beat 1 (0-3.5s): the setup */}
      <Sequence from={0} durationInFrames={SEC(3.7)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 26}}>
            <Eyebrow from={SEC(0.2)}>you've reread it three times</Eyebrow>
            <Headline from={SEC(0.4)} size={110}>you don't have to.</Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Beat 2 (3.5-9s): the grid of things you've reread */}
      <Sequence from={SEC(3.5)} durationInFrames={SEC(5.5)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 34}}>
            <Eyebrow from={SEC(0.2)}>every dense doc you've kept</Eyebrow>
            <DocsGrid from={SEC(0.4)} />
          </div>
        </Stage>
      </Sequence>

      {/* Beat 3 (9-15.5s): the reframe — a real question, a real answer */}
      <Sequence from={SEC(9)} durationInFrames={SEC(6.5)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 30}}>
            <Headline from={SEC(0.2)} size={110}>ask it instead.</Headline>
            <CitedAnswer
              from={SEC(0.8)}
              width={940}
              query="how much notice do i owe if i move out early?"
              answer={
                <span>
                  <span style={{color: c.accent}}>Two months' rent</span> as break-fee, plus 30 days' written notice.
                </span>
              }
              cite="Page 7, §12"
            />
          </div>
        </Stage>
      </Sequence>

      {/* Beat 4 (15.5-20s): end */}
      <Sequence from={SEC(15.5)} durationInFrames={SEC(4.5)}>
        <Stage>
          <EndCard from={SEC(0.3)} tagline="Stop rereading. Just ask." />
        </Stage>
      </Sequence>
    </AbsoluteFill>
  );
};
