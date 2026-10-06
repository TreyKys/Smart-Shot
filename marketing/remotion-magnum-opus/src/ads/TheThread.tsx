import React from 'react';
import {AbsoluteFill, Sequence, interpolate, useCurrentFrame} from 'remotion';
import {SEC, FONT, c} from '../theme';
import {EndCard} from '../components/EndCard';

// ─────────────────────────────────────────────────────────────────────────
// AD 7 · "The Thread" · 25s · 16:9
// Deliberately breaks the editorial house style. The whole ad is a fake
// Gmail web interface — a lease-renewal thread 11 replies deep, with one
// critical rate buried in a quoted-reply block. Universal pain for anyone
// with a job + a landlord. Only in the last 5 seconds does Magnum Opus
// appear.
// ─────────────────────────────────────────────────────────────────────────

const C = {
  bg: '#F6F8FC',
  shell: '#FFFFFF',
  sidebar: '#F1F3F4',
  topBar: '#FFFFFF',
  headerShadow: 'rgba(0,0,0,0.06)',
  sender: '#202124',
  subject: '#202124',
  bodyText: '#3C4043',
  meta: '#5F6368',
  divider: '#DADCE0',
  quoteBorder: '#DADCE0',
  quoteBg: '#F8F9FA',
  starred: '#F4B400',
  unread: '#1A73E8',
  attach: '#1A73E8',
  red: '#D93025',
};

type Reply = {
  from: string;
  time: string;
  body: React.ReactNode;
  isNested?: boolean;
};

const REPLIES: Reply[] = [
  {
    from: 'Lauren Parker (property mgmt)',
    time: 'May 14, 11:04 AM',
    body: (
      <>
        Hi — attached is the renewal paperwork. The new monthly rate is{' '}
        <span style={{background: '#FFF59D'}}>$3,200 starting Jun 1</span>. Let me know by
        the 25th.
      </>
    ),
  },
  {
    from: 'You',
    time: 'May 16, 9:21 AM',
    body: <>Thanks — reviewing with Alex. Will circle back.</>,
  },
  {
    from: 'Alex (co-tenant)',
    time: 'May 18, 7:48 PM',
    body: <>are we actually renewing lol</>,
  },
  {
    from: 'You',
    time: 'May 20, 10:12 AM',
    body: <>I think so. Lauren can you re-send the rate?</>,
  },
  {
    from: 'Lauren Parker',
    time: 'May 20, 3:33 PM',
    body: <>Rate is in the first email. Let me know by Thursday please.</>,
  },
  {
    from: 'Alex',
    time: 'May 21, 8:11 AM',
    body: <>wait what was it</>,
  },
];

const StatusBar: React.FC = () => (
  <div
    style={{
      background: C.topBar,
      padding: '14px 32px',
      display: 'flex',
      alignItems: 'center',
      gap: 24,
      borderBottom: `1px solid ${C.divider}`,
      fontFamily: FONT,
    }}
  >
    <div
      style={{
        width: 44,
        height: 44,
        borderRadius: 8,
        background: '#EA4335',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: '#fff',
        fontWeight: 800,
        fontSize: 22,
      }}
    >
      M
    </div>
    <div style={{fontSize: 22, color: C.sender, fontWeight: 500}}>Gmail</div>
    <div
      style={{
        flex: 1,
        background: '#EAF1FB',
        borderRadius: 999,
        padding: '12px 24px',
        fontSize: 20,
        color: C.meta,
      }}
    >
      Search mail
    </div>
    <div
      style={{
        width: 40,
        height: 40,
        borderRadius: '50%',
        background: '#1A73E8',
        color: '#fff',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontWeight: 700,
        fontSize: 18,
      }}
    >
      Y
    </div>
  </div>
);

const Shell: React.FC<{children: React.ReactNode}> = ({children}) => (
  <AbsoluteFill style={{background: C.bg}}>
    <div
      style={{
        margin: '40px 60px',
        height: 'calc(100% - 80px)',
        background: C.shell,
        borderRadius: 14,
        overflow: 'hidden',
        display: 'flex',
        flexDirection: 'column',
        boxShadow: '0 20px 60px rgba(0,0,0,0.08)',
      }}
    >
      <StatusBar />
      {children}
    </div>
  </AbsoluteFill>
);

const SubjectHeader: React.FC<{title: string; count: number}> = ({title, count}) => (
  <div
    style={{
      padding: '28px 44px 20px',
      borderBottom: `1px solid ${C.divider}`,
      fontFamily: FONT,
    }}
  >
    <div style={{fontSize: 36, fontWeight: 500, color: C.subject, lineHeight: 1.25}}>
      {title}{' '}
      <span style={{color: C.meta, fontWeight: 400}}>(Inbox)</span>
    </div>
    <div style={{marginTop: 10, fontSize: 20, color: C.meta}}>{count} messages</div>
  </div>
);

const ReplyBlock: React.FC<{from: number; reply: Reply; depth?: number}> = ({
  from,
  reply,
  depth = 0,
}) => {
  const frame = useCurrentFrame() - from;
  const op = interpolate(frame, [0, 10], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const y = interpolate(frame, [0, 10], [10, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const isYou = reply.from.startsWith('You');
  return (
    <div
      style={{
        opacity: op,
        transform: `translateY(${y}px)`,
        marginLeft: depth * 24,
        padding: '16px 20px',
        borderLeft: depth > 0 ? `3px solid ${C.quoteBorder}` : 'none',
        background: depth > 0 ? C.quoteBg : 'transparent',
        borderRadius: depth === 0 ? 10 : 0,
        marginBottom: 10,
        fontFamily: FONT,
      }}
    >
      <div style={{display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6}}>
        <div
          style={{
            width: 32,
            height: 32,
            borderRadius: '50%',
            background: isYou ? '#1A73E8' : '#9AA0A6',
            color: '#fff',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: 15,
            fontWeight: 700,
          }}
        >
          {reply.from.charAt(0)}
        </div>
        <div style={{fontSize: 20, fontWeight: 700, color: C.sender}}>{reply.from}</div>
        <div style={{fontSize: 18, color: C.meta, marginLeft: 'auto'}}>{reply.time}</div>
      </div>
      <div style={{fontSize: 22, color: C.bodyText, lineHeight: 1.4, marginLeft: 42}}>
        {reply.body}
      </div>
    </div>
  );
};

const MoMock: React.FC = () => {
  const frame = useCurrentFrame();
  const askOp = interpolate(frame, [0, 16], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const ansOp = interpolate(frame, [36, 54], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const ansY = interpolate(frame, [36, 54], [20, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const chipOp = interpolate(frame, [62, 76], [0, 1], {
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
        gap: 32,
      }}
    >
      <div
        style={{
          opacity: askOp,
          width: 1200,
          padding: '26px 34px',
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
        what's the new monthly rate and when does it start?
      </div>
      <div
        style={{
          opacity: ansOp,
          transform: `translateY(${ansY}px)`,
          width: 1200,
          padding: '38px 42px',
          borderRadius: 24,
          background: '#fff',
          border: `1.5px solid ${c.line}`,
          fontFamily: FONT,
          fontSize: 40,
          fontWeight: 500,
          color: c.ink,
          lineHeight: 1.4,
          boxShadow: '0 30px 70px rgba(15,22,38,0.1)',
        }}
      >
        <span style={{color: c.accent, fontWeight: 700}}>$3,200/mo</span>, starting{' '}
        <span style={{color: c.accent, fontWeight: 700}}>Jun 1</span>.
        <div style={{marginTop: 20, opacity: chipOp}}>
          <span
            style={{
              display: 'inline-block',
              padding: '10px 22px',
              borderRadius: 999,
              background: c.accentWash,
              color: c.accent,
              fontSize: 22,
              fontWeight: 700,
              letterSpacing: 0.5,
            }}
          >
            Cited — Lauren Parker, May 14
          </span>
        </div>
      </div>
    </AbsoluteFill>
  );
};

export const TheThread: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Act 1 (0-3s): inbox-style thread opens */}
      <Sequence from={0} durationInFrames={SEC(3)}>
        <Shell>
          <SubjectHeader title="Re: Re: Fwd: Re: Re: Lease renewal — ACTION REQUIRED" count={11} />
        </Shell>
      </Sequence>

      {/* Act 2 (3-10s): the thread fills in, depth increasing */}
      <Sequence from={SEC(3)} durationInFrames={SEC(7)}>
        <Shell>
          <SubjectHeader title="Re: Re: Fwd: Re: Re: Lease renewal — ACTION REQUIRED" count={11} />
          <div
            style={{
              flex: 1,
              padding: '20px 40px',
              overflow: 'hidden',
              display: 'flex',
              flexDirection: 'column',
            }}
          >
            {REPLIES.map((r, i) => (
              <ReplyBlock
                key={i}
                from={SEC(0.3 + i * 0.9)}
                reply={r}
                depth={Math.min(i, 4)}
              />
            ))}
          </div>
        </Shell>
      </Sequence>

      {/* Act 3 (10-14s): hold on the full thread — no fake search bar,
          no overlay. The nested "wait what was it" ending and Lauren's
          "rate is in the first email" already carry the "nobody can find
          anything" story on their own */}
      <Sequence from={SEC(10)} durationInFrames={SEC(4)}>
        <Shell>
          <SubjectHeader title="Re: Re: Fwd: Re: Re: Lease renewal — ACTION REQUIRED" count={11} />
          <div
            style={{
              flex: 1,
              padding: '20px 40px',
              overflow: 'hidden',
              display: 'flex',
              flexDirection: 'column',
            }}
          >
            {REPLIES.map((r, i) => (
              <ReplyBlock key={i} from={-100} reply={r} depth={Math.min(i, 4)} />
            ))}
          </div>
        </Shell>
      </Sequence>

      {/* Act 4 (14-23s): Magnum Opus — ask the thread */}
      <Sequence from={SEC(14)} durationInFrames={SEC(9)}>
        <MoMock />
      </Sequence>

      {/* Act 5 (23-25s): end lockup */}
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
          <EndCard tagline="Stop scrolling the thread. Ask it." />
        </AbsoluteFill>
      </Sequence>
    </AbsoluteFill>
  );
};
