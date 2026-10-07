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
// AD 10 · "The Clause / Remix" · 24s · 9:16
// Kinetic reworking of the CarbonLoan auto-renewal scenario. Max cuts,
// big typography, vibrant backgrounds. VO-ready — leaves pockets.
// ─────────────────────────────────────────────────────────────────────────

export const TheClauseRemix: React.FC = () => {
  return (
    <AbsoluteFill>
      <Sequence from={0} durationInFrames={SEC(24)}>
        <Audio src={staticFile('sfx/music-bed.mp3')} volume={0.3} />
      </Sequence>

      {/* 0–1.2s · HOOK — "DEBIT" slams in red */}
      <Sequence from={0} durationInFrames={SEC(1.2)}>
        <Block color={K.deepRed}>
          <Cascade text="DEBIT." from={0} size={420} color="#FFF" each={2} />
        </Block>
        <Audio src={staticFile('sfx/debit.mp3')} />
      </Sequence>

      {/* 1.2–2.4s · the amount */}
      <Sequence from={SEC(1.2)} durationInFrames={SEC(1.2)}>
        <Block color={K.blackMatte}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 16}}>
            <div style={{fontFamily: FONT, fontSize: 36, color: K.deepRed, fontWeight: 900, letterSpacing: 3}}>
              CARBON LOAN
            </div>
            <Slam from={0} size={360} color="#FFF" mono>
              −₦14,500
            </Slam>
          </div>
        </Block>
        <Audio src={staticFile('sfx/slam.mp3')} />
      </Sequence>

      {/* 2.4–3.6s · "WHAT LOAN?" */}
      <Sequence from={SEC(2.4)} durationInFrames={SEC(1.2)}>
        <Block color={K.yellow}>
          <Stab from={0} size={340} color={K.blackMatte} italic rotate={-2}>
            what loan?
          </Stab>
        </Block>
        <Audio src={staticFile('sfx/nope.mp3')} />
      </Sequence>

      {/* 3.6–4.4s · "oh. that one." split */}
      <Sequence from={SEC(3.6)} durationInFrames={SEC(0.8)}>
        <Split
          topColor={K.pink}
          bottomColor={K.blackMatte}
          topChildren={<Stab from={0} size={200} color="#FFF">oh.</Stab>}
          bottomChildren={<Cascade text="that one." from={0} size={160} color={K.yellow} each={2} />}
        />
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* 4.4–5.6s · "23 PAGES" */}
      <Sequence from={SEC(4.4)} durationInFrames={SEC(1.2)}>
        <Block color={K.cobalt}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10}}>
            <Slam from={0} size={500} color={K.acid}>
              23
            </Slam>
            <div style={{fontFamily: FONT, fontSize: 100, color: '#FFF', fontWeight: 900, letterSpacing: -3}}>
              pages.
            </div>
          </div>
        </Block>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* 5.6–6.6s · "YOU SCROLLED" */}
      <Sequence from={SEC(5.6)} durationInFrames={SEC(1.0)}>
        <Block color={K.violet}>
          <Cascade text="you scrolled." from={0} size={140} color="#FFF" each={1} />
        </Block>
        <Audio src={staticFile('sfx/click.mp3')} />
      </Sequence>

      {/* 6.6–7.6s · "I AGREE" button slam */}
      <Sequence from={SEC(6.6)} durationInFrames={SEC(1.0)}>
        <Block color={K.paperOff}>
          <div
            style={{
              padding: '50px 100px',
              background: K.deepRed,
              borderRadius: 24,
              fontFamily: FONT,
              fontSize: 140,
              fontWeight: 900,
              color: '#FFF',
              transform: 'rotate(-1deg)',
              boxShadow: '0 0 60px rgba(0,0,0,0.3)',
            }}
          >
            I AGREE
          </div>
        </Block>
        <Audio src={staticFile('sfx/slam.mp3')} />
      </Sequence>

      {/* 7.6–8.8s · "the clause" */}
      <Sequence from={SEC(7.6)} durationInFrames={SEC(1.2)}>
        <Block color={K.blackMatte}>
          <Ransom
            from={0}
            each={2}
            words={[
              {text: 'the clause', size: 220, color: K.yellow, rotate: -3},
              {text: 'you missed.', size: 120, italic: true, color: '#FFF', rotate: 2, weight: 700},
            ]}
          />
        </Block>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* 8.8–11.3s · highlighter sweep across the real clause */}
      <Sequence from={SEC(8.8)} durationInFrames={SEC(2.5)}>
        <Block color={K.paperOff}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 24, maxWidth: 920}}>
            <div style={{fontFamily: FONT, fontSize: 32, color: '#666', fontWeight: 700, letterSpacing: 2}}>
              §7.4 · PAGE 19
            </div>
            <div
              style={{
                fontFamily: FONT,
                fontSize: 60,
                fontWeight: 500,
                color: K.blackMatte,
                lineHeight: 1.3,
              }}
            >
              auto-renews{' '}
              <Highlight from={0} size={60} bgColor={K.yellow} color={K.deepRed} weight={900}>
                every 30 days
              </Highlight>
              <br />
              with a{' '}
              <Highlight from={SEC(0.5)} size={60} bgColor={K.yellow} color={K.deepRed} weight={900}>
                10% fee
              </Highlight>
            </div>
          </div>
        </Block>
        <Audio src={staticFile('sfx/whoosh.mp3')} />
      </Sequence>

      {/* 11.3–12.3s · "FOREVER" */}
      <Sequence from={SEC(11.3)} durationInFrames={SEC(1.0)}>
        <Block color={K.deepRed}>
          <Stab from={0} size={340} color="#FFF" italic rotate={-3}>
            forever.
          </Stab>
        </Block>
        <Audio src={staticFile('sfx/debit.mp3')} />
      </Sequence>

      {/* 12.3–13.3s · "there is a question" */}
      <Sequence from={SEC(12.3)} durationInFrames={SEC(1.0)}>
        <Block color={K.blackMatte}>
          <Cascade text="one question." from={0} size={140} color="#FFF" each={1} />
        </Block>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* 13.3–14.3s · "YOU FORGOT TO ASK" */}
      <Sequence from={SEC(13.3)} durationInFrames={SEC(1.0)}>
        <Block color={K.yellow}>
          <Cascade text="you forgot to ask." from={0} size={100} color={K.blackMatte} each={1} />
        </Block>
        <Audio src={staticFile('sfx/snap.mp3')} />
      </Sequence>

      {/* 14.3–15.3s · "MAGNUM OPUS" slam */}
      <Sequence from={SEC(14.3)} durationInFrames={SEC(1.0)}>
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

      {/* 15.3–17.3s · the ask */}
      <Sequence from={SEC(15.3)} durationInFrames={SEC(2.0)}>
        <Block color={K.paperOff}>
          <div
            style={{
              padding: '40px 56px',
              background: K.cobalt,
              color: '#fff',
              borderRadius: 32,
              fontFamily: FONT,
              fontSize: 56,
              fontWeight: 700,
              maxWidth: 950,
              lineHeight: 1.3,
              textAlign: 'center',
            }}
          >
            anything I should watch out for before I sign?
          </div>
        </Block>
        <Audio src={staticFile('sfx/click.mp3')} />
      </Sequence>

      {/* 17.3–19.8s · the answer slams in */}
      <Sequence from={SEC(17.3)} durationInFrames={SEC(2.5)}>
        <Block color={K.acid}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20}}>
            <div style={{fontFamily: FONT, fontSize: 32, color: K.blackMatte, fontWeight: 700, letterSpacing: 2}}>
              MO ANSWERS
            </div>
            <Stab from={0} size={110} color={K.blackMatte} rotate={-1}>
              yes.
            </Stab>
            <div style={{fontFamily: FONT, fontSize: 56, color: K.blackMatte, fontWeight: 700, textAlign: 'center', maxWidth: 950, lineHeight: 1.3}}>
              auto-renews every 30 days.
              <br />
              <span style={{color: K.deepRed}}>10% fee each time.</span>
            </div>
            <div
              style={{
                padding: '10px 22px',
                borderRadius: 999,
                background: K.blackMatte,
                color: K.acid,
                fontFamily: FONT,
                fontSize: 24,
                fontWeight: 800,
                letterSpacing: 1,
                marginTop: 6,
              }}
            >
              Cited — §7.4, p19
            </div>
          </div>
        </Block>
        <Audio src={staticFile('sfx/chime-win.mp3')} />
      </Sequence>

      {/* 19.8–21.5s · "ASK BEFORE YOU SIGN" */}
      <Sequence from={SEC(19.8)} durationInFrames={SEC(1.7)}>
        <Block color={K.blackMatte}>
          <Ransom
            from={0}
            each={3}
            words={[
              {text: 'ask', size: 240, color: '#FFF', rotate: -2},
              {text: 'before', size: 140, italic: true, color: K.yellow, rotate: 1, weight: 700},
              {text: 'you sign.', size: 200, color: '#FFF', rotate: 0},
            ]}
          />
        </Block>
        <Audio src={staticFile('sfx/slam.mp3')} />
      </Sequence>

      {/* 21.5–24.0s · end lockup */}
      <Sequence from={SEC(21.5)} durationInFrames={SEC(2.5)}>
        <Block color={K.paperOff}>
          <EndCard tagline="Ask the doc before you sign it." />
        </Block>
        <Audio src={staticFile('sfx/chime-win.mp3')} />
      </Sequence>
    </AbsoluteFill>
  );
};
