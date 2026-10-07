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
import {Block, Stab, Cascade, Slam, Highlight, Flash, Split, Ransom, K} from '../components/kinetic';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 15 · "The Alert / Remix" · 24s · 9:16
// Kinetic reworking of TheAlert — same WhatsApp payment-proof scenario,
// but shot like a 2026 paid-social ad: hook in 1s, cuts every 0.8–1.2s,
// typography replaces UI chrome, backgrounds change every beat. Built
// VO-ready — short text on screen leaves pockets for the voiceover.
// ─────────────────────────────────────────────────────────────────────────

const RotatingWord: React.FC<{words: string[]; each: number; size?: number; color?: string}> = ({
  words,
  each,
  size = 300,
  color = '#000',
}) => {
  const frame = useCurrentFrame();
  const idx = Math.min(words.length - 1, Math.floor(frame / each));
  const w = words[idx];
  const subFrame = frame - idx * each;
  const op = interpolate(subFrame, [0, 4], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        opacity: op,
        fontFamily: FONT,
        fontSize: size,
        fontWeight: 900,
        color,
        letterSpacing: -size * 0.04,
        textAlign: 'center',
        lineHeight: 0.9,
      }}
    >
      {w}
    </div>
  );
};

// A phone-screen WhatsApp bubble, floating/jittering on a vibrant bg
const FloatingBubble: React.FC<{
  from: number;
  text: string;
  side: 'left' | 'right';
  sender?: string;
}> = ({from, text, side, sender}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 12, stiffness: 200, mass: 0.5}});
  const op = interpolate(s, [0, 1], [0, 1]);
  const sc = interpolate(s, [0, 1], [0.7, 1]);
  const isMine = side === 'right';
  return (
    <div
      style={{
        opacity: op,
        transform: `scale(${sc})`,
        padding: '28px 36px',
        borderRadius: 24,
        background: isMine ? '#D9FDD3' : '#FFFFFF',
        color: '#111B21',
        fontFamily: FONT,
        fontSize: 44,
        fontWeight: 500,
        lineHeight: 1.3,
        maxWidth: 820,
        boxShadow: '0 10px 40px rgba(0,0,0,0.2)',
        display: 'flex',
        flexDirection: 'column',
        gap: 10,
      }}
    >
      {sender && !isMine && (
        <span style={{color: '#667781', fontSize: 24, fontWeight: 600}}>{sender}</span>
      )}
      <span>{text}</span>
    </div>
  );
};

export const TheAlertRemix: React.FC = () => {
  ensureFonts();
  return (
    <AbsoluteFill>
      {/* ── Music bed throughout ── */}
      <Sequence from={0} durationInFrames={SEC(24)}>
        <Audio src={staticFile('sfx/music-bed.mp3')} volume={0.3} />
      </Sequence>

      {/* ── Act 0 · 0–1s · HOOK — "DID" "YOU" "SEND?" rotating ── */}
      <Sequence from={0} durationInFrames={SEC(1.4)}>
        <Block color={K.acid}>
          <RotatingWord words={['DID', 'YOU', 'SEND?']} each={14} size={340} color={K.blackMatte} />
        </Block>
        <Audio src={staticFile('sfx/slam.mp3')} />
      </Sequence>

      {/* ── Act 1 · 1.4–2.8s · Kemi's bubble bursts in on hot pink ── */}
      <Sequence from={SEC(1.4)} durationInFrames={SEC(1.4)}>
        <Block color={K.pink}>
          <FloatingBubble from={0} side="left" sender="Kemi (plumber)" text="hello sir did u send?" />
        </Block>
        <Audio src={staticFile('sfx/wa-pop.mp3')} />
      </Sequence>

      {/* ── Act 2 · 2.8–4.2s · "YES I DID" massive white on black ── */}
      <Sequence from={SEC(2.8)} durationInFrames={SEC(1.4)}>
        <Block color={K.blackMatte}>
          <Cascade text="YES I DID." from={0} size={260} color="#FFF" each={2} />
        </Block>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* ── Act 3 · 4.2–5.0s · FLASH white ── */}
      <Sequence from={SEC(4.2)} durationInFrames={SEC(0.8)}>
        <Block color="#FFF">
          <Stab from={0} size={220} color={K.blackMatte} rotate={-2}>
            now prove it.
          </Stab>
        </Block>
      </Sequence>

      {/* ── Act 4 · 5.0–6.2s · gallery scroll fail — 3,247 photos ── */}
      <Sequence from={SEC(5.0)} durationInFrames={SEC(1.2)}>
        <Block color={K.tangerine}>
          <Ransom
            from={0}
            each={3}
            words={[
              {text: '3,247', size: 400, color: K.blackMatte, rotate: -3},
              {text: 'photos.', size: 160, italic: true, color: K.blackMatte, rotate: 2, weight: 700},
            ]}
          />
        </Block>
        <Audio src={staticFile('sfx/click.mp3')} />
      </Sequence>

      {/* ── Act 5 · 6.2–7.0s · "nope." ── */}
      <Sequence from={SEC(6.2)} durationInFrames={SEC(0.8)}>
        <Block color={K.deepRed}>
          <Cascade text="not there." from={0} size={220} color="#FFF" each={2} />
        </Block>
        <Audio src={staticFile('sfx/nope.mp3')} />
      </Sequence>

      {/* ── Act 6 · 7.0–8.4s · time jumps — 4:28 → 4:35 → 4:42 ── */}
      <Sequence from={SEC(7.0)} durationInFrames={SEC(0.47)}>
        <Block color={K.cobalt}>
          <Slam from={0} size={480} color="#FFF">
            4:28
          </Slam>
        </Block>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>
      <Sequence from={SEC(7.47)} durationInFrames={SEC(0.47)}>
        <Block color={K.violet}>
          <Slam from={0} size={480} color="#FFF">
            4:35
          </Slam>
        </Block>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>
      <Sequence from={SEC(7.94)} durationInFrames={SEC(0.47)}>
        <Block color={K.deepRed}>
          <Slam from={0} size={480} color="#FFF">
            4:42
          </Slam>
        </Block>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* ── Act 7 · 8.4–10.0s · the accusation ── */}
      <Sequence from={SEC(8.4)} durationInFrames={SEC(1.6)}>
        <Block color={K.yellow}>
          <FloatingBubble
            from={0}
            side="left"
            sender="Kemi"
            text="are you sure you sent?"
          />
        </Block>
        <Audio src={staticFile('sfx/wa-pop.mp3')} />
      </Sequence>

      {/* ── Act 8 · 10.0–11.0s · black screen w/ "DIGNITY" split color ── */}
      <Sequence from={SEC(10.0)} durationInFrames={SEC(1.0)}>
        <Split
          topColor={K.blackMatte}
          bottomColor={K.pink}
          topChildren={
            <Stab from={0} size={240} color="#FFF" italic rotate={-3}>
              your dignity
            </Stab>
          }
          bottomChildren={
            <Cascade text="is a screenshot." from={0} size={120} color="#FFF" each={2} />
          }
        />
        <Audio src={staticFile('sfx/slam.mp3')} />
      </Sequence>

      {/* ── Act 9 · 11.0–12.0s · "SIFT" slam reveal ── */}
      <Sequence from={SEC(11.0)} durationInFrames={SEC(1.0)}>
        <Block color={K.paperOff}>
          <Stab from={0} size={520} color={K.cobalt} weight={900}>
            Sift.
          </Stab>
        </Block>
        <Audio src={staticFile('sfx/whoosh.mp3')} />
      </Sequence>

      {/* ── Act 10 · 12.0–14.0s · search bar + typed query ── */}
      <Sequence from={SEC(12.0)} durationInFrames={SEC(2.0)}>
        <Block color={K.paperOff} justify="center" align="center">
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 30}}>
            <div style={{fontFamily: FONT, fontSize: 32, color: '#666', fontWeight: 600, letterSpacing: 2}}>
              YOU TYPE
            </div>
            <div
              style={{
                padding: '36px 48px',
                background: K.cobalt,
                color: '#fff',
                borderRadius: 32,
                fontFamily: FONT,
                fontSize: 56,
                fontWeight: 700,
                maxWidth: 900,
              }}
            >
              transfer to kemi
            </div>
          </div>
        </Block>
        <Audio src={staticFile('sfx/click.mp3')} />
      </Sequence>

      {/* ── Act 11 · 14.0–16.5s · the answer slams in ── */}
      <Sequence from={SEC(14.0)} durationInFrames={SEC(2.5)}>
        <Block color={K.acid}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 24}}>
            <div style={{fontFamily: FONT, fontSize: 32, color: K.blackMatte, fontWeight: 700, letterSpacing: 2}}>
              SIFT ANSWERS
            </div>
            <Slam from={0} size={260} color={K.blackMatte}>
              ₦18,500
            </Slam>
            <div style={{fontFamily: FONT, fontSize: 46, color: K.blackMatte, fontWeight: 700}}>
              Ref: TXN8841 · 4:12 PM
            </div>
          </div>
        </Block>
        <Audio src={staticFile('sfx/chime-win.mp3')} />
      </Sequence>

      {/* ── Act 12 · 16.5–18.0s · back to WhatsApp, "received 🙏" ── */}
      <Sequence from={SEC(16.5)} durationInFrames={SEC(1.5)}>
        <Block color="#ECE5DD">
          <div style={{display: 'flex', flexDirection: 'column', gap: 20, maxWidth: 820}}>
            <FloatingBubble
              from={0}
              side="right"
              text="TXN8841 · ₦18,500 · 4:12 PM"
            />
            <FloatingBubble
              from={SEC(0.6)}
              side="left"
              sender="Kemi"
              text="oh sorry oga, received 🙏"
            />
          </div>
        </Block>
        <Audio src={staticFile('sfx/wa-pop.mp3')} />
      </Sequence>

      {/* ── Act 13 · 18.0–19.0s · "2 SECONDS" slam ── */}
      <Sequence from={SEC(18.0)} durationInFrames={SEC(1.0)}>
        <Block color={K.limeNeon}>
          <Ransom
            from={0}
            each={3}
            words={[
              {text: '2 SECONDS.', size: 220, color: K.blackMatte, rotate: -2},
              {text: 'that\'s it.', size: 120, italic: true, color: K.blackMatte, rotate: 2, weight: 700},
            ]}
          />
        </Block>
        <Audio src={staticFile('sfx/pop.mp3')} />
      </Sequence>

      {/* ── Act 14 · 19.0–20.0s · tagline block ── */}
      <Sequence from={SEC(19.0)} durationInFrames={SEC(1.0)}>
        <Block color={K.blackMatte}>
          <Cascade
            text="you sent it."
            from={0}
            size={160}
            color="#FFF"
            each={1}
          />
        </Block>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* ── Act 15 · 20.0–21.5s · "prove it in 2 seconds" ── */}
      <Sequence from={SEC(20.0)} durationInFrames={SEC(1.5)}>
        <Block color={K.cobalt}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20}}>
            <Cascade text="prove it." from={0} size={200} color="#FFF" each={2} />
            <div style={{fontFamily: FONT, fontSize: 60, color: K.acid, fontWeight: 900, fontStyle: 'italic'}}>
              in 2 seconds.
            </div>
          </div>
        </Block>
        <Audio src={staticFile('sfx/whoosh.mp3')} />
      </Sequence>

      {/* ── Act 16 · 21.5–24.0s · end lockup ── */}
      <Sequence from={SEC(21.5)} durationInFrames={SEC(2.5)}>
        <Block color={K.paperOff}>
          <EndCard tagline="Prove it in 2 seconds." />
        </Block>
        <Audio src={staticFile('sfx/chime-win.mp3')} />
      </Sequence>
    </AbsoluteFill>
  );
};
