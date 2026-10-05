import React from 'react';
import {
  AbsoluteFill,
  Sequence,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import {c, FONT, SEC} from '../theme';
import {Stage} from '../components/Stage';
import {Eyebrow, Headline} from '../components/type';
import {Card} from '../components/cards';
import {Chip} from '../components/Chip';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 10 · "The Face You Remember" · 24s · 16:9
// The capability gap the earlier "All You Need" ad deliberately stepped
// around: finding a specific PERSON in your gallery, not just a tagged or
// keyword-matched screenshot. This ad is written for the cross-reference
// search planned in the follow-up build — see the commit message — and
// should stay out of any live ad account until that function ships.
//
// The hero beat isn't just "it found him" — it's SHOWING the reasoning
// that triggered the deeper search (no tag match / query names a person /
// gallery is full of faces) before the scan itself. That's the actual
// product idea: not a black box, a visible decision.
// ─────────────────────────────────────────────────────────────────────────

const QueryPill: React.FC<{from: number; children: React.ReactNode; width?: number}> = ({
  from,
  children,
  width = 1000,
}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 16], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const y = interpolate(frame, [0, 16], [16, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        opacity: op,
        transform: `translateY(${y}px)`,
        width,
        display: 'flex',
        alignItems: 'center',
        gap: 16,
        padding: '22px 28px',
        borderRadius: 20,
        background: c.card,
        border: `1.5px solid ${c.line}`,
        boxShadow: '0 30px 70px rgba(15,22,38,0.1)',
      }}
    >
      <div
        style={{width: 14, height: 14, borderRadius: 999, background: c.accentBright, flexShrink: 0}}
      />
      <span style={{fontSize: 30, fontWeight: 500, color: c.ink, fontFamily: FONT}}>{children}</span>
    </div>
  );
};

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

// Abstract grid of "candidate" dots lighting up as they're checked — never
// literal face clip art, same rule the Tile component follows elsewhere in
// this project. Reads as "working through the gallery," not a stock photo.
const FaceDotGrid: React.FC<{from: number; count?: number}> = ({from, count = 32}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  return (
    <div style={{display: 'grid', gridTemplateColumns: 'repeat(8, 1fr)', gap: 16, width: 560}}>
      {Array.from({length: count}).map((_, i) => {
        const s = spring({
          frame: frame - i * 2,
          fps,
          config: {damping: 20, stiffness: 160, mass: 0.5},
        });
        const op = interpolate(s, [0, 1], [0, 1]);
        const sc = interpolate(s, [0, 1], [0.6, 1]);
        const lit = s > 0.5;
        return (
          <div
            key={i}
            style={{
              opacity: op,
              transform: `scale(${sc})`,
              width: 48,
              height: 48,
              borderRadius: '50%',
              background: lit ? c.accentWash : c.navyCard,
              border: `2px solid ${lit ? c.accentBright : c.navyLine}`,
            }}
          />
        );
      })}
    </div>
  );
};

// Fast climb to target, eased to a soft stop — same shape as the
// word-count counter in the Magnum Opus "Six Hours" ad, reused here for
// the "scanning N photos" readout.
const ScanCounter: React.FC<{from: number; target: number}> = ({from, target}) => {
  const frame = useCurrentFrame() - from;
  const settle = 70;
  const t = Math.min(1, Math.max(0, frame) / settle);
  const eased = 1 - Math.pow(1 - t, 3);
  const n = Math.floor(eased * target);
  const op = interpolate(frame, [0, 12], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        opacity: op,
        fontFamily: FONT,
        fontVariantNumeric: 'tabular-nums',
        fontSize: 40,
        fontWeight: 700,
        color: c.onNavy,
      }}
    >
      {n.toLocaleString()} photos checked
    </div>
  );
};

export const TheFaceYouRemember: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Act 1 (0-3s): the setup */}
      <Sequence from={0} durationInFrames={SEC(3)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 24}}>
            <Eyebrow from={SEC(0.2)}>you remember the face</Eyebrow>
            <Headline from={SEC(0.5)} size={118}>not which app it's in.</Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 2 (3-8s): the ask — no tags, no filename, just a person */}
      <Sequence from={SEC(3)} durationInFrames={SEC(5)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 24}}>
            <Eyebrow from={SEC(0.2)}>ask like you'd ask a friend</Eyebrow>
            <QueryPill from={SEC(0.6)}>
              <Typewriter
                text="the guy from Jake's wedding — not the groom, the other one"
                from={SEC(0.2)}
                dur={SEC(2.2)}
              />
            </QueryPill>
          </div>
        </Stage>
      </Sequence>

      {/* Act 3 (8-15s): the reasoning, then the scan (dark) */}
      <Sequence from={SEC(8)} durationInFrames={SEC(7)}>
        <Stage dark pad={90}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 24}}>
            <Eyebrow from={SEC(0.1)} color={c.onNavySoft}>how sift knew to look deeper</Eyebrow>
            <div style={{display: 'flex', gap: 14}}>
              <Chip from={SEC(0.3)} label="no tag match" onDark />
              <Chip from={SEC(0.9)} label="query names a person" onDark />
              <Chip from={SEC(1.5)} label="your gallery is full of faces" onDark highlighted />
            </div>
            <div style={{marginTop: 8}}>
              <FaceDotGrid from={SEC(2.4)} count={32} />
            </div>
            <ScanCounter from={SEC(2.6)} target={1842} />
            <div style={{marginTop: 2}}>
              <Chip from={SEC(5.6)} label="4 matches found" onDark highlighted />
            </div>
          </div>
        </Stage>
      </Sequence>

      {/* Act 4 (15-19s): the reveal */}
      <Sequence from={SEC(15)} durationInFrames={SEC(4)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
            <Eyebrow from={SEC(0.2)}>found him</Eyebrow>
            <Card from={SEC(0.5)} width={1000}>
              <div style={{marginBottom: 18}}>
                <Chip from={SEC(0.3)} label="Matched · 4 photos" highlighted />
              </div>
              <div style={{fontSize: 32, fontWeight: 600, color: c.ink, lineHeight: 1.4, fontFamily: FONT}}>
                <span style={{color: c.accent}}>Marcus</span> — best man, back row. tagged
                automatically.
              </div>
            </Card>
          </div>
        </Stage>
      </Sequence>

      {/* Act 5 (19-24s): end lockup */}
      <Sequence from={SEC(19)} durationInFrames={SEC(5)}>
        <Stage>
          <EndCard from={SEC(0.3)} tagline="If it's in your gallery, Sift finds who's in it." />
        </Stage>
      </Sequence>
    </AbsoluteFill>
  );
};
