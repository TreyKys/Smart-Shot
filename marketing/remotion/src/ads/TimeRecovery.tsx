import React from 'react';
import {AbsoluteFill, Sequence, interpolate, useCurrentFrame} from 'remotion';
import {c, SEC, FONT} from '../theme';
import {Stage} from '../components/Stage';
import {Eyebrow, Headline, Body} from '../components/type';
import {Card} from '../components/cards';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 8 · "Get your time back" · 60s · 16:9
// The economics angle: a real number of hours lost to re-finding what you
// already saved, what that time could be, then Sift handing it back.
// ─────────────────────────────────────────────────────────────────────────

const BigNumber: React.FC<{from: number; to: number; suffix: string; color: string}> = ({
  from,
  to,
  suffix,
  color,
}) => {
  const frame = useCurrentFrame() - from;
  const v = interpolate(frame, [0, SEC(1.4)], [0, to], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const op = interpolate(frame, [0, 10], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  return (
    <span
      style={{
        opacity: op,
        fontFamily: FONT,
        fontWeight: 800,
        fontSize: 300,
        lineHeight: 1,
        letterSpacing: -12,
        color,
        fontVariantNumeric: 'tabular-nums',
      }}
    >
      {Math.round(v)}
      {suffix}
    </span>
  );
};

const AltCard: React.FC<{from: number; big: string; small: string}> = ({from, big, small}) => (
  <Card from={from} width={360}>
    <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8, textAlign: 'center'}}>
      <div style={{fontSize: 44, fontWeight: 800, color: c.ink}}>{big}</div>
      <div style={{fontSize: 24, fontWeight: 500, color: c.inkSoft}}>{small}</div>
    </div>
  </Card>
);

const Feature: React.FC<{from: number; title: string; body: string}> = ({from, title, body}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 14], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const x = interpolate(frame, [0, 14], [20, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  return (
    <div
      style={{
        opacity: op,
        transform: `translateX(${x}px)`,
        display: 'flex',
        alignItems: 'baseline',
        gap: 20,
        width: 900,
      }}
    >
      <div style={{width: 14, height: 14, borderRadius: 999, background: c.accentBright, flexShrink: 0, transform: 'translateY(2px)'}} />
      <div>
        <span style={{fontFamily: FONT, fontSize: 40, fontWeight: 700, color: c.ink}}>{title}</span>
        <span style={{fontFamily: FONT, fontSize: 40, fontWeight: 500, color: c.inkSoft}}> — {body}</span>
      </div>
    </div>
  );
};

export const TimeRecovery: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Act 1 (0-8s): the number (dark) */}
      <Sequence from={0} durationInFrames={SEC(8)}>
        <Stage dark>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10}}>
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>every single month</Eyebrow>
            <BigNumber from={SEC(0.5)} to={4} suffix=" hrs" color={c.accentBright} />
            <Body from={SEC(2.2)} color={c.onNavySoft} size={38} maxWidth={1000}>
              lost looking for a screenshot you already had.
            </Body>
          </div>
        </Stage>
      </Sequence>

      {/* Act 2 (8-18s): what that time could be */}
      <Sequence from={SEC(8)} durationInFrames={SEC(10)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 44}}>
            <Headline from={SEC(0.2)} size={92}>that's not nothing.</Headline>
            <div style={{display: 'flex', gap: 28}}>
              <AltCard from={SEC(0.8)} big="16" small="cups of coffee" />
              <AltCard from={SEC(1.4)} big="a novel" small="start to finish" />
              <AltCard from={SEC(2)} big="a lie-in" small="you actually earned" />
            </div>
          </div>
        </Stage>
      </Sequence>

      {/* Act 3 (18-30s): how Sift takes it back */}
      <Sequence from={SEC(18)} durationInFrames={SEC(12)}>
        <Stage align="flex-start" justify="center" pad={140}>
          <div style={{display: 'flex', flexDirection: 'column', gap: 34, marginTop: 40}}>
            <Headline from={SEC(0.2)} align="left" size={88}>Sift takes it back.</Headline>
            <div style={{display: 'flex', flexDirection: 'column', gap: 24, marginTop: 10}}>
              <Feature from={SEC(1)} title="Auto-tags on capture" body="on-device, the moment it lands" />
              <Feature from={SEC(2)} title="Clears duplicates & junk" body="gigabytes back, no digging" />
              <Feature from={SEC(3)} title="Answers in plain English" body="just ask, get the exact one" />
            </div>
          </div>
        </Stage>
      </Sequence>

      {/* Act 4 (30-40s): before / after */}
      <Sequence from={SEC(30)} durationInFrames={SEC(10)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 40}}>
            <Eyebrow from={SEC(0.2)}>finding one screenshot</Eyebrow>
            <div style={{display: 'flex', gap: 50, alignItems: 'center'}}>
              <BeforeAfter from={SEC(0.6)} label="before" time="4 min" color={c.danger} />
              <div style={{fontFamily: FONT, fontSize: 70, color: c.inkFaint, fontWeight: 300}}>→</div>
              <BeforeAfter from={SEC(1.4)} label="with sift" time="3 sec" color={c.success} />
            </div>
          </div>
        </Stage>
      </Sequence>

      {/* Act 5 (40-50s): the time back (dark) */}
      <Sequence from={SEC(40)} durationInFrames={SEC(10)}>
        <Stage dark>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10}}>
            <BigNumber from={SEC(0.4)} to={4} suffix=" hrs" color={c.success} />
            <Body from={SEC(2)} color={c.onNavySoft} size={38} maxWidth={1000}>
              back. every month. for as long as you have a phone.
            </Body>
          </div>
        </Stage>
      </Sequence>

      {/* Act 6 (50-60s): CTA */}
      <Sequence from={SEC(50)} durationInFrames={SEC(4)}>
        <Stage>
          <Headline from={SEC(0.2)} size={124}>get your time back.</Headline>
        </Stage>
      </Sequence>
      <Sequence from={SEC(54)} durationInFrames={SEC(6)}>
        <Stage>
          <EndCard from={SEC(0.4)} tagline="Stop searching. Start asking." />
        </Stage>
      </Sequence>
    </AbsoluteFill>
  );
};

const BeforeAfter: React.FC<{from: number; label: string; time: string; color: string}> = ({
  from,
  label,
  time,
  color,
}) => (
  <Card from={from} width={420}>
    <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14}}>
      <div style={{fontSize: 22, fontWeight: 700, letterSpacing: 2, textTransform: 'uppercase', color: c.inkFaint}}>
        {label}
      </div>
      <div style={{fontFamily: FONT, fontSize: 96, fontWeight: 800, color, letterSpacing: -3, fontVariantNumeric: 'tabular-nums'}}>
        {time}
      </div>
    </div>
  </Card>
);
