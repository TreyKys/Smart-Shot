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
import {CitedAnswer, Card} from '../components/cards';
import {WallClock} from '../components/Countdown';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 5 · "The Night Before" · 60s · 9:16 · STUDENT
// The pain: exam tomorrow, textbook + notes + slides, you've reread the
// chapter three times and nothing has stuck. The reframe: you don't need
// to reread it — you need to be quizzed on it. Same 10-act rhythm as
// MeetingPanic and The Six Hours; picks up the countdown treatment.
// ─────────────────────────────────────────────────────────────────────────

// "You've read this chapter three times" — three highlighter passes drawn
// across a stack of page-lines, then a small × chip at the end for the
// question the reread never answered. Faceless, on the light stage.
const RereadPasses: React.FC<{from: number}> = ({from}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        gap: 18,
        alignItems: 'stretch',
        width: 720,
      }}
    >
      {[0, 1, 2].map((pass) => {
        const start = pass * 22; // ~0.7s between passes
        const s = spring({
          frame: frame - start,
          fps,
          config: {damping: 24, stiffness: 120, mass: 0.7},
        });
        const width = interpolate(s, [0, 1], [0, 100]);
        const op = interpolate(s, [0, 1], [0, 1]);
        return (
          <div key={pass} style={{position: 'relative', height: 28}}>
            {/* the "page line" — dim, always present */}
            <div
              style={{
                position: 'absolute',
                inset: 0,
                borderRadius: 999,
                background: c.lineSoft,
              }}
            />
            {/* the highlighter pass — draws across the line */}
            <div
              style={{
                position: 'absolute',
                top: 0,
                bottom: 0,
                left: 0,
                width: `${width}%`,
                opacity: op * 0.85,
                borderRadius: 999,
                background: c.accentWash,
                border: `1.5px solid ${c.accentBright}`,
              }}
            />
          </div>
        );
      })}
    </div>
  );
};

// "Practice-question mode" — your rough answer, then the correction. Two
// small stacked lines inside a card, so the beat reads as one interaction
// (question → your guess → corrected answer with a cite) rather than
// three separate cards on screen.
const PracticeCard: React.FC<{
  from: number;
  q: string;
  yourGuess: string;
  correction: React.ReactNode;
  cite: string;
}> = ({from, q, yourGuess, correction, cite}) => {
  const frame = useCurrentFrame();
  const guessAt = from + 18;
  const correctionAt = from + 42;
  const chipAt = from + 60;
  const guessOp = interpolate(frame, [guessAt, guessAt + 14], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const correctionOp = interpolate(
    frame,
    [correctionAt, correctionAt + 14],
    [0, 1],
    {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'},
  );
  const chipOp = interpolate(frame, [chipAt, chipAt + 14], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <Card from={from} width={960}>
      {/* the question the app asked you */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 16,
          padding: '18px 22px',
          borderRadius: 18,
          background: c.paper,
          border: `1.5px solid ${c.line}`,
        }}
      >
        <div
          style={{
            width: 12,
            height: 12,
            borderRadius: 999,
            background: c.accentBright,
            flexShrink: 0,
          }}
        />
        <span
          style={{
            fontSize: 28,
            fontWeight: 500,
            color: c.ink,
            fontFamily: FONT,
          }}
        >
          {q}
        </span>
      </div>

      {/* your rough guess (faint, italic, feels like the user typed it) */}
      <div
        style={{
          opacity: guessOp,
          marginTop: 18,
          fontSize: 26,
          fontStyle: 'italic',
          fontWeight: 500,
          color: c.inkFaint,
          fontFamily: FONT,
        }}
      >
        you: "{yourGuess}"
      </div>

      {/* the correction */}
      <div
        style={{
          opacity: correctionOp,
          marginTop: 14,
          fontSize: 30,
          fontWeight: 600,
          lineHeight: 1.4,
          color: c.ink,
          fontFamily: FONT,
        }}
      >
        <span style={{color: c.accent, fontWeight: 700}}>Close. </span>
        {correction}
      </div>

      <div style={{opacity: chipOp, marginTop: 18}}>
        <span
          style={{
            display: 'inline-block',
            padding: '8px 18px',
            borderRadius: 999,
            background: c.accentWash,
            color: c.accent,
            fontSize: 20,
            fontWeight: 700,
            letterSpacing: 0.5,
            fontFamily: FONT,
          }}
        >
          {cite}
        </span>
      </div>
    </Card>
  );
};

export const TheNightBefore: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Act 1 (0-4s): 2:15 a.m. bedside clock — the exam is 7 hours out */}
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
            <Eyebrow from={SEC(0.2)}>exam · 9 a.m.</Eyebrow>
            <WallClock from={SEC(0.4)} startHour={2} startMinute={15} />
            <Body from={SEC(1.2)} size={34} color={c.inkSoft}>
              seven hours. one chapter you don't know.
            </Body>
          </div>
        </Stage>
      </Sequence>

      {/* Act 2 (4-9s): the specific chapter that won't stick */}
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
            <Eyebrow from={SEC(0.2)}>chapter 8</Eyebrow>
            <Headline from={SEC(0.4)} size={132}>
              you've read it
              <br />
              three times.
            </Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 3 (9-16s): the three highlighter passes — and still nothing */}
      <Sequence from={SEC(9)} durationInFrames={SEC(7)}>
        <Stage>
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 34,
            }}
          >
            <Eyebrow from={SEC(0.2)}>the old plan · reread it again</Eyebrow>
            <RereadPasses from={SEC(0.6)} />
            <Body from={SEC(3.2)} size={38} maxWidth={820} color={c.inkSoft}>
              you still can't answer the practice questions.
            </Body>
          </div>
        </Stage>
      </Sequence>

      {/* Act 4 (16-22s): the number nobody has time for (dark) */}
      <Sequence from={SEC(16)} durationInFrames={SEC(6)}>
        <Stage dark>
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 24,
            }}
          >
            <Eyebrow from={SEC(0.2)} color={c.onNavySoft}>
              your textbook
            </Eyebrow>
            <Headline from={SEC(0.4)} size={200} color={c.onNavy}>
              847
            </Headline>
            <Body from={SEC(0.9)} size={38} color={c.onNavySoft}>
              pages. six hours of sleep. good luck.
            </Body>
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
            <Headline from={SEC(0.5)} size={128} color={c.onNavy}>
              stop rereading.
              <br />
              get quizzed on it.
            </Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 6 (28-36s): explain-it-to-me — the honest, cited answer */}
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
            <Eyebrow from={SEC(0.2)}>ask it anything</Eyebrow>
            <CitedAnswer
              from={SEC(0.6)}
              width={960}
              query="explain the Krebs cycle like i've never heard of it."
              answer={
                <span>
                  A cell takes{' '}
                  <span style={{color: c.accent}}>acetyl-CoA</span>, runs it
                  through eight reactions, and hands back{' '}
                  <span style={{color: c.accent}}>ATP, NADH, and FADH₂</span> —
                  the fuel for everything else.
                </span>
              }
              cite="Cited — Chapter 8, Page 213"
            />
          </div>
        </Stage>
      </Sequence>

      {/* Act 7 (36-44s): quiz-me #1 — you're close, here's the real one */}
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
            <Eyebrow from={SEC(0.2)}>quiz me · question one</Eyebrow>
            <PracticeCard
              from={SEC(0.6)}
              q="where does the Krebs cycle actually happen?"
              yourGuess="the cytoplasm?"
              correction={
                <span>
                  The <span style={{color: c.accent}}>mitochondrial matrix</span>{' '}
                  — glycolysis is in the cytoplasm.
                </span>
              }
              cite="Cited — Chapter 8, Page 219"
            />
          </div>
        </Stage>
      </Sequence>

      {/* Act 8 (44-52s): quiz-me #2 — the one you'd have missed on the test */}
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
            <Eyebrow from={SEC(0.2)}>quiz me · question two</Eyebrow>
            <PracticeCard
              from={SEC(0.6)}
              q="how many ATP per glucose, net?"
              yourGuess="38, i think?"
              correction={
                <span>
                  <span style={{color: c.accent}}>30–32 ATP</span> — the older
                  38 figure assumed 100% efficiency. Nothing in a cell is.
                </span>
              }
              cite="Cited — Chapter 8, Page 224"
            />
          </div>
        </Stage>
      </Sequence>

      {/* Act 9 (52-56s): the reveal — laptop shut, alarm set, ready */}
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
            <Eyebrow from={SEC(0.2)}>alarm set · 7:30 a.m.</Eyebrow>
            <Headline from={SEC(0.5)} size={130}>
              you're ready.
            </Headline>
          </div>
        </Stage>
      </Sequence>

      {/* Act 10 (56-60s): end lockup */}
      <Sequence from={SEC(56)} durationInFrames={SEC(4)}>
        <Stage>
          <EndCard
            from={SEC(0.3)}
            tagline="Study every page. Answer every question. Cited."
          />
        </Stage>
      </Sequence>
    </AbsoluteFill>
  );
};
