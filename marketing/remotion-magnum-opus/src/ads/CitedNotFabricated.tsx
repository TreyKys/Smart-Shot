import React from 'react';
import {AbsoluteFill, Sequence, interpolate, useCurrentFrame} from 'remotion';
import {c, FONT, SEC} from '../theme';
import {Stage} from '../components/Stage';
import {Eyebrow, Headline, Body} from '../components/type';
import {Card, CitedAnswer, DocumentPage} from '../components/cards';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 2 · "It made up the page number" · 60s · 9:16
// Generic AI confidently cites a page → the page doesn't say that →
// Magnum Opus's cited answer is what's actually there. Leans on the
// existing product's cite-chip. Nine acts.
// ─────────────────────────────────────────────────────────────────────────

// A tension-building "reveal" card — a document page that turns out NOT to
// contain the promised text. Used in the fake-cite reveal beat.
const RevealPage: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  // A red overlay slowly fills in over the page to signal "this isn't
  // there" without lifting the visual too fast.
  const overlayOp = interpolate(frame, [SEC(1.6), SEC(2.6)], [0, 0.35], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const stampOp = interpolate(frame, [SEC(2.4), SEC(3.2)], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const stampRot = interpolate(stampOp, [0, 1], [-14, -7]);
  return (
    <div style={{position: 'relative'}}>
      <DocumentPage
        from={from}
        pageNum={34}
        title="Section 7 · Insurance"
        lines={8}
        width={620}
        onDark
      />
      <div
        style={{
          position: 'absolute',
          inset: 0,
          borderRadius: 28,
          background: c.danger,
          opacity: overlayOp,
          pointerEvents: 'none',
        }}
      />
      <div
        style={{
          position: 'absolute',
          top: 40,
          right: -30,
          transform: `rotate(${stampRot}deg)`,
          opacity: stampOp,
          padding: '10px 22px',
          border: `4px solid ${c.danger}`,
          borderRadius: 8,
          color: c.danger,
          fontFamily: FONT,
          fontSize: 30,
          fontWeight: 800,
          letterSpacing: 3,
          textTransform: 'uppercase',
          background: 'rgba(20,27,46,0.8)',
        }}
      >
        Not there
      </div>
    </div>
  );
};

// The invalidated "generic AI" card — same-question answer, then the
// strikethrough falls across it.
const FabricatedCard: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const strikeOp = interpolate(frame, [SEC(1.6), SEC(2.2)], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div style={{position: 'relative', width: 900}}>
      <Card from={from} width={900}>
        <div
          style={{
            fontSize: 20,
            fontWeight: 800,
            letterSpacing: 2,
            textTransform: 'uppercase',
            color: c.danger,
            marginBottom: 14,
          }}
        >
          Generic AI
        </div>
        <div style={{fontSize: 32, fontWeight: 600, color: c.ink, lineHeight: 1.45}}>
          "The termination notice is <span style={{fontWeight: 800}}>60 days</span> —
          see <span style={{fontWeight: 800}}>page 34</span>."
        </div>
        <div
          style={{
            marginTop: 18,
            fontSize: 22,
            fontWeight: 700,
            color: c.danger,
            opacity: strikeOp,
          }}
        >
          Page 34 doesn't say that.
        </div>
      </Card>
      <div
        style={{
          position: 'absolute',
          top: '48%',
          left: -20,
          right: -20,
          height: 5,
          background: c.danger,
          transform: `translateY(-2.5px) scaleX(${strikeOp})`,
          transformOrigin: 'left center',
          borderRadius: 3,
        }}
      />
    </div>
  );
};

export const CitedNotFabricated: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Act 1 (0-5s): the moment before */}
      <Sequence from={0} durationInFrames={SEC(5)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 26}}>
            <Eyebrow from={SEC(0.2)}>in the meeting</Eyebrow>
            <Headline from={SEC(0.5)} size={124}>you asked. it answered.</Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 2 (5-10s): confidently */}
      <Sequence from={SEC(5)} durationInFrames={SEC(5)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
            <Headline from={SEC(0.2)} size={130}>confidently.</Headline>
            <Body from={SEC(1.2)} color={c.inkSoft} size={38}>
              "The termination notice is 60 days, see page 34."
            </Body>
          </div>
        </Stage>
      </Sequence>

      {/* Act 3 (10-15s): then someone checked */}
      <Sequence from={SEC(10)} durationInFrames={SEC(5)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 26}}>
            <Eyebrow from={SEC(0.2)} color={c.danger}>then</Eyebrow>
            <Headline from={SEC(0.5)} size={130}>someone checked.</Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 4 (15-24s): page 34 shown → red overlay + "not there" stamp */}
      <Sequence from={SEC(15)} durationInFrames={SEC(9)}>
        <Stage dark>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 34}}>
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>the page it named</Eyebrow>
            <RevealPage from={SEC(0.5)} />
          </div>
        </Stage>
      </Sequence>

      {/* Act 5 (24-30s): the line lands */}
      <Sequence from={SEC(24)} durationInFrames={SEC(6)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20}}>
            <Eyebrow from={SEC(0.2)} color={c.danger}>section 7 is about insurance</Eyebrow>
            <Headline from={SEC(0.5)} size={112} color={c.danger}>
              it made
              <br />
              that up.
            </Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 6 (30-38s): the invalidated card, then the real one */}
      <Sequence from={SEC(30)} durationInFrames={SEC(8)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 28}}>
            <Eyebrow from={SEC(0.2)}>the answer that was in the meeting</Eyebrow>
            <FabricatedCard from={SEC(0.6)} />
          </div>
        </Stage>
      </Sequence>

      {/* Act 7 (38-48s): the Magnum Opus answer — same question, real cite */}
      <Sequence from={SEC(38)} durationInFrames={SEC(10)}>
        <Stage>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 26}}>
            <Eyebrow from={SEC(0.2)}>the answer that's actually there</Eyebrow>
            <CitedAnswer
              from={SEC(0.6)}
              width={960}
              query="what's the termination notice period?"
              answer={
                <span>
                  <span style={{color: c.accent}}>30 days' written notice</span>, before renewal.
                </span>
              }
              cite="Cited — Page 11, §4.2"
            />
            <Body from={SEC(4)} color={c.inkSoft} size={32} maxWidth={800}>
              tap the chip. the exact clause opens.
            </Body>
          </div>
        </Stage>
      </Sequence>

      {/* Act 8 (48-56s): the mechanism */}
      <Sequence from={SEC(48)} durationInFrames={SEC(8)}>
        <Stage dark>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>every answer</Eyebrow>
            <Headline from={SEC(0.5)} size={124} color={c.onNavy}>
              cited to
              <br />
              the page.
            </Headline>
            <Body from={SEC(2.5)} color={c.onNavySoft} size={34} maxWidth={800}>
              no invented sources. no confident nonsense.
            </Body>
          </div>
        </Stage>
      </Sequence>

      {/* Act 9 (56-60s): end lockup */}
      <Sequence from={SEC(56)} durationInFrames={SEC(4)}>
        <Stage>
          <EndCard from={SEC(0.3)} tagline="Every answer, cited to the page." />
        </Stage>
      </Sequence>
    </AbsoluteFill>
  );
};
