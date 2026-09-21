import React from 'react';
import {AbsoluteFill, Sequence, interpolate, useCurrentFrame} from 'remotion';
import {c, SEC, FONT} from '../theme';
import {Stage} from '../components/Stage';
import {Eyebrow, Headline} from '../components/type';
import {AskCard} from '../components/cards';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 5 · "Just ask" · 20s · 16:9
// The hero feature: talk to your gallery like a person. Three quick
// questions, three instant answers — no folders, no filters.
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

export const AskInPlainEnglish: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Beat 1 (0-3s) */}
      <Sequence from={0} durationInFrames={SEC(3.2)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 24}}>
            <Eyebrow from={SEC(0.2)}>no folders. no filters.</Eyebrow>
            <Headline from={SEC(0.5)}>just ask.</Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Beat 2 (3-8s): question one */}
      <Sequence from={SEC(3)} durationInFrames={SEC(5)}>
        <Stage>
          <AskCard
            from={SEC(0.2)}
            query={<Typewriter text="what was that wifi password?" from={SEC(0.6)} dur={SEC(1.4)} />}
            answer={<span>Crown Plaza · <span style={{color: c.accent}}>crown-guest / stay2026</span></span>}
            width={1000}
          />
        </Stage>
      </Sequence>

      {/* Beat 3 (8-13s): question two */}
      <Sequence from={SEC(8)} durationInFrames={SEC(5)}>
        <Stage>
          <AskCard
            from={SEC(0.2)}
            query={<Typewriter text="the restaurant Maya recommended" from={SEC(0.6)} dur={SEC(1.4)} />}
            answer={<span>Found it — <span style={{color: c.accent}}>Bavel</span>, saved in April.</span>}
            width={1000}
          />
        </Stage>
      </Sequence>

      {/* Beat 4 (13-15.5s): the line */}
      <Sequence from={SEC(13)} durationInFrames={SEC(2.7)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
            <Eyebrow from={SEC(0.2)}>ask like a human</Eyebrow>
            <Headline from={SEC(0.4)} size={116}>answer like a friend.</Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Beat 5 (15.5-20s) */}
      <Sequence from={SEC(15.5)} durationInFrames={SEC(4.5)}>
        <Stage>
          <EndCard from={SEC(0.3)} tagline="Talk to your screenshots. Get answers." />
        </Stage>
      </Sequence>
    </AbsoluteFill>
  );
};
