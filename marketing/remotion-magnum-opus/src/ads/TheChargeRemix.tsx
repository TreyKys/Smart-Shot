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
import {Block, Stab, Cascade, Slam, Highlight, Flash, Split, Ransom, K} from '../components/kinetic';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 11 · "The Charge / Remix" · 24s · 9:16
// Kinetic reworking of the hospital-bill mystery-fee scenario.
// ─────────────────────────────────────────────────────────────────────────

export const TheChargeRemix: React.FC = () => {
  return (
    <AbsoluteFill>
      <Sequence from={0} durationInFrames={SEC(24)}>
        <Audio src={staticFile('sfx/music-bed.mp3')} volume={0.3} />
      </Sequence>

      {/* 0–1.0s · HOOK — "₦25,000?" */}
      <Sequence from={0} durationInFrames={SEC(1.0)}>
        <Block color={K.deepRed}>
          <Slam from={0} size={360} color="#FFF">
            ₦25,000?
          </Slam>
        </Block>
        <Audio src={staticFile('sfx/debit.mp3')} />
      </Sequence>

      {/* 1.0–2.0s · "FOR WHAT?" */}
      <Sequence from={SEC(1.0)} durationInFrames={SEC(1.0)}>
        <Block color={K.yellow}>
          <Stab from={0} size={360} color={K.blackMatte} italic rotate={-2}>
            for what?
          </Stab>
        </Block>
        <Audio src={staticFile('sfx/slam.mp3')} />
      </Sequence>

      {/* 2.0–3.0s · "HOSPITAL BILL" */}
      <Sequence from={SEC(2.0)} durationInFrames={SEC(1.0)}>
        <Block color={K.teal}>
          <Cascade text="hospital bill." from={0} size={160} color="#FFF" each={1} />
        </Block>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* 3.0–5.0s · the itemised list storms in on paper bg */}
      <Sequence from={SEC(3.0)} durationInFrames={SEC(2.0)}>
        <Block color={K.paperOff} justify="flex-start" align="flex-start">
          <div style={{display: 'flex', flexDirection: 'column', gap: 14, width: '100%', padding: '40px 20px'}}>
            {[
              'consultation ₦5,000',
              'blood test ₦8,500',
              'IV drip ₦4,800',
              'drugs ₦6,500',
              'overnight ₦18,000',
              'nurse ₦4,500',
              'oxygen ₦2,750',
              'MISC. SERVICE FEE ₦25,000',
              'VAT ₦6,000',
            ].map((line, i) => (
              <ListRow key={i} from={SEC(0.1 + i * 0.18)} text={line} highlight={line.includes('MISC')} />
            ))}
          </div>
        </Block>
        {[0, 1, 2, 3, 4, 5, 6, 7, 8].map((i) => (
          <Sequence key={i} from={SEC(0.1 + i * 0.18)} durationInFrames={SEC(0.1)}>
            <Audio src={staticFile('sfx/click.mp3')} />
          </Sequence>
        ))}
      </Sequence>

      {/* 5.0–6.5s · zoom on the mystery line, highlighter sweep */}
      <Sequence from={SEC(5.0)} durationInFrames={SEC(1.5)}>
        <Block color={K.paperOff}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 24}}>
            <div style={{fontFamily: FONT, fontSize: 70, color: K.blackMatte, fontWeight: 700}}>
              <Highlight from={0} size={70} bgColor={K.yellow} color={K.deepRed} weight={900}>
                miscellaneous service fee
              </Highlight>
            </div>
            <Slam from={SEC(0.3)} size={240} color={K.deepRed} mono>
              ₦25,000
            </Slam>
          </div>
        </Block>
        <Audio src={staticFile('sfx/whoosh.mp3')} />
      </Sequence>

      {/* 6.5–7.5s · cashier's shrug */}
      <Sequence from={SEC(6.5)} durationInFrames={SEC(1.0)}>
        <Block color={K.blackMatte}>
          <Cascade text="that's just what" from={0} size={110} color="#FFF" each={1} />
        </Block>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* 7.5–8.5s · "the system says" */}
      <Sequence from={SEC(7.5)} durationInFrames={SEC(1.0)}>
        <Block color={K.blackMatte}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10}}>
            <Cascade text="the system says." from={0} size={110} color={K.yellow} each={1} />
            <div style={{fontFamily: FONT, fontSize: 36, color: '#888', fontStyle: 'italic', marginTop: 20}}>
              — the cashier
            </div>
          </div>
        </Block>
        <Audio src={staticFile('sfx/nope.mp3')} />
      </Sequence>

      {/* 8.5–9.5s · "SHE DOESN'T KNOW" */}
      <Sequence from={SEC(8.5)} durationInFrames={SEC(1.0)}>
        <Block color={K.pink}>
          <Stab from={0} size={240} color="#FFF" italic rotate={-3}>
            she has
          </Stab>
        </Block>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>
      <Sequence from={SEC(9.0)} durationInFrames={SEC(0.5)}>
        <Block color={K.deepRed}>
          <Stab from={0} size={360} color="#FFF">
            no idea.
          </Stab>
        </Block>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* 9.5–10.5s · "YOU PAID ANYWAY" */}
      <Sequence from={SEC(9.5)} durationInFrames={SEC(1.0)}>
        <Block color={K.blackMatte}>
          <Ransom
            from={0}
            each={2}
            words={[
              {text: 'you paid', size: 180, color: '#FFF', rotate: -2},
              {text: 'anyway.', size: 220, color: K.deepRed, rotate: 2, italic: true},
            ]}
          />
        </Block>
        <Audio src={staticFile('sfx/debit.mp3')} />
      </Sequence>

      {/* 10.5–11.5s · "NEXT TIME" */}
      <Sequence from={SEC(10.5)} durationInFrames={SEC(1.0)}>
        <Block color={K.cobalt}>
          <Cascade text="next time —" from={0} size={160} color={K.acid} each={1} />
        </Block>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* 11.5–12.5s · MAGNUM OPUS logo pop */}
      <Sequence from={SEC(11.5)} durationInFrames={SEC(1.0)}>
        <Block color={K.paperOff}>
          <div style={{display: 'flex', alignItems: 'baseline', gap: 20}}>
            <Stab from={0} size={200} color={K.blackMatte}>
              Magnum
            </Stab>
            <Stab from={SEC(0.2)} size={200} color={K.cobalt} italic>
              Opus.
            </Stab>
          </div>
        </Block>
        <Audio src={staticFile('sfx/whoosh.mp3')} />
      </Sequence>

      {/* 12.5–14.0s · you ask */}
      <Sequence from={SEC(12.5)} durationInFrames={SEC(1.5)}>
        <Block color={K.paperOff}>
          <div
            style={{
              padding: '40px 56px',
              background: K.cobalt,
              color: '#fff',
              borderRadius: 32,
              fontFamily: FONT,
              fontSize: 50,
              fontWeight: 700,
              maxWidth: 950,
              lineHeight: 1.3,
              textAlign: 'center',
            }}
          >
            what IS the misc. service fee?
          </div>
        </Block>
        <Audio src={staticFile('sfx/click.mp3')} />
      </Sequence>

      {/* 14.0–16.5s · the answer, cited */}
      <Sequence from={SEC(14.0)} durationInFrames={SEC(2.5)}>
        <Block color={K.acid}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20, maxWidth: 950}}>
            <div style={{fontFamily: FONT, fontSize: 32, color: K.blackMatte, fontWeight: 700, letterSpacing: 2}}>
              CONSENT FORM §4.2
            </div>
            <div style={{fontFamily: FONT, fontSize: 60, color: K.blackMatte, fontWeight: 700, textAlign: 'center', lineHeight: 1.2}}>
              laundry · sterilisation
              <br />
              <span style={{color: K.deepRed}}>admin handling.</span>
            </div>
            <div style={{fontFamily: FONT, fontSize: 44, color: K.blackMatte, fontWeight: 700, marginTop: 10}}>
              Standard: <span style={{color: K.deepRed}}>₦8–12k</span>
            </div>
          </div>
        </Block>
        <Audio src={staticFile('sfx/chime-win.mp3')} />
      </Sequence>

      {/* 16.5–18.0s · "GO ARGUE" */}
      <Sequence from={SEC(16.5)} durationInFrames={SEC(1.5)}>
        <Block color={K.deepRed}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12}}>
            <Stab from={0} size={200} color="#FFF">
              now you
            </Stab>
            <Cascade text="have an argument." from={SEC(0.3)} size={100} color={K.yellow} each={1} />
          </div>
        </Block>
        <Audio src={staticFile('sfx/slam.mp3')} />
      </Sequence>

      {/* 18.0–19.5s · "KNOW WHAT YOU'RE PAYING FOR" */}
      <Sequence from={SEC(18.0)} durationInFrames={SEC(1.5)}>
        <Block color={K.blackMatte}>
          <Ransom
            from={0}
            each={2}
            words={[
              {text: 'know what', size: 160, color: '#FFF', rotate: -2},
              {text: 'you\'re paying for.', size: 110, color: K.acid, rotate: 1, italic: true, weight: 700},
            ]}
          />
        </Block>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* 19.5–21.5s · "ASK IT. ASK EVERYTHING." */}
      <Sequence from={SEC(19.5)} durationInFrames={SEC(2.0)}>
        <Block color={K.violet}>
          <Ransom
            from={0}
            each={3}
            words={[
              {text: 'ask', size: 320, color: '#FFF', rotate: -3},
              {text: 'everything.', size: 180, color: K.limeNeon, italic: true, rotate: 2},
            ]}
          />
        </Block>
        <Audio src={staticFile('sfx/whoosh.mp3')} />
      </Sequence>

      {/* 21.5–24.0s · end lockup */}
      <Sequence from={SEC(21.5)} durationInFrames={SEC(2.5)}>
        <Block color={K.paperOff}>
          <EndCard tagline="Know what you paid for." />
        </Block>
        <Audio src={staticFile('sfx/chime-win.mp3')} />
      </Sequence>
    </AbsoluteFill>
  );
};

// A line row on the paper-bg bill screen, with optional yellow-highlight
const ListRow: React.FC<{from: number; text: string; highlight?: boolean}> = ({
  from,
  text,
  highlight,
}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 8], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const x = interpolate(frame, [0, 8], [30, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        opacity: op,
        transform: `translateX(${x}px)`,
        padding: highlight ? '18px 24px' : '12px 24px',
        fontFamily: FONT,
        fontSize: highlight ? 60 : 44,
        fontWeight: highlight ? 900 : 500,
        color: highlight ? K.deepRed : K.blackMatte,
        background: highlight ? K.yellow : 'transparent',
        borderRadius: highlight ? 10 : 0,
        letterSpacing: highlight ? 0 : 0,
      }}
    >
      {text}
    </div>
  );
};
