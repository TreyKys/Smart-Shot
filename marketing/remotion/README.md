# Sift marketing — Remotion

Seven video ads as code. Everything renders locally to `out/*.mp4`; no
uploads, no cloud, no accounts required.

- 5 × 20 s shorts — each targets one pain point
- 2 × 60 s films — same product, two angles

All vertical (1080 × 1920), 30 fps, H.264 CRF 18. Vertical is the shared
format for Reels/Shorts/TikTok/Play Store trailers — any surface that
takes 16:9 also takes a centred 9:16.

## First-time setup

```bash
cd marketing/remotion
npm install
```

Remotion pulls in a headless Chromium the first time. If the download
stalls behind a proxy, set `PUPPETEER_DOWNLOAD_BASE_URL` before install.

## Preview

Live-editing browser preview — pick a composition from the sidebar and
scrub:

```bash
npm run dev
```

## Render

```bash
npm run render:all       # all 7
npm run render:shorts    # just the five 20-second ads
npm run render:longs     # just the two 60-second films
```

Or one at a time:

```bash
npx remotion render SearchFrustration out/01-search-frustration.mp4
```

Rendered files land in `out/` (gitignored). A ~20-second clip on a
modern laptop takes ~1 minute; the 60-second films take ~3 minutes each.

## The 7 ads

| # | Composition ID       | Length | Pain point                                              |
|---|----------------------|--------|---------------------------------------------------------|
| 1 | `SearchFrustration`  | 20 s   | "Where's that receipt?" scrolling through 3,000 shots    |
| 2 | `DuplicateTrap`      | 20 s   | Five near-identical takes eating storage                 |
| 3 | `JunkPile`           | 20 s   | Years of dead memes / expired coupons / old URLs        |
| 4 | `MemoryLane`         | 20 s   | Forgotten screenshots from years past                    |
| 5 | `AskInPlainEnglish`  | 20 s   | The AI chat — no folders, no filters                     |
| 6 | `ChaosStory`         | 60 s   | Everyday narrative angle                                 |
| 7 | `TimeRecovery`       | 60 s   | Hours-per-month economics angle                          |

## Editing

- **Colors** — `src/theme.ts` (mirrored from the app's `SiftColors`).
  Change once, propagates through every ad.
- **Copy** — each ad's `.tsx` file has the text inline near the beat it
  belongs to. Comments at the top document the intended narration cue
  per beat, so a voice-over recording can time to the same beats.
- **Timing** — `SEC(n)` (from `theme.ts`) is the "seconds → frames"
  helper. Every timing in every ad reads in seconds.
- **New ad** — copy any file in `src/ads/`, register it in
  `src/Root.tsx` with a new `Composition` id, add a render entry in
  `package.json`'s `render:all`. That's all three touch points.

## Voice-over

Every ad renders silently — Remotion supports audio via `<Audio>` in a
composition, but shipping the ads muted means anyone can drop in their
own VO or music without re-rendering visuals. If you generate narration
with a TTS service, place the audio next to the composition file and
add an `<Audio src={staticFile('...')} />` inside the outer
`<AbsoluteFill>`. See the top-of-file comments in
`ChaosStory.tsx` for the intended narration cues per beat.
