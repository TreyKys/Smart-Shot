import React from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame} from 'remotion';
import {c, SEC} from '../theme';
import {Stage} from '../components/Stage';
import {Eyebrow, Headline} from '../components/type';
import {AskCard} from '../components/cards';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 9 · "All You Need" · 45s · 16:9
// Pure reliability pitch: no new app, no new habit — Sift is the one
// system that actually holds. Three real asks back the claim with the
// actual mechanism (tag match, keyword/OCR-text search, date range) rather
// than a capability the app doesn't ship yet — see the commit message for
// why that distinction mattered here.
// ─────────────────────────────────────────────────────────────────────────

const Typewriter: React.FC<{text: string; from: number; dur: number}> = ({text, from, dur}) => {
  const frame = useCurrentFrame() - from;
  const n = Math.max(0, Math.min(text.length, Math.floor((frame / dur) * text.length)));
  const caret = frame >= 0 && frame < dur;
  return (
    <span>
      {text.slice(0, n)}
      {caret && <span style={{opacity: Math.round(frame / 8) % 2 ? 0.2 : 1}}>|</span>}
    </span>
  );
};

export const AllYouNeed: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Act 1 (0-5s): the chaos, honestly */}
      <Sequence from={0} durationInFrames={SEC(5)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 24}}>
            <Eyebrow from={SEC(0.2)}>your camera roll, honestly</Eyebrow>
            <Headline from={SEC(0.5)} size={118}>4,000 screenshots. no system.</Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 2 (5-10s): the pivot (dark) */}
      <Sequence from={SEC(5)} durationInFrames={SEC(5)}>
        <Stage dark>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20}}>
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>so stop organizing</Eyebrow>
            <Headline from={SEC(0.5)} size={140} color={c.onNavy}>just ask.</Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 3 (10-18s): ask one — tax season, the receipts */}
      <Sequence from={SEC(10)} durationInFrames={SEC(8)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
            <Eyebrow from={SEC(0.2)}>tax season</Eyebrow>
            <AskCard
              from={SEC(0.6)}
              width={1000}
              query={
                <Typewriter text="receipts from last month" from={SEC(0.2)} dur={SEC(1.3)} />
              }
              answer={
                <span>
                  <span style={{color: c.accent}}>14 found</span> — tagged, dated, ready to
                  export.
                </span>
              }
            />
          </div>
        </Stage>
      </Sequence>

      {/* Act 4 (18-26s): ask two — moving out, the lease clause */}
      <Sequence from={SEC(18)} durationInFrames={SEC(8)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
            <Eyebrow from={SEC(0.2)}>moving out</Eyebrow>
            <AskCard
              from={SEC(0.6)}
              width={1000}
              query={
                <Typewriter
                  text="the lease clause about breaking it early"
                  from={SEC(0.2)}
                  dur={SEC(1.6)}
                />
              }
              answer={
                <span>
                  <span style={{color: c.accent}}>Two months' rent</span> — saved back in
                  March.
                </span>
              }
            />
          </div>
        </Stage>
      </Sequence>

      {/* Act 5 (26-34s): ask three — "you know the one" */}
      <Sequence from={SEC(26)} durationInFrames={SEC(8)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
            <Eyebrow from={SEC(0.2)}>"you know the one"</Eyebrow>
            <AskCard
              from={SEC(0.6)}
              width={1000}
              query={
                <Typewriter
                  text="the photo from Mia's graduation — the big group one"
                  from={SEC(0.2)}
                  dur={SEC(1.9)}
                />
              }
              answer={
                <span>
                  Found it — tagged <span style={{color: c.accent}}>Graduation</span>, saved in
                  May.
                </span>
              }
            />
          </div>
        </Stage>
      </Sequence>

      {/* Act 6 (34-40s): the reframe (dark) — "all you need" */}
      <Sequence from={SEC(34)} durationInFrames={SEC(6)}>
        <Stage dark>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20}}>
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>no new app. no new habit.</Eyebrow>
            <Headline from={SEC(0.5)} size={96} color={c.onNavy} maxWidth={1500}>
              Sift is all you need to stay organized.
            </Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 7 (40-45s): end lockup */}
      <Sequence from={SEC(40)} durationInFrames={SEC(5)}>
        <Stage>
          <EndCard
            from={SEC(0.3)}
            tagline="One app. Everything you need to stay organized."
          />
        </Stage>
      </Sequence>
    </AbsoluteFill>
  );
};
