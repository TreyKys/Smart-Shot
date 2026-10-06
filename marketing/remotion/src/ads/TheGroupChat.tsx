import React from 'react';
import {AbsoluteFill, Sequence, interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {SEC, FONT, ensureFonts, c} from '../theme';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 11 · "The Group Chat" · 25s · 9:16
// Deliberately breaks the editorial house style — no eyebrows, no spring
// headlines, no cards. The whole ad IS a fake iMessage thread. Only in the
// last 3 seconds does Sift chrome appear. Vertical because that's where
// people actually see this kind of thing (TikTok, Reels, Shorts).
//
// The joke lives in time: the chat timestamps race from 10:47pm forward
// while "you" scroll through gallery for a booking screenshot. Everyone
// has been in this chat.
// ─────────────────────────────────────────────────────────────────────────

const C = {
  wallpaper: '#000',
  screenBg: '#FFFFFF',
  statusBar: '#000',
  header: '#F6F6F6',
  headerText: '#000',
  divider: '#C6C6C8',
  theirs: '#E9E9EB',
  mine: '#007AFF',
  textTheirs: '#000',
  textMine: '#FFF',
  meta: '#8E8E93',
};

const Bubble: React.FC<{
  from: number;
  side: 'left' | 'right';
  text: string;
  sender?: string;
  color?: string;
}> = ({from, side, text, sender, color}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 22, stiffness: 170, mass: 0.6}});
  const op = interpolate(s, [0, 1], [0, 1]);
  const y = interpolate(s, [0, 1], [20, 0]);
  const sc = interpolate(s, [0, 1], [0.96, 1]);
  const isMine = side === 'right';
  return (
    <div
      style={{
        opacity: op,
        transform: `translateY(${y}px) scale(${sc})`,
        alignSelf: isMine ? 'flex-end' : 'flex-start',
        maxWidth: '78%',
        display: 'flex',
        flexDirection: 'column',
        alignItems: isMine ? 'flex-end' : 'flex-start',
      }}
    >
      {sender && !isMine && (
        <div
          style={{
            fontFamily: FONT,
            fontSize: 24,
            color: C.meta,
            fontWeight: 500,
            marginLeft: 20,
            marginBottom: 6,
          }}
        >
          {sender}
        </div>
      )}
      <div
        style={{
          padding: '20px 28px',
          borderRadius: 36,
          background: color ?? (isMine ? C.mine : C.theirs),
          color: isMine ? C.textMine : C.textTheirs,
          fontFamily: FONT,
          fontSize: 36,
          fontWeight: 400,
          lineHeight: 1.3,
          borderBottomRightRadius: isMine ? 10 : 36,
          borderBottomLeftRadius: isMine ? 36 : 10,
        }}
      >
        {text}
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
        alignSelf: 'flex-end',
        background: C.mine,
        padding: '20px 30px',
        borderRadius: 36,
        borderBottomRightRadius: 10,
        display: 'flex',
        gap: 8,
      }}
    >
      {[0, 1, 2].map((i) => {
        const t = ((frame + i * 10) % 30) / 30;
        const bOp = 0.4 + 0.6 * Math.abs(Math.sin(t * Math.PI * 2));
        return (
          <div
            key={i}
            style={{
              width: 14,
              height: 14,
              borderRadius: '50%',
              background: '#fff',
              opacity: bOp,
            }}
          />
        );
      })}
    </div>
  );
};

const TimeSep: React.FC<{from: number; time: string}> = ({from, time}) => {
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
        fontFamily: FONT,
        fontSize: 22,
        color: C.meta,
        fontWeight: 500,
        margin: '14px 0',
        letterSpacing: 0.3,
      }}
    >
      {time}
    </div>
  );
};

const ChatHeader: React.FC = () => (
  <div
    style={{
      background: C.header,
      borderBottom: `0.5px solid ${C.divider}`,
      padding: '20px 32px 24px',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      fontFamily: FONT,
    }}
  >
    <div style={{width: 90, height: 90, borderRadius: '50%', background: '#D1D1D6', marginBottom: 8}} />
    <div style={{fontSize: 28, color: C.headerText, fontWeight: 500, letterSpacing: 0.1}}>Jake, Mia</div>
    <div style={{fontSize: 20, color: C.meta, fontWeight: 400, marginTop: 2}}>iMessage</div>
  </div>
);

const Phone: React.FC<{children: React.ReactNode}> = ({children}) => {
  ensureFonts();
  return (
    <AbsoluteFill style={{background: C.wallpaper}}>
      <AbsoluteFill
        style={{
          background: C.screenBg,
          display: 'flex',
          flexDirection: 'column',
        }}
      >
        {/* iOS status bar */}
        <div
          style={{
            fontFamily: FONT,
            fontSize: 24,
            fontWeight: 600,
            color: C.statusBar,
            padding: '28px 44px 10px',
            display: 'flex',
            justifyContent: 'space-between',
          }}
        >
          <span>10:47</span>
          <span>5G ●●●●</span>
        </div>
        {children}
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const ChatBody: React.FC<{children: React.ReactNode}> = ({children}) => (
  <>
    <ChatHeader />
    <div
      style={{
        flex: 1,
        display: 'flex',
        flexDirection: 'column',
        gap: 14,
        padding: '20px 20px',
        overflow: 'hidden',
      }}
    >
      {children}
    </div>
  </>
);

// ── Sift app mock-up for the reveal — looks like Ask Sift ───────────────
const SiftMock: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const headerOp = interpolate(frame, [0, 10], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const askOp = interpolate(frame, [20, 32], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const ansOp = interpolate(frame, [45, 60], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const ansY = interpolate(frame, [45, 60], [20, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <AbsoluteFill style={{background: c.paper}}>
      <AbsoluteFill style={{display: 'flex', flexDirection: 'column', padding: '120px 60px 60px'}}>
        <div
          style={{
            opacity: headerOp,
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
          booking screenshot
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
          Hotel Marbella —{' '}
          <span style={{color: c.accent, fontWeight: 700}}>check-in 3 PM</span>
          <br />
          <span style={{color: c.inkSoft, fontSize: 32}}>Confirmation #AB2847</span>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

export const TheGroupChat: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Act 1 (0-3s): header + Jake's question */}
      <Sequence from={0} durationInFrames={SEC(3)}>
        <Phone>
          <ChatBody>
            <Bubble from={SEC(0.8)} side="left" sender="Jake" text="anyone remember what time check-in is tomorrow?" />
          </ChatBody>
        </Phone>
      </Sequence>

      {/* Act 2 (3-7s): Mia + Jake back and forth */}
      <Sequence from={SEC(3)} durationInFrames={SEC(4)}>
        <Phone>
          <ChatBody>
            <Bubble from={0} side="left" sender="Jake" text="anyone remember what time check-in is tomorrow?" />
            <Bubble from={SEC(0.4)} side="left" sender="Mia" text="pretty sure 3pm?" />
            <Bubble from={SEC(1.6)} side="left" sender="Jake" text="need to confirm w the driver" />
            <Bubble from={SEC(2.6)} side="left" sender="Mia" text="idk check the booking" />
          </ChatBody>
        </Phone>
      </Sequence>

      {/* Act 3 (7-11s): you join — "I have the screenshot" */}
      <Sequence from={SEC(7)} durationInFrames={SEC(4)}>
        <Phone>
          <ChatBody>
            <Bubble from={0} side="left" sender="Mia" text="pretty sure 3pm?" />
            <Bubble from={0} side="left" sender="Jake" text="need to confirm w the driver" />
            <Bubble from={0} side="left" sender="Mia" text="idk check the booking" />
            <Bubble from={SEC(0.4)} side="right" text="wait I have the screenshot" />
            <Bubble from={SEC(1.4)} side="right" text="gimme a sec" />
            <TypingDots from={SEC(2.8)} />
          </ChatBody>
        </Phone>
      </Sequence>

      {/* Act 4 (11-16s): the panic — time jumps, "still looking" */}
      <Sequence from={SEC(11)} durationInFrames={SEC(5)}>
        <Phone>
          <ChatBody>
            <Bubble from={0} side="right" text="gimme a sec" />
            <TimeSep from={SEC(0.6)} time="11:03 PM" />
            <Bubble from={SEC(1.0)} side="right" text="it's in here somewhere" />
            <TimeSep from={SEC(2.6)} time="11:19 PM" />
            <Bubble from={SEC(3.0)} side="right" text="fml" />
          </ChatBody>
        </Phone>
      </Sequence>

      {/* Act 5 (16-18s): Mia roasts you */}
      <Sequence from={SEC(16)} durationInFrames={SEC(2)}>
        <Phone>
          <ChatBody>
            <Bubble from={0} side="right" text="it's in here somewhere" />
            <Bubble from={0} side="right" text="fml" />
            <Bubble from={SEC(0.4)} side="left" sender="Mia" text="lol you had one job" />
          </ChatBody>
        </Phone>
      </Sequence>

      {/* Act 6 (18-22s): Sift reveal — ask, answer */}
      <Sequence from={SEC(18)} durationInFrames={SEC(4)}>
        <SiftMock from={0} />
      </Sequence>

      {/* Act 7 (22-24s): back to chat — "FOUND IT" */}
      <Sequence from={SEC(22)} durationInFrames={SEC(2)}>
        <Phone>
          <ChatBody>
            <Bubble from={0} side="left" sender="Mia" text="lol you had one job" />
            <Bubble from={SEC(0.3)} side="right" text="FOUND IT" />
            <Bubble from={SEC(1.0)} side="right" text="3 PM. confirmation #AB2847" />
          </ChatBody>
        </Phone>
      </Sequence>

      {/* Act 8 (24-25s): end lockup */}
      <Sequence from={SEC(24)} durationInFrames={SEC(1)}>
        <AbsoluteFill
          style={{
            background: c.paper,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 60,
          }}
        >
          <EndCard tagline="Never lose the thing you screenshotted." />
        </AbsoluteFill>
      </Sequence>
    </AbsoluteFill>
  );
};
