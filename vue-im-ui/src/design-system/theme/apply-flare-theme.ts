import { generateCSSVariables, imTheme } from "./im-theme";

const STYLE_ID = "flare-im-theme-vars";

/** Web 示例额外语义变量（与历史 `--im-*` 类名兼容，并映射 Flutter `FlareThemeTokens` 用法） */
export function generateWebAppThemeExtensions(isDark = false): string {
  const colors = isDark ? { ...imTheme.colors, ...imTheme.dark.colors } : imTheme.colors;

  return `
:root {
  color-scheme: ${isDark ? "dark" : "light"};
  --im-font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display",
    "PingFang SC", "Microsoft YaHei", "Noto Sans CJK SC", "Inter", "Segoe UI", Arial, sans-serif;
  --im-brand-primary: var(--flare-color-primary, #7C3AED);
  --im-brand-primary-soft: ${isDark ? "rgba(124, 58, 237, 0.24)" : "var(--flare-color-bg-selected, #F1EAFF)"};
  --im-gradient-start: var(--flare-color-primary, #7c3aed);
  --im-gradient-end: var(--flare-color-info, #6366f1);
  --im-primary-soft: var(--im-brand-primary-soft);
  --im-message-outgoing: ${isDark ? colors.bubble.self : `var(--flare-color-bubble-self, ${colors.bubble.self})`};
  --im-message-outgoing-text: #ffffff;
  // Received bubble = white card (Flare thread grammar), aligned with the
  // native packages + reference app. The bubble CSS already supplies the
  // hairline border + soft shadow; the fill follows the surface for dark mode.
  --im-message-incoming: ${colors.bg.primary};
  --im-message-incoming-text: ${colors.text.primary};
  --im-message-pinned-bg: ${isDark ? "rgba(245, 158, 11, 0.14)" : "#FFF7DE"};
  --im-message-pinned-border: ${isDark ? "rgba(245, 158, 11, 0.34)" : "#F2C94C"};
  --im-message-pinned-text: ${isDark ? "#FFE8A3" : "#8A5A00"};
  --im-presence-online: var(--flare-color-success, ${colors.success});
  --im-composer-bar-bg: ${isDark ? "#1a1d23" : "#eef1f6"};
  --im-composer-desktop-height: 46px;
  --im-composer-mobile-min-height: 96px;
  --im-conv-unread-ring: ${isDark ? "#1a1d23" : "#ffffff"};
  --im-bubble-radius: 13px;
  --im-bubble-radius-tail: 6px;
  --im-bubble-max-width: 68%;
  --im-workbench-rail-width: 56px;
  --im-workbench-conversation-width: clamp(300px, 24vw, 360px);
  --im-workbench-details-width: 320px;
  --im-workbench-tablet-conversation-width: clamp(286px, 42vw, 340px);
  --im-radius-md: var(--radius-md);
  --im-radius-lg: var(--radius-lg);
  --im-radius-pill: 999px;
  --im-shadow-panel: var(--shadow-sm);
  --im-shadow-floating: var(--shadow-md);
  --im-motion-fast: var(--transition-fast);
  --im-motion-normal: var(--transition-normal);
  --im-conversation-row-height: var(--layout-session);
  --wechat-status-sent: ${isDark ? "rgba(255, 255, 255, 0.55)" : "#888888"};
  --wechat-status-read: #07c160;
  --im-bubble-on-sent-muted: rgba(255, 255, 255, 0.66);
  font-family: var(--im-font-family);
  color: var(--im-text-primary);
  background: var(--im-bg-app);
}
`.trim();
}

export function buildFlareThemeStylesheet(
  isDark = false,
  variant: "default" | "compact" | "callDark" | "highContrast" = "default",
): string {
  const variantBlock = variant === "compact"
    ? `:root { --layout-session: 56px; --layout-header: 52px; --font-sm: 11px; --font-md: 12px; --font-lg: 13px; }`
    : variant === "highContrast"
      ? `:root { --border-primary: ${isDark ? "#FFFFFF" : "#111318"}; --text-primary: ${isDark ? "#FFFFFF" : "#000000"}; --primary: ${isDark ? "#C4B5FD" : "#5B21B6"}; }`
      : variant === "callDark"
        ? `:root { --im-chat-window-bg: #0B1018; --bg-secondary: #0E131B; --bg-primary: #121821; }`
        : "";
  return `${generateCSSVariables(imTheme, isDark)}\n${generateWebAppThemeExtensions(isDark)}\n${variantBlock}`;
}

/** 将主题 CSS 变量注入 document（与 Tauri `applyFeishuThemeVars` / Flutter ThemeData 同级） */
export function applyFlareTheme(isDark = false, variant: "default" | "compact" | "callDark" | "highContrast" = "default"): void {
  if (typeof document === "undefined") return;
  let el = document.getElementById(STYLE_ID) as HTMLStyleElement | null;
  if (!el) {
    el = document.createElement("style");
    el.id = STYLE_ID;
    document.head.appendChild(el);
  }
  el.textContent = buildFlareThemeStylesheet(isDark, variant);
  document.documentElement.dataset.theme = isDark ? "dark" : "light";
  document.documentElement.dataset.themeVariant = variant;
}

export function isSystemDarkPreferred(): boolean {
  if (typeof window === "undefined" || !window.matchMedia) return false;
  return window.matchMedia("(prefers-color-scheme: dark)").matches;
}

export function watchPreferredColorScheme(onChange: (dark: boolean) => void): () => void {
  if (typeof window === "undefined" || !window.matchMedia) {
    return () => {};
  }
  const mq = window.matchMedia("(prefers-color-scheme: dark)");
  const handler = () => onChange(mq.matches);
  mq.addEventListener("change", handler);
  return () => mq.removeEventListener("change", handler);
}
