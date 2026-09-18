import React from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, interpolate, spring, useVideoConfig} from 'remotion';
import {theme, fonts, SEC} from '../theme';
import {BgGradient} from '../components/BgGradient';
import {Screenshot} from '../components/Screenshot';
import {Kicker} from '../components/Kicker';
import {Logo} from '../components/Logo';
import {useFadeIn} from '../components/anim';

// ─────────────────────────────────────────────────────────────────────────
// AD 4 · "On This Day" · 20s
// Angle: nostalgic. That message from a friend, that concert ticket, that
// menu from a trip — you screenshotted them and forgot they existed. Sift
// resurfaces the ones from years past on the day they matter.
// ─────────────────────────────────────────────────────────────────────────

const MEMORIES = [
  {hue: theme.tag.social, icon: '💬', label: 'A text · 2 years ago', year: '2024'},
  {hue: theme.tag.travel, icon: '✈️', label: 'Boarding pass · 3 years', year: '2023'},
  {hue: theme.tag.finance, icon: '🎫', label: 'Concert ticket · 1 year', year: '2025'},
  {hue: theme.tag.memes, icon: '📸', label: 'Sunset photo · 2 years', year: '2024'},
];

const MemoryCard: React.FC<{
  from: number;
  item: {hue: string; icon: string; label: string; year: string};
}> = ({from, item}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const inSpring = spring({frame, fps, config: {damping: 16, stiffness: 100}});
  const outAt = SEC(2.2);
  const outT = interpolate(frame, [outAt, outAt + 15], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const scale = interpolate(inSpring, [0, 1], [0.75, 1]);
  const opIn = interpolate(inSpring, [0, 1], [0, 1]);
  const opOut = interpolate(outT, [0, 1], [1, 0]);
  const yOut = interpolate(outT, [0, 1], [0, -60]);
  return (
    <div
      style={{
        opacity: opIn * opOut,
        transform: `translateY(${yOut}px) scale(${scale})`,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 20,
      }}
    >
      <div
        style={{
          padding: '8px 20px',
          borderRadius: 999,
          background: `${theme.accent}22`,
          border: `1px solid ${theme.accent}55`,
          color: theme.accent,
          fontWeight: 700,
          fontSize: 20,
          letterSpacing: 1,
        }}
      >
        ON THIS DAY · {item.year}
      </div>
      <Screenshot hue={item.hue} icon={item.icon} label={item.label} size={340} />
    </div>
  );
};

export const MemoryLane: React.FC = () => {
  return (
    <AbsoluteFill style={{background: theme.bg, fontFamily: fonts.ui}}>
      <BgGradient from={theme.tag.memes} intensity={0.18} />

      {/* Beat 1 (0-3s): setup */}
      <Sequence from={0} durationInFrames={SEC(3)}>
        <AbsoluteFill
          style={{justifyContent: 'center', alignItems: 'center'}}
        >
          <Kicker
            headline={"Remember this?"}
            sub={"You screenshotted it. Then forgot."}
            from={SEC(0.3)}
          />
        </AbsoluteFill>
      </Sequence>

      {/* Beat 2 (3-14s): a stream of forgotten memories. Each memory
          gets its own Sequence — child `from` is always Sequence-local. */}
      {MEMORIES.map((m, i) => (
        <Sequence
          key={i}
          from={SEC(3 + i * 2.5)}
          durationInFrames={SEC(3)}
        >
          <AbsoluteFill
            style={{justifyContent: 'center', alignItems: 'center'}}
          >
            <MemoryCard from={0} item={m} />
          </AbsoluteFill>
        </Sequence>
      ))}

      {/* Beat 3 (14-18s): the promise */}
      <Sequence from={SEC(14)} durationInFrames={SEC(4)}>
        <AbsoluteFill
          style={{
            background: theme.bg,
            justifyContent: 'center',
            alignItems: 'center',
          }}
        >
          <Kicker
            headline={"Sift brings them back."}
            sub={"On the day they mattered."}
            from={0}
          />
        </AbsoluteFill>
      </Sequence>

      {/* Beat 4 (18-20s): logo */}
      <Sequence from={SEC(18)} durationInFrames={SEC(2)}>
        <AbsoluteFill
          style={{
            background: theme.bg,
            justifyContent: 'center',
            alignItems: 'center',
          }}
        >
          <Logo from={0} tagline="Every screenshot, remembered." />
        </AbsoluteFill>
      </Sequence>
    </AbsoluteFill>
  );
};
