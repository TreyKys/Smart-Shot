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
// AD 6 · "The Chaos Story" · 60s (angle: relatable everyday narrative)
//
// All `from={...}` passed to child components INSIDE a Sequence are
// Sequence-local — not composition-absolute — see SearchFrustration.tsx's
// header comment for why.
//
// 0-8s   Morning. Screenshot the address someone sent you.
// 8-16s  Later same day. Boarding pass. Wifi password. A meme.
// 16-24s Three weeks later. You need one of them back.
// 24-34s The scroll. The scroll. The scroll.
// 34-46s Sift arrives. One question. Done.
// 46-60s Life after Sift.
// ─────────────────────────────────────────────────────────────────────────

const TimeStamp: React.FC<{from: number; text: string}> = ({from, text}) => {
  const op = useFadeInOut(from, from + SEC(2.5), 8);
  return (
    <div
      style={{
        opacity: op,
        position: 'absolute',
        top: 60,
        left: 60,
        padding: '10px 22px',
        borderRadius: 999,
        background: `${theme.surface}dd`,
        border: `1px solid ${theme.border}`,
        color: theme.textSecondary,
        fontFamily: fonts.ui,
        fontSize: 26,
        fontWeight: 600,
        letterSpacing: 1,
      }}
    >
      {text}
    </div>
  );
};

const SavedFlash: React.FC<{
  from: number;
  label: string;
  hue: string;
  icon: string;
  holdFor?: number; // frames to hold before fading out
}> = ({from, label, hue, icon, holdFor = SEC(2.5)}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 14, stiffness: 110}});
  const scale = interpolate(s, [0, 1], [0.6, 1]);
  const op = interpolate(
    frame,
    [0, 8, holdFor, holdFor + 12],
    [0, 1, 1, 0],
    {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'},
  );
  return (
    <div
      style={{
        opacity: op,
        transform: `scale(${scale})`,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 18,
      }}
    >
      <Screenshot hue={hue} icon={icon} label={label} size={320} />
      <div
        style={{
          padding: '10px 22px',
          borderRadius: 999,
          background: `${theme.success}22`,
          color: theme.success,
          fontFamily: fonts.ui,
          fontSize: 24,
          fontWeight: 700,
        }}
      >
        ✓ Screenshot saved
      </div>
    </div>
  );
};

const FranticScroll: React.FC<{duration: number}> = ({duration}) => {
  const frame = useCurrentFrame();
  const y = interpolate(frame, [0, duration], [0, -3000]);
  const tiles = Array.from({length: 90});
  const palette = [
    theme.tag.finance,
    theme.tag.memes,
    theme.tag.junk,
    theme.tag.travel,
    theme.tag.todo,
    theme.tag.social,
    theme.tag.web3,
    theme.tag.code,
    theme.surfaceElev,
  ];
  const icons = ['🧾', '💬', '📸', '🎫', '🔗', '📍', '🎥', '📝', '⬛', '📊', '🎟️'];
  return (
    <div style={{width: '100%', height: '100%', overflow: 'hidden', position: 'relative'}}>
      <div
        style={{
          position: 'absolute',
          top: 20,
          left: 20,
          right: 20,
          display: 'grid',
          gridTemplateColumns: 'repeat(3, 1fr)',
          gap: 8,
          transform: `translateY(${y}px)`,
        }}
      >
        {tiles.map((_, i) => (
          <Screenshot
            key={i}
            hue={palette[i % palette.length]}
            icon={icons[i % icons.length]}
            size={140}
          />
        ))}
      </div>
    </div>
  );
};

const AfterGrid: React.FC = () => {
  return (
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(3, 1fr)',
        gap: 12,
        padding: 24,
      }}
    >
      {[
        {hue: theme.tag.finance, icon: '🧾', tag: '#Receipt'},
        {hue: theme.tag.travel, icon: '✈️', tag: '#Travel'},
        {hue: theme.tag.social, icon: '💬', tag: '#Chat'},
        {hue: theme.tag.finance, icon: '🎫', tag: '#Ticket'},
        {hue: theme.tag.todo, icon: '📝', tag: '#To-Do'},
        {hue: theme.tag.web3, icon: '💰', tag: '#Web3'},
        {hue: theme.tag.code, icon: '💻', tag: '#Code'},
        {hue: theme.tag.memes, icon: '😂', tag: '#Memes'},
        {hue: theme.tag.travel, icon: '📍', tag: '#Places'},
      ].map((s, i) => (
        <Screenshot
          key={i}
          hue={s.hue}
          icon={s.icon}
          size={130}
          tag={s.tag}
          tagColor={s.hue}
        />
      ))}
    </div>
  );
};

const ScrollOverlay: React.FC = () => {
  // Sequence-local, inside Act 4 (10s Sequence)
  const l1 = useFadeInOut(SEC(0.5), SEC(4));
  const l2 = useFadeInOut(SEC(3), SEC(7));
  const l3 = useFadeInOut(SEC(6), SEC(10));
  return (
    <div style={{display: 'flex', flexDirection: 'column', gap: 18, alignItems: 'center'}}>
      <div
        style={{
          opacity: l1,
          fontSize: 52,
          fontWeight: 700,
          color: theme.textPrimary,
          textShadow: '0 3px 20px rgba(0,0,0,0.9)',
        }}
      >
        …it was in July.
      </div>
      <div
        style={{
          opacity: l2,
          fontSize: 52,
          fontWeight: 700,
          color: theme.textPrimary,
          textShadow: '0 3px 20px rgba(0,0,0,0.9)',
        }}
      >
        Or August?
      </div>
      <div
        style={{
          opacity: l3,
          fontSize: 62,
          fontWeight: 800,
          color: theme.danger,
          textShadow: '0 3px 20px rgba(0,0,0,0.9)',
        }}
      >
        Four minutes gone.
      </div>
    </div>
  );
};

const SiftAnswerCard: React.FC = () => {
  // Sequence-local, inside its own inner Sequence
  const opQ = useFadeIn(0, 10);
  const opA = useFadeIn(SEC(2.5), 12);
  return (
    <div style={{width: 900, display: 'flex', flexDirection: 'column', gap: 20}}>
      <div
        style={{
          opacity: opQ,
          alignSelf: 'flex-end',
          padding: '22px 28px',
          borderRadius: 28,
          background: `linear-gradient(135deg, ${theme.accent}, ${theme.accentDim})`,
          color: '#fff',
          fontSize: 32,
          fontWeight: 500,
          maxWidth: '80%',
          fontFamily: fonts.ui,
        }}
      >
        what was that wifi password from the hotel
      </div>
      <div
        style={{
          opacity: opA,
          alignSelf: 'flex-start',
          padding: '22px 28px',
          borderRadius: 28,
          background: theme.surfaceElev,
          color: theme.textPrimary,
          fontSize: 32,
          maxWidth: '80%',
          border: `1px solid ${theme.border}`,
          fontFamily: fonts.ui,
          fontWeight: 500,
        }}
      >
        Crown Plaza, three weeks ago: <b>crown-guest / stay2026</b>
      </div>
    </div>
  );
};

export const ChaosStory: React.FC = () => {
  return (
    <AbsoluteFill style={{background: theme.bg, fontFamily: fonts.ui}}>
      <BgGradient from={theme.accent} intensity={0.18} />

      {/* Act 1 (0-8s): morning */}
      <Sequence from={0} durationInFrames={SEC(8)}>
        <AbsoluteFill style={{justifyContent: 'center', alignItems: 'center'}}>
          <SavedFlash
            from={SEC(1)}
            label="42 Baker Street, 3B"
            hue={theme.tag.travel}
            icon="📍"
            holdFor={SEC(4)}
          />
        </AbsoluteFill>
        <AbsoluteFill>
          <TimeStamp from={SEC(0.2)} text="MONDAY · 9:14 AM" />
        </AbsoluteFill>
        <AbsoluteFill style={{justifyContent: 'flex-end', alignItems: 'center', paddingBottom: 120}}>
          <Kicker headline={"Quick, screenshot that address."} from={SEC(4.5)} />
        </AbsoluteFill>
      </Sequence>

      {/* Act 2 (8-16s): more, throughout the day */}
      <Sequence from={SEC(8)} durationInFrames={SEC(8)}>
        <AbsoluteFill
          style={{
            justifyContent: 'center',
            alignItems: 'center',
          }}
        >
          <div style={{display: 'flex', gap: 40, alignItems: 'center'}}>
            <SavedFlash from={SEC(0.2)} label="Boarding pass" hue={theme.tag.travel} icon="✈️" holdFor={SEC(6)} />
            <SavedFlash from={SEC(2.2)} label="Wifi: crown-guest" hue={theme.tag.code} icon="📶" holdFor={SEC(4)} />
            <SavedFlash from={SEC(4.2)} label="A meme, obviously" hue={theme.tag.memes} icon="😹" holdFor={SEC(3)} />
          </div>
        </AbsoluteFill>
        <AbsoluteFill>
          <TimeStamp from={SEC(0.2)} text="THROUGHOUT THE DAY" />
        </AbsoluteFill>
      </Sequence>

      {/* Act 3 (16-24s): three weeks later, need one back */}
      <Sequence from={SEC(16)} durationInFrames={SEC(8)}>
        <AbsoluteFill
          style={{
            background: theme.bg,
            justifyContent: 'center',
            alignItems: 'center',
          }}
        >
          <Kicker
            headline={"Three weeks later."}
            sub={"You need the wifi password."}
            from={SEC(0.5)}
          />
        </AbsoluteFill>
        <AbsoluteFill>
          <TimeStamp from={SEC(0.5)} text="3 WEEKS LATER" />
        </AbsoluteFill>
      </Sequence>

      {/* Act 4 (24-34s): the frantic scroll */}
      <Sequence from={SEC(24)} durationInFrames={SEC(10)}>
        <AbsoluteFill
          style={{justifyContent: 'center', alignItems: 'center'}}
        >
          <PhoneFrame width={560}>
            <FranticScroll duration={SEC(10)} />
          </PhoneFrame>
        </AbsoluteFill>
        <AbsoluteFill
          style={{
            justifyContent: 'flex-end',
            alignItems: 'center',
            paddingBottom: 140,
            pointerEvents: 'none',
          }}
        >
          <ScrollOverlay />
        </AbsoluteFill>
      </Sequence>

      {/* Act 5a (34-37s): the transition line */}
      <Sequence from={SEC(34)} durationInFrames={SEC(3)}>
        <AbsoluteFill
          style={{
            background: theme.bg,
            justifyContent: 'center',
            alignItems: 'center',
          }}
        >
          <Kicker headline={"There's a faster way."} from={SEC(0.3)} />
        </AbsoluteFill>
      </Sequence>

      {/* Act 5b (37-46s): the Sift chat answer */}
      <Sequence from={SEC(37)} durationInFrames={SEC(9)}>
        <AbsoluteFill
          style={{
            background: theme.bg,
            justifyContent: 'center',
            alignItems: 'center',
          }}
        >
          <SiftAnswerCard />
        </AbsoluteFill>
      </Sequence>

      {/* Act 6 (46-60s): life after Sift */}
      <Sequence from={SEC(46)} durationInFrames={SEC(4)}>
        <AbsoluteFill
          style={{justifyContent: 'center', alignItems: 'center'}}
        >
          <Kicker
            headline={"Everything you saved."}
            sub={"Finally where you can find it."}
            from={SEC(0.3)}
          />
        </AbsoluteFill>
      </Sequence>
      <Sequence from={SEC(50)} durationInFrames={SEC(6)}>
        <AbsoluteFill
          style={{justifyContent: 'center', alignItems: 'center'}}
        >
          <PhoneFrame width={520}>
            <AfterGrid />
          </PhoneFrame>
        </AbsoluteFill>
      </Sequence>
      <Sequence from={SEC(56)} durationInFrames={SEC(4)}>
        <AbsoluteFill
          style={{
            background: theme.bg,
            justifyContent: 'center',
            alignItems: 'center',
          }}
        >
          <Logo from={0} tagline="The order you didn't know you needed." />
        </AbsoluteFill>
      </Sequence>
    </AbsoluteFill>
  );
};
