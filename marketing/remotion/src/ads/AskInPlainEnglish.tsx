import React from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, interpolate} from 'remotion';
import {theme, fonts, SEC} from '../theme';
import {BgGradient} from '../components/BgGradient';
import {PhoneFrame} from '../components/PhoneFrame';
import {Screenshot} from '../components/Screenshot';
import {Kicker} from '../components/Kicker';
import {Logo} from '../components/Logo';
import {useFadeIn, useFadeInOut} from '../components/anim';

// ─────────────────────────────────────────────────────────────────────────
// AD 5 · "Ask in Plain English" · 20s
// Angle: the AI chat. No filters, no folders, no learning "the app's way"
// — you talk to it like you'd text a friend.
// ─────────────────────────────────────────────────────────────────────────

// Progressive typewriter — reveals text as if it's being typed.
const Typewriter: React.FC<{text: string; from: number; chars: number; style?: React.CSSProperties}> = ({
  text,
  from,
  chars,
  style,
}) => {
  const frame = useCurrentFrame() - from;
  const revealed = Math.min(text.length, Math.max(0, Math.floor((frame / chars) * text.length)));
  return <span style={style}>{text.slice(0, revealed)}</span>;
};

const ChatBubble: React.FC<{
  from: number;
  text?: string;
  fromUser?: boolean;
  typing?: boolean;
  children?: React.ReactNode;
}> = ({from, text, fromUser, typing, children}) => {
  const op = useFadeIn(from, 8);
  return (
    <div
      style={{
        opacity: op,
        alignSelf: fromUser ? 'flex-end' : 'flex-start',
        maxWidth: '85%',
        padding: '14px 18px',
        borderRadius: 22,
        background: fromUser
          ? `linear-gradient(135deg, ${theme.accent}, ${theme.accentDim})`
          : theme.surfaceElev,
        color: fromUser ? '#fff' : theme.textPrimary,
        border: fromUser ? 'none' : `1px solid ${theme.border}`,
        fontFamily: fonts.ui,
        fontSize: 16,
        fontWeight: 500,
        lineHeight: 1.4,
      }}
    >
      {typing && text ? <Typewriter text={text} from={from + 3} chars={35} /> : text}
      {children}
    </div>
  );
};

const ChatScreen: React.FC = () => {
  return (
    <div style={{display: 'flex', flexDirection: 'column', gap: 12, padding: 20}}>
      {/* Header */}
      <div
        style={{
          textAlign: 'center',
          color: theme.textSecondary,
          fontSize: 14,
          fontWeight: 600,
          marginBottom: 8,
        }}
      >
        Ask Sift
      </div>
      {/* Prompt bubble */}
      <ChatBubble
        from={SEC(2)}
        text="find that uber receipt from october — the airport one"
        fromUser
        typing
      />
      {/* Response bubble */}
      <ChatBubble from={SEC(6)}>
        <div>
          Found it — <b>Oct 14</b>, LAX → Downtown, $47.60.
        </div>
        <div
          style={{
            marginTop: 10,
            display: 'grid',
            gridTemplateColumns: 'repeat(3, 1fr)',
            gap: 6,
          }}
        >
          <Screenshot
            hue={theme.tag.finance}
            icon="🧾"
            size={80}
            tag="#Receipt"
            tagColor={theme.tag.finance}
          />
        </div>
      </ChatBubble>
    </div>
  );
};

export const AskInPlainEnglish: React.FC = () => {
  return (
    <AbsoluteFill style={{background: theme.bg, fontFamily: fonts.ui}}>
      <BgGradient from={theme.accent} intensity={0.28} />

      {/* Beat 1 (0-3s): the question */}
      <Sequence from={0} durationInFrames={SEC(3)}>
        <AbsoluteFill
          style={{justifyContent: 'center', alignItems: 'center'}}
        >
          <Kicker
            headline={"No folders. No filters."}
            sub={"Just ask."}
            from={SEC(0.3)}
          />
        </AbsoluteFill>
      </Sequence>

      {/* Beat 2 (3-15s): chat interaction */}
      <Sequence from={SEC(3)} durationInFrames={SEC(12)}>
        <AbsoluteFill
          style={{justifyContent: 'center', alignItems: 'center'}}
        >
          <PhoneFrame width={430}>
            <ChatScreen />
          </PhoneFrame>
        </AbsoluteFill>
      </Sequence>

      {/* Beat 3 (15-20s): logo. Sequence-local from here. */}
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
            headline={"Ask like a human."}
            sub={"Answer like a friend."}
            from={0}
          />
          <div style={{marginTop: 40}}>
            <Logo from={SEC(2)} size={80} />
          </div>
        </AbsoluteFill>
      </Sequence>
    </AbsoluteFill>
  );
};
