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
import {Block, Stab, Cascade, Slam, Flash, Split, Ransom, K} from '../components/kinetic';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 16 · "The Address / Remix" · 24s · 9:16
// Kinetic reworking of the taxi-late-to-interview scenario. Same stakes,
// shot like a social ad: countdown urgency, panic cuts, Sift reveal
// slams in.
// ─────────────────────────────────────────────────────────────────────────

const CountdownBig: React.FC<{from: number; startMin: number; color: string}> = ({
  from,
  startMin,
  color,
}) => {
  const frame = useCurrentFrame() - from;
  const totalSec = startMin * 60 - Math.floor(frame / 2);
  const mm = Math.max(0, Math.floor(totalSec / 60));
  const ss = Math.max(0, totalSec % 60);
  return (
    <div
      style={{
        fontFamily: 'monospace',
        fontVariantNumeric: 'tabular-nums',
        fontSize: 480,
        fontWeight: 900,
        color,
        letterSpacing: -20,
        lineHeight: 0.9,
      }}
    >
      {mm}:{ss.toString().padStart(2, '0')}
    </div>
  );
};

// Gallery scroll — rapid-fire tiles cycling
const GalleryBurst: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const palette = ['#FF6B6B', '#4ECDC4', '#FFD93D', '#95E1D3', '#F38181', '#AA96DA', '#FCBAD3', '#A8D8EA'];
  return (
    <div
      style={{
        position: 'absolute',
        inset: 0,
        display: 'grid',
        gridTemplateColumns: 'repeat(4, 1fr)',
        gap: 10,
        padding: 40,
      }}
    >
      {Array.from({length: 24}).map((_, i) => {
        const t = (frame - i * 2) / 30;
        const op = Math.max(0, Math.min(1, 1 - Math.abs(t % 2 - 1) * 2));
        const hue = palette[i % palette.length];
        return (
          <div
            key={i}
            style={{
              background: `linear-gradient(135deg, ${hue}, ${hue}80)`,
              borderRadius: 12,
              opacity: op * 0.8 + 0.1,
            }}
          />
        );
      })}
    </div>
  );
};

export const TheAddressRemix: React.FC = () => {
  ensureFonts();
  return (
    <AbsoluteFill>
      <Sequence from={0} durationInFrames={SEC(24)}>
        <Audio src={staticFile('sfx/music-bed.mp3')} volume={0.3} />
      </Sequence>

      {/* 0–1.2s · HOOK — the time ticking down (interview in 13 min) */}
      <Sequence from={0} durationInFrames={SEC(1.2)}>
        <Block color={K.deepRed}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10}}>
            <div style={{fontFamily: FONT, fontSize: 42, color: K.yellow, fontWeight: 900, letterSpacing: 4}}>
              INTERVIEW IN
            </div>
            <CountdownBig from={0} startMin={13} color="#FFF" />
          </div>
        </Block>
        <Audio src={staticFile('sfx/horn.mp3')} />
      </Sequence>

      {/* 1.2–2.4s · "you don't know where it is" */}
      <Sequence from={SEC(1.2)} durationInFrames={SEC(1.2)}>
        <Block color={K.blackMatte}>
          <Cascade text="you don't know" from={0} size={160} color="#FFF" each={1} />
        </Block>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* 2.4–3.6s · "WHERE IT IS" massive */}
      <Sequence from={SEC(2.4)} durationInFrames={SEC(1.2)}>
        <Block color={K.yellow}>
          <Stab from={0} size={380} color={K.blackMatte}>
            where.
          </Stab>
        </Block>
        <Audio src={staticFile('sfx/slam.mp3')} />
      </Sequence>

      {/* 3.6–4.4s · she sent it (bubble) */}
      <Sequence from={SEC(3.6)} durationInFrames={SEC(0.8)}>
        <Block color={K.cobalt}>
          <Ransom
            from={0}
            each={2}
            words={[
              {text: 'she sent it.', size: 180, color: '#FFF', rotate: -2},
              {text: '3 days ago.', size: 100, italic: true, color: K.acid, rotate: 2, weight: 700},
            ]}
          />
        </Block>
        <Audio src={staticFile('sfx/wa-pop.mp3')} />
      </Sequence>

      {/* 4.4–6.0s · gallery burst — 3,247 photos flying by */}
      <Sequence from={SEC(4.4)} durationInFrames={SEC(1.6)}>
        <Block color={K.blackMatte}>
          <GalleryBurst from={0} />
          <div
            style={{
              position: 'absolute',
              top: '50%',
              left: '50%',
              transform: 'translate(-50%, -50%)',
              padding: '28px 44px',
              background: '#FFF',
              borderRadius: 20,
              fontFamily: FONT,
              fontSize: 100,
              fontWeight: 900,
              color: K.blackMatte,
              boxShadow: '0 0 60px rgba(0,0,0,0.6)',
            }}
          >
            3,247
          </div>
        </Block>
        <Audio src={staticFile('sfx/click.mp3')} />
      </Sequence>

      {/* 6.0–7.2s · "none of them." red */}
      <Sequence from={SEC(6.0)} durationInFrames={SEC(1.2)}>
        <Block color={K.deepRed}>
          <Cascade text="none." from={0} size={400} color="#FFF" each={2} />
        </Block>
        <Audio src={staticFile('sfx/nope.mp3')} />
      </Sequence>

      {/* 7.2–8.0s · phone-call UI minimalist */}
      <Sequence from={SEC(7.2)} durationInFrames={SEC(0.8)}>
        <Block color="#1C1C1E">
          <Ransom
            from={0}
            each={3}
            words={[
              {text: '📞 calling…', size: 100, italic: true, color: '#8E8E93', weight: 500, rotate: 0},
              {text: 'Mrs. Adebayo', size: 90, color: '#FFF', weight: 700, rotate: 0},
            ]}
          />
        </Block>
        <Audio src={staticFile('sfx/ding.mp3')} />
      </Sequence>

      {/* 8.0–10.0s · the quote lands */}
      <Sequence from={SEC(8.0)} durationInFrames={SEC(2.0)}>
        <Block color={K.violet}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20, maxWidth: 950}}>
            <div style={{fontFamily: FONT, fontSize: 220, color: K.yellow, fontWeight: 900, lineHeight: 0.9}}>
              "
            </div>
            <Cascade
              text="i sent you"
              from={0}
              size={110}
              color="#FFF"
              each={1}
            />
            <Cascade
              text="three days ago"
              from={SEC(0.4)}
              size={110}
              color="#FFF"
              each={1}
            />
          </div>
        </Block>
      </Sequence>

      {/* 10.0–11.0s · white flash + "SIFT." */}
      <Sequence from={SEC(10.0)} durationInFrames={SEC(1.0)}>
        <Block color={K.paperOff}>
          <Stab from={0} size={520} color={K.cobalt}>
            Sift.
          </Stab>
        </Block>
        <Audio src={staticFile('sfx/whoosh.mp3')} />
      </Sequence>

      {/* 11.0–12.5s · query typed */}
      <Sequence from={SEC(11.0)} durationInFrames={SEC(1.5)}>
        <Block color={K.paperOff}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 30}}>
            <div style={{fontFamily: FONT, fontSize: 32, color: '#666', fontWeight: 700, letterSpacing: 2}}>
              YOU ASK
            </div>
            <div
              style={{
                padding: '36px 48px',
                background: K.cobalt,
                color: '#fff',
                borderRadius: 32,
                fontFamily: FONT,
                fontSize: 60,
                fontWeight: 700,
              }}
            >
              address mrs adebayo
            </div>
          </div>
        </Block>
        <Audio src={staticFile('sfx/click.mp3')} />
      </Sequence>

      {/* 12.5–15.0s · answer slams in */}
      <Sequence from={SEC(12.5)} durationInFrames={SEC(2.5)}>
        <Block color={K.acid}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20}}>
            <div style={{fontFamily: FONT, fontSize: 32, color: K.blackMatte, fontWeight: 700, letterSpacing: 2}}>
              FOUND IT
            </div>
            <Stab from={0} size={140} color={K.blackMatte} rotate={-1}>
              14b Allen Avenue
            </Stab>
            <div style={{fontFamily: FONT, fontSize: 70, color: K.blackMatte, fontWeight: 700}}>
              Ikeja
            </div>
            <div style={{fontFamily: FONT, fontSize: 46, color: K.deepRed, fontWeight: 500, fontStyle: 'italic'}}>
              opposite GTBank · blue gate
            </div>
          </div>
        </Block>
        <Audio src={staticFile('sfx/chime-win.mp3')} />
      </Sequence>

      {/* 15.0–16.0s · "ROUTE SET" */}
      <Sequence from={SEC(15.0)} durationInFrames={SEC(1.0)}>
        <Split
          topColor={K.cobalt}
          bottomColor={K.acid}
          topChildren={<Cascade text="route set" from={0} size={140} color="#FFF" each={1} />}
          bottomChildren={<Slam from={0} size={240} color={K.blackMatte}>6 min</Slam>}
        />
        <Audio src={staticFile('sfx/pop.mp3')} />
      </Sequence>

      {/* 16.0–17.0s · "YOU MADE IT" */}
      <Sequence from={SEC(16.0)} durationInFrames={SEC(1.0)}>
        <Block color={K.tangerine}>
          <Cascade text="you made it." from={0} size={180} color="#FFF" each={1} />
        </Block>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* 17.0–19.0s · the question flipped — "do you still think they didn't send?" */}
      <Sequence from={SEC(17.0)} durationInFrames={SEC(2.0)}>
        <Block color={K.blackMatte}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 24}}>
            <div style={{fontFamily: FONT, fontSize: 70, fontWeight: 500, color: '#999', fontStyle: 'italic'}}>
              they sent it.
            </div>
            <Cascade text="you screenshotted it." from={SEC(0.4)} size={100} color="#FFF" each={1} />
            <div style={{fontFamily: FONT, fontSize: 110, color: K.acid, fontWeight: 900, marginTop: 20}}>
              just ask Sift.
            </div>
          </div>
        </Block>
        <Audio src={staticFile('sfx/slam.mp3')} />
      </Sequence>

      {/* 19.0–21.5s · tagline block */}
      <Sequence from={SEC(19.0)} durationInFrames={SEC(2.5)}>
        <Block color={K.pink}>
          <Ransom
            from={0}
            each={3}
            words={[
              {text: 'the address', size: 140, color: '#FFF', rotate: -2},
              {text: 'the receipt', size: 140, color: '#FFF', rotate: 1},
              {text: 'the password', size: 140, color: '#FFF', rotate: -1},
              {text: 'everything.', size: 180, color: K.yellow, rotate: 0, italic: true},
            ]}
          />
        </Block>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* 21.5–24.0s · end lockup */}
      <Sequence from={SEC(21.5)} durationInFrames={SEC(2.5)}>
        <Block color={K.paperOff}>
          <EndCard tagline="Just ask Sift." />
        </Block>
        <Audio src={staticFile('sfx/chime-win.mp3')} />
      </Sequence>
    </AbsoluteFill>
  );
};
