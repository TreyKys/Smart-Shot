import React from 'react';
import {AbsoluteFill, Sequence, interpolate, useCurrentFrame} from 'remotion';
import {c, FONT, SEC} from '../theme';
import {Stage} from '../components/Stage';
import {Eyebrow, Headline, Body} from '../components/type';
import {DocumentPage, CitedAnswer} from '../components/cards';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 1 · "20 minutes till the meeting" · 20s · 9:16
// The universal white-collar dread: you were supposed to read the 60-page
// thing, the meeting starts in 20 min, and you cannot possibly speed-read
// it now. Angle NOT covered by the existing 3 ads (context/search/study).
// ─────────────────────────────────────────────────────────────────────────

// Countdown clock, ticking down on-screen. Frames map to seconds so
// timing reads honestly — no faked digits.
const Clock: React.FC<{from: number; startSec: number}> = ({from, startSec}) => {
  const frame = useCurrentFrame() - from;
  const t = Math.max(0, startSec - Math.floor(frame / 6)); // ~1 tick / 0.2s of screen time
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
        fontSize: 220,
        fontWeight: 800,
        color: c.danger,
        letterSpacing: -8,
        lineHeight: 1,
      }}
    >
      {mm}:{ss}
    </div>
  );
};

export const MeetingPanic: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Beat 1 (0-3.5s): the panic */}
      <Sequence from={0} durationInFrames={SEC(3.7)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 26}}>
            <Eyebrow from={SEC(0.2)}>the meeting is in</Eyebrow>
            <Clock from={SEC(0.4)} startSec={19 * 60 + 42} />
            <Body from={SEC(2)} color={c.inkSoft} size={36}>
              you didn't read it.
            </Body>
          </div>
        </Stage>
      </Sequence>

      {/* Beat 2 (3.5-8s): the 60 pages (dark canvas, unread stack) */}
      <Sequence from={SEC(3.5)} durationInFrames={SEC(4.5)}>
        <Stage dark pad={60}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 40}}>
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>the Q3 review, 62 pages</Eyebrow>
            <div style={{display: 'flex', gap: 18, justifyContent: 'center'}}>
              <DocumentPage from={SEC(0.4)} pageNum={1} lines={7} width={280} onDark />
              <DocumentPage from={SEC(0.7)} pageNum={2} lines={7} width={280} onDark />
              <DocumentPage from={SEC(1)} pageNum={3} lines={7} width={280} onDark />
            </div>
            <Headline from={SEC(1.8)} size={72} color={c.onNavy}>
              you cannot skim 62 pages.
            </Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Beat 3 (8-15.5s): what you actually do — ask three questions */}
      <Sequence from={SEC(8)} durationInFrames={SEC(7.5)}>
        <Stage justify="center">
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 24}}>
            <Eyebrow from={SEC(0.2)}>instead — three questions</Eyebrow>
            <div style={{display: 'flex', flexDirection: 'column', gap: 20, width: 940}}>
              <CitedAnswer
                from={SEC(0.6)}
                width={940}
                query="what's the headline number?"
                answer={<span>Revenue up <span style={{color: c.accent}}>18%</span> YoY — driven by APAC expansion.</span>}
                cite="Page 3"
              />
              <CitedAnswer
                from={SEC(2.4)}
                width={940}
                query="any red flags i should know?"
                answer={<span>Two: <span style={{color: c.accent}}>Q3 churn in mid-market</span> and <span style={{color: c.accent}}>rising cloud costs</span>.</span>}
                cite="Pages 18, 47"
              />
              <CitedAnswer
                from={SEC(4.2)}
                width={940}
                query="what does leadership want us to decide?"
                answer={<span>Whether to <span style={{color: c.accent}}>hire ahead of Q4</span> or hold.</span>}
                cite="Page 61"
              />
            </div>
          </div>
        </Stage>
      </Sequence>

      {/* Beat 4 (15.5-20s): end */}
      <Sequence from={SEC(15.5)} durationInFrames={SEC(4.5)}>
        <Stage>
          <EndCard from={SEC(0.3)} tagline="Walk into any meeting across the doc." />
        </Stage>
      </Sequence>
    </AbsoluteFill>
  );
};
