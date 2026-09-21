import React from 'react';
import {AbsoluteFill, Sequence} from 'remotion';
import {c, SEC} from '../theme';
import {Stage} from '../components/Stage';
import {Eyebrow, Headline, Body} from '../components/type';
import {Chip} from '../components/Chip';
import {AskCard, ReceiptCard} from '../components/cards';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 1 · "Never scroll again" · 20s · 16:9
// Structure mirrors the reference film: relatable question → a grid of the
// mess filling in (background darkens, one item highlights) → bold headline
// beside a clean answer card → end lockup. No emoji; the content is real
// filenames, a real query, a real receipt card.
//
// Reminder: useCurrentFrame() is Sequence-LOCAL — every `from` passed to a
// child of a <Sequence> is relative to that Sequence's start.
// ─────────────────────────────────────────────────────────────────────────

// The overwhelm: what your gallery actually looks like — anonymous
// filenames, not neat categories.
const FILENAMES = [
  'Screenshot_0417',
  'IMG_2831',
  'Screen Recording',
  'Photo_4102',
  'Screenshot_1120',
  'IMG_9930',
  'Screenshot_0038',
  'IMG_2288',
  'Screenshot_7741',
  'Photo_0916',
  'IMG_5502',
  'Screenshot_3390',
];

const ChipGrid: React.FC = () => {
  return (
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(4, 1fr)',
        gap: 20,
        width: 1400,
      }}
    >
      {FILENAMES.map((name, i) => {
        const isTarget = i === 6; // the one you actually need
        return (
          <Chip
            key={name}
            label={isTarget ? 'Uber · receipt' : name}
            from={SEC(0.3) + i * 4}
            highlighted={isTarget}
            onDark
          />
        );
      })}
    </div>
  );
};

export const SearchFrustration: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Beat 1 (0-3.5s): the relatable question on paper */}
      <Sequence from={0} durationInFrames={SEC(3.7)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 26}}>
            <Eyebrow from={SEC(0.2)}>you, looking for one thing</Eyebrow>
            <Headline from={SEC(0.5)}>where's that receipt?</Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Beat 2 (3.5-9s): the mess fills in; canvas darkens; one highlights */}
      <Sequence from={SEC(3.5)} durationInFrames={SEC(5.5)}>
        <Stage dark pad={80}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 46}}>
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>
              three thousand, one hundred and four
            </Eyebrow>
            <ChipGrid />
          </div>
        </Stage>
      </Sequence>

      {/* Beat 3 (9-15.5s): bold headline + the answer, back on paper */}
      <Sequence from={SEC(9)} durationInFrames={SEC(6.5)}>
        <Stage justify="center" pad={110}>
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
              <Eyebrow from={SEC(0.3)} align="left">
                one question. one answer.
              </Eyebrow>
              <div style={{height: 18}} />
              <Headline from={SEC(0.5)} align="left" size={120} maxWidth={720}>
                just ask.
              </Headline>
            </div>
            <AskCard
              from={SEC(1)}
              query="find my uber receipts from march"
              answer={
                <span>
                  4 receipts · <span style={{color: c.accent}}>$87.50</span> total.
                </span>
              }
              width={760}
            />
          </div>
        </Stage>
      </Sequence>

      {/* Beat 4 (15.5-20s): end lockup */}
      <Sequence from={SEC(15.5)} durationInFrames={SEC(4.5)}>
        <Stage>
          <EndCard from={SEC(0.3)} tagline="Find any screenshot, just by asking." />
        </Stage>
      </Sequence>
    </AbsoluteFill>
  );
};
