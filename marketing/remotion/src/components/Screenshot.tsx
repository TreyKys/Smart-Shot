import React from 'react';
import {theme} from '../theme';

/// A stylized "screenshot" — a colored rect with an optional icon and a
/// couple of text lines. Used everywhere the app shows a screenshot
/// thumbnail. Deliberately NOT a real image asset: keeps the ads self-
/// contained (no missing-file failures in someone else's clone) and lets
/// each ad tell its story with color/text without shipping actual user
/// screenshots.
export const Screenshot: React.FC<{
  hue?: string;
  label?: string;
  icon?: string;
  size?: number;
  dim?: boolean;
  tag?: string;
  tagColor?: string;
}> = ({
  hue = theme.surfaceElev,
  label,
  icon,
  size = 100,
  dim = false,
  tag,
  tagColor = theme.accent,
}) => {
  return (
    <div
      style={{
        width: size,
        height: size * 1.35,
        borderRadius: 14,
        background: `linear-gradient(160deg, ${hue}, ${darken(hue, 0.25)})`,
        border: `1px solid ${theme.border}`,
        boxShadow: '0 8px 20px rgba(0,0,0,0.35)',
        opacity: dim ? 0.45 : 1,
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        padding: 10,
        color: theme.textPrimary,
        fontSize: Math.max(10, size * 0.11),
        fontWeight: 600,
        position: 'relative',
      }}
    >
      {icon && (
        <div style={{fontSize: size * 0.35, lineHeight: 1}}>{icon}</div>
      )}
      {label && (
        <div style={{opacity: 0.9, lineHeight: 1.15}}>{label}</div>
      )}
      {tag && (
        <div
          style={{
            position: 'absolute',
            bottom: 8,
            right: 8,
            padding: '2px 8px',
            borderRadius: 999,
            background: `${tagColor}30`,
            color: tagColor,
            fontSize: Math.max(8, size * 0.08),
            fontWeight: 700,
            letterSpacing: 0.3,
          }}
        >
          {tag}
        </div>
      )}
    </div>
  );
};

// Rough HSL-agnostic darken by fading toward black by [amt] (0..1).
function darken(hex: string, amt: number) {
  const h = hex.replace('#', '');
  const r = parseInt(h.slice(0, 2), 16);
  const g = parseInt(h.slice(2, 4), 16);
  const b = parseInt(h.slice(4, 6), 16);
  const f = 1 - Math.max(0, Math.min(1, amt));
  const to = (v: number) =>
    Math.round(v * f)
      .toString(16)
      .padStart(2, '0');
  return `#${to(r)}${to(g)}${to(b)}`;
}
