import React from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, interpolate} from 'remotion';
import {theme, fonts, SEC} from '../theme';
import {BgGradient} from '../components/BgGradient';
import {PhoneFrame} from '../components/PhoneFrame';
import {Screenshot} from '../components/Screenshot';
import {Logo} from '../components/Logo';
import {useFadeIn, useFadeInOut} from '../components/anim';

// ─────────────────────────────────────────────────────────────────────────
// AD 1 · "The 5-Minute Search" · 20s
// Angle: everyone has that receipt / voucher / boarding pass buried
// somewhere in 3,000 screenshots and can't find it when they need it.
//
// IMPORTANT: `useCurrentFrame()` inside a <Sequence> is Sequence-LOCAL
// (frame 0 at the Sequence's `from` boundary). All `from={...}` values
// passed to child components below are therefore Sequence-local — never
// composition-absolute. The initial version of this file used absolute
// frames and nothing inside any Sequence ever faded in.
//
// Narration cue (optional VO):
//   0-4s  "Where's that Uber receipt?"
//   4-9s  "Was it March? April? …It's in here somewhere."
//   9-14s "3,247 screenshots. One receipt."
//  14-18s "Sift finds it in three seconds."
//  18-20s "Sift. Just ask."
// ─────────────────────────────────────────────────────────────────────────

const ScrollingGrid: React.FC = () => {
  const frame = useCurrentFrame();
  const y = interpolate(frame, [0, SEC(9)], [0, -1400]);
  const tiles = Array.from({length: 60});
  const colors = [
    theme.tag.finance,
    theme.tag.memes,
    theme.tag.travel,
    theme.tag.junk,
    theme.tag.social,
    theme.tag.todo,
    theme.tag.web3,
    theme.tag.code,
  ];
  const icons = ['🧾', '💬', '🎫', '📸', '📍', '💳', '🎥', '🔗', '📝', '📦'];
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
          gap: 10,
          transform: `translateY(${y}px)`,
        }}
      >
        {tiles.map((_, i) => (
          <Screenshot
            key={i}
            hue={colors[i % colors.length]}
            icon={icons[i % icons.length]}
            size={112}
          />
        ))}
      </div>
    </div>
  );
};

const AskResult: React.FC = () => {
  const chipsIn = useFadeIn(0, 20);
  return (
    <div
      style={{
        padding: 20,
        display: 'flex',
        flexDirection: 'column',
        gap: 14,
        opacity: chipsIn,
      }}
    >
      <div
        style={{
          background: theme.surfaceElev,
          borderRadius: 20,
          padding: '14px 18px',
          color: theme.textPrimary,
          fontSize: 22,
          border: `1px solid ${theme.border}`,
          alignSelf: 'flex-end',
          maxWidth: '85%',
          fontFamily: fonts.ui,
        }}
      >
        find my uber receipts from march
      </div>
      <div
        style={{
          background: `linear-gradient(135deg, ${theme.accent}, ${theme.accentDim})`,
          borderRadius: 20,
          padding: '14px 18px',
          color: '#fff',
          fontSize: 22,
          alignSelf: 'flex-start',
          maxWidth: '85%',
          fontFamily: fonts.ui,
          fontWeight: 500,
        }}
      >
        Found 4 receipts. Total $87.50.
      </div>
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(4, 1fr)',
          gap: 8,
          marginTop: 6,
        }}
      >
        {[0, 1, 2, 3].map((i) => (
          <Screenshot
            key={i}
            hue={theme.tag.finance}
            icon="🧾"
            size={80}
            tag="#Receipt"
            tagColor={theme.tag.finance}
          />
        ))}
      </div>
    </div>
  );
};

export const SearchFrustration: React.FC = () => {
  return (
    <AbsoluteFill style={{background: theme.bg, fontFamily: fonts.ui}}>
      <BgGradient from={theme.danger} intensity={0.15} />

      {/* Beat 1 (0-9s): the frantic scroll */}
      <Sequence from={0} durationInFrames={SEC(9.2)}>
        <AbsoluteFill style={{justifyContent: 'center', alignItems: 'center'}}>
          <PhoneFrame width={520}>
            <ScrollingGrid />
          </PhoneFrame>
        </AbsoluteFill>
        <AbsoluteFill
          style={{
            justifyContent: 'flex-start',
            alignItems: 'center',
            paddingTop: 140,
            pointerEvents: 'none',
          }}
        >
          <FrustrationOverlay />
        </AbsoluteFill>
      </Sequence>

      {/* Beat 2 (9-14s): the number lands */}
      <Sequence from={SEC(9)} durationInFrames={SEC(5)}>
        <AbsoluteFill
          style={{
            background: theme.bg,
            justifyContent: 'center',
            alignItems: 'center',
          }}
        >
          <NumberPunch />
        </AbsoluteFill>
      </Sequence>

      {/* Beat 3 (14-18s): the answer arrives */}
      <Sequence from={SEC(14)} durationInFrames={SEC(4)}>
        <AbsoluteFill style={{justifyContent: 'center', alignItems: 'center'}}>
          <PhoneFrame width={520}>
            <AskResult />
          </PhoneFrame>
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
          <Logo from={0} tagline="Just ask." />
        </AbsoluteFill>
      </Sequence>
    </AbsoluteFill>
  );
};

const FrustrationOverlay: React.FC = () => {
  const l1 = useFadeInOut(SEC(0.5), SEC(4));
  const l2 = useFadeInOut(SEC(3), SEC(7));
  const l3 = useFadeInOut(SEC(6), SEC(9));
  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        gap: 20,
        alignItems: 'center',
        textShadow: '0 3px 20px rgba(0,0,0,0.9)',
      }}
    >
      <div
        style={{
          opacity: l1,
          fontSize: 72,
          fontWeight: 800,
          color: theme.textPrimary,
          letterSpacing: -1.5,
          textAlign: 'center',
        }}
      >
        Where's that receipt?
      </div>
      <div
        style={{
          opacity: l2,
          fontSize: 44,
          color: theme.textSecondary,
          fontWeight: 600,
        }}
      >
        …was it March? April?
      </div>
      <div
        style={{
          opacity: l3,
          fontSize: 38,
          color: theme.danger,
          fontWeight: 700,
          letterSpacing: 1,
        }}
      >
        it's in here somewhere.
      </div>
    </div>
  );
};

const NumberPunch: React.FC = () => {
  // Sequence-local: this component lives inside a Sequence from SEC(9), so
  // its own frame 0 = the composition's SEC(9) mark. Fades start at
  // Sequence-local 0 and 1.5s.
  const numOp = useFadeIn(0, 8);
  const subOp = useFadeIn(SEC(1.5), 10);
  return (
    <div style={{textAlign: 'center', fontFamily: fonts.ui}}>
      <div
        style={{
          opacity: numOp,
          fontSize: 320,
          fontWeight: 800,
          color: theme.accent,
          letterSpacing: -10,
          lineHeight: 1,
          fontVariantNumeric: 'tabular-nums',
        }}
      >
        3,247
      </div>
      <div
        style={{
          opacity: numOp,
          fontSize: 52,
          color: theme.textPrimary,
          fontWeight: 600,
          marginTop: 8,
        }}
      >
        screenshots.
      </div>
      <div
        style={{
          opacity: subOp,
          fontSize: 68,
          color: theme.danger,
          fontWeight: 800,
          marginTop: 26,
          letterSpacing: -1,
        }}
      >
        One receipt.
      </div>
    </div>
  );
};
