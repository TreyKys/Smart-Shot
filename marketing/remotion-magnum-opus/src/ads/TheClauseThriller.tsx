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
import {SEC, FONT} from '../theme';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 12 · "The Clause / THRILLER" · 24s · 9:16
// CarbonLoan silent-auto-renewal scenario, re-shot as a Netflix finance
// documentary / thriller opening. Deliberately slow pacing (holds, slow
// zooms), mostly black backgrounds with a serif title grammar, deep red
// as the single hostile accent color. Nothing in common visually with
// the kinetic remix — this is dread, not energy.
// ─────────────────────────────────────────────────────────────────────────

const C = {
  black: '#07070A',
  blackSoft: '#15161C',
  white: '#F2EDE4',
  whiteSoft: '#B7B2A6',
  blood: '#9D0208',
  bloodBright: '#D00000',
  oxblood: '#550000',
  grey: '#4A4A52',
  gold: '#A68C4A',
};

// Slow fade-in with gentle rise
const SlowReveal: React.FC<{
  children: React.ReactNode;
  from: number;
  hold?: number;
  outFrom?: number;
}> = ({children, from, hold = 60, outFrom}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 24], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const outOp =
    outFrom !== undefined
      ? interpolate(frame, [outFrom - from, outFrom - from + 20], [1, 0], {
          extrapolateLeft: 'clamp',
          extrapolateRight: 'clamp',
        })
      : 1;
  return <div style={{opacity: op * outOp}}>{children}</div>;
};

// Vignette on dark bg
const Scene: React.FC<{children: React.ReactNode; tint?: string}> = ({
  children,
  tint = C.black,
}) => (
  <AbsoluteFill
    style={{
      background: tint,
      overflow: 'hidden',
    }}
  >
    {/* Film grain — faint radial */}
    <div
      style={{
        position: 'absolute',
        inset: 0,
        background: `radial-gradient(circle at center, transparent 40%, rgba(0,0,0,0.6) 100%)`,
        pointerEvents: 'none',
      }}
    />
    {/* Subtle 2.35:1 letterbox feel */}
    <div style={{position: 'absolute', top: 0, left: 0, right: 0, height: 60, background: C.black}} />
    <div style={{position: 'absolute', bottom: 0, left: 0, right: 0, height: 60, background: C.black}} />
    {children}
  </AbsoluteFill>
);

// Serif documentary-style title card
const Title: React.FC<{
  from: number;
  pre?: string;
  big: string;
  post?: string;
  color?: string;
}> = ({from, pre, big, post, color = C.white}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 20], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const sc = interpolate(frame, [0, 90], [1, 1.03], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        position: 'absolute',
        inset: 0,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 60,
        opacity: op,
        transform: `scale(${sc})`,
      }}
    >
      {pre && (
        <div
          style={{
            fontFamily: FONT,
            fontSize: 24,
            color: C.whiteSoft,
            fontWeight: 500,
            letterSpacing: 8,
            marginBottom: 30,
          }}
        >
          {pre}
        </div>
      )}
      <div
        style={{
          fontFamily: 'serif',
          fontSize: 180,
          color,
          fontWeight: 400,
          lineHeight: 1,
          letterSpacing: -2,
          textAlign: 'center',
          fontStyle: 'italic',
        }}
      >
        {big}
      </div>
      {post && (
        <div
          style={{
            fontFamily: FONT,
            fontSize: 26,
            color: C.whiteSoft,
            fontWeight: 400,
            fontStyle: 'italic',
            marginTop: 30,
            maxWidth: 900,
            textAlign: 'center',
            lineHeight: 1.4,
          }}
        >
          {post}
        </div>
      )}
    </div>
  );
};

// A date stamp, documentary style (bottom-left corner)
const DateStamp: React.FC<{text: string; from: number}> = ({text, from}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 15], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        position: 'absolute',
        bottom: 100,
        left: 50,
        opacity: op,
        fontFamily: 'monospace',
        fontSize: 22,
        color: C.whiteSoft,
        letterSpacing: 3,
      }}
    >
      {text}
    </div>
  );
};

// A fine-print excerpt from the "contract," presented like evidence
const ContractExcerpt: React.FC<{from: number; highlight?: boolean}> = ({from, highlight}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 20], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const spot = interpolate(frame, [40, 70], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        position: 'absolute',
        inset: 0,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 60,
        opacity: op,
      }}
    >
      <div
        style={{
          background: C.white,
          color: C.black,
          padding: '60px 80px',
          maxWidth: 980,
          fontFamily: 'serif',
          fontSize: 42,
          lineHeight: 1.5,
          position: 'relative',
          boxShadow: '0 40px 100px rgba(0,0,0,0.8)',
        }}
      >
        <div
          style={{
            fontFamily: FONT,
            fontSize: 22,
            color: C.grey,
            fontWeight: 700,
            letterSpacing: 3,
            marginBottom: 24,
          }}
        >
          § 7.4 — PAGE 19
        </div>
        <div style={{fontStyle: 'italic'}}>
          The Loan shall{' '}
          {highlight ? (
            <span style={{background: C.bloodBright, color: C.white, padding: '2px 8px', opacity: spot}}>
              automatically renew every 30 days
            </span>
          ) : (
            <span>automatically renew every 30 days</span>
          )}{' '}
          at the Lender's discretion, with a renewal fee equal to{' '}
          {highlight ? (
            <span style={{background: C.bloodBright, color: C.white, padding: '2px 8px', opacity: spot}}>
              10% of the principal
            </span>
          ) : (
            <span>10% of the principal</span>
          )}
          , unless cancelled in writing seven (7) days prior.
        </div>
      </div>
    </div>
  );
};

// A big number counter with mono font, dread aesthetic
const DebitDisplay: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 20], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        position: 'absolute',
        inset: 0,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 60,
        gap: 20,
        opacity: op,
      }}
    >
      <div
        style={{
          fontFamily: FONT,
          fontSize: 28,
          color: C.bloodBright,
          fontWeight: 700,
          letterSpacing: 8,
        }}
      >
        — DEBITED —
      </div>
      <div
        style={{
          fontFamily: 'monospace',
          fontSize: 240,
          color: C.white,
          fontWeight: 900,
          letterSpacing: -4,
          lineHeight: 1,
        }}
      >
        ₦14,500
      </div>
      <div
        style={{
          fontFamily: FONT,
          fontSize: 24,
          color: C.whiteSoft,
          fontStyle: 'italic',
          marginTop: 20,
          letterSpacing: 2,
        }}
      >
        every 30 days. without warning.
      </div>
    </div>
  );
};

export const TheClauseThriller: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Lower-volume music bed for dread pacing */}
      <Sequence from={0} durationInFrames={SEC(24)}>
        <Audio src={staticFile('sfx/music-bed.mp3')} volume={0.15} />
      </Sequence>

      {/* Act 1 (0-3.5s): slow fade in — "A STORY ABOUT MONEY" */}
      <Sequence from={0} durationInFrames={SEC(3.5)}>
        <Scene>
          <Title
            from={SEC(0.3)}
            pre="A FILM ABOUT THE FINE PRINT"
            big="Signed."
            post="Three million Nigerians sign loan agreements every month. Most never read them."
          />
        </Scene>
      </Sequence>

      {/* Act 2 (3.5-6s): date stamp + a date, documentary cold-open feel */}
      <Sequence from={SEC(3.5)} durationInFrames={SEC(2.5)}>
        <Scene>
          <Title
            from={SEC(0.2)}
            pre="SEPTEMBER · LAGOS"
            big={`"I needed ₦50,000 for school fees."`}
            color={C.white}
          />
          <DateStamp from={SEC(0.5)} text="REC · 09:14:28" />
        </Scene>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* Act 3 (6-9s): contract excerpt — not yet highlighted */}
      <Sequence from={SEC(6)} durationInFrames={SEC(3)}>
        <Scene tint={C.blackSoft}>
          <ContractExcerpt from={SEC(0.2)} highlight={false} />
          <DateStamp from={SEC(0.2)} text="EVIDENCE · DOC 1 OF 1" />
        </Scene>
        <Audio src={staticFile('sfx/pop.mp3')} />
      </Sequence>

      {/* Act 4 (9-12s): the same excerpt — now with highlights */}
      <Sequence from={SEC(9)} durationInFrames={SEC(3)}>
        <Scene tint={C.blackSoft}>
          <ContractExcerpt from={SEC(0.2)} highlight={true} />
          <DateStamp from={SEC(0.2)} text="EVIDENCE · DOC 1 OF 1 · ANNOTATED" />
        </Scene>
      </Sequence>

      {/* Act 5 (12-15s): the debit alert — full dread */}
      <Sequence from={SEC(12)} durationInFrames={SEC(3)}>
        <Scene>
          <DebitDisplay from={SEC(0.3)} />
          <DateStamp from={SEC(0.3)} text="DAY 31. 00:00:00." />
        </Scene>
        <Audio src={staticFile('sfx/debit.mp3')} />
      </Sequence>

      {/* Act 6 (15-17s): a serif aphorism */}
      <Sequence from={SEC(15)} durationInFrames={SEC(2)}>
        <Scene>
          <Title
            from={SEC(0.2)}
            big="The clause was always there."
            post="You just didn't ask."
            color={C.white}
          />
        </Scene>
      </Sequence>

      {/* Act 7 (17-19s): "there is a question" */}
      <Sequence from={SEC(17)} durationInFrames={SEC(2)}>
        <Scene>
          <Title
            from={SEC(0.2)}
            pre="THERE IS, HOWEVER, A QUESTION."
            big="One."
            color={C.bloodBright}
          />
        </Scene>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* Act 8 (19-21.5s): MO interrogates the document, cited answer */}
      <Sequence from={SEC(19)} durationInFrames={SEC(2.5)}>
        <Scene tint={C.blackSoft}>
          <div
            style={{
              position: 'absolute',
              inset: 0,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              padding: 60,
              gap: 30,
            }}
          >
            <div
              style={{
                fontFamily: 'serif',
                fontSize: 50,
                fontStyle: 'italic',
                color: C.whiteSoft,
                textAlign: 'center',
                maxWidth: 900,
                lineHeight: 1.3,
              }}
            >
              "Anything I should watch out for before I sign this?"
            </div>
            <div
              style={{
                padding: '26px 40px',
                background: C.white,
                color: C.black,
                maxWidth: 900,
                fontFamily: 'serif',
                fontSize: 44,
                fontWeight: 700,
                lineHeight: 1.3,
                textAlign: 'center',
              }}
            >
              Yes. It auto-renews.{' '}
              <span style={{color: C.bloodBright}}>Every 30 days.</span>
            </div>
            <div
              style={{
                fontFamily: FONT,
                fontSize: 22,
                color: C.gold,
                letterSpacing: 3,
                fontWeight: 700,
              }}
            >
              — Magnum Opus. Cited: §7.4, p19.
            </div>
          </div>
        </Scene>
        <Audio src={staticFile('sfx/chime-win.mp3')} />
      </Sequence>

      {/* Act 9 (21.5-24s): end title + lockup */}
      <Sequence from={SEC(21.5)} durationInFrames={SEC(2.5)}>
        <Scene tint="#F6F3E8">
          <div
            style={{
              position: 'absolute',
              inset: 0,
              background: '#F6F3E8',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              padding: 60,
            }}
          >
            <EndCard tagline="Ask before you sign." />
          </div>
        </Scene>
        <Audio src={staticFile('sfx/chime-win.mp3')} />
      </Sequence>
    </AbsoluteFill>
  );
};
