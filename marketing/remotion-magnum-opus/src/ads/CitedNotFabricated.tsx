import React from 'react';
import {AbsoluteFill, Sequence, interpolate, useCurrentFrame} from 'remotion';
import {c, FONT, SEC} from '../theme';
import {Stage} from '../components/Stage';
import {Eyebrow, Headline, Body} from '../components/type';
import {Card, CitedAnswer, DocumentPage} from '../components/cards';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 2 · "It made up the page number" · 20s · 9:16
// Generic AI hallucinates a plausible page → you look stupid quoting it
// → Magnum Opus cites the real one. Leans on the .cite-chip visual the
// existing HTML ads already use. Angle NOT covered by the existing 3.
// ─────────────────────────────────────────────────────────────────────────

// Two side-by-side "answers" — the fabricated one crossed out, the real
// one arriving with its cite chip. Same query, different source.
const CompareCards: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  // The left card gets crossed out at ~1.5s to visually "invalidate" it.
  const strikeOp = interpolate(frame, [SEC(1.5), SEC(2.1)], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div style={{display: 'flex', gap: 32, alignItems: 'flex-start'}}>
      {/* Fabricated */}
      <div style={{position: 'relative'}}>
        <Card from={from + 4} width={480}>
          <div
            style={{
              fontSize: 18,
              fontWeight: 800,
              letterSpacing: 2,
              textTransform: 'uppercase',
              color: c.danger,
              marginBottom: 12,
            }}
          >
            Generic AI
          </div>
          <div style={{fontSize: 27, fontWeight: 600, color: c.ink, lineHeight: 1.45}}>
            "The termination notice is 60 days — see <span style={{fontWeight: 800}}>page 34</span>."
          </div>
          <div
            style={{
              marginTop: 14,
              fontSize: 20,
              fontWeight: 700,
              color: c.danger,
              opacity: strikeOp,
            }}
          >
            Page 34 doesn't say that.
          </div>
        </Card>
        {/* Strike-through line */}
        <div
          style={{
            position: 'absolute',
            top: '50%',
            left: -20,
            right: -20,
            height: 4,
            background: c.danger,
            transform: `translateY(-2px) scaleX(${strikeOp})`,
            transformOrigin: 'left center',
            borderRadius: 2,
          }}
        />
      </div>

      {/* Cited */}
      <Card from={from + SEC(1.8)} width={480}>
        <div
          style={{
            fontSize: 18,
            fontWeight: 800,
            letterSpacing: 2,
            textTransform: 'uppercase',
            color: c.accent,
            marginBottom: 12,
          }}
        >
          Magnum Opus
        </div>
        <div style={{fontSize: 27, fontWeight: 600, color: c.ink, lineHeight: 1.45}}>
          "30 days' written notice, before renewal."
        </div>
        <div
          style={{
            marginTop: 18,
            display: 'inline-block',
            padding: '8px 18px',
            borderRadius: 999,
            background: c.accentWash,
            color: c.accent,
            fontSize: 20,
            fontWeight: 700,
            letterSpacing: 0.5,
          }}
        >
          Cited — Page 11, §4.2
        </div>
      </Card>
    </div>
  );
};

export const CitedNotFabricated: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Beat 1 (0-3.5s): the setup */}
      <Sequence from={0} durationInFrames={SEC(3.7)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 26}}>
            <Eyebrow from={SEC(0.2)}>you asked. it answered.</Eyebrow>
            <Headline from={SEC(0.4)} size={110}>then someone checked.</Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Beat 2 (3.5-8s): the fabricated quote (dark) */}
      <Sequence from={SEC(3.5)} durationInFrames={SEC(4.5)}>
        <Stage dark>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 34}}>
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>the page it named</Eyebrow>
            <DocumentPage
              from={SEC(0.4)}
              pageNum={34}
              title="Section 7 · Insurance"
              lines={7}
              width={620}
              onDark
            />
            <Headline from={SEC(1.6)} size={62} color={c.danger}>
              …says nothing about termination.
            </Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Beat 3 (8-15.5s): the comparison */}
      <Sequence from={SEC(8)} durationInFrames={SEC(7.5)}>
        <Stage justify="center">
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 40}}>
            <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14}}>
              <Eyebrow from={SEC(0.2)}>same question. two answers.</Eyebrow>
              <Headline from={SEC(0.4)} size={92}>
                one made it up. one didn't.
              </Headline>
            </div>
            <CompareCards from={SEC(1.2)} />
          </div>
        </Stage>
      </Sequence>

      {/* Beat 4 (15.5-20s): end */}
      <Sequence from={SEC(15.5)} durationInFrames={SEC(4.5)}>
        <Stage>
          <EndCard from={SEC(0.3)} tagline="Every answer, cited to the page." />
        </Stage>
      </Sequence>
    </AbsoluteFill>
  );
};
