import React from 'react';
import {AbsoluteFill, Sequence, interpolate, useCurrentFrame} from 'remotion';
import {c, FONT, SEC} from '../theme';
import {Stage} from '../components/Stage';
import {Eyebrow, Headline, Body} from '../components/type';
import {DocumentPage, CitedAnswer, Card} from '../components/cards';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 1 · "The 4-minute meeting prep" · 60s · 9:16
// The universal white-collar dread: the meeting is minutes away, you were
// supposed to read the long doc, you didn't. Angle NOT covered by the
// existing 3 Magnum Opus ads (context/search/study).
//
// Ten acts, ~6s each: setup → the sinking realization → 62 pages →
// impossibility → the pivot → three cited answers → the reveal.
//
// Sequence-local timing throughout: any `from={...}` passed to a child of
// a <Sequence> is 0-based against that Sequence's start, not the
// composition timeline.
// ─────────────────────────────────────────────────────────────────────────

// A live countdown clock — mm:ss counting down from a start value. The
// digits change roughly every 10 frames of screen time so the tick reads
// as "the seconds are really moving" not "static image with a fake time".
const Countdown: React.FC<{from: number; startSec: number; color?: string}> = ({
  from,
  startSec,
  color = c.danger,
}) => {
  const frame = useCurrentFrame() - from;
  const t = Math.max(0, startSec - Math.floor(frame / 10));
  const mm = Math.floor(t / 60).toString().padStart(2, '0');
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
        fontSize: 260,
        fontWeight: 800,
        color,
        letterSpacing: -10,
        lineHeight: 1,
      }}
    >
      {mm}:{ss}
    </div>
  );
};

// A row of pages sliding in — visualizes "62 pages" without listing them.
const PageStack: React.FC<{from: number; count: number; onDark?: boolean}> = ({
  from,
  count,
  onDark,
}) => {
  return (
    <div style={{display: 'flex', gap: 14, justifyContent: 'center', flexWrap: 'wrap', maxWidth: 900}}>
      {Array.from({length: count}).map((_, i) => (
        <DocumentPage
          key={i}
          from={from + i * 3}
          pageNum={i + 1}
          lines={5}
          width={180}
          onDark={onDark}
        />
      ))}
    </div>
  );
};

export const MeetingPanic: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Act 1 (0-4s): the eyebrow + the clock */}
      <Sequence from={0} durationInFrames={SEC(4)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 30}}>
            <Eyebrow from={SEC(0.2)}>the meeting is in</Eyebrow>
            <Countdown from={SEC(0.4)} startSec={19 * 60 + 42} />
          </div>
        </Stage>
      </Sequence>

      {/* Act 2 (4-9s): the sinking realization */}
      <Sequence from={SEC(4)} durationInFrames={SEC(5)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 24}}>
            <Eyebrow from={SEC(0.2)}>and</Eyebrow>
            <Headline from={SEC(0.4)} size={140}>you didn't read it.</Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 3 (9-16s): the 62 pages (dark) */}
      <Sequence from={SEC(9)} durationInFrames={SEC(7)}>
        <Stage dark pad={80}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 30}}>
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>the Q3 review</Eyebrow>
            <Headline from={SEC(0.5)} size={200} color={c.onNavy}>62</Headline>
            <Body from={SEC(1)} color={c.onNavySoft} size={40}>pages.</Body>
            <div style={{marginTop: 20}}>
              <PageStack from={SEC(1.6)} count={12} onDark />
            </div>
          </div>
        </Stage>
      </Sequence>

      {/* Act 4 (16-22s): impossibility */}
      <Sequence from={SEC(16)} durationInFrames={SEC(6)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 24}}>
            <Eyebrow from={SEC(0.2)}>the old plan</Eyebrow>
            <Headline from={SEC(0.5)} size={126}>
              skim & pray.
            </Headline>
            <Body from={SEC(2)} color={c.inkSoft} size={38} maxWidth={800}>
              you cannot speed-read 62 pages in 19 minutes.
            </Body>
          </div>
        </Stage>
      </Sequence>

      {/* Act 5 (22-28s): the pivot (dark) */}
      <Sequence from={SEC(22)} durationInFrames={SEC(6)}>
        <Stage dark>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20}}>
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>the new plan</Eyebrow>
            <Headline from={SEC(0.5)} size={130} color={c.onNavy}>
              ask three
              <br />
              questions.
            </Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 6 (28-36s): Q1 — the headline number */}
      <Sequence from={SEC(28)} durationInFrames={SEC(8)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
            <Eyebrow from={SEC(0.2)}>question one</Eyebrow>
            <CitedAnswer
              from={SEC(0.6)}
              width={960}
              query="what's the headline number?"
              answer={
                <span>
                  Revenue up <span style={{color: c.accent}}>18%</span> YoY, driven by APAC expansion.
                </span>
              }
              cite="Page 3"
            />
          </div>
        </Stage>
      </Sequence>

      {/* Act 7 (36-44s): Q2 — red flags */}
      <Sequence from={SEC(36)} durationInFrames={SEC(8)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
            <Eyebrow from={SEC(0.2)}>question two</Eyebrow>
            <CitedAnswer
              from={SEC(0.6)}
              width={960}
              query="any red flags i should know?"
              answer={
                <span>
                  Two: <span style={{color: c.accent}}>Q3 churn in mid-market</span> and{' '}
                  <span style={{color: c.accent}}>rising cloud costs</span>.
                </span>
              }
              cite="Pages 18, 47"
            />
          </div>
        </Stage>
      </Sequence>

      {/* Act 8 (44-52s): Q3 — the decision */}
      <Sequence from={SEC(44)} durationInFrames={SEC(8)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
            <Eyebrow from={SEC(0.2)}>question three</Eyebrow>
            <CitedAnswer
              from={SEC(0.6)}
              width={960}
              query="what does leadership want us to decide?"
              answer={
                <span>
                  Whether to <span style={{color: c.accent}}>hire ahead of Q4</span> or hold.
                </span>
              }
              cite="Page 61"
            />
          </div>
        </Stage>
      </Sequence>

      {/* Act 9 (52-56s): the reveal */}
      <Sequence from={SEC(52)} durationInFrames={SEC(4)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20}}>
            <Eyebrow from={SEC(0.2)}>4 minutes. meeting-ready.</Eyebrow>
            <Headline from={SEC(0.5)} size={124}>walk in prepared.</Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 10 (56-60s): end lockup */}
      <Sequence from={SEC(56)} durationInFrames={SEC(4)}>
        <Stage>
          <EndCard from={SEC(0.3)} tagline="Walk into any meeting across the doc." />
        </Stage>
      </Sequence>
    </AbsoluteFill>
  );
};
