import React from 'react';
import {AbsoluteFill, Sequence, interpolate, useCurrentFrame} from 'remotion';
import {c, SEC} from '../theme';
import {Stage} from '../components/Stage';
import {Eyebrow, Headline, Body} from '../components/type';
import {Chip} from '../components/Chip';
import {Card, AskCard} from '../components/cards';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 6 · "The Chaos Story" · 60s · 16:9
// The narrative the client liked, rebuilt in the editorial style. A normal
// day → screenshots quietly pile up → three weeks later you need one back →
// the scroll → Sift answers in a sentence → order restored.
//
// Sequence-local timing throughout (see SearchFrustration header).
// ─────────────────────────────────────────────────────────────────────────

// A small "saved" toast card — a labelled note with a subtle confirmation.
const SavedNote: React.FC<{from: number; label: string; sub: string}> = ({from, label, sub}) => (
  <Card from={from} width={560}>
    <div style={{display: 'flex', flexDirection: 'column', gap: 10}}>
      <div style={{fontSize: 20, fontWeight: 700, letterSpacing: 2, textTransform: 'uppercase', color: c.inkFaint}}>
        {sub}
      </div>
      <div style={{fontSize: 40, fontWeight: 700, color: c.ink}}>{label}</div>
      <div style={{display: 'flex', alignItems: 'center', gap: 10, marginTop: 6}}>
        <div style={{width: 10, height: 10, borderRadius: 999, background: c.success}} />
        <span style={{fontSize: 22, fontWeight: 600, color: c.inkSoft}}>Screenshot saved</span>
      </div>
    </div>
  </Card>
);

const FLOOD = [
  'Screenshot_0417', 'IMG_2831', 'Screen Recording', 'Photo_4102',
  'Screenshot_1120', 'IMG_9930', 'Screenshot_0038', 'IMG_2288',
  'Screenshot_7741', 'Photo_0916', 'IMG_5502', 'Screenshot_3390',
];

const FloodGrid: React.FC<{highlight?: number}> = ({highlight}) => (
  <div style={{display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 20, width: 1400}}>
    {FLOOD.map((name, i) => (
      <Chip
        key={name}
        label={highlight === i ? 'the wifi one' : name}
        from={SEC(0.2) + i * 4}
        highlighted={highlight === i}
        onDark
      />
    ))}
  </div>
);

export const ChaosStory: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Act 1 (0-8s): a normal Monday, one screenshot */}
      <Sequence from={0} durationInFrames={SEC(8)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 40}}>
            <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 18}}>
              <Eyebrow from={SEC(0.2)}>monday, 9:14 am</Eyebrow>
              <Headline from={SEC(0.4)} size={96}>"quick, let me screenshot that."</Headline>
            </div>
            <SavedNote from={SEC(1.6)} sub="address" label="42 Baker Street, 3B" />
          </div>
        </Stage>
      </Sequence>

      {/* Act 2 (8-18s): the day fills up */}
      <Sequence from={SEC(8)} durationInFrames={SEC(10)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 40}}>
            <Eyebrow from={SEC(0.2)}>by the end of the day</Eyebrow>
            <div style={{display: 'flex', gap: 24}}>
              <SavedNote from={SEC(0.6)} sub="travel" label="Boarding pass" />
              <SavedNote from={SEC(1.4)} sub="wifi" label="crown-guest / stay2026" />
              <SavedNote from={SEC(2.2)} sub="later" label="a meme, obviously" />
            </div>
          </div>
        </Stage>
      </Sequence>

      {/* Act 3 (18-26s): three weeks later, you need one back (dark) */}
      <Sequence from={SEC(18)} durationInFrames={SEC(8)}>
        <Stage dark>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>three weeks later</Eyebrow>
            <Headline from={SEC(0.4)} size={104} color={c.onNavy}>
              "…what was that wifi password?"
            </Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 4 (26-38s): the scroll — the flood of filenames (dark) */}
      <Sequence from={SEC(26)} durationInFrames={SEC(12)}>
        <Stage dark pad={80}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 44}}>
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>somewhere in three thousand screenshots</Eyebrow>
            <FloodGrid />
            <Body from={SEC(5)} color={c.onNavySoft} size={36}>
              four minutes of scrolling. still nothing.
            </Body>
          </div>
        </Stage>
      </Sequence>

      {/* Act 5 (38-50s): there's a faster way (light) */}
      <Sequence from={SEC(38)} durationInFrames={SEC(12)}>
        <Stage>
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              width: '100%',
              maxWidth: 1680,
              gap: 80,
            }}
          >
            <div style={{flexShrink: 0}}>
              <Eyebrow from={SEC(0.3)} align="left">there's a faster way</Eyebrow>
              <div style={{height: 18}} />
              <Headline from={SEC(0.5)} align="left" size={112} maxWidth={640}>
                just ask.
              </Headline>
            </div>
            <AskCard
              from={SEC(1.2)}
              query="what was that hotel wifi password?"
              answer={
                <span>
                  Crown Plaza, 3 weeks ago:{' '}
                  <span style={{color: c.accent}}>crown-guest / stay2026</span>
                </span>
              }
              width={820}
            />
          </div>
        </Stage>
      </Sequence>

      {/* Act 6 (50-60s): order restored + end */}
      <Sequence from={SEC(50)} durationInFrames={SEC(4)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20}}>
            <Eyebrow from={SEC(0.2)}>everything you saved</Eyebrow>
            <Headline from={SEC(0.4)} size={104}>finally where you can find it.</Headline>
          </div>
        </Stage>
      </Sequence>
      <Sequence from={SEC(54)} durationInFrames={SEC(6)}>
        <Stage>
          <EndCard from={SEC(0.4)} tagline="The order you didn't know you needed." />
        </Stage>
      </Sequence>
    </AbsoluteFill>
  );
};
