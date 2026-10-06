import React from 'react';
import {AbsoluteFill, Sequence, interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {SEC, FONT, c} from '../theme';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 6 · "Which One Is It" · 20s · 16:9
// Deliberately breaks the editorial house style. The whole ad is a fake
// macOS Finder window with a growing list of filenames nobody can tell
// apart — contract_FINAL.pdf, contract_FINAL_v2.pdf, contract_USE_THIS.pdf.
// Universal pain for anyone with a job. Only in the last 4 seconds does
// Magnum Opus appear.
// ─────────────────────────────────────────────────────────────────────────

const C = {
  wallpaper: '#4A6CF7', // generic macOS gradient blue
  wallpaperDark: '#2F3EB5',
  window: '#F6F6F6',
  windowChrome: '#E8E8E8',
  sidebar: '#F0F0F0',
  rowOdd: '#FFFFFF',
  rowEven: '#F6F6F6',
  text: '#000',
  textMeta: '#8E8E93',
  divider: '#D1D1D6',
  select: '#1E88E5',
  trafficRed: '#FF605C',
  trafficYellow: '#FFBD44',
  trafficGreen: '#00CA4E',
};

type FileRow = {
  name: string;
  size: string;
  date: string;
  isHero?: boolean;
};

const FILES: FileRow[] = [
  {name: 'Westfield_contract.pdf', size: '2.4 MB', date: 'Mar 3, 2026'},
  {name: 'Westfield_contract_v2.pdf', size: '2.4 MB', date: 'Mar 4, 2026'},
  {name: 'Westfield_contract_v2_edits.pdf', size: '2.4 MB', date: 'Mar 4, 2026'},
  {name: 'Westfield_contract_FINAL.pdf', size: '2.5 MB', date: 'Mar 5, 2026'},
  {name: 'Westfield_contract_FINAL_v2.pdf', size: '2.5 MB', date: 'Mar 5, 2026'},
  {name: 'Westfield_contract_USE_THIS.pdf', size: '2.5 MB', date: 'Mar 7, 2026'},
  {name: 'Westfield_contract_FINAL_actually.pdf', size: '2.5 MB', date: 'Mar 8, 2026'},
  {name: 'Westfield_contract_Monday_version.pdf', size: '2.5 MB', date: 'Mar 11, 2026'},
  {name: 'Westfield_FINAL_signed.pdf', size: '2.6 MB', date: 'Mar 12, 2026', isHero: true},
  {name: 'Westfield_FINAL_signed_v2.pdf', size: '2.6 MB', date: 'Mar 12, 2026'},
];

// A tiny PDF-like file icon — red triangle corner, black "PDF" tag
const PdfIcon: React.FC = () => (
  <div
    style={{
      position: 'relative',
      width: 28,
      height: 36,
      background: '#fff',
      border: '1.5px solid #BDBDBD',
      borderRadius: 3,
      flexShrink: 0,
      display: 'flex',
      alignItems: 'flex-end',
      justifyContent: 'center',
      paddingBottom: 2,
      fontFamily: FONT,
      fontSize: 8,
      fontWeight: 800,
      color: '#D32F2F',
      letterSpacing: 0.5,
    }}
  >
    <div
      style={{
        position: 'absolute',
        top: 0,
        right: 0,
        width: 10,
        height: 10,
        background: '#F6F6F6',
        borderLeft: '1.5px solid #BDBDBD',
        borderBottom: '1.5px solid #BDBDBD',
      }}
    />
    PDF
  </div>
);

const FileRowView: React.FC<{
  from: number;
  file: FileRow;
  index: number;
  selected?: boolean;
}> = ({from, file, index, selected}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 8], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const bg = selected ? C.select : index % 2 === 0 ? C.rowOdd : C.rowEven;
  const textColor = selected ? '#fff' : C.text;
  return (
    <div
      style={{
        opacity: op,
        display: 'grid',
        gridTemplateColumns: '60px 1fr 140px 220px',
        alignItems: 'center',
        padding: '12px 20px',
        background: bg,
        fontFamily: FONT,
        fontSize: 22,
        color: textColor,
        gap: 20,
      }}
    >
      <PdfIcon />
      <span style={{fontWeight: 500}}>{file.name}</span>
      <span style={{color: selected ? '#fff' : C.textMeta, fontSize: 20}}>{file.size}</span>
      <span style={{color: selected ? '#fff' : C.textMeta, fontSize: 20}}>{file.date}</span>
    </div>
  );
};

const WindowFrame: React.FC<{children: React.ReactNode; title?: string}> = ({
  children,
  title = 'Westfield',
}) => (
  <div
    style={{
      width: 1550,
      height: 920,
      background: C.window,
      borderRadius: 14,
      boxShadow: '0 40px 100px rgba(0,0,0,0.4)',
      overflow: 'hidden',
      display: 'flex',
      flexDirection: 'column',
    }}
  >
    {/* Title bar */}
    <div
      style={{
        background: C.windowChrome,
        padding: '14px 20px',
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        borderBottom: `1px solid ${C.divider}`,
      }}
    >
      <div style={{display: 'flex', gap: 8}}>
        <div style={{width: 14, height: 14, borderRadius: '50%', background: C.trafficRed}} />
        <div style={{width: 14, height: 14, borderRadius: '50%', background: C.trafficYellow}} />
        <div style={{width: 14, height: 14, borderRadius: '50%', background: C.trafficGreen}} />
      </div>
      <div
        style={{
          flex: 1,
          textAlign: 'center',
          fontFamily: FONT,
          fontSize: 20,
          fontWeight: 600,
          color: C.text,
        }}
      >
        {title}
      </div>
    </div>
    {/* Column headers */}
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: '60px 1fr 140px 220px',
        padding: '10px 20px',
        background: C.windowChrome,
        borderBottom: `1px solid ${C.divider}`,
        fontFamily: FONT,
        fontSize: 18,
        color: C.textMeta,
        fontWeight: 600,
        gap: 20,
      }}
    >
      <span>Kind</span>
      <span>Name</span>
      <span>Size</span>
      <span>Date Modified</span>
    </div>
    <div style={{flex: 1, display: 'flex', flexDirection: 'column'}}>{children}</div>
  </div>
);

const Desktop: React.FC<{children: React.ReactNode}> = ({children}) => (
  <AbsoluteFill
    style={{
      background: `linear-gradient(135deg, ${C.wallpaper}, ${C.wallpaperDark})`,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
    }}
  >
    {children}
  </AbsoluteFill>
);

// Floating caption, white on a dark bar at the bottom — like TikTok captions.
const Caption: React.FC<{from: number; text: string}> = ({from, text}) => {
  const frame = useCurrentFrame() - from;
  const {fps} = useVideoConfig();
  const s = spring({frame, fps, config: {damping: 20, stiffness: 140, mass: 0.7}});
  const op = interpolate(s, [0, 1], [0, 1]);
  const y = interpolate(s, [0, 1], [14, 0]);
  return (
    <AbsoluteFill
      style={{display: 'flex', alignItems: 'flex-end', justifyContent: 'center', padding: '0 0 80px'}}
    >
      <div
        style={{
          opacity: op,
          transform: `translateY(${y}px)`,
          background: 'rgba(0,0,0,0.85)',
          color: '#fff',
          padding: '18px 36px',
          borderRadius: 14,
          fontFamily: FONT,
          fontSize: 36,
          fontWeight: 700,
          letterSpacing: 0.3,
        }}
      >
        {text}
      </div>
    </AbsoluteFill>
  );
};

// Magnum Opus mock-up — mimics the question/answer surface the real app has
const MoMock: React.FC = () => {
  const frame = useCurrentFrame();
  const askOp = interpolate(frame, [0, 14], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const ansOp = interpolate(frame, [30, 46], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const ansY = interpolate(frame, [30, 46], [20, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const chipOp = interpolate(frame, [52, 66], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <AbsoluteFill
      style={{
        background: c.paper,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 80,
        gap: 36,
      }}
    >
      <div
        style={{
          opacity: askOp,
          width: 1200,
          padding: '24px 32px',
          borderRadius: 20,
          background: '#fff',
          border: `1.5px solid ${c.line}`,
          display: 'flex',
          alignItems: 'center',
          gap: 18,
          fontFamily: FONT,
          fontSize: 34,
          fontWeight: 500,
          color: c.ink,
          boxShadow: '0 20px 50px rgba(15,22,38,0.08)',
        }}
      >
        <div style={{width: 14, height: 14, borderRadius: '50%', background: c.accentBright}} />
        which version has the arbitration clause?
      </div>
      <div
        style={{
          opacity: ansOp,
          transform: `translateY(${ansY}px)`,
          width: 1200,
          padding: '36px 40px',
          borderRadius: 24,
          background: '#fff',
          border: `1.5px solid ${c.line}`,
          fontFamily: FONT,
          fontSize: 38,
          fontWeight: 500,
          color: c.ink,
          lineHeight: 1.4,
          boxShadow: '0 30px 70px rgba(15,22,38,0.1)',
        }}
      >
        <span style={{color: c.accent, fontWeight: 700}}>Westfield_FINAL_signed.pdf</span>
        {' '}— §12, page 14.
        <div style={{marginTop: 20, opacity: chipOp}}>
          <span
            style={{
              display: 'inline-block',
              padding: '10px 22px',
              borderRadius: 999,
              background: c.accentWash,
              color: c.accent,
              fontSize: 24,
              fontWeight: 700,
              letterSpacing: 0.5,
            }}
          >
            Cited — Page 14
          </span>
        </div>
      </div>
    </AbsoluteFill>
  );
};

export const WhichOneIsIt: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Act 1 (0-4s): window opens, first files appear */}
      <Sequence from={0} durationInFrames={SEC(4)}>
        <Desktop>
          <WindowFrame>
            {FILES.slice(0, 4).map((f, i) => (
              <FileRowView key={f.name} from={SEC(0.6 + i * 0.4)} file={f} index={i} />
            ))}
          </WindowFrame>
        </Desktop>
        <Caption from={SEC(1.2)} text="which version is live?" />
      </Sequence>

      {/* Act 2 (4-9s): the hall of shame fills in */}
      <Sequence from={SEC(4)} durationInFrames={SEC(5)}>
        <Desktop>
          <WindowFrame>
            {FILES.slice(0, 10).map((f, i) => (
              <FileRowView
                key={f.name}
                from={i < 4 ? -100 : SEC(0.2 + (i - 4) * 0.35)}
                file={f}
                index={i}
              />
            ))}
          </WindowFrame>
        </Desktop>
        <Caption from={SEC(1.5)} text="they all say FINAL." />
      </Sequence>

      {/* Act 3 (9-12s): the cursor hovers, nothing clicked */}
      <Sequence from={SEC(9)} durationInFrames={SEC(3)}>
        <Desktop>
          <WindowFrame>
            {FILES.slice(0, 10).map((f, i) => (
              <FileRowView key={f.name} from={-100} file={f} index={i} />
            ))}
          </WindowFrame>
        </Desktop>
        <Caption from={SEC(0.3)} text="one has the arbitration clause." />
      </Sequence>

      {/* Act 4 (12-14s): a selection highlight — but the WRONG one */}
      <Sequence from={SEC(12)} durationInFrames={SEC(2)}>
        <Desktop>
          <WindowFrame>
            {FILES.slice(0, 10).map((f, i) => (
              <FileRowView
                key={f.name}
                from={-100}
                file={f}
                index={i}
                selected={i === 6}
              />
            ))}
          </WindowFrame>
        </Desktop>
        <Caption from={SEC(0.3)} text="not that one." />
      </Sequence>

      {/* Act 5 (14-18s): Magnum Opus — the actual answer */}
      <Sequence from={SEC(14)} durationInFrames={SEC(4)}>
        <MoMock />
      </Sequence>

      {/* Act 6 (18-20s): end lockup */}
      <Sequence from={SEC(18)} durationInFrames={SEC(2)}>
        <AbsoluteFill
          style={{
            background: c.paper,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 60,
          }}
        >
          <EndCard tagline='Stop guessing which "FINAL" is final.' />
        </AbsoluteFill>
      </Sequence>
    </AbsoluteFill>
  );
};
