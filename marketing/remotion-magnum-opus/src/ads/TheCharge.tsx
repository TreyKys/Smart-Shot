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
// AD 9 · "The Charge" · 25s · 9:16
// Universal shock scenario: hospital bill at discharge. One line reads
// "Miscellaneous service fee: ₦25,000" and nobody at the counter can
// explain it. The cashier says "that's just what the system says." You
// paid it last time. This time you ask MO what you actually signed —
// and it tells you exactly what the fee covers and whether the amount
// is standard.
//
// Beat shape: the itemised bill with a shock amount → the line that
// makes no sense → the shrug from the cashier → MO reveal (clause +
// what it actually means) → end card.
// ─────────────────────────────────────────────────────────────────────────

const C = {
  paper: '#FDFCF7',       // off-white carbonless-copy paper
  rule: '#1C1C1E',
  faint: '#999',
  ink: '#0F1626',
  stamp: '#B91C1C',
  highlight: '#FFEB3B',
  meta: '#8E8E93',
};

type Row = {label: string; amount: string; highlight?: boolean};
const BILL: Row[] = [
  {label: 'Consultation', amount: '₦5,000'},
  {label: 'Blood test (CBC)', amount: '₦8,500'},
  {label: 'Blood test (Malaria)', amount: '₦3,200'},
  {label: 'IV drip (Ringers)', amount: '₦4,800'},
  {label: 'Anti-malarial drugs', amount: '₦6,500'},
  {label: 'Pain management', amount: '₦3,000'},
  {label: 'Overnight observation', amount: '₦18,000'},
  {label: 'Nurse attendance', amount: '₦4,500'},
  {label: 'Oxygen (standby)', amount: '₦2,750'},
  {label: 'Miscellaneous service fee', amount: '₦25,000', highlight: true},
  {label: 'VAT (7.5%)', amount: '₦6,000'},
];

const BillRow: React.FC<{from: number; row: Row}> = ({from, row}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 10], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        opacity: op,
        display: 'grid',
        gridTemplateColumns: '1fr auto',
        padding: '10px 0',
        borderBottom: `1px dashed ${C.faint}`,
        fontFamily: FONT,
        fontSize: 28,
        color: C.ink,
        gap: 20,
      }}
    >
      <span style={{fontWeight: row.highlight ? 700 : 500}}>{row.label}</span>
      <span style={{fontWeight: 700, color: row.highlight ? C.stamp : C.ink, fontFamily: 'monospace'}}>
        {row.amount}
      </span>
    </div>
  );
};

const BillHeader: React.FC = () => (
  <div style={{textAlign: 'center', fontFamily: FONT, paddingBottom: 20, borderBottom: `2px solid ${C.rule}`}}>
    <div style={{fontSize: 42, fontWeight: 800, color: C.ink, letterSpacing: 2}}>
      LAGOON PRIVATE HOSPITAL
    </div>
    <div style={{fontSize: 22, color: C.faint, marginTop: 6, letterSpacing: 1}}>
      Discharge Invoice · #DH-28491
    </div>
  </div>
);

const BillPage: React.FC<{children: React.ReactNode; scrollY?: number}> = ({
  children,
  scrollY = 0,
}) => (
  <AbsoluteFill style={{background: C.paper, overflow: 'hidden'}}>
    <AbsoluteFill
      style={{
        transform: `translateY(${scrollY}px)`,
        padding: '80px 60px',
        display: 'flex',
        flexDirection: 'column',
        gap: 30,
      }}
    >
      {children}
    </AbsoluteFill>
  </AbsoluteFill>
);

// Zoom on the mystery line
const MysteryLine: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const highlightDraw = interpolate(frame, [15, 40], [0, 100], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <AbsoluteFill style={{background: C.paper}}>
      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          padding: '140px 60px 80px',
          justifyContent: 'center',
          gap: 36,
        }}
      >
        <div
          style={{
            fontFamily: FONT,
            fontSize: 24,
            color: C.meta,
            fontWeight: 600,
            letterSpacing: 2,
          }}
        >
          LINE 10 OF 11
        </div>
        <div
          style={{
            fontFamily: FONT,
            fontSize: 48,
            color: C.ink,
            fontWeight: 500,
            lineHeight: 1.3,
            position: 'relative',
          }}
        >
          <span
            style={{
              background: `linear-gradient(to right, ${C.highlight} ${highlightDraw}%, transparent ${highlightDraw}%)`,
              padding: '2px 6px',
              fontWeight: 700,
            }}
          >
            Miscellaneous service fee
          </span>
          <br />
          <span style={{fontSize: 100, fontWeight: 800, color: C.stamp, fontFamily: 'monospace', letterSpacing: -2, display: 'inline-block', marginTop: 20}}>
            ₦25,000
          </span>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// Cashier's shrug — black screen with dialog bubble
const CashierShrug: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 24, stiffness: 150, mass: 0.6}});
  const op = interpolate(s, [0, 1], [0, 1]);
  const y = interpolate(s, [0, 1], [18, 0]);
  return (
    <AbsoluteFill
      style={{
        background: '#0F0F0F',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 60,
        gap: 24,
      }}
    >
      <div
        style={{
          fontFamily: FONT,
          fontSize: 24,
          color: C.meta,
          fontWeight: 600,
          letterSpacing: 3,
          textTransform: 'uppercase',
          marginBottom: 20,
        }}
      >
        at the cashier
      </div>
      <div
        style={{
          opacity: op,
          transform: `translateY(${y}px)`,
          padding: '28px 36px',
          background: '#1C1C1E',
          borderRadius: 24,
          maxWidth: '90%',
          fontFamily: FONT,
          fontSize: 36,
          color: '#fff',
          fontWeight: 500,
          lineHeight: 1.4,
          textAlign: 'center',
        }}
      >
        "that's just what the system says."
      </div>
      <div
        style={{
          opacity: op,
          fontFamily: FONT,
          fontSize: 24,
          color: C.meta,
          marginTop: 10,
          fontStyle: 'italic',
        }}
      >
        — the cashier, every time
      </div>
    </AbsoluteFill>
  );
};

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
            fontSize: 22,
            color: c.inkFaint,
            fontWeight: 500,
            letterSpacing: 2,
            marginBottom: 20,
          }}
        >
          CONSENT FORM YOU SIGNED AT ADMISSION
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
            fontSize: 32,
            fontWeight: 500,
            marginBottom: 30,
            maxWidth: '92%',
            lineHeight: 1.3,
          }}
        >
          what's the "miscellaneous service fee" on my bill?
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
            fontSize: 32,
            fontWeight: 500,
            color: c.ink,
            lineHeight: 1.4,
            maxWidth: '95%',
            boxShadow: '0 30px 70px rgba(15,22,38,0.08)',
          }}
        >
          §4.2 — covers{' '}
          <span style={{color: c.accent, fontWeight: 700}}>bed-sheet laundry</span>,{' '}
          <span style={{color: c.accent, fontWeight: 700}}>equipment sterilisation</span>,
          and{' '}
          <span style={{color: c.accent, fontWeight: 700}}>administrative handling</span>.
          <br />
          <span style={{fontSize: 26, color: c.inkSoft}}>
            Standard range: ₦8,000–₦12,000. Yours is itemised separately on page 3.
          </span>
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
              Cited — Consent form, §4.2
            </span>
          </div>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

export const TheCharge: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Act 1 (0-6s): the itemised bill lands, row by row */}
      <Sequence from={0} durationInFrames={SEC(6)}>
        <BillPage>
          <BillHeader />
          <div style={{display: 'flex', flexDirection: 'column'}}>
            {BILL.map((row, i) => (
              <BillRow key={row.label} from={SEC(0.3 + i * 0.35)} row={row} />
            ))}
          </div>
        </BillPage>
        {/* Click per row */}
        {BILL.map((row, i) => (
          <Sequence key={i} from={SEC(0.3 + i * 0.35)} durationInFrames={SEC(0.1)}>
            <Audio src={staticFile('sfx/click.mp3')} />
          </Sequence>
        ))}
      </Sequence>

      {/* Act 2 (6-9s): zoom on the mystery line */}
      <Sequence from={SEC(6)} durationInFrames={SEC(3)}>
        <MysteryLine from={0} />
        <Sequence from={SEC(0.3)} durationInFrames={SEC(0.5)}>
          <Audio src={staticFile('sfx/debit.mp3')} />
        </Sequence>
      </Sequence>

      {/* Act 3 (9-13s): cashier shrug */}
      <Sequence from={SEC(9)} durationInFrames={SEC(4)}>
        <CashierShrug from={0} />
        <Sequence from={SEC(0.5)} durationInFrames={SEC(0.3)}>
          <Audio src={staticFile('sfx/nope.mp3')} />
        </Sequence>
      </Sequence>

      {/* Act 4 (13-21s): Magnum Opus — the real answer, cited */}
      <Sequence from={SEC(13)} durationInFrames={SEC(8)}>
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

      {/* Act 5 (21-25s): end lockup */}
      <Sequence from={SEC(21)} durationInFrames={SEC(4)}>
        <AbsoluteFill
          style={{
            background: c.paper,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 60,
          }}
        >
          <EndCard tagline="You already paid for that bill. Know what you paid for." />
        </AbsoluteFill>
        <Sequence from={SEC(0.3)} durationInFrames={SEC(0.5)}>
          <Audio src={staticFile('sfx/ding.mp3')} />
        </Sequence>
      </Sequence>
    </AbsoluteFill>
  );
};
