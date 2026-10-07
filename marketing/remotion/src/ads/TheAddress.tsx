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
// AD 14 · "The Address" · 25s · 9:16
// Stakes-driven, non-SV framing. You're late to something that matters
// (interview, inspection, deadline). You're in a cab/okada. You screenshot
// -ted the address weeks ago. You can't find it now, when it costs you
// money every minute. The caller is annoyed. The driver is annoyed. Sift
// finds it by neighborhood name in two taps.
//
// Fully phone-UI (status bar + whatever app is open). Rotates: Maps panic,
// Gallery scroll, Phone call UI, Sift reveal, Maps success.
// ─────────────────────────────────────────────────────────────────────────

const C = {
  bg: '#000',
  screen: '#FFFFFF',
  statusBar: '#000',
  mapsBg: '#E6E7E8',       // light grey map canvas
  mapsLine: '#C8CBD0',
  mapsRoad: '#FFFFFF',
  youDot: '#1A73E8',
  galleryBg: '#000',
  gallerySwatch: '#333',
  callerGreen: '#4CAF50',
  callerRed: '#F44336',
  callerCard: '#1C1C1E',
  callerText: '#FFFFFF',
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
    <span>1:47</span>
    <span>4G •••</span>
  </div>
);

// ── Maps "you are here" with no destination set ──────────────────────────
const MapsLost: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const pulse = Math.abs(Math.sin((frame * Math.PI) / 20));
  const op = interpolate(frame, [0, 12], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <AbsoluteFill style={{background: C.screen, opacity: op}}>
      <StatusBar />
      {/* Top notification pill — context: appointment time */}
      <div
        style={{
          margin: '8px 14px',
          padding: '16px 22px',
          background: '#F2F2F7',
          borderRadius: 14,
          fontFamily: FONT,
          display: 'flex',
          flexDirection: 'column',
          gap: 4,
        }}
      >
        <div style={{fontSize: 22, color: C.meta, fontWeight: 600, letterSpacing: 1}}>
          CALENDAR · in 13 min
        </div>
        <div style={{fontSize: 30, color: '#000', fontWeight: 600}}>
          Interview — Mrs. Adebayo
        </div>
      </div>
      {/* Map canvas */}
      <div
        style={{
          flex: 1,
          background: C.mapsBg,
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        {/* Fake road grid */}
        {[0, 1, 2, 3, 4].map((i) => (
          <div
            key={`h${i}`}
            style={{
              position: 'absolute',
              left: 0,
              right: 0,
              top: `${15 + i * 20}%`,
              height: 24,
              background: C.mapsRoad,
              borderTop: `1px solid ${C.mapsLine}`,
              borderBottom: `1px solid ${C.mapsLine}`,
            }}
          />
        ))}
        {[0, 1, 2].map((i) => (
          <div
            key={`v${i}`}
            style={{
              position: 'absolute',
              top: 0,
              bottom: 0,
              left: `${20 + i * 30}%`,
              width: 24,
              background: C.mapsRoad,
              borderLeft: `1px solid ${C.mapsLine}`,
              borderRight: `1px solid ${C.mapsLine}`,
            }}
          />
        ))}
        {/* You dot — pulsing */}
        <div
          style={{
            position: 'absolute',
            left: '48%',
            top: '48%',
            width: 36 + pulse * 8,
            height: 36 + pulse * 8,
            borderRadius: '50%',
            background: C.youDot,
            border: '4px solid #fff',
            boxShadow: `0 0 ${pulse * 40}px ${C.youDot}66`,
          }}
        />
        {/* Destination unknown pill */}
        <div
          style={{
            position: 'absolute',
            left: '50%',
            top: 40,
            transform: 'translateX(-50%)',
            padding: '14px 24px',
            background: '#000',
            color: '#fff',
            borderRadius: 999,
            fontFamily: FONT,
            fontSize: 24,
            fontWeight: 600,
          }}
        >
          Enter destination
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ── Gallery scroll — a wall of swatches with no address in sight ─────────
const GalleryScroll: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const scroll = interpolate(frame, [0, 90], [0, -1200], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  // Deterministic "random" swatch colors
  const palette = ['#FF6B6B', '#4ECDC4', '#FFD93D', '#95E1D3', '#F38181', '#AA96DA', '#FCBAD3', '#FFFFD2', '#A8D8EA', '#C7CEEA'];
  return (
    <AbsoluteFill style={{background: C.galleryBg}}>
      <StatusBar darkText={false} />
      {/* Header */}
      <div
        style={{
          padding: '10px 20px 20px',
          color: '#fff',
          fontFamily: FONT,
          fontSize: 32,
          fontWeight: 700,
        }}
      >
        Gallery · 3,247 items
      </div>
      {/* Scrolling grid */}
      <div style={{transform: `translateY(${scroll}px)`, display: 'flex', flexDirection: 'column'}}>
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(3, 1fr)',
            gap: 4,
            padding: '0 4px',
          }}
        >
          {Array.from({length: 45}).map((_, i) => {
            const hue = palette[i % palette.length];
            return (
              <div
                key={i}
                style={{
                  aspectRatio: '1 / 1.4',
                  background: `linear-gradient(145deg, ${hue}, ${hue}80)`,
                  borderRadius: 4,
                }}
              />
            );
          })}
        </div>
      </div>
      {/* Overlay — frustration note */}
      <div
        style={{
          position: 'absolute',
          bottom: 60,
          left: 0,
          right: 0,
          textAlign: 'center',
          color: '#fff',
          fontFamily: FONT,
          fontSize: 28,
          fontWeight: 500,
          opacity: 0.7,
          fontStyle: 'italic',
        }}
      >
        it was DEFINITELY in here
      </div>
    </AbsoluteFill>
  );
};

// ── Incoming / Outgoing phone call UI ────────────────────────────────────
const PhoneCall: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 10], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <AbsoluteFill style={{background: C.callerCard, opacity: op}}>
      <StatusBar darkText={false} />
      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          padding: 60,
          gap: 20,
        }}
      >
        <div
          style={{
            width: 180,
            height: 180,
            borderRadius: '50%',
            background: '#C7A86C',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#fff',
            fontSize: 70,
            fontWeight: 700,
            fontFamily: FONT,
            marginBottom: 30,
          }}
        >
          A
        </div>
        <div style={{color: C.callerText, fontSize: 48, fontWeight: 600, fontFamily: FONT}}>
          Mrs. Adebayo
        </div>
        <div style={{color: C.meta, fontSize: 28, fontFamily: FONT}}>calling…</div>
        {/* Dialogue bubble */}
        <div
          style={{
            marginTop: 60,
            padding: '26px 36px',
            background: 'rgba(255,255,255,0.08)',
            borderRadius: 24,
            maxWidth: '85%',
            fontFamily: FONT,
            fontSize: 34,
            color: '#fff',
            fontWeight: 500,
            lineHeight: 1.4,
            textAlign: 'center',
          }}
        >
          "I sent you the address three days ago."
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// ── Sift answer reveal ───────────────────────────────────────────────────
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
          mrs adebayo address
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
            fontSize: 36,
            fontWeight: 500,
            color: c.ink,
            lineHeight: 1.4,
            maxWidth: '92%',
            boxShadow: '0 30px 70px rgba(15,22,38,0.08)',
          }}
        >
          <span style={{color: c.accent, fontWeight: 700}}>14b Allen Avenue</span>, Ikeja
          <br />
          <span style={{color: c.inkSoft, fontSize: 30}}>
            opposite the GTBank, blue gate.
          </span>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// ── Final: map with route drawn, "arriving" ──────────────────────────────
const MapsRouted: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 12], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const routeDraw = interpolate(frame, [8, 36], [0, 100], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <AbsoluteFill style={{background: C.screen, opacity: op}}>
      <StatusBar />
      <div
        style={{
          margin: '8px 14px',
          padding: '16px 22px',
          background: '#D6F0D6',
          borderRadius: 14,
          fontFamily: FONT,
          display: 'flex',
          flexDirection: 'column',
          gap: 4,
        }}
      >
        <div style={{fontSize: 22, color: '#2E7D32', fontWeight: 700, letterSpacing: 1}}>
          ROUTE SET · 6 MIN
        </div>
        <div style={{fontSize: 28, color: '#000', fontWeight: 600}}>
          14b Allen Avenue, Ikeja
        </div>
      </div>
      <div
        style={{
          flex: 1,
          background: C.mapsBg,
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        {[0, 1, 2, 3, 4].map((i) => (
          <div
            key={`h${i}`}
            style={{
              position: 'absolute',
              left: 0,
              right: 0,
              top: `${15 + i * 20}%`,
              height: 24,
              background: C.mapsRoad,
            }}
          />
        ))}
        {[0, 1, 2].map((i) => (
          <div
            key={`v${i}`}
            style={{
              position: 'absolute',
              top: 0,
              bottom: 0,
              left: `${20 + i * 30}%`,
              width: 24,
              background: C.mapsRoad,
            }}
          />
        ))}
        {/* Route line — draws L-shape from you dot to destination */}
        <div
          style={{
            position: 'absolute',
            left: '48%',
            top: '48%',
            width: `${routeDraw * 0.3}%`,
            height: 12,
            background: C.youDot,
            borderRadius: 6,
          }}
        />
        <div
          style={{
            position: 'absolute',
            left: `calc(48% + ${routeDraw * 0.3}%)`,
            top: `${48 - routeDraw * 0.25}%`,
            width: 12,
            height: `${routeDraw * 0.25}%`,
            background: C.youDot,
            borderRadius: 6,
          }}
        />
        <div
          style={{
            position: 'absolute',
            left: '48%',
            top: '48%',
            width: 36,
            height: 36,
            borderRadius: '50%',
            background: C.youDot,
            border: '4px solid #fff',
          }}
        />
        {/* Pin at destination */}
        {routeDraw > 90 && (
          <div
            style={{
              position: 'absolute',
              left: 'calc(48% + 30%)',
              top: '23%',
              width: 40,
              height: 50,
              background: '#F44336',
              borderRadius: '50% 50% 50% 0',
              transform: 'rotate(-45deg)',
            }}
          />
        )}
      </div>
    </AbsoluteFill>
  );
};

const Phone: React.FC<{children: React.ReactNode}> = ({children}) => {
  ensureFonts();
  return <AbsoluteFill>{children}</AbsoluteFill>;
};

export const TheAddress: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Act 1 (0-3s): maps open, no destination, calendar countdown */}
      <Sequence from={0} durationInFrames={SEC(3)}>
        <Phone>
          <MapsLost from={0} />
        </Phone>
        <Sequence from={SEC(0.3)} durationInFrames={SEC(0.5)}>
          <Audio src={staticFile('sfx/horn.mp3')} />
        </Sequence>
      </Sequence>

      {/* Act 2 (3-9s): gallery scroll — thousands of photos, no address */}
      <Sequence from={SEC(3)} durationInFrames={SEC(6)}>
        <Phone>
          <GalleryScroll from={0} />
        </Phone>
        <Sequence from={SEC(0.2)} durationInFrames={SEC(0.1)}>
          <Audio src={staticFile('sfx/click.mp3')} />
        </Sequence>
        <Sequence from={SEC(1.0)} durationInFrames={SEC(0.1)}>
          <Audio src={staticFile('sfx/click.mp3')} />
        </Sequence>
        <Sequence from={SEC(2.0)} durationInFrames={SEC(0.1)}>
          <Audio src={staticFile('sfx/click.mp3')} />
        </Sequence>
        <Sequence from={SEC(3.5)} durationInFrames={SEC(0.3)}>
          <Audio src={staticFile('sfx/nope.mp3')} />
        </Sequence>
      </Sequence>

      {/* Act 3 (9-14s): phone call — Mrs Adebayo is annoyed */}
      <Sequence from={SEC(9)} durationInFrames={SEC(5)}>
        <Phone>
          <PhoneCall from={0} />
        </Phone>
        <Sequence from={0} durationInFrames={SEC(0.5)}>
          <Audio src={staticFile('sfx/ding.mp3')} />
        </Sequence>
      </Sequence>

      {/* Act 4 (14-19s): Sift reveal — found it, with landmark */}
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

      {/* Act 5 (19-23s): maps routed, arriving */}
      <Sequence from={SEC(19)} durationInFrames={SEC(4)}>
        <Phone>
          <MapsRouted from={0} />
        </Phone>
        <Sequence from={SEC(0.3)} durationInFrames={SEC(0.3)}>
          <Audio src={staticFile('sfx/pop.mp3')} />
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
          <EndCard tagline="They sent it. You screenshotted it. Just ask Sift." />
        </AbsoluteFill>
        <Sequence from={SEC(0.3)} durationInFrames={SEC(0.5)}>
          <Audio src={staticFile('sfx/ding.mp3')} />
        </Sequence>
      </Sequence>
    </AbsoluteFill>
  );
};
