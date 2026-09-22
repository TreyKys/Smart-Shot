# Magnum Opus marketing — Remotion

Three video ads for Magnum Opus, built in the same editorial system as
Sift's ads (`marketing/remotion/`): Inter, cool paper + navy contrast,
blue accent, big bold sentence-case headlines with tiny letter-spaced
eyebrows, real content cards — **no emoji, no gold gimmick**. Deliberately
similar (same design system across NeuroDev Labs' apps), not a re-run
of Magnum Opus's existing black+gold HTML ads.

Vertical 9:16 (1080 × 1920) to match Magnum Opus's existing ads
(`marketing/ad_v3_*/` in the Magnum-Opus repo).

## Setup

```bash
cd marketing/remotion-magnum-opus
npm install --legacy-peer-deps
```

Fonts are self-hosted in `public/fonts/` (same Inter woff2 files
Sift uses).

## Render

```bash
npm run dev            # live preview
npm run render:all     # all 3 ads → out/*.mp4
```

Or one at a time: `npx remotion render <CompositionId> out/name.mp4`

## The 3 ads

Each targets an angle the existing Magnum Opus ads
(`ad_v3_context`, `ad_v3_search`, `ad_v3_study`) do NOT cover:

| # | Composition ID       | Length | Angle                                              |
|---|----------------------|--------|----------------------------------------------------|
| 1 | `MeetingPanic`       | 20 s   | 20 min till the meeting, 62 pages, three questions |
| 2 | `CitedNotFabricated` | 20 s   | Generic AI hallucinated a page → Opus cites the real one |
| 3 | `StopReading`        | 20 s   | Every dense doc you kept — you don't have to reread them |

## Editing

- **Palette** — `src/theme.ts`. Deliberately identical to Sift's; change
  once, propagates everywhere. Change only if you want to fork it away.
- **Copy** — inline in each `src/ads/*.tsx`, next to the beat it belongs
  to. Header comment on each file names the pain-point the ad targets.
- **The differentiator** (cited answers) — the `CitedAnswer` component in
  `src/components/cards.tsx` produces the "answer + Page N chip" that
  Magnum Opus's own product surfaces. That's the visual echo that keeps
  the ads honest about what the app does.
- **Timing** — `SEC(n)` from `theme.ts` (30 fps × n). All `from={...}`
  passed into a `<Sequence>` child is Sequence-LOCAL (0 = the Sequence's
  first frame), not composition-absolute.
