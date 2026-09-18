import React from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, interpolate, spring, useVideoConfig} from 'remotion';
import {theme, fonts, SEC} from '../theme';
import {BgGradient} from '../components/BgGradient';
import {Screenshot} from '../components/Screenshot';
import {Kicker} from '../components/Kicker';
import {Logo} from '../components/Logo';
import {useFadeIn, useFadeInOut} from '../components/anim';

// ─────────────────────────────────────────────────────────────────────────
// AD 2 · "Five of the Same Thing" · 20s
// Angle: the classic "I'll just take one more in case that one blurred"
// leaves your gallery with five identical shots. Sift finds them.
// ─────────────────────────────────────────────────────────────────────────

const FiveIdentical: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  return (
    <div style={{display: 'flex', gap: 20, alignItems: 'center'}}>
      {[0, 1, 2, 3, 4].map((i) => {
        const s = spring({frame: frame - i * 6, fps, config: {damping: 16, stiffness: 120}});
        const scale = interpolate(s, [0, 1], [0.4, 1]);
        const op = interpolate(s, [0, 1], [0, 1]);
        const rot = (i - 2) * 3; // slight fan
        return (
          <div
            key={i}
            style={{
              opacity: op,
              transform: `scale(${scale}) rotate(${rot}deg)`,
            }}
          >
            <Screenshot
              hue={theme.tag.social}
              icon="📸"
              size={180}
              label={i === 0 ? 'Sunset · take 1' : `take ${i + 1}`}
            />
          </div>
        );
      })}
    </div>
  );
};

const StorageBar: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const fill = interpolate(frame, [0, SEC(3)], [0, 0.86], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const gb = Math.round(interpolate(frame, [0, SEC(3)], [0, 27], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  }));
  return (
    <div
      style={{
        width: 780,
        padding: 32,
        background: theme.surface,
        borderRadius: 28,
        border: `1px solid ${theme.border}`,
        boxShadow: '0 30px 60px rgba(0,0,0,0.5)',
      }}
    >
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          fontSize: 22,
          fontWeight: 700,
          color: theme.textPrimary,
          marginBottom: 14,
        }}
      >
        <span>Storage — Screenshots</span>
        <span
          style={{
            color: theme.danger,
            fontVariantNumeric: 'tabular-nums',
            fontSize: 26,
          }}
        >
          {gb} GB in duplicates
        </span>
      </div>
      <div
        style={{
          height: 22,
          background: theme.surfaceElev,
          borderRadius: 999,
          overflow: 'hidden',
          border: `1px solid ${theme.border}`,
        }}
      >
        <div
          style={{
            height: '100%',
            width: `${fill * 100}%`,
            background: `linear-gradient(90deg, ${theme.warning}, ${theme.danger})`,
          }}
        />
      </div>
    </div>
  );
};

const CleanupCard: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  // Duplicates highlighted, then 4 of 5 fade out, one survives.
  const highlight = useFadeIn(from, 15);
  const kill = interpolate(frame, [SEC(2), SEC(3)], [1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const savedOp = useFadeIn(from + SEC(3), 12);
  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        gap: 22,
        alignItems: 'center',
      }}
    >
      <div
        style={{
          opacity: highlight,
          fontSize: 30,
          fontWeight: 700,
          color: theme.accent,
          letterSpacing: 0.5,
        }}
      >
        Sift found 5 duplicates.
      </div>
      <div style={{display: 'flex', gap: 20}}>
        {[0, 1, 2, 3, 4].map((i) => (
          <div
            key={i}
            style={{
              opacity: i === 0 ? 1 : kill,
              transform: `scale(${i === 0 ? 1 : interpolate(kill, [0, 1], [0.6, 1])})`,
              transition: 'none',
              border: `2px solid ${i === 0 ? theme.success : theme.danger}`,
              borderRadius: 16,
              padding: 4,
            }}
          >
            <Screenshot hue={theme.tag.social} icon="📸" size={150} />
          </div>
        ))}
      </div>
      <div
        style={{
          opacity: savedOp,
          fontSize: 34,
          fontWeight: 700,
          color: theme.success,
        }}
      >
        Kept 1. Freed 21 MB.
      </div>
    </div>
  );
};

export const DuplicateTrap: React.FC = () => {
  return (
    <AbsoluteFill style={{background: theme.bg, fontFamily: fonts.ui}}>
      <BgGradient from={theme.warning} intensity={0.12} />

      {/* Beat 1 (0-5s): five identical shots fan into view.
          Beat 1's Sequence starts at composition-frame 0, so
          Sequence-local time == composition time here. */}
      <Sequence from={0} durationInFrames={SEC(5)}>
        <AbsoluteFill
          style={{
            justifyContent: 'center',
            alignItems: 'center',
            flexDirection: 'column',
            gap: 40,
          }}
        >
          <FiveIdentical from={0} />
          <Kicker
            headline={"Ever done this?"}
            sub={"One shot. Just to be sure. Then one more."}
            from={SEC(0.5)}
          />
        </AbsoluteFill>
      </Sequence>

      {/* Beat 2 (5-9s): storage bar fills. All child `from` values are
          Sequence-local from here on (see SearchFrustration.tsx's header
          comment for why). */}
      <Sequence from={SEC(5)} durationInFrames={SEC(4)}>
        <AbsoluteFill
          style={{justifyContent: 'center', alignItems: 'center'}}
        >
          <StorageBar from={0} />
        </AbsoluteFill>
      </Sequence>

      {/* Beat 3 (9-16s): Sift finds and cleans */}
      <Sequence from={SEC(9)} durationInFrames={SEC(7)}>
        <AbsoluteFill
          style={{justifyContent: 'center', alignItems: 'center'}}
        >
          <CleanupCard from={0} />
        </AbsoluteFill>
      </Sequence>

      {/* Beat 4 (16-20s): logo */}
      <Sequence from={SEC(16)} durationInFrames={SEC(4)}>
        <AbsoluteFill
          style={{
            background: theme.bg,
            justifyContent: 'center',
            alignItems: 'center',
          }}
        >
          <Logo from={0} tagline="Never twice." />
        </AbsoluteFill>
      </Sequence>
    </AbsoluteFill>
  );
};
