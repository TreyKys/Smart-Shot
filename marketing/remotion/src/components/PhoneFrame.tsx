import {theme} from '../theme';
import React from 'react';

/// A minimal, credible phone frame — deliberately not a photorealistic
/// device render (which dates fast the moment Apple/Samsung release a new
/// shape); a plain rounded rect with a status bar reads as "phone" without
/// making the ad look like it was made for last year's hardware.
export const PhoneFrame: React.FC<{
  children: React.ReactNode;
  width?: number;
  showStatusBar?: boolean;
  scale?: number;
}> = ({children, width = 380, showStatusBar = true, scale = 1}) => {
  const height = Math.round(width * (19.5 / 9)); // 19.5:9 tall aspect
  return (
    <div
      style={{
        width,
        height,
        transform: `scale(${scale})`,
        borderRadius: 44,
        background: '#000',
        padding: 8,
        boxShadow:
          '0 30px 60px rgba(0,0,0,0.55), 0 6px 20px rgba(0,0,0,0.35)',
        border: `1px solid ${theme.border}`,
      }}
    >
      <div
        style={{
          width: '100%',
          height: '100%',
          borderRadius: 36,
          overflow: 'hidden',
          background: theme.bg,
          position: 'relative',
        }}
      >
        {showStatusBar && (
          <div
            style={{
              height: 32,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: '0 24px',
              color: theme.textPrimary,
              fontSize: 13,
              fontWeight: 600,
              fontVariantNumeric: 'tabular-nums',
            }}
          >
            <span>9:41</span>
            <span style={{fontSize: 11, color: theme.textSecondary}}>●●●● 5G</span>
          </div>
        )}
        <div style={{width: '100%', height: showStatusBar ? 'calc(100% - 32px)' : '100%'}}>
          {children}
        </div>
      </div>
    </div>
  );
};
