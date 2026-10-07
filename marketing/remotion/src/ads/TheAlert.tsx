import React from 'react';
import {
  AbsoluteFill,
  Audio,
  Sequence,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import {SEC, FONT, ensureFonts, c} from '../theme';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 13 · "The Alert" · 25s · 9:16
// Pure stakes ad, not a style parody. The pain: you sent money. The person
// is asking "did you send?" You know you did. You even took the screenshot
// for proof. You can't find it NOW, when they need it. Trust visibly
// drops in real time. Sift finds it in two seconds.
//
// First Sift ad with SFX baked in — WhatsApp pops, send swishes, and a
// win-chime at the find.
// ─────────────────────────────────────────────────────────────────────────

const C = {
  bg: '#ECE5DD',          // WhatsApp wallpaper beige
  pattern: 'rgba(255,255,255,0.03)',
  topBar: '#075E54',      // WhatsApp green
  topBarText: '#FFFFFF',
  mine: '#D9FDD3',        // WhatsApp outgoing green
  theirs: '#FFFFFF',
  text: '#111B21',
  textMeta: '#667781',
  check: '#53BDEB',
  divider: '#D1D7DB',
};

const Bubble: React.FC<{
  from: number;
  side: 'left' | 'right';
  text: string;
  time: string;
  read?: boolean;
}> = ({from, side, text, time, read}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 24, stiffness: 170, mass: 0.5}});
  const op = interpolate(s, [0, 1], [0, 1]);
  const y = interpolate(s, [0, 1], [12, 0]);
  const isMine = side === 'right';
  return (
    <div
      style={{
        opacity: op,
        transform: `translateY(${y}px)`,
        alignSelf: isMine ? 'flex-end' : 'flex-start',
        maxWidth: '82%',
        padding: '14px 20px 10px',
        borderRadius: 14,
        background: isMine ? C.mine : C.theirs,
        color: C.text,
        fontFamily: FONT,
        fontSize: 34,
        fontWeight: 400,
        lineHeight: 1.3,
        boxShadow: '0 1px 1px rgba(0,0,0,0.06)',
        display: 'flex',
        flexDirection: 'column',
        gap: 4,
      }}
    >
      <span>{text}</span>
      <div
        style={{
          alignSelf: 'flex-end',
          fontSize: 20,
          color: C.textMeta,
          fontWeight: 400,
          display: 'flex',
          alignItems: 'center',
          gap: 4,
        }}
      >
        {time}
        {isMine && (
          <span style={{color: read ? C.check : C.textMeta, fontSize: 18, letterSpacing: -2}}>
            ✓✓
          </span>
        )}
      </div>
    </div>
  );
};

const TypingDots: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 10], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        opacity: op,
        alignSelf: 'flex-start',
        background: C.theirs,
        padding: '14px 20px',
        borderRadius: 14,
        display: 'flex',
        gap: 6,
      }}
    >
      {[0, 1, 2].map((i) => {
        const t = ((frame + i * 10) % 30) / 30;
        const bOp = 0.3 + 0.7 * Math.abs(Math.sin(t * Math.PI * 2));
        return (
          <div
            key={i}
            style={{
              width: 10,
              height: 10,
              borderRadius: '50%',
              background: C.textMeta,
              opacity: bOp,
            }}
          />
        );
      })}
    </div>
  );
};

const DateChip: React.FC<{from: number; text: string}> = ({from, text}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 14], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        opacity: op,
        alignSelf: 'center',
        background: '#D4E4EC',
        color: C.textMeta,
        padding: '6px 14px',
        borderRadius: 10,
        fontSize: 20,
        fontFamily: FONT,
        fontWeight: 500,
        margin: '10px 0',
      }}
    >
      {text}
    </div>
  );
};

const WaHeader: React.FC = () => (
  <div
    style={{
      background: C.topBar,
      padding: '36px 20px 16px',
      display: 'flex',
      alignItems: 'center',
      gap: 14,
      fontFamily: FONT,
    }}
  >
    <div
      style={{
        width: 70,
        height: 70,
        borderRadius: '50%',
        background: '#C7A86C',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: '#fff',
        fontSize: 28,
        fontWeight: 700,
      }}
    >
      K
    </div>
    <div style={{display: 'flex', flexDirection: 'column'}}>
      <span style={{color: C.topBarText, fontSize: 28, fontWeight: 500}}>Kemi (plumber)</span>
      <span style={{color: 'rgba(255,255,255,0.75)', fontSize: 18}}>online</span>
    </div>
  </div>
);

const Phone: React.FC<{children: React.ReactNode}> = ({children}) => {
  ensureFonts();
  return (
    <AbsoluteFill style={{background: C.bg}}>
      <WaHeader />
      <div
        style={{
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          gap: 10,
          padding: '14px 14px',
          overflow: 'hidden',
        }}
      >
        {children}
      </div>
    </AbsoluteFill>
  );
};

// Sift reveal — green win moment
const SiftReveal: React.FC = () => {
  const frame = useCurrentFrame();
  const askOp = interpolate(frame, [0, 14], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const ansOp = interpolate(frame, [26, 42], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const ansY = interpolate(frame, [26, 42], [20, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <AbsoluteFill style={{background: c.paper}}>
      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          padding: '140px 60px 60px',
        }}
      >
        <div
          style={{
            fontFamily: FONT,
            fontSize: 42,
            fontWeight: 800,
            color: c.ink,
            marginBottom: 50,
          }}
        >
          Ask Sift
        </div>
        <div
          style={{
            opacity: askOp,
            alignSelf: 'flex-end',
            background: c.accentBright,
            padding: '26px 36px',
            borderRadius: 36,
            borderBottomRightRadius: 10,
            color: '#fff',
            fontFamily: FONT,
            fontSize: 38,
            fontWeight: 500,
            marginBottom: 36,
            maxWidth: '85%',
          }}
        >
          transfer to kemi
        </div>
        <div
          style={{
            opacity: ansOp,
            transform: `translateY(${ansY}px)`,
            alignSelf: 'flex-start',
            background: '#fff',
            padding: '36px 40px',
            borderRadius: 32,
            border: `1.5px solid ${c.line}`,
            fontFamily: FONT,
            fontSize: 38,
            fontWeight: 500,
            color: c.ink,
            lineHeight: 1.4,
            maxWidth: '92%',
            boxShadow: '0 30px 70px rgba(15,22,38,0.08)',
          }}
        >
          Transfer Successful —{' '}
          <span style={{color: c.accent, fontWeight: 700}}>₦18,500</span>
          <br />
          <span style={{color: c.inkSoft, fontSize: 32}}>Ref: TXN8841 · 4:12 PM</span>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

export const TheAlert: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Act 1 (0-3s): the ask lands */}
      <Sequence from={0} durationInFrames={SEC(3)}>
        <Phone>
          <DateChip from={0} text="TODAY" />
          <Bubble from={SEC(0.6)} side="left" text="hello sir did u send?" time="4:28 PM" />
        </Phone>
        <Sequence from={SEC(0.5)} durationInFrames={SEC(0.5)}>
          <Audio src={staticFile('sfx/wa-pop.mp3')} />
        </Sequence>
      </Sequence>

      {/* Act 2 (3-6s): you reply — "yes i did" */}
      <Sequence from={SEC(3)} durationInFrames={SEC(3)}>
        <Phone>
          <DateChip from={-100} text="TODAY" />
          <Bubble from={-100} side="left" text="hello sir did u send?" time="4:28 PM" />
          <Bubble from={SEC(0.6)} side="right" text="yes i sent it already" time="4:29 PM" read />
          <Bubble from={SEC(1.6)} side="right" text="wait let me find the screenshot" time="4:29 PM" />
        </Phone>
        <Sequence from={SEC(0.6)} durationInFrames={SEC(0.3)}>
          <Audio src={staticFile('sfx/pop.mp3')} />
        </Sequence>
        <Sequence from={SEC(1.6)} durationInFrames={SEC(0.3)}>
          <Audio src={staticFile('sfx/pop.mp3')} />
        </Sequence>
      </Sequence>

      {/* Act 3 (6-11s): silence while you search — their trust drops */}
      <Sequence from={SEC(6)} durationInFrames={SEC(5)}>
        <Phone>
          <Bubble from={-100} side="right" text="yes i sent it already" time="4:29 PM" read />
          <Bubble from={-100} side="right" text="wait let me find the screenshot" time="4:29 PM" read />
          <DateChip from={SEC(1.5)} text="4:35 PM" />
          <Bubble from={SEC(2.5)} side="left" text="i'm still waiting o" time="4:36 PM" />
          <TypingDots from={SEC(4.0)} />
        </Phone>
        <Sequence from={SEC(2.6)} durationInFrames={SEC(0.3)}>
          <Audio src={staticFile('sfx/wa-pop.mp3')} />
        </Sequence>
      </Sequence>

      {/* Act 4 (11-14s): accusation — they don't believe you */}
      <Sequence from={SEC(11)} durationInFrames={SEC(3)}>
        <Phone>
          <Bubble from={-100} side="right" text="wait let me find the screenshot" time="4:29 PM" read />
          <Bubble from={-100} side="left" text="i'm still waiting o" time="4:36 PM" />
          <Bubble from={SEC(0.4)} side="left" text="are you sure you sent?" time="4:38 PM" />
        </Phone>
        <Sequence from={SEC(0.4)} durationInFrames={SEC(0.3)}>
          <Audio src={staticFile('sfx/wa-pop.mp3')} />
        </Sequence>
      </Sequence>

      {/* Act 5 (14-19s): Sift reveal — the screenshot is right there */}
      <Sequence from={SEC(14)} durationInFrames={SEC(5)}>
        <SiftReveal />
        <Sequence from={0} durationInFrames={SEC(0.3)}>
          <Audio src={staticFile('sfx/pop.mp3')} />
        </Sequence>
        <Sequence from={SEC(0.9)} durationInFrames={SEC(0.1)}>
          <Audio src={staticFile('sfx/click.mp3')} />
        </Sequence>
        <Sequence from={SEC(2.5)} durationInFrames={SEC(1)}>
          <Audio src={staticFile('sfx/chime-win.mp3')} />
        </Sequence>
      </Sequence>

      {/* Act 6 (19-23s): send back to WhatsApp — vindication */}
      <Sequence from={SEC(19)} durationInFrames={SEC(4)}>
        <Phone>
          <Bubble from={-100} side="left" text="are you sure you sent?" time="4:38 PM" />
          <Bubble
            from={SEC(0.3)}
            side="right"
            text="Transfer Successful — ₦18,500 · Ref: TXN8841 · 4:12 PM"
            time="4:39 PM"
            read
          />
          <Bubble from={SEC(2.0)} side="left" text="oh sorry oga, received 🙏" time="4:39 PM" />
        </Phone>
        <Sequence from={SEC(0.3)} durationInFrames={SEC(0.3)}>
          <Audio src={staticFile('sfx/pop.mp3')} />
        </Sequence>
        <Sequence from={SEC(2.0)} durationInFrames={SEC(0.3)}>
          <Audio src={staticFile('sfx/wa-pop.mp3')} />
        </Sequence>
      </Sequence>

      {/* Act 7 (23-25s): end lockup */}
      <Sequence from={SEC(23)} durationInFrames={SEC(2)}>
        <AbsoluteFill
          style={{
            background: c.paper,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 60,
          }}
        >
          <EndCard tagline="You sent it. Prove it in two seconds." />
        </AbsoluteFill>
        <Sequence from={SEC(0.3)} durationInFrames={SEC(0.5)}>
          <Audio src={staticFile('sfx/ding.mp3')} />
        </Sequence>
      </Sequence>
    </AbsoluteFill>
  );
};
