import React from 'react';
import {AbsoluteFill, Sequence, interpolate, useCurrentFrame} from 'remotion';
import {c, SEC, FONT} from '../theme';
import {Stage} from '../components/Stage';
import {Eyebrow, Headline, Body} from '../components/type';
import {Card, AskCard} from '../components/cards';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 7 · "The Reliable One" · 60s · 16:9
// A SECOND angle on the Chaos Story — not your own frustration, but the
// social one: other people always ask YOU for the thing you screenshotted,
// and you're the one scrambling to find it. With Sift you're instantly the
// person who always has it. Angle = social proof / being dependable.
// ─────────────────────────────────────────────────────────────────────────

// An incoming-message card — someone asking you for something.
const AskingCard: React.FC<{from: number; who: string; msg: string}> = ({from, who, msg}) => (
  <Card from={from} width={620}>
    <div style={{display: 'flex', flexDirection: 'column', gap: 12}}>
      <div style={{fontSize: 20, fontWeight: 700, letterSpacing: 1.5, textTransform: 'uppercase', color: c.inkFaint}}>
        {who}
      </div>
      <div
        style={{
          alignSelf: 'flex-start',
          maxWidth: '92%',
          padding: '18px 24px',
          borderRadius: 22,
          borderTopLeftRadius: 6,
          background: c.paper,
          border: `1.5px solid ${c.line}`,
          fontSize: 32,
          fontWeight: 600,
          color: c.ink,
          fontFamily: FONT,
        }}
      >
        {msg}
      </div>
    </div>
  </Card>
);

// The apologetic "still looking" reply — the moment Sift kills.
const ScramblingLine: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  // Clamp BOTH ends and floor at 0 — before the beat starts `frame` is
  // negative and un-clamped interpolation would return a negative count,
  // which String.repeat() rejects with a RangeError (this crashed the whole
  // render on the first pass).
  const dots = Math.max(
    0,
    Math.floor(
      interpolate(frame, [0, SEC(2)], [0, 4], {
        extrapolateLeft: 'clamp',
        extrapolateRight: 'clamp',
      }),
    ),
  );
  return (
    <div
      style={{
        alignSelf: 'flex-end',
        padding: '18px 24px',
        borderRadius: 22,
        borderTopRightRadius: 6,
        background: c.accentBright,
        color: '#fff',
        fontSize: 30,
        fontWeight: 600,
        fontFamily: FONT,
      }}
    >
      one sec, still looking{'.'.repeat(dots)}
    </div>
  );
};

export const TheReliableOne: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Act 1 (0-8s): the ask */}
      <Sequence from={0} durationInFrames={SEC(8)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 40}}>
            <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 18}}>
              <Eyebrow from={SEC(0.2)}>the group chat · 9:47 pm</Eyebrow>
              <Headline from={SEC(0.4)} size={100}>"you screenshotted it, right?"</Headline>
            </div>
            <AskingCard from={SEC(1.8)} who="Maya" msg="send me that restaurant you saved?" />
          </div>
        </Stage>
      </Sequence>

      {/* Act 2 (8-16s): you know you have it... somewhere (dark) */}
      <Sequence from={SEC(8)} durationInFrames={SEC(8)}>
        <Stage dark>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>you, absolutely certain</Eyebrow>
            <Headline from={SEC(0.4)} size={108} color={c.onNavy}>
              "it's in here somewhere…"
            </Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 3 (16-26s): the asks pile up */}
      <Sequence from={SEC(16)} durationInFrames={SEC(10)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 34}}>
            <Eyebrow from={SEC(0.2)}>everyone asks you</Eyebrow>
            <div style={{display: 'flex', gap: 28, alignItems: 'flex-start'}}>
              <AskingCard from={SEC(0.6)} who="Dad" msg="what was the flight number?" />
              <AskingCard from={SEC(1.4)} who="Work" msg="do you still have that receipt?" />
              <AskingCard from={SEC(2.2)} who="Sam" msg="send the wifi code again?" />
            </div>
          </div>
        </Stage>
      </Sequence>

      {/* Act 4 (26-36s): the scramble (dark) */}
      <Sequence from={SEC(26)} durationInFrames={SEC(10)}>
        <Stage dark>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 40}}>
            <Headline from={SEC(0.2)} size={104} color={c.onNavy}>
              and every time…
            </Headline>
            <div style={{display: 'flex', flexDirection: 'column', gap: 14, width: 640}}>
              <ScramblingLine from={SEC(1)} />
              <Body from={SEC(3.5)} color={c.onNavySoft} size={32} align="center">
                four minutes of scrolling. every single time.
              </Body>
            </div>
          </div>
        </Stage>
      </Sequence>

      {/* Act 5 (36-50s): with Sift — instant answers */}
      <Sequence from={SEC(36)} durationInFrames={SEC(14)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 30}}>
            <Eyebrow from={SEC(0.2)}>with sift</Eyebrow>
            <Headline from={SEC(0.4)} size={92}>you just… have it.</Headline>
            <div style={{marginTop: 10}}>
              <AskCard
                from={SEC(1.4)}
                query="the restaurant Maya asked about"
                answer={<span>Saved in April — <span style={{color: c.accent}}>Bavel, Arts District</span>.</span>}
                width={980}
              />
            </div>
          </div>
        </Stage>
      </Sequence>

      {/* Act 6 (50-60s): CTA */}
      <Sequence from={SEC(50)} durationInFrames={SEC(4)}>
        <Stage>
          <Headline from={SEC(0.2)} size={128} maxWidth={1300}>
            be the one
            <br />
            who always has it.
          </Headline>
        </Stage>
      </Sequence>
      <Sequence from={SEC(54)} durationInFrames={SEC(6)}>
        <Stage>
          <EndCard from={SEC(0.4)} tagline="Always have the answer. Just ask Sift." />
        </Stage>
      </Sequence>
    </AbsoluteFill>
  );
};
