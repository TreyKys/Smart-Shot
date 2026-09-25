import React from 'react';
import {
  AbsoluteFill,
  Sequence,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import {c, FONT, SEC} from '../theme';
import {Stage} from '../components/Stage';
import {Eyebrow, Headline, Body} from '../components/type';
import {CitedAnswer, Chip} from '../components/cards';
import {WallClock} from '../components/Countdown';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 4 · "The Six Hours" · 60s · 9:16 · STUDENT
// The pain: a research paper due at 8 a.m., a folder of 15 PDFs open, a
// specific stat you know is in one of them, and Ctrl-F is a lie. Same
// 10-act rhythm as MeetingPanic — pressure → sinking → attempt → new plan
// → three cited answers → shipped.
// ─────────────────────────────────────────────────────────────────────────

// Failed search chips — "sample size" 0 results, "n=" 0 results, etc. The
// visual of Ctrl-F giving up on document after document. Uses the shared
// Chip primitive with the `wrong` red-outline treatment.
const SEARCH_FAILURES: Array<{q: string}> = [
  {q: '"sample size" — 0 results'},
  {q: '"n = 240" — 0 results'},
  {q: '"participants" — 47 results, wrong ones'},
  {q: '"undergraduates" — 12 results, wrong ones'},
];

const SearchFailStack: React.FC<{from: number}> = ({from}) => {
  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        gap: 14,
        alignItems: 'stretch',
        maxWidth: 900,
      }}
    >
      {SEARCH_FAILURES.map((s, i) => (
        <Chip key={s.q} from={from + i * 8} label={s.q} wrong />
      ))}
    </div>
  );
};

// The "fifteen PDFs" wall — a grid of dim tile rectangles standing in for
// journal-article tabs, on the dark stage where the panic peaks. Kept
// deliberately faceless — no titles, no highlights — so the beat reads as
// "you can't remember which is which" not "here's your file list".
const PdfWall: React.FC<{from: number; count?: number}> = ({from, count = 15}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  return (
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(5, 1fr)',
        gap: 14,
        width: 860,
      }}
    >
      {Array.from({length: count}).map((_, i) => {
        const s = spring({
          frame: frame - i * 2,
          fps,
          config: {damping: 24, stiffness: 130, mass: 0.6},
        });
        const op = interpolate(s, [0, 1], [0, 1]);
        const y = interpolate(s, [0, 1], [12, 0]);
        return (
          <div
            key={i}
            style={{
              opacity: op,
              transform: `translateY(${y}px)`,
              height: 150,
              borderRadius: 12,
              background: c.navyCard,
              border: `1.5px solid ${c.navyLine}`,
              display: 'flex',
              flexDirection: 'column',
              gap: 8,
              padding: 14,
              justifyContent: 'flex-start',
            }}
          >
            {/* faint "text lines" — same fake-page look as DocumentPage */}
            {[70, 55, 65, 40].map((w, li) => (
              <div
                key={li}
                style={{
                  height: 8,
                  borderRadius: 999,
                  background: c.navyLine,
                  width: `${w}%`,
                }}
              />
            ))}
            <div style={{flex: 1}} />
            <div
              style={{
                fontSize: 12,
                letterSpacing: 2,
                textTransform: 'uppercase',
                color: c.onNavySoft,
                fontFamily: FONT,
                fontWeight: 700,
                textAlign: 'right',
              }}
            >
              .pdf
            </div>
          </div>
        );
      })}
    </div>
  );
};

// Rising word-count counter — the payoff visual: the empty doc starts at
// 0, the number climbs each frame while the Q3 cited answer is on screen,
// then holds. Reads as "I'm actually shipping this."
const WordCount: React.FC<{from: number; target: number}> = ({from, target}) => {
  const frame = useCurrentFrame() - from;
  const settle = 60; // frames to reach target
  const t = Math.min(1, Math.max(0, frame) / settle);
  // Ease-out — quick climb, slow finish, so the number "settles" rather
  // than jumping straight to target.
  const eased = 1 - Math.pow(1 - t, 3);
  const n = Math.floor(eased * target);
  const op = interpolate(frame, [0, 12], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <div
      style={{
        opacity: op,
        fontFamily: FONT,
        fontVariantNumeric: 'tabular-nums',
        fontSize: 44,
        fontWeight: 700,
        color: c.ink,
      }}
    >
      {n.toLocaleString()} / {target.toLocaleString()} words
    </div>
  );
};

export const TheSixHours: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Act 1 (0-4s): 2:14 a.m. — the timestamp that says everything */}
      <Sequence from={0} durationInFrames={SEC(4)}>
        <Stage>
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 22,
            }}
          >
            <Eyebrow from={SEC(0.2)}>the paper is due at 8</Eyebrow>
            <WallClock from={SEC(0.4)} startHour={2} startMinute={14} />
            <Body from={SEC(1.2)} size={34} color={c.inkSoft}>
              you have not started.
            </Body>
          </div>
        </Stage>
      </Sequence>

      {/* Act 2 (4-9s): the sinking realization */}
      <Sequence from={SEC(4)} durationInFrames={SEC(5)}>
        <Stage>
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 24,
            }}
          >
            <Eyebrow from={SEC(0.2)}>you've read all of them</Eyebrow>
            <Headline from={SEC(0.4)} size={124}>
              you just can't
              <br />
              remember which
              <br />
              said what.
            </Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 3 (9-16s): the 15 PDFs wall (dark) */}
      <Sequence from={SEC(9)} durationInFrames={SEC(7)}>
        <Stage dark pad={80}>
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 30,
            }}
          >
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>
              your folder
            </Eyebrow>
            <Headline from={SEC(0.4)} size={168} color={c.onNavy}>
              15
            </Headline>
            <Body from={SEC(0.9)} color={c.onNavySoft} size={38}>
              PDFs. one has the stat. good luck.
            </Body>
            <div style={{marginTop: 16}}>
              <PdfWall from={SEC(1.4)} count={15} />
            </div>
          </div>
        </Stage>
      </Sequence>

      {/* Act 4 (16-22s): ctrl-F, the false hope */}
      <Sequence from={SEC(16)} durationInFrames={SEC(6)}>
        <Stage>
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 24,
            }}
          >
            <Eyebrow from={SEC(0.2)}>the old plan · ctrl + F</Eyebrow>
            <SearchFailStack from={SEC(0.5)} />
          </div>
        </Stage>
      </Sequence>

      {/* Act 5 (22-28s): the pivot (dark) */}
      <Sequence from={SEC(22)} durationInFrames={SEC(6)}>
        <Stage dark>
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 20,
            }}
          >
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>
              the new plan
            </Eyebrow>
            <Headline from={SEC(0.5)} size={130} color={c.onNavy}>
              drop the folder in.
              <br />
              ask the folder.
            </Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 6 (28-36s): Q1 — the number you couldn't find */}
      <Sequence from={SEC(28)} durationInFrames={SEC(8)}>
        <Stage>
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 22,
            }}
          >
            <Eyebrow from={SEC(0.2)}>question one</Eyebrow>
            <CitedAnswer
              from={SEC(0.6)}
              width={960}
              query="which paper used the Rutgers undergrad sample of 240?"
              answer={
                <span>
                  <span style={{color: c.accent}}>Kahneman & Frederick, 2012</span>
                  , Study 2 — <span style={{color: c.accent}}>n&nbsp;=&nbsp;240</span>{' '}
                  Rutgers undergraduates.
                </span>
              }
              cite="Cited — Page 4"
            />
          </div>
        </Stage>
      </Sequence>

      {/* Act 7 (36-44s): Q2 — the definition you needed verbatim */}
      <Sequence from={SEC(36)} durationInFrames={SEC(8)}>
        <Stage>
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 22,
            }}
          >
            <Eyebrow from={SEC(0.2)}>question two</Eyebrow>
            <CitedAnswer
              from={SEC(0.6)}
              width={960}
              query="Piaget's definition of accommodation, verbatim?"
              answer={
                <span>
                  "The modification of existing{' '}
                  <span style={{color: c.accent}}>schemas</span> to fit new
                  information from the environment."
                </span>
              }
              cite="Cited — Chapter 3, Page 87"
            />
          </div>
        </Stage>
      </Sequence>

      {/* Act 8 (44-52s): Q3 — and the word count starts climbing */}
      <Sequence from={SEC(44)} durationInFrames={SEC(8)}>
        <Stage>
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 22,
            }}
          >
            <Eyebrow from={SEC(0.2)}>question three</Eyebrow>
            <CitedAnswer
              from={SEC(0.6)}
              width={960}
              query="which paper argued for embodied cognition?"
              answer={
                <span>
                  <span style={{color: c.accent}}>Barsalou, 2008</span> — "Grounded
                  Cognition," Annual Review of Psychology.
                </span>
              }
              cite="Cited — Page 617, Abstract"
            />
            <div style={{marginTop: 12}}>
              <WordCount from={SEC(3.2)} target={3000} />
            </div>
          </div>
        </Stage>
      </Sequence>

      {/* Act 9 (52-56s): the reveal — 2:47 a.m., 13 minutes to spare */}
      <Sequence from={SEC(52)} durationInFrames={SEC(4)}>
        <Stage>
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 18,
            }}
          >
            <Eyebrow from={SEC(0.2)}>submitted</Eyebrow>
            <Headline from={SEC(0.5)} size={126}>
              2:47 a.m.
            </Headline>
            <Body from={SEC(1.1)} size={34} color={c.inkSoft}>
              13 minutes to spare.
            </Body>
          </div>
        </Stage>
      </Sequence>

      {/* Act 10 (56-60s): end lockup */}
      <Sequence from={SEC(56)} durationInFrames={SEC(4)}>
        <Stage>
          <EndCard
            from={SEC(0.3)}
            tagline="Every source you kept. Every answer, cited."
          />
        </Stage>
      </Sequence>
    </AbsoluteFill>
  );
};
