import React from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, interpolate, spring, useVideoConfig} from 'remotion';
import {theme, fonts, SEC} from '../theme';
import {BgGradient} from '../components/BgGradient';
import {Screenshot} from '../components/Screenshot';
import {Kicker} from '../components/Kicker';
import {Logo} from '../components/Logo';
import {useFadeIn} from '../components/anim';

// ─────────────────────────────────────────────────────────────────────────
// AD 3 · "The Junk Pile" · 20s
// Angle: everyone has 500 dead memes, a screenshot of a URL from 2022,
// and a coupon that expired 8 months ago. Sift's junk review is the
// swipe-through-it-in-one-sitting antidote.
// ─────────────────────────────────────────────────────────────────────────

const JUNK = [
  {hue: theme.tag.memes, icon: '😹', label: 'meme #482'},
  {hue: theme.tag.junk, icon: '🎟️', label: 'coupon · expired'},
  {hue: theme.tag.social, icon: '🔗', label: 'random URL'},
  {hue: theme.tag.junk, icon: '📉', label: 'blank screen'},
  {hue: theme.tag.memes, icon: '😂', label: 'meme #483'},
  {hue: theme.tag.todo, icon: '🧾', label: 'expired offer'},
  {hue: theme.tag.junk, icon: '⬛', label: 'accidental cap'},
  {hue: theme.tag.social, icon: '💬', label: 'old DM'},
];

const PileGrowing: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  // Steady stream of dumb screenshots falling into a pile — accelerates
  // over the ~5s window.
  const count = Math.min(24, Math.floor(interpolate(frame, [0, SEC(5)], [3, 24])));
  const items = Array.from({length: count}).map((_, i) => JUNK[i % JUNK.length]);
  return (
    <div style={{position: 'relative', width: 900, height: 520}}>
      {items.map((it, i) => {
        const bornAt = i * 3;
        const s = spring({frame: frame - bornAt, fps, config: {damping: 14, stiffness: 90}});
        const scale = interpolate(s, [0, 1], [0.4, 1]);
        const op = interpolate(s, [0, 1], [0, 1]);
        const rot = (i * 37) % 40 - 20; // pseudo-random tilt
        const x = ((i * 127) % 800) - 20;
        const y = ((i * 53) % 340) + 30;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: x,
              top: y,
              opacity: op,
              transform: `scale(${scale}) rotate(${rot}deg)`,
            }}
          >
            <Screenshot hue={it.hue} icon={it.icon} label={it.label} size={128} />
          </div>
        );
      })}
    </div>
  );
};

const SwipeCard: React.FC<{
  from: number;
  hue: string;
  icon: string;
  label: string;
  dir: 'left' | 'right';
}> = ({from, hue, icon, label, dir}) => {
  const frame = useCurrentFrame() - from;
  const throwAt = SEC(0.9);
  const t = interpolate(frame, [throwAt, throwAt + 14], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const inOp = useFadeIn(from, 8);
  const x = dir === 'right' ? interpolate(t, [0, 1], [0, 900]) : interpolate(t, [0, 1], [0, -900]);
  const rot = dir === 'right' ? interpolate(t, [0, 1], [0, 25]) : interpolate(t, [0, 1], [0, -25]);
  const op = interpolate(t, [0, 0.9], [1, 0]) * inOp;
  return (
    <div
      style={{
        position: 'absolute',
        left: 0,
        right: 0,
        display: 'flex',
        justifyContent: 'center',
        transform: `translateX(${x}px) rotate(${rot}deg)`,
        opacity: op,
      }}
    >
      <Screenshot hue={hue} icon={icon} label={label} size={320} tag={dir === 'right' ? '#Keep' : '#Delete'} tagColor={dir === 'right' ? theme.success : theme.danger} />
    </div>
  );
};

const SwipeStack: React.FC<{from: number}> = ({from}) => {
  return (
    <div style={{position: 'relative', width: 400, height: 450}}>
      <SwipeCard from={from + SEC(0)} {...JUNK[0]} dir="left" />
      <SwipeCard from={from + SEC(1.2)} {...JUNK[1]} dir="left" />
      <SwipeCard from={from + SEC(2.4)} {...JUNK[2]} dir="right" />
      <SwipeCard from={from + SEC(3.6)} {...JUNK[3]} dir="left" />
    </div>
  );
};

export const JunkPile: React.FC = () => {
  return (
    <AbsoluteFill style={{background: theme.bg, fontFamily: fonts.ui}}>
      <BgGradient from={theme.danger} intensity={0.14} />

      {/* Beat 1 (0-6s): the pile keeps growing */}
      <Sequence from={0} durationInFrames={SEC(6)}>
        <AbsoluteFill
          style={{
            justifyContent: 'center',
            alignItems: 'center',
            flexDirection: 'column',
            gap: 20,
          }}
        >
          <PileGrowing from={0} />
          <Kicker
            headline={"Every screenshot lives forever."}
            sub={"Memes. Coupons. That URL from 2022."}
            from={SEC(0.5)}
          />
        </AbsoluteFill>
      </Sequence>

      {/* Beat 2 (6-15s): swipe through in one sitting. All child `from`
          values here are Sequence-local from now on. */}
      <Sequence from={SEC(6)} durationInFrames={SEC(9)}>
        <AbsoluteFill
          style={{
            justifyContent: 'center',
            alignItems: 'center',
            gap: 30,
          }}
        >
          <SwipeStack from={0} />
        </AbsoluteFill>
        <AbsoluteFill
          style={{
            justifyContent: 'flex-start',
            alignItems: 'center',
            paddingTop: 80,
            pointerEvents: 'none',
          }}
        >
          <SwipeHeader />
        </AbsoluteFill>
      </Sequence>

      {/* Beat 3 (15-20s): CTA */}
      <Sequence from={SEC(15)} durationInFrames={SEC(5)}>
        <AbsoluteFill
          style={{
            background: theme.bg,
            justifyContent: 'center',
            alignItems: 'center',
            gap: 30,
          }}
        >
          <Kicker
            headline={"Swipe once. Done."}
            sub={"Sift's Junk Review clears years of clutter in a coffee break."}
            from={0}
          />
          <div style={{marginTop: 40}}>
            <Logo from={SEC(2)} tagline="Sift. Clean without thinking." size={80} />
          </div>
        </AbsoluteFill>
      </Sequence>
    </AbsoluteFill>
  );
};

const SwipeHeader: React.FC = () => {
  // Sequence-local: lives inside the Beat 2 Sequence which starts at
  // composition SEC(6). We want the header to fade in 0.2s into the beat.
  const op = useFadeIn(SEC(0.2), 10);
  return (
    <div
      style={{
        opacity: op,
        fontSize: 30,
        fontWeight: 700,
        color: theme.textSecondary,
        letterSpacing: 0.4,
      }}
    >
      Keep <span style={{color: theme.success}}>→</span> &nbsp;·&nbsp; <span style={{color: theme.danger}}>←</span> Delete
    </div>
  );
};
