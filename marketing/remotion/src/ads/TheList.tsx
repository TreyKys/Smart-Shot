import React from 'react';
import {AbsoluteFill, Sequence, interpolate, useCurrentFrame} from 'remotion';
import {SEC, FONT, ensureFonts, c} from '../theme';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 12 · "The List" · 25s · 9:16
// Second deliberately-off-brand Sift ad. Looks like a page of the iOS
// Notes app — pale yellow paper, system font, scratched-out lines, a
// title at the top. The list of "stuff I'll remember" grows faster and
// faster until it's unreadable, then quietly flips to Sift's reframe.
// The joke: this list is a lie. You never remember any of it. You just
// take screenshots.
// ─────────────────────────────────────────────────────────────────────────

const C = {
  paper: '#FEFCE4',        // iOS Notes yellow
  rule: '#F3EBB8',
  ink: '#111',
  pencil: '#555',
  faint: '#9B9B9B',
  accent: '#F0A500',
  // Reused Sift token for the reveal
  siftPaper: c.paper,
};

type Line = {
  text: string;
  strike?: boolean;
  bold?: boolean;
  color?: string;
};

const LINES: Line[] = [
  {text: 'wifi — airbnb paris'},
  {text: "jake's dog's name", strike: true},
  {text: "mia's new address"},
  {text: 'that coffee place in silver lake'},
  {text: 'insurance policy #'},
  {text: "mom's medication"},
  {text: 'car service — $340'},
  {text: 'the quote from that book'},
  {text: 'parking spot — level 3B'},
  {text: 'leo\'s dentist referral'},
  {text: 'the restaurant from the podcast'},
  {text: 'my own passport number lol'},
  {text: 'confirmation # for the flight'},
  {text: 'the recipe for ella\'s cake'},
  {text: 'what is my frequent flyer no.'},
  {text: 'auntie carla\'s birthday'},
  {text: 'the exact words of my vows'},
  {text: 'the garage code'},
  {text: 'which keychain the storage key is on'},
  {text: '....', color: '#9B9B9B'},
];

const Row: React.FC<{from: number; line: Line}> = ({from, line}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 10], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const x = interpolate(frame, [0, 10], [-14, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const strikeDraw = interpolate(frame, [10, 24], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        opacity: op,
        transform: `translateX(${x}px)`,
        padding: '18px 0',
        borderBottom: `1px dashed ${C.rule}`,
        display: 'flex',
        alignItems: 'center',
        gap: 24,
        fontFamily: FONT,
      }}
    >
      <div
        style={{
          width: 24,
          height: 24,
          border: `3px solid ${C.pencil}`,
          borderRadius: 6,
          flexShrink: 0,
        }}
      />
      <div
        style={{
          position: 'relative',
          fontFamily: FONT,
          fontSize: 42,
          fontWeight: line.bold ? 700 : 500,
          color: line.color ?? C.ink,
          lineHeight: 1.1,
        }}
      >
        {line.text}
        {line.strike && (
          <div
            style={{
              position: 'absolute',
              left: 0,
              top: '50%',
              height: 3,
              width: `${strikeDraw * 100}%`,
              background: C.ink,
              transform: 'translateY(-50%) rotate(-1deg)',
            }}
          />
        )}
      </div>
    </div>
  );
};

const NotesHeader: React.FC = () => (
  <div
    style={{
      padding: '70px 70px 20px',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      fontFamily: FONT,
    }}
  >
    <div style={{fontSize: 26, color: C.faint, marginBottom: 10, letterSpacing: 0.3}}>Today · 11:48 PM</div>
    <div style={{fontSize: 60, color: C.ink, fontWeight: 700, textAlign: 'center', lineHeight: 1.1}}>
      stuff i'll remember
    </div>
    <div style={{fontSize: 28, color: C.pencil, marginTop: 10, fontStyle: 'italic'}}>(a lie)</div>
  </div>
);

const Page: React.FC<{children: React.ReactNode; scrollY?: number}> = ({
  children,
  scrollY = 0,
}) => {
  ensureFonts();
  return (
    <AbsoluteFill style={{background: C.paper, overflow: 'hidden'}}>
      {/* Scrollable content — sits BELOW the status bar in the stacking
          order so scrolled rows don't bleed into the time/signal corners */}
      <div
        style={{
          transform: `translateY(${scrollY}px)`,
          display: 'flex',
          flexDirection: 'column',
          paddingTop: 80,
        }}
      >
        {children}
      </div>
      {/* iOS status bar — absolute-positioned OVER the scrolled list, with
          a solid paper backdrop that masks any row that drifts beneath it */}
      <div
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          background: C.paper,
          fontFamily: FONT,
          fontSize: 24,
          fontWeight: 600,
          color: C.ink,
          padding: '28px 44px 10px',
          display: 'flex',
          justifyContent: 'space-between',
        }}
      >
        <span>11:48</span>
        <span>5G ●●●●</span>
      </div>
    </AbsoluteFill>
  );
};

export const TheList: React.FC = () => {
  const frame = useCurrentFrame();
  // Scroll — accelerates once the list gets long. At frame 0 the content
  // sits at translateY(0); as the list fills past the viewport, the whole
  // column drifts up so the newest line stays near the center.
  const scroll = interpolate(frame, [SEC(5), SEC(21)], [0, -1200], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill>
      {/* Acts 1–6 (0–21s): the growing list */}
      <Sequence from={0} durationInFrames={SEC(21)}>
        <Page scrollY={scroll}>
          <NotesHeader />
          <div style={{padding: '0 70px'}}>
            {LINES.map((line, i) => {
              // Lines accelerate: first few are leisurely, later ones pile on fast.
              // Formula tuned to land the final "...." around 19s.
              const start = Math.round(SEC(2 + Math.pow(i, 0.78)));
              return <Row key={i} from={start} line={line} />;
            })}
          </div>
        </Page>
      </Sequence>

      {/* Act 7 (21-23s): the reframe — Notes paper fades through */}
      <Sequence from={SEC(21)} durationInFrames={SEC(2)}>
        <AbsoluteFill
          style={{
            background: C.paper,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 80,
          }}
        >
          <div
            style={{
              fontFamily: FONT,
              fontSize: 54,
              fontWeight: 500,
              color: C.pencil,
              textAlign: 'center',
              lineHeight: 1.3,
              fontStyle: 'italic',
              maxWidth: 900,
            }}
          >
            or
          </div>
          <div
            style={{
              fontFamily: FONT,
              fontSize: 78,
              fontWeight: 800,
              color: C.ink,
              textAlign: 'center',
              lineHeight: 1.1,
              marginTop: 24,
              letterSpacing: -2,
              maxWidth: 920,
            }}
          >
            you already screenshotted all of it.
          </div>
        </AbsoluteFill>
      </Sequence>

      {/* Act 8 (23-25s): end lockup */}
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
          <EndCard tagline="Stop writing the list. Sift already has it." />
        </AbsoluteFill>
      </Sequence>
    </AbsoluteFill>
  );
};
