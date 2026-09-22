import {continueRender, delayRender, staticFile} from 'remotion';

// Same self-hosted Inter setup Sift uses — see marketing/remotion/src/theme.ts
// for the full rationale (Google Fonts fetches fail behind the render sandbox's
// proxy CA). Files bundled in public/fonts, loaded via local @font-face with a
// delayRender guard so the first frame doesn't paint before glyphs land.
export const FONT = 'Inter';

let fontsLoaded = false;
export function ensureFonts() {
  if (fontsLoaded || typeof document === 'undefined') return;
  fontsLoaded = true;
  const weights = [400, 500, 600, 700, 800];
  const handle = delayRender('Loading Inter');
  Promise.all(
    weights.map((w) => {
      const face = new FontFace(
        'Inter',
        `url(${staticFile(`fonts/inter-${w}.woff2`)}) format('woff2')`,
        {weight: String(w), style: 'normal', display: 'swap'},
      );
      return face.load().then((loaded) => {
        (document.fonts as unknown as {add: (f: FontFace) => void}).add(loaded);
      });
    }),
  )
    .catch(() => {})
    .finally(() => continueRender(handle));
}

// ── Palette ──────────────────────────────────────────────────────────────
// Deliberately the SAME editorial palette Sift's ads use — the client asked
// for "similar" (not "distinct brand"), and reusing the palette signals that
// both apps come out of the same studio. Only the copy, the card content,
// and the end lockup differ.
export const c = {
  paper: '#F4F6FA',
  card: '#FFFFFF',
  chip: '#FFFFFF',
  line: '#E2E7F0',
  lineSoft: '#EDF1F7',

  ink: '#0F1626',
  inkSoft: '#4C5A72',
  inkFaint: '#94A1B8',

  accent: '#2F6FED',
  accentBright: '#4C8DFF',
  accentWash: '#E8EFFF',

  navy: '#0A0F1E',
  navyCard: '#141B2E',
  navyLine: '#243044',
  onNavy: '#F5F7FC',
  onNavySoft: '#8C9BB5',

  success: '#2ED573',
  danger: '#FF5A67',
};

export const FPS = 30;
export const SEC = (n: number) => Math.round(n * FPS);
