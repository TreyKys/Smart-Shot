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
import {SEC, FONT, ensureFonts} from '../theme';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 17 · "The Alert / BROADCAST" · 24s · 9:16
// WhatsApp payment-proof scenario, re-shot as a 24-hour news broadcast.
// Chyron, breaking-news badge, ticker tape, anchor-style graphics, serif
// title cards. Nothing in common visually with the kinetic remix — this
// is the "news parody" grammar top to bottom.
// ─────────────────────────────────────────────────────────────────────────

const C = {
  bg: '#0A0E1A',
  bgAlt: '#141B2E',
  red: '#DC2626',
  redDark: '#991B1B',
  gold: '#FBBF24',
  white: '#F5F7FC',
  grey: '#8B96A8',
  tickerBg: '#1F2937',
};

// ── Live indicator pulsing ──
const LiveBadge: React.FC = () => {
  const frame = useCurrentFrame();
  const pulse = Math.abs(Math.sin((frame * Math.PI) / 15));
  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        padding: '8px 16px',
        background: C.red,
        borderRadius: 4,
        fontFamily: FONT,
        fontSize: 24,
        fontWeight: 900,
        color: '#FFF',
        letterSpacing: 2,
      }}
    >
      <div
        style={{
          width: 14,
          height: 14,
          borderRadius: '50%',
          background: '#FFF',
          opacity: 0.5 + pulse * 0.5,
        }}
      />
      LIVE
    </div>
  );
};

// ── Scrolling ticker tape ──
const Ticker: React.FC<{texts: string[]}> = ({texts}) => {
  const frame = useCurrentFrame();
  const combined = texts.join('   •   ') + '   •   ';
  const x = -(frame * 6) % 2000;
  return (
    <div
      style={{
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        height: 60,
        background: C.tickerBg,
        borderTop: `3px solid ${C.red}`,
        overflow: 'hidden',
        display: 'flex',
        alignItems: 'center',
      }}
    >
      <div
        style={{
          position: 'absolute',
          left: 0,
          top: 0,
          bottom: 0,
          background: C.red,
          padding: '0 20px',
          display: 'flex',
          alignItems: 'center',
          fontFamily: FONT,
          fontSize: 20,
          fontWeight: 900,
          color: '#FFF',
          letterSpacing: 2,
          zIndex: 2,
        }}
      >
        BREAKING
      </div>
      <div
        style={{
          position: 'absolute',
          left: 180 + x,
          top: '50%',
          transform: 'translateY(-50%)',
          whiteSpace: 'nowrap',
          fontFamily: FONT,
          fontSize: 24,
          color: '#FFF',
          fontWeight: 500,
          letterSpacing: 1,
        }}
      >
        {combined.repeat(4)}
      </div>
    </div>
  );
};

// ── Top chrome: time + channel ──
const TopBar: React.FC = () => (
  <div
    style={{
      position: 'absolute',
      top: 60,
      left: 0,
      right: 0,
      padding: '0 40px',
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
    }}
  >
    <div style={{display: 'flex', alignItems: 'center', gap: 16}}>
      <LiveBadge />
      <div style={{fontFamily: FONT, fontSize: 22, color: C.grey, fontWeight: 600, letterSpacing: 1}}>
        PAYMENT DISPUTES NIGERIA · PDN24
      </div>
    </div>
    <div style={{fontFamily: 'monospace', fontSize: 28, color: C.gold, fontWeight: 700}}>
      16:42 GMT
    </div>
  </div>
);

// ── Lower-third chyron bar ──
const LowerThird: React.FC<{headline: string; subtitle?: string; from: number}> = ({
  headline,
  subtitle,
  from,
}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 20, stiffness: 180, mass: 0.5}});
  const x = interpolate(s, [0, 1], [-800, 0]);
  const op = interpolate(s, [0, 1], [0, 1]);
  return (
    <div
      style={{
        position: 'absolute',
        bottom: 80,
        left: 0,
        right: 0,
        opacity: op,
        transform: `translateX(${x}px)`,
      }}
    >
      <div style={{display: 'flex', alignItems: 'stretch', boxShadow: '0 10px 30px rgba(0,0,0,0.5)'}}>
        <div
          style={{
            background: C.red,
            padding: '20px 24px',
            display: 'flex',
            alignItems: 'center',
            fontFamily: FONT,
            fontSize: 24,
            fontWeight: 900,
            color: '#FFF',
            letterSpacing: 3,
          }}
        >
          ALERT
        </div>
        <div
          style={{
            flex: 1,
            background: C.bgAlt,
            padding: '18px 28px',
            display: 'flex',
            flexDirection: 'column',
            gap: 6,
          }}
        >
          <div
            style={{
              fontFamily: FONT,
              fontSize: 44,
              fontWeight: 800,
              color: '#FFF',
              lineHeight: 1.1,
              letterSpacing: -0.5,
            }}
          >
            {headline}
          </div>
          {subtitle && (
            <div
              style={{
                fontFamily: FONT,
                fontSize: 22,
                color: C.gold,
                fontWeight: 500,
                letterSpacing: 1,
                textTransform: 'uppercase',
              }}
            >
              {subtitle}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

// ── Breaking news title card (center) ──
const TitleCard: React.FC<{
  preLabel: string;
  big: string;
  sub?: string;
  from: number;
}> = ({preLabel, big, sub, from}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 20, stiffness: 150, mass: 0.6}});
  const op = interpolate(s, [0, 1], [0, 1]);
  const y = interpolate(s, [0, 1], [20, 0]);
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
        transform: `translateY(${y}px)`,
      }}
    >
      <div
        style={{
          fontFamily: FONT,
          fontSize: 28,
          color: C.red,
          fontWeight: 900,
          letterSpacing: 6,
          borderTop: `3px solid ${C.red}`,
          borderBottom: `3px solid ${C.red}`,
          padding: '12px 24px',
        }}
      >
        {preLabel}
      </div>
      <div
        style={{
          fontFamily: 'serif',
          fontSize: 160,
          color: C.white,
          fontWeight: 900,
          textAlign: 'center',
          lineHeight: 0.95,
          letterSpacing: -4,
        }}
      >
        {big}
      </div>
      {sub && (
        <div
          style={{
            fontFamily: FONT,
            fontSize: 32,
            color: C.gold,
            fontWeight: 500,
            fontStyle: 'italic',
            textAlign: 'center',
            maxWidth: 900,
            lineHeight: 1.3,
          }}
        >
          {sub}
        </div>
      )}
    </div>
  );
};

// ── Anchor-desk "scene" background with graphic frame ──
const Scene: React.FC<{children: React.ReactNode; tint?: string}> = ({children, tint = C.bg}) => {
  ensureFonts();
  return (
    <AbsoluteFill style={{background: tint, overflow: 'hidden'}}>
      {/* Faint graph-paper grid */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          backgroundImage:
            'linear-gradient(rgba(255,255,255,0.02) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.02) 1px, transparent 1px)',
          backgroundSize: '60px 60px',
        }}
      />
      {/* Red diagonal corner band — breaking news aesthetic */}
      <div
        style={{
          position: 'absolute',
          top: -40,
          left: -140,
          width: 400,
          height: 80,
          background: C.red,
          transform: 'rotate(-30deg)',
          boxShadow: '0 4px 20px rgba(220,38,38,0.5)',
        }}
      />
      {children}
    </AbsoluteFill>
  );
};

// ── Reporter-at-scene card showing a "witness statement" ──
const WitnessCard: React.FC<{
  from: number;
  quote: string;
  witness: string;
}> = ({from, quote, witness}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 20, stiffness: 150, mass: 0.5}});
  const op = interpolate(s, [0, 1], [0, 1]);
  const sc = interpolate(s, [0, 1], [0.95, 1]);
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
      }}
    >
      <div
        style={{
          opacity: op,
          transform: `scale(${sc})`,
          width: '100%',
          maxWidth: 920,
          background: C.bgAlt,
          border: `2px solid ${C.red}`,
          padding: '40px 44px',
          position: 'relative',
        }}
      >
        <div
          style={{
            position: 'absolute',
            top: -2,
            left: 0,
            background: C.red,
            padding: '8px 20px',
            fontFamily: FONT,
            fontSize: 22,
            fontWeight: 900,
            color: '#FFF',
            letterSpacing: 3,
            transform: 'translateY(-100%)',
          }}
        >
          STATEMENT
        </div>
        <div
          style={{
            fontFamily: 'serif',
            fontSize: 72,
            fontStyle: 'italic',
            color: C.white,
            lineHeight: 1.2,
            letterSpacing: -2,
          }}
        >
          "{quote}"
        </div>
        <div
          style={{
            marginTop: 24,
            fontFamily: FONT,
            fontSize: 26,
            color: C.gold,
            fontWeight: 700,
            letterSpacing: 2,
          }}
        >
          — {witness}
        </div>
      </div>
    </div>
  );
};

// ── "Evidence" card: screenshot of the Sift answer ──
const EvidenceCard: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 14, stiffness: 180, mass: 0.6}});
  const op = interpolate(s, [0, 1], [0, 1]);
  const sc = interpolate(s, [0, 1], [0.8, 1]);
  const rot = interpolate(s, [0, 1], [-3, 0]);
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
      }}
    >
      <div
        style={{
          opacity: op,
          transform: `scale(${sc}) rotate(${rot}deg)`,
          width: '100%',
          maxWidth: 900,
          background: '#FFF',
          padding: '50px 54px',
          borderRadius: 8,
          boxShadow: '0 40px 100px rgba(0,0,0,0.6)',
          position: 'relative',
        }}
      >
        {/* "Exhibit A" stamp */}
        <div
          style={{
            position: 'absolute',
            top: 20,
            right: 24,
            padding: '10px 20px',
            border: `4px solid ${C.red}`,
            fontFamily: 'serif',
            fontSize: 28,
            fontWeight: 900,
            color: C.red,
            letterSpacing: 4,
            transform: 'rotate(8deg)',
            fontStyle: 'italic',
          }}
        >
          EXHIBIT A
        </div>
        <div
          style={{
            fontFamily: FONT,
            fontSize: 24,
            color: '#666',
            fontWeight: 700,
            letterSpacing: 2,
            marginBottom: 20,
          }}
        >
          BANK TRANSFER CONFIRMATION
        </div>
        <div
          style={{
            fontFamily: 'monospace',
            fontSize: 110,
            fontWeight: 900,
            color: '#000',
            lineHeight: 1,
            letterSpacing: -3,
          }}
        >
          ₦18,500
        </div>
        <div
          style={{
            marginTop: 16,
            fontFamily: 'monospace',
            fontSize: 32,
            color: '#000',
            fontWeight: 700,
          }}
        >
          Ref: TXN8841
        </div>
        <div
          style={{
            marginTop: 10,
            fontFamily: 'monospace',
            fontSize: 28,
            color: '#666',
          }}
        >
          04:12 PM · PAID TO: KEMI
        </div>
        <div
          style={{
            marginTop: 30,
            paddingTop: 20,
            borderTop: '2px dashed #999',
            fontFamily: FONT,
            fontSize: 22,
            color: C.red,
            fontWeight: 700,
            fontStyle: 'italic',
            textAlign: 'center',
          }}
        >
          Retrieved via SIFT in 2 seconds
        </div>
      </div>
    </div>
  );
};

export const TheAlertBroadcast: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Music bed */}
      <Sequence from={0} durationInFrames={SEC(24)}>
        <Audio src={staticFile('sfx/music-bed.mp3')} volume={0.25} />
      </Sequence>

      {/* Act 1 (0-3s): Cold open — breaking news title card */}
      <Sequence from={0} durationInFrames={SEC(3)}>
        <Scene>
          <TitleCard
            from={SEC(0.2)}
            preLabel="BREAKING"
            big="PAYMENT MISSING"
            sub="Lagos tradesman demands proof. Customer swears he sent."
          />
          <TopBar />
          <Ticker
            texts={[
              'Developing: ₦18,500 transfer in dispute',
              'Plumber threatens to not return',
              'Screenshot buried in gallery of 3,247 photos',
            ]}
          />
        </Scene>
        <Audio src={staticFile('sfx/slam.mp3')} />
      </Sequence>

      {/* Act 2 (3-6s): Reporter chyron — "the plumber demands proof" */}
      <Sequence from={SEC(3)} durationInFrames={SEC(3)}>
        <Scene>
          <LowerThird
            from={SEC(0.3)}
            headline="PLUMBER DEMANDS PROOF OF PAYMENT"
            subtitle="SENDER CLAIMS: 'I ALREADY SENT'"
          />
          <TopBar />
          <Ticker
            texts={[
              'Lagos — a routine plumbing invoice has escalated',
              'Scroll continues. Sweat intensifies.',
            ]}
          />
        </Scene>
      </Sequence>

      {/* Act 3 (6-9s): Witness statement from Kemi */}
      <Sequence from={SEC(6)} durationInFrames={SEC(3)}>
        <Scene>
          <WitnessCard
            from={SEC(0.2)}
            quote="Hello sir did u send?"
            witness="KEMI · PLUMBER · LAGOS"
          />
          <TopBar />
          <Ticker texts={['WhatsApp message timestamped 4:28 PM', 'Response pending']} />
        </Scene>
        <Audio src={staticFile('sfx/wa-pop.mp3')} />
      </Sequence>

      {/* Act 4 (9-11s): The accused's response — second statement */}
      <Sequence from={SEC(9)} durationInFrames={SEC(2)}>
        <Scene>
          <WitnessCard
            from={SEC(0.2)}
            quote="wait let me find the screenshot…"
            witness="THE ACCUSED · WIFI STABLE · 1 BAR OF SELF-RESPECT"
          />
          <TopBar />
          <Ticker texts={['Suspect begins scrolling', 'Gallery count: 3,247']} />
        </Scene>
      </Sequence>

      {/* Act 5 (11-13s): Time-jump chyron — minutes pass */}
      <Sequence from={SEC(11)} durationInFrames={SEC(2)}>
        <Scene tint="#1A0A0A">
          <TitleCard
            from={SEC(0.2)}
            preLabel="14 MINUTES LATER"
            big="STILL NOTHING"
            sub="Trust eroding. Payment unverified. Receipt unlocatable."
          />
          <TopBar />
          <Ticker texts={['Witness statements continue', 'No evidence surfaced']} />
        </Scene>
        <Audio src={staticFile('sfx/debit.mp3')} />
      </Sequence>

      {/* Act 6 (13-16s): BREAKING — SIFT INTERVENES */}
      <Sequence from={SEC(13)} durationInFrames={SEC(3)}>
        <Scene tint="#001A00">
          <TitleCard
            from={SEC(0.2)}
            preLabel="DEVELOPING"
            big="SIFT INTERVENES"
            sub="Evidence recovered in two seconds."
          />
          <TopBar />
          <Ticker
            texts={[
              'Breaking: Sift AI resolves payment dispute',
              'Timeline shortened: hours → seconds',
            ]}
          />
        </Scene>
        <Audio src={staticFile('sfx/whoosh.mp3')} />
      </Sequence>

      {/* Act 7 (16-20s): Evidence card — the receipt */}
      <Sequence from={SEC(16)} durationInFrames={SEC(4)}>
        <Scene>
          <EvidenceCard from={SEC(0.2)} />
          <TopBar />
          <Ticker texts={['Case closed', 'Reputation restored', 'Plumber returning Tuesday']} />
        </Scene>
        <Audio src={staticFile('sfx/chime-win.mp3')} />
      </Sequence>

      {/* Act 8 (20-24s): Sign-off — end lockup */}
      <Sequence from={SEC(20)} durationInFrames={SEC(4)}>
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
            <EndCard tagline="You sent it. Prove it in two seconds." />
          </div>
        </Scene>
        <Audio src={staticFile('sfx/chime-win.mp3')} />
      </Sequence>
    </AbsoluteFill>
  );
};
