// Brand palette pulled from the app's SiftColors (lib/core/theme/app_theme.dart)
// — same navy background and electric-blue accent that ship in every actual
// screen of the app, so an ad and the app read as one product.

export const theme = {
  // Structural (dark side of SiftColors)
  bg: '#0A0F1E',
  surface: '#111827',
  surfaceElev: '#1A2436',
  border: '#243044',

  // Brand
  accent: '#4C8DFF',
  accentDim: '#2F6FED',
  proGold: '#FFD700',
  proGoldWarm: '#FFA500',

  // Text
  textPrimary: '#F5F7FC',
  textSecondary: '#8C9BB5',
  textTertiary: '#4E5C74',

  // Semantic
  danger: '#FF4757',
  warning: '#FFA502',
  success: '#2ED573',

  // Tag palette (matches SiftColors.forTag)
  tag: {
    finance: '#2ED573',
    memes: '#AE6EFD',
    junk: '#FF4757',
    todo: '#FFA502',
    travel: '#4C8DFF',
    web3: '#FF6B81',
    code: '#38BDF8',
    social: '#FC5C7D',
    default: '#8C9BB5',
  },
};

export const fonts = {
  // System-first stack — no webfont fetch means the render doesn't stall
  // waiting on a network request, and this is what the app ships with too.
  ui: `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif`,
  mono: `ui-monospace, "SF Mono", Menlo, Consolas, monospace`,
};

// One canonical set of durations so a "beat" reads the same across ads.
// Frame math throughout assumes 30fps — see Root.tsx.
export const FPS = 30;
export const SEC = (n: number) => Math.round(n * FPS);
