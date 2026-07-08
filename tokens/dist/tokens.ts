// GENERATED. Do not edit by hand. Source: flare-im-design-tokens/tokens.json

export const flareDesignTokens = {
  "colors": {
    "bg": {
      "disabled": "#F2F3F5",
      "hover": "#EEF1F6",
      "primary": "#FFFFFF",
      "secondary": "#F5F6F8",
      "selected": "#F1EAFF",
      "tertiary": "#F2F3F5"
    },
    "border": {
      "hover": "#D7DBE3",
      "primary": "#E7E9EE",
      "secondary": "#EEF0F4",
      "selected": "#7C3AED"
    },
    "bubble": {
      "other": "#ECE5FF",
      "robot": "#F4F0FF",
      "self": "#7C3AED",
      "system": "#F2F3F5"
    },
    "error": "#EF4444",
    "important": "#F59E0B",
    "info": "#6D5DF6",
    "pinned": "#7C3AED",
    "primary": "#7C3AED",
    "primaryActive": "#5B21B6",
    "primaryHover": "#6D28D9",
    "robot": "#64748B",
    "success": "#22C55E",
    "text": {
      "disabled": "#C9CDD4",
      "link": "#7C3AED",
      "linkHover": "#6D28D9",
      "primary": "#111318",
      "secondary": "#6B7280",
      "tertiary": "#A3A7AE"
    },
    "warning": "#F59E0B"
  },
  "composer": {
    "attachMenuShadow": "0 4px 16px rgba(31, 35, 41, 0.12)",
    "expandedShadow": "0 8px 32px rgba(31, 35, 41, 0.12)",
    "surfaceShadow": "0 1px 2px rgba(31, 35, 41, 0.06)"
  },
  "dark": {
    "colors": {
      "bg": {
        "hover": "rgba(255, 255, 255, 0.06)",
        "primary": "#1A1D23",
        "secondary": "#111318",
        "selected": "rgba(124, 58, 237, 0.20)",
        "tertiary": "#22262E"
      },
      "border": {
        "primary": "rgba(255, 255, 255, 0.10)",
        "secondary": "rgba(255, 255, 255, 0.08)",
        "selected": "#A78BFA"
      },
      "bubble": {
        "other": "#241D33",
        "robot": "#2B2340",
        "self": "#8B5CF6"
      },
      "text": {
        "link": "#C4B5FD",
        "primary": "rgba(255, 255, 255, 0.94)",
        "secondary": "rgba(255, 255, 255, 0.62)",
        "tertiary": "rgba(255, 255, 255, 0.4)"
      }
    },
    "composer": {
      "attachMenuShadow": "0 4px 16px rgba(0, 0, 0, 0.35)",
      "expandedShadow": "0 8px 32px rgba(0, 0, 0, 0.35)",
      "surfaceShadow": "0 1px 2px rgba(0, 0, 0, 0.2)"
    }
  },
  "shadows": {
    "lg": "0 18px 48px rgba(17, 19, 24, 0.18)",
    "md": "0 6px 18px rgba(17, 19, 24, 0.10)",
    "none": "none",
    "sm": "0 1px 2px rgba(17, 19, 24, 0.06)",
    "xl": "0 24px 64px rgba(17, 19, 24, 0.22)"
  },
  "sizes": {
    "fontSize": {
      "2xl": "16px",
      "3xl": "18px",
      "4xl": "20px",
      "lg": "14px",
      "md": "13px",
      "sm": "12px",
      "xl": "15px",
      "xs": "11px"
    },
    "layout": {
      "avatarSize": "42px",
      "headerHeight": "60px",
      "leftPanel": "260px",
      "rightPanel": "300px",
      "sessionItemHeight": "68px"
    },
    "lineHeight": {
      "normal": "1.5",
      "relaxed": "1.6",
      "tight": "1.2"
    },
    "radius": {
      "lg": "8px",
      "md": "6px",
      "sm": "4px",
      "xl": "12px",
      "xs": "2px"
    },
    "spacing": {
      "2xl": "24px",
      "lg": "16px",
      "md": "12px",
      "sm": "8px",
      "xl": "20px",
      "xs": "4px"
    }
  },
  "transitions": {
    "fast": "140ms ease",
    "normal": "180ms ease",
    "slow": "220ms ease"
  }
} as const;

export type FlareDesignTokens = typeof flareDesignTokens;
