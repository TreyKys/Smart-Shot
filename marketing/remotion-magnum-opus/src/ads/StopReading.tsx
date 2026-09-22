import React from 'react';
import {AbsoluteFill, Sequence, interpolate, useCurrentFrame, useVideoConfig, spring} from 'remotion';
import {c, FONT, SEC} from '../theme';
import {Stage} from '../components/Stage';
import {Eyebrow, Headline, Body} from '../components/type';
import {Card, CitedAnswer} from '../components/cards';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 3 · "Stop reading it. Ask it." · 60s · 9:16
// The reframe: every dense doc you've saved — you don't have to reread
// them. Ask instead. Three real everyday examples (lease, tax form,
// manual), then a stack of every other doc you've kept, then the payoff.
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
  'the terms of service',
  'the insurance policy',
];

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
      <span style={{fontSize: 28, fontWeight: 600, color: c.ink}}>{label}</span>
    </div>
  );
};

const DocsGrid: React.FC<{from: number}> = ({from}) => (
  <div
    style={{
      display: 'grid',
      gridTemplateColumns: 'repeat(2, 1fr)',
      gap: 18,
      width: 820,
    }}
  >
    {DOCS.map((label, i) => (
      <DocTile key={label} from={from + i * 4} label={label} />
    ))}
  </div>
);

export const StopReading: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Act 1 (0-5s): the setup */}
      <Sequence from={0} durationInFrames={SEC(5)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 26}}>
            <Eyebrow from={SEC(0.2)}>you've reread it three times</Eyebrow>
            <Headline from={SEC(0.4)} size={130}>and still.</Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 2 (5-10s): the pivot */}
      <Sequence from={SEC(5)} durationInFrames={SEC(5)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
            <Headline from={SEC(0.2)} size={140}>you don't have to.</Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 3 (10-18s): what "reread" looks like in real life */}
      <Sequence from={SEC(10)} durationInFrames={SEC(8)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 34}}>
            <Eyebrow from={SEC(0.2)}>every dense doc you've kept</Eyebrow>
            <DocsGrid from={SEC(0.4)} />
          </div>
        </Stage>
      </Sequence>

      {/* Act 4 (18-22s): the reframe */}
      <Sequence from={SEC(18)} durationInFrames={SEC(4)}>
        <Stage dark>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>instead of rereading</Eyebrow>
            <Headline from={SEC(0.5)} size={140} color={c.onNavy}>
              just ask.
            </Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 5 (22-30s): example 1 — the lease */}
      <Sequence from={SEC(22)} durationInFrames={SEC(8)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
            <Eyebrow from={SEC(0.2)}>your lease</Eyebrow>
            <CitedAnswer
              from={SEC(0.6)}
              width={960}
              query="how much notice do i owe if i move out early?"
              answer={
                <span>
                  <span style={{color: c.accent}}>Two months' rent</span> as break-fee, plus 30 days' written notice.
                </span>
              }
              cite="Cited — Page 7, §12"
            />
          </div>
        </Stage>
      </Sequence>

      {/* Act 6 (30-38s): example 2 — the tax form */}
      <Sequence from={SEC(30)} durationInFrames={SEC(8)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
            <Eyebrow from={SEC(0.2)}>the tax form</Eyebrow>
            <CitedAnswer
              from={SEC(0.6)}
              width={960}
              query="which box is the freelance income?"
              answer={
                <span>
                  Line <span style={{color: c.accent}}>17b</span> — under "Self-employment", not "Other".
                </span>
              }
              cite="Cited — Instructions p. 4"
            />
          </div>
        </Stage>
      </Sequence>

      {/* Act 7 (38-46s): example 3 — the appliance manual */}
      <Sequence from={SEC(38)} durationInFrames={SEC(8)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
            <Eyebrow from={SEC(0.2)}>the manual</Eyebrow>
            <CitedAnswer
              from={SEC(0.6)}
              width={960}
              query="what does the flashing red light mean?"
              answer={
                <span>
                  Water filter needs replacing —{' '}
                  <span style={{color: c.accent}}>part #W10295370A</span>.
                </span>
              }
              cite="Cited — Page 22, Troubleshooting"
            />
          </div>
        </Stage>
      </Sequence>

      {/* Act 8 (46-52s): the payoff */}
      <Sequence from={SEC(46)} durationInFrames={SEC(6)}>
        <Stage dark>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>any doc you've ever kept</Eyebrow>
            <Headline from={SEC(0.5)} size={112} color={c.onNavy}>
              in your pocket,
              <br />
              forever.
            </Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 9 (52-56s): the reframe closer */}
      <Sequence from={SEC(52)} durationInFrames={SEC(4)}>
        <Stage>
          <Headline from={SEC(0.2)} size={140}>stop rereading.</Headline>
        </Stage>
      </Sequence>

      {/* Act 10 (56-60s): end lockup */}
      <Sequence from={SEC(56)} durationInFrames={SEC(4)}>
        <Stage>
          <EndCard from={SEC(0.3)} tagline="Stop rereading. Just ask." />
        </Stage>
      </Sequence>
    </AbsoluteFill>
  );
};
