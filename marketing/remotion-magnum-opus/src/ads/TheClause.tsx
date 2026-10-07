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
import {c, SEC, FONT} from '../theme';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 8 · "The Clause That Costs You" · 25s · 9:16
// Stakes-driven, grounded in lending-app pain (Branch, Carbon, FairMoney,
// Palmpay). The scenario everyone knows: you borrowed ₦X, you paid it
// back, now you're seeing a mystery debit for a "renewal fee" or "insurance
// cover" you never agreed to on purpose — it was in the 23 pages of T&C
// you scrolled past.
//
// Beat shape: debit alert → wait what loan? → flashback to signing (23
// pages, speed-scroll, "I AGREE") → zoom on the one buried clause → MO
// reveal (what the right question would have surfaced in 10 seconds) →
// end card.
// ─────────────────────────────────────────────────────────────────────────

const C = {
  screenDark: '#000',
  screenLight: '#F2F2F7',
  statusBar: '#000',
  bankCard: '#1C1C1E',
  bankText: '#FFF',
  debitRed: '#FF453A',
  pdfBg: '#FFFFFF',
  pdfLine: '#1C1C1E',
  pdfFaint: '#999',
  highlightYellow: '#FFEB3B',
  meta: '#8E8E93',
};

const StatusBar: React.FC<{darkText?: boolean}> = ({darkText = true}) => (
  <div
    style={{
      fontFamily: FONT,
      fontSize: 24,
      fontWeight: 600,
      color: darkText ? '#000' : '#FFF',
      padding: '28px 44px 10px',
      display: 'flex',
      justifyContent: 'space-between',
    }}
  >
    <span>7:12</span>
    <span>4G •••</span>
  </div>
);

// ── Debit alert — the gut-punch bank notification ────────────────────────
const DebitAlert: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 18, stiffness: 160, mass: 0.6}});
  const op = interpolate(s, [0, 1], [0, 1]);
  const y = interpolate(s, [0, 1], [60, 0]);
  const shake = Math.sin((frame * Math.PI) / 4) * (frame < 20 ? 4 : 0);
  return (
    <AbsoluteFill style={{background: C.screenDark}}>
      <StatusBar darkText={false} />
      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          padding: 40,
        }}
      >
        <div
          style={{
            opacity: op,
            transform: `translate(${shake}px, ${y}px)`,
            width: '92%',
            background: C.bankCard,
            borderRadius: 24,
            padding: '32px 36px',
            border: `2px solid ${C.debitRed}`,
            boxShadow: `0 0 40px ${C.debitRed}44`,
            fontFamily: FONT,
          }}
        >
          <div
            style={{
              fontSize: 24,
              color: C.debitRed,
              fontWeight: 800,
              letterSpacing: 2,
              marginBottom: 12,
            }}
          >
            DEBIT ALERT
          </div>
          <div
            style={{
              fontSize: 72,
              color: C.bankText,
              fontWeight: 800,
              letterSpacing: -2,
              marginBottom: 10,
              lineHeight: 1,
            }}
          >
            −₦14,500
          </div>
          <div style={{fontSize: 28, color: '#D1D1D6', fontWeight: 500, marginBottom: 18}}>
            CarbonLoan — Renewal Fee
          </div>
          <div
            style={{
              fontSize: 22,
              color: C.meta,
              fontWeight: 500,
              borderTop: '1px solid #333',
              paddingTop: 16,
            }}
          >
            Available balance: ₦3,284.00
          </div>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// ── Confusion — what loan? ───────────────────────────────────────────────
const WhatLoan: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 14], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <AbsoluteFill
      style={{
        background: '#0F0F0F',
        opacity: op,
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
          fontFamily: FONT,
          fontSize: 32,
          color: C.debitRed,
          fontWeight: 700,
          letterSpacing: 3,
          textTransform: 'uppercase',
        }}
      >
        wait
      </div>
      <div
        style={{
          fontFamily: FONT,
          fontSize: 110,
          color: '#FFF',
          fontWeight: 800,
          lineHeight: 1,
          letterSpacing: -3,
          textAlign: 'center',
        }}
      >
        what loan?
      </div>
    </AbsoluteFill>
  );
};

// ── Flashback: signing — PDF speed-scroll past 23 pages ──────────────────
const SpeedScroll: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const scrollY = interpolate(frame, [0, 100], [0, -3600], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <AbsoluteFill style={{background: C.screenLight}}>
      <StatusBar />
      {/* Doc title bar */}
      <div
        style={{
          padding: '12px 24px',
          background: '#FFF',
          borderBottom: `1px solid #D1D1D6`,
          fontFamily: FONT,
          fontSize: 24,
          fontWeight: 600,
          color: '#000',
          display: 'flex',
          justifyContent: 'space-between',
        }}
      >
        <span>Loan Agreement.pdf</span>
        <span style={{color: C.meta}}>23 pages</span>
      </div>
      {/* Scrolling text pages */}
      <div
        style={{
          flex: 1,
          background: C.pdfBg,
          overflow: 'hidden',
          padding: '20px 30px',
        }}
      >
        <div
          style={{
            transform: `translateY(${scrollY}px)`,
            display: 'flex',
            flexDirection: 'column',
            gap: 24,
          }}
        >
          {Array.from({length: 60}).map((_, i) => (
            <div key={i} style={{display: 'flex', flexDirection: 'column', gap: 8}}>
              <div
                style={{
                  width: `${50 + (i * 7) % 40}%`,
                  height: 20,
                  background: C.pdfFaint,
                  borderRadius: 4,
                  opacity: 0.6,
                }}
              />
              <div
                style={{
                  width: `${65 + (i * 11) % 30}%`,
                  height: 16,
                  background: C.pdfFaint,
                  borderRadius: 4,
                  opacity: 0.4,
                }}
              />
              <div
                style={{
                  width: `${40 + (i * 13) % 50}%`,
                  height: 16,
                  background: C.pdfFaint,
                  borderRadius: 4,
                  opacity: 0.4,
                }}
              />
            </div>
          ))}
        </div>
      </div>
      {/* I AGREE button stuck at bottom */}
      <div style={{padding: '20px 30px', background: '#FFF', borderTop: '1px solid #D1D1D6'}}>
        <div
          style={{
            padding: '26px',
            background: c.accentBright,
            color: '#fff',
            borderRadius: 16,
            textAlign: 'center',
            fontFamily: FONT,
            fontSize: 36,
            fontWeight: 700,
            letterSpacing: 1,
          }}
        >
          I AGREE
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ── Zoom on the one buried clause ────────────────────────────────────────
const BuriedClause: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const highlightDraw = interpolate(frame, [20, 46], [0, 100], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const op = interpolate(frame, [0, 14], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <AbsoluteFill style={{background: C.pdfBg, opacity: op}}>
      <StatusBar />
      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          padding: '140px 70px 80px',
          justifyContent: 'center',
          gap: 30,
        }}
      >
        <div
          style={{
            fontFamily: FONT,
            fontSize: 22,
            color: C.meta,
            fontWeight: 600,
            letterSpacing: 2,
          }}
        >
          SECTION 7.4 · PAGE 19
        </div>
        <div
          style={{
            fontFamily: FONT,
            fontSize: 40,
            fontWeight: 500,
            color: '#000',
            lineHeight: 1.5,
            position: 'relative',
          }}
        >
          "The Loan shall{' '}
          <span
            style={{
              background: `linear-gradient(to right, ${C.highlightYellow} ${highlightDraw}%, transparent ${highlightDraw}%)`,
              padding: '0 4px',
              fontWeight: 700,
            }}
          >
            automatically renew every 30 days
          </span>{' '}
          at the Lender's discretion, with a renewal fee equal to{' '}
          <span
            style={{
              background: `linear-gradient(to right, ${C.highlightYellow} ${highlightDraw}%, transparent ${highlightDraw}%)`,
              padding: '0 4px',
              fontWeight: 700,
            }}
          >
            10% of the principal
          </span>
          , unless cancelled in writing 7 days prior."
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// ── Magnum Opus — the right question, answered ───────────────────────────
const MoReveal: React.FC = () => {
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
  const chipOp = interpolate(frame, [50, 64], [0, 1], {
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
          gap: 20,
        }}
      >
        <div
          style={{
            fontFamily: FONT,
            fontSize: 42,
            fontWeight: 800,
            color: c.ink,
          }}
        >
          Magnum <span style={{fontStyle: 'italic'}}>Opus</span>
        </div>
        <div
          style={{
            fontFamily: FONT,
            fontSize: 24,
            color: c.inkFaint,
            fontWeight: 500,
            letterSpacing: 2,
            marginBottom: 20,
          }}
        >
          THE QUESTION YOU FORGOT TO ASK
        </div>
        <div
          style={{
            opacity: askOp,
            alignSelf: 'flex-end',
            background: c.accentBright,
            padding: '26px 36px',
            borderRadius: 32,
            borderBottomRightRadius: 10,
            color: '#fff',
            fontFamily: FONT,
            fontSize: 34,
            fontWeight: 500,
            marginBottom: 30,
            maxWidth: '92%',
            lineHeight: 1.3,
          }}
        >
          anything I should watch out for before I sign this?
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
            fontSize: 34,
            fontWeight: 500,
            color: c.ink,
            lineHeight: 1.4,
            maxWidth: '95%',
            boxShadow: '0 30px 70px rgba(15,22,38,0.08)',
          }}
        >
          Yes — the loan{' '}
          <span style={{color: c.accent, fontWeight: 700}}>auto-renews every 30 days</span>{' '}
          with a <span style={{color: c.accent, fontWeight: 700}}>10% renewal fee</span>{' '}
          unless you cancel 7 days before.
          <div style={{marginTop: 20, opacity: chipOp}}>
            <span
              style={{
                display: 'inline-block',
                padding: '10px 22px',
                borderRadius: 999,
                background: c.accentWash,
                color: c.accent,
                fontSize: 22,
                fontWeight: 700,
                letterSpacing: 0.5,
              }}
            >
              Cited — §7.4, Page 19
            </span>
          </div>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

export const TheClause: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Act 1 (0-4s): the debit lands */}
      <Sequence from={0} durationInFrames={SEC(4)}>
        <DebitAlert from={0} />
        <Sequence from={SEC(0.2)} durationInFrames={SEC(0.6)}>
          <Audio src={staticFile('sfx/debit.mp3')} />
        </Sequence>
      </Sequence>

      {/* Act 2 (4-7s): wait, what loan? */}
      <Sequence from={SEC(4)} durationInFrames={SEC(3)}>
        <WhatLoan from={0} />
        <Sequence from={0} durationInFrames={SEC(0.3)}>
          <Audio src={staticFile('sfx/nope.mp3')} />
        </Sequence>
      </Sequence>

      {/* Act 3 (7-13s): flashback — speed-scrolling 23 pages, hitting agree */}
      <Sequence from={SEC(7)} durationInFrames={SEC(6)}>
        <SpeedScroll from={0} />
        <Sequence from={SEC(0.3)} durationInFrames={SEC(0.1)}>
          <Audio src={staticFile('sfx/click.mp3')} />
        </Sequence>
        <Sequence from={SEC(1.0)} durationInFrames={SEC(0.1)}>
          <Audio src={staticFile('sfx/click.mp3')} />
        </Sequence>
        <Sequence from={SEC(1.8)} durationInFrames={SEC(0.1)}>
          <Audio src={staticFile('sfx/click.mp3')} />
        </Sequence>
        <Sequence from={SEC(2.6)} durationInFrames={SEC(0.1)}>
          <Audio src={staticFile('sfx/click.mp3')} />
        </Sequence>
        <Sequence from={SEC(3.4)} durationInFrames={SEC(0.1)}>
          <Audio src={staticFile('sfx/click.mp3')} />
        </Sequence>
        <Sequence from={SEC(4.5)} durationInFrames={SEC(0.3)}>
          <Audio src={staticFile('sfx/pop.mp3')} />
        </Sequence>
      </Sequence>

      {/* Act 4 (13-17s): zoom on the buried clause */}
      <Sequence from={SEC(13)} durationInFrames={SEC(4)}>
        <BuriedClause from={0} />
        <Sequence from={SEC(0.6)} durationInFrames={SEC(0.5)}>
          <Audio src={staticFile('sfx/ding.mp3')} />
        </Sequence>
      </Sequence>

      {/* Act 5 (17-23s): Magnum Opus — the right question answered */}
      <Sequence from={SEC(17)} durationInFrames={SEC(6)}>
        <MoReveal />
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

      {/* Act 6 (23-25s): end lockup */}
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
          <EndCard tagline="Ask the doc before you sign it." />
        </AbsoluteFill>
        <Sequence from={SEC(0.3)} durationInFrames={SEC(0.5)}>
          <Audio src={staticFile('sfx/ding.mp3')} />
        </Sequence>
      </Sequence>
    </AbsoluteFill>
  );
};
