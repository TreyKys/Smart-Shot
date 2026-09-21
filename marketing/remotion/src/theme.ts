import {continueRender, delayRender, staticFile} from 'remotion';

// ── Font: self-hosted Inter ──────────────────────────────────────────────
// Google Fonts is fetched over the network at render time, which fails in
// sandboxes where the render browser doesn't trust the egress proxy's CA
// (ERR_CERT_AUTHORITY_INVALID on fonts.gstatic.com). So Inter's woff2 files
// are bundled in public/fonts and registered with a local @font-face — no
// render-time network dependency, works anywhere. FontFace is loaded with a
// delayRender handle so frames don't render before the glyphs are ready.
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
        // document.fonts is a FontFaceSet; .add exists at runtime but the
        // DOM lib types it on the wrong interface in this TS version.
        (document.fonts as unknown as {add: (f: FontFace) => void}).add(loaded);
      });
    }),
  )
    .catch(() => {
      // Fall back silently to the system stack if anything fails — never
      // block the whole render on a font.
    })
    .finally(() => continueRender(handle));
}

// ── Palette ────────────────────────────────────────────────────────────────
// Editorial / light-first, adapted to Sift. The reference is warm cream +
// amber; this keeps that airy, high-whitespace feel but swaps in Sift's own
// cool neutrals and electric-blue accent (which doubles as a very "Google"
// blue), with the navy brand color reserved for full-bleed contrast beats.
export const c = {
  // Light canvas
  paper: '#F4F6FA',
  card: '#FFFFFF',
  chip: '#FFFFFF',
  line: '#E2E7F0',
  lineSoft: '#EDF1F7',

  // Ink (text on light)
  ink: '#0F1626',
  inkSoft: '#4C5A72',
  inkFaint: '#94A1B8',

  // Accent — the single highlight color
  accent: '#2F6FED',
  accentBright: '#4C8DFF',
  accentWash: '#E8EFFF',

  // Dark full-bleed beats (Sift's real brand navy)
  navy: '#0A0F1E',
  navyCard: '#141B2E',
  navyLine: '#243044',
  onNavy: '#F5F7FC',
  onNavySoft: '#8C9BB5',

  // Sparing warm emphasis
  gold: '#E8A33D',
  success: '#2ED573',
  danger: '#FF5A67',
};

export const FPS = 30;
export const SEC = (n: number) => Math.round(n * FPS);
