import React from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, interpolate, spring, useVideoConfig} from 'remotion';
import {theme, fonts, SEC} from '../theme';
import {BgGradient} from '../components/BgGradient';
import {PhoneFrame} from '../components/PhoneFrame';
import {Screenshot} from '../components/Screenshot';
import {Kicker} from '../components/Kicker';
import {Logo} from '../components/Logo';
import {useFadeIn, useFadeInOut} from '../components/anim';

// ─────────────────────────────────────────────────────────────────────────
// AD 7 · "Get Your Time Back" · 60s (angle: time / economics)
//
// A colder, punchier angle than the Chaos Story. Puts a real number on
// how much time gets lost re-finding what you already saved, then closes
// on what that time could be worth.
//
// 0-8s   The number: hours per month lost to screenshot chaos.
// 8-18s  What that time actually is (coffee, a walk, sleep).
// 18-30s The mechanism: auto-tag, dedupe, ask-in-english.
// 30-42s The proof: before/after storage + a clean search.
// 42-52s The recovered time — same graph, minutes not hours.
// 52-60s CTA.
// ─────────────────────────────────────────────────────────────────────────

const AnimatedCounter: React.FC<{
  from: number;
  duration: number;
  to: number;
  suffix?: string;
  style?: React.CSSProperties;
}> = ({from, duration, to, suffix = '', style}) => {
  const frame = useCurrentFrame() - from;
  const t = interpolate(frame, [0, duration], [0, to], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <span style={{fontVariantNumeric: 'tabular-nums', ...style}}>
      {Math.round(t)}
      {suffix}
    </span>
  );
};

const BigStat: React.FC<{
  from: number;
  n: number;
  suffix: string;
  label: string;
  color?: string;
}> = ({from, n, suffix, label, color = theme.danger}) => {
  const op = useFadeIn(from, 10);
  return (
    <div style={{opacity: op, textAlign: 'center'}}>
      <div
        style={{
          fontSize: 240,
          fontWeight: 800,
          lineHeight: 1,
          color,
          letterSpacing: -8,
        }}
      >
        <AnimatedCounter from={from} duration={SEC(1.5)} to={n} suffix={suffix} />
      </div>
      <div
        style={{
          fontSize: 34,
          fontWeight: 600,
          color: theme.textPrimary,
          marginTop: 12,
          letterSpacing: 0.5,
        }}
      >
        {label}
      </div>
    </div>
  );
};

const AlternativeUse: React.FC<{
  from: number;
  icon: string;
  text: string;
  delay?: number;
}> = ({from, icon, text, delay = 0}) => {
  const frame = useCurrentFrame() - from - delay;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 14, stiffness: 100}});
  const scale = interpolate(s, [0, 1], [0.7, 1]);
  const op = interpolate(s, [0, 1], [0, 1]);
  return (
    <div
      style={{
        opacity: op,
        transform: `scale(${scale})`,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 16,
        padding: '30px 40px',
        background: theme.surface,
        borderRadius: 28,
        border: `1px solid ${theme.border}`,
        minWidth: 240,
      }}
    >
      <div style={{fontSize: 72}}>{icon}</div>
      <div style={{fontSize: 24, color: theme.textPrimary, fontWeight: 600}}>{text}</div>
    </div>
  );
};

const Mechanism: React.FC<{
  from: number;
  icon: string;
  title: string;
  body: string;
}> = ({from, icon, title, body}) => {
  const op = useFadeIn(from, 12);
  const y = interpolate(useFadeIn(from, 12), [0, 1], [30, 0]);
  return (
    <div
      style={{
        opacity: op,
        transform: `translateY(${y}px)`,
        width: 700,
        padding: 32,
        background: theme.surface,
        borderRadius: 28,
        border: `1px solid ${theme.border}`,
        display: 'flex',
        alignItems: 'center',
        gap: 24,
      }}
    >
      <div
        style={{
          width: 84,
          height: 84,
          borderRadius: 22,
          background: `${theme.accent}22`,
          border: `1px solid ${theme.accent}55`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: 44,
          flexShrink: 0,
        }}
      >
        {icon}
      </div>
      <div>
        <div style={{fontSize: 32, fontWeight: 700, color: theme.textPrimary, marginBottom: 6}}>
          {title}
        </div>
        <div style={{fontSize: 20, color: theme.textSecondary, lineHeight: 1.4}}>{body}</div>
      </div>
    </div>
  );
};

export const TimeRecovery: React.FC = () => {
  return (
    <AbsoluteFill style={{background: theme.bg, fontFamily: fonts.ui}}>
      <BgGradient from={theme.accent} intensity={0.18} />

      {/* Act 1 (0-8s): the number. Act 1's Sequence starts at 0, so
          Sequence-local == composition-absolute here. */}
      <Sequence from={0} durationInFrames={SEC(8)}>
        <AbsoluteFill
          style={{justifyContent: 'center', alignItems: 'center'}}
        >
          <BigStat from={SEC(1)} n={4} suffix=" hrs" label="lost every month searching for a screenshot you already have." />
        </AbsoluteFill>
      </Sequence>

      {/* Act 2 (8-18s): what those hours could be. All child `from` values
          are Sequence-local from here on. */}
      <Sequence from={SEC(8)} durationInFrames={SEC(10)}>
        <AbsoluteFill
          style={{
            justifyContent: 'center',
            alignItems: 'center',
            gap: 40,
          }}
        >
          <Kicker headline={"That's a lot of coffee."} from={SEC(0.3)} />
          <div style={{display: 'flex', gap: 24}}>
            <AlternativeUse from={SEC(2)} icon="☕" text="16 cups of coffee" />
            <AlternativeUse from={SEC(2)} icon="📖" text="A whole novel" delay={SEC(0.5)} />
            <AlternativeUse from={SEC(2)} icon="🛌" text="Half a night's sleep" delay={SEC(1)} />
          </div>
        </AbsoluteFill>
      </Sequence>

      {/* Act 3 (18-30s): the mechanism (three cards) */}
      <Sequence from={SEC(18)} durationInFrames={SEC(12)}>
        <AbsoluteFill
          style={{
            justifyContent: 'center',
            alignItems: 'center',
            flexDirection: 'column',
            gap: 20,
          }}
        >
          <Kicker
            headline={"Sift takes it back."}
            from={SEC(0.3)}
          />
          <div style={{marginTop: 30, display: 'flex', flexDirection: 'column', gap: 14}}>
            <Mechanism
              from={SEC(2)}
              icon="🏷️"
              title="Auto-tag on capture"
              body="On-device AI reads every screenshot the moment it lands."
            />
            <Mechanism
              from={SEC(4.5)}
              icon="🧹"
              title="Duplicates cleared, junk swiped"
              body="Reclaim gigabytes without opening the gallery."
            />
            <Mechanism
              from={SEC(7)}
              icon="💬"
              title="Ask like a human"
              body='"Find that Uber receipt from October." Done in a second.'
            />
          </div>
        </AbsoluteFill>
      </Sequence>

      {/* Act 4 (30-42s): before/after search */}
      <Sequence from={SEC(30)} durationInFrames={SEC(12)}>
        <AbsoluteFill
          style={{
            justifyContent: 'center',
            alignItems: 'center',
            gap: 48,
          }}
        >
          <Kicker headline={"Before vs. after."} from={SEC(0.3)} />
          <div style={{display: 'flex', gap: 48, alignItems: 'flex-end'}}>
            <BeforeAfterColumn
              from={SEC(2)}
              label="Before"
              time="4 min 12 s"
              color={theme.danger}
            />
            <div style={{fontSize: 60, color: theme.textSecondary, alignSelf: 'center'}}>→</div>
            <BeforeAfterColumn
              from={SEC(4)}
              label="With Sift"
              time="3 sec"
              color={theme.success}
            />
          </div>
        </AbsoluteFill>
      </Sequence>

      {/* Act 5 (42-52s): the same graph, but the recovered time */}
      <Sequence from={SEC(42)} durationInFrames={SEC(10)}>
        <AbsoluteFill
          style={{
            justifyContent: 'center',
            alignItems: 'center',
          }}
        >
          <BigStat
            from={SEC(1)}
            n={4}
            suffix=" hrs"
            label="back. Every month. For the rest of your phone's life."
            color={theme.success}
          />
        </AbsoluteFill>
      </Sequence>

      {/* Act 6 (52-60s): CTA */}
      <Sequence from={SEC(52)} durationInFrames={SEC(8)}>
        <AbsoluteFill
          style={{
            background: theme.bg,
            justifyContent: 'center',
            alignItems: 'center',
            gap: 30,
          }}
        >
          <Kicker
            headline={"Get your time back."}
            from={SEC(0.5)}
          />
          <div style={{marginTop: 40}}>
            <Logo from={SEC(2)} tagline="Sift. On Google Play." />
          </div>
        </AbsoluteFill>
      </Sequence>
    </AbsoluteFill>
  );
};

const BeforeAfterColumn: React.FC<{
  from: number;
  label: string;
  time: string;
  color: string;
}> = ({from, label, time, color}) => {
  const op = useFadeIn(from, 12);
  return (
    <div
      style={{
        opacity: op,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 20,
      }}
    >
      <div
        style={{
          fontSize: 22,
          fontWeight: 700,
          color: theme.textSecondary,
          letterSpacing: 2,
          textTransform: 'uppercase',
        }}
      >
        {label}
      </div>
      <div
        style={{
          padding: '36px 60px',
          background: theme.surface,
          borderRadius: 28,
          border: `2px solid ${color}55`,
          color,
          fontSize: 72,
          fontWeight: 800,
          fontVariantNumeric: 'tabular-nums',
          letterSpacing: -2,
        }}
      >
        {time}
      </div>
    </div>
  );
};
