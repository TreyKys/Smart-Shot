# Sift marketing — Remotion

Eight video ads as code, in a modern editorial style (big bold Inter
headlines, tiny letter-spaced eyebrows, clean cards, one blue accent, lots
of whitespace, navy full-bleed beats for contrast). Everything renders
locally to `out/*.mp4`.

- 5 × 20 s shorts — each one pain point
- 3 × 60 s films — Chaos Story + a second angle + the time-economics angle

All **16:9 (1920 × 1080)**, 30 fps, H.264 CRF 18.

## Setup

```bash
cd marketing/remotion
npm install --legacy-peer-deps
```

Fonts are **self-hosted** — Inter's woff2 files live in `public/fonts/` and
load via a local `@font-face` (see `src/theme.ts`). No render-time network
fetch, so it works behind restrictive proxies where Google Fonts fails.

## Preview / render

```bash
npm run dev            # live browser preview
npm run render:all     # all 8
npm run render:shorts  # the five 20s ads
npm run render:longs   # the three 60s films
```

Single: `npx remotion render <CompositionId> out/name.mp4`

## The 8 ads

| # | Composition ID      | Length | Angle                                            |
|---|---------------------|--------|--------------------------------------------------|
| 1 | `SearchFrustration` | 20 s   | "Where's that receipt?" → just ask                |
| 2 | `DuplicateTrap`     | 20 s   | "Just one more" → keep the best, lose the rest    |
| 3 | `JunkPile`          | 20 s   | The camera-roll basement → clear it in a break    |
| 4 | `MemoryLane`        | 20 s   | On this day → forgotten screenshots resurfaced    |
| 5 | `AskInPlainEnglish` | 20 s   | Talk to your gallery like a person                |
| 6 | `ChaosStory`        | 60 s   | A normal day → the pile → Sift answers (narrative)|
| 7 | `TheReliableOne`    | 60 s   | Everyone asks you → be the one who always has it  |
| 8 | `TimeRecovery`      | 60 s   | 4 hrs/month lost → Sift hands it back             |

6 and 7 are the two Chaos-Story angles: 6 is personal frustration, 7 is the
social "always be the reliable one" angle.

## Design system (`src/`)

- `theme.ts` — palette (`c.*`) + self-hosted Inter loader. Change colors in
  one place.
- `components/type.tsx` — `Eyebrow`, `Headline`, `Body`.
- `components/Chip.tsx` — the soft word-chips (filenames, junk types).
- `components/cards.tsx` — `Card`, `AskCard`, `ReceiptCard`, `ChatCard`,
  `Tile`. Real UI mocks, **no emoji** anywhere.
- `components/EndCard.tsx` — closing lockup: app icon, name, Google Play
  badge, maker credit.
- `components/Stage.tsx` — the light/dark canvas every beat sits on; also
  registers the fonts.
- `components/anim.ts` — fade/spring primitives.

**Timing convention:** `useCurrentFrame()` is Sequence-local, so every
`from={...}` passed to a child of a `<Sequence>` is relative to that
Sequence's start (0 = its first frame). Getting this wrong makes fades
silently never fire.

## Portrait / square cuts

These are 16:9 to match the reference. For 9:16 (Reels/Shorts) or 1:1, add
a second `Composition` per ad in `src/Root.tsx` with the same component and
the new size — the layouts key off the canvas, but the editorial split
beats (headline beside a card) are designed for landscape and would want
their flex direction switched for portrait.

## Voice-over

Ads render silent. Each long-form ad documents its intended narration cues
in a header comment, timed to the beats, so a VO recording lines up.
