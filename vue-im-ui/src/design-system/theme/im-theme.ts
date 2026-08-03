import type { GlobalThemeOverrides } from "naive-ui";
import { flareDesignTokens } from "@flare-im/tokens";

export const imTheme = flareDesignTokens;

function mergeComposerShadows(theme: typeof imTheme, isDark: boolean) {
  const base = { ...theme.composer };
  if (isDark && theme.dark.composer) {
    Object.assign(base, theme.dark.composer);
  }
  return base;
}

/** Composer 语义色与全局 `--*` 对齐；阴影仍可按明暗单独调。 */
function composerVariablesBlock(theme: typeof imTheme, isDark: boolean): string {
  const s = mergeComposerShadows(theme, isDark);
  const lines: [string, string][] = [
    ["surface-bg", "var(--bg-primary)"],
    ["surface-border", "var(--border-primary)"],
    ["surface-radius", "var(--radius-lg)"],
    ["surface-radius-compact", "var(--radius-md)"],
    ["surface-shadow", s.surfaceShadow],
    ["dock-bg", "var(--bg-secondary)"],
    ["expanded-shadow", s.expandedShadow],
    ["text-primary", "var(--text-primary)"],
    ["text-placeholder", "var(--text-tertiary)"],
    ["text-hint", "var(--text-secondary)"],
    ["title-placeholder", "var(--text-tertiary)"],
    ["icon-default", "var(--text-secondary)"],
    ["icon-hover-bg", "var(--bg-hover)"],
    ["icon-hover-color", "var(--text-link)"],
    ["icon-active-bg", "var(--bg-selected)"],
    ["icon-active-color", "var(--primary)"],
    ["border-subtle", "var(--border-secondary)"],
    ["caret-color", "var(--primary)"],
    ["send-primary", "var(--primary)"],
    ["send-hover", "var(--primary-hover)"],
    ["send-pressed", "var(--primary-active)"],
    ["fmt-hover-bg", "var(--bg-hover)"],
    ["fmt-hover-color", "var(--text-link)"],
    /** 富文本格式条：按钮「开启/选中」态，与 imTheme.colors.primary / bg.selected 一致 */
    ["format-active-color", "var(--primary)"],
    ["format-active-bg", "var(--bg-selected)"],
    ["emoji-cell-hover-bg", "var(--bg-secondary)"],
    ["emoji-panel-bg", "var(--bg-primary)"],
    ["emoji-section-muted", "var(--text-tertiary)"],
    ["emoji-tabbar-bg", "var(--bg-secondary)"],
    ["emoji-tabbar-border", "var(--border-secondary)"],
    ["emoji-tab-active-bg", "var(--bg-primary)"],
    [
      "emoji-panel-shadow",
      "0 8px 32px rgba(0, 0, 0, 0.18)",
    ],
    ["attach-menu-bg", "var(--bg-primary)"],
    ["attach-menu-border", "var(--border-primary)"],
    ["attach-menu-radius", "var(--radius-lg)"],
    ["attach-menu-shadow", s.attachMenuShadow],
    ["attach-item-hover-bg", "var(--bg-hover)"],
    ["attach-item-text", "var(--text-primary)"],
    ["attach-item-icon", "var(--text-secondary)"],
  ];
  return lines.map(([k, v]) => `      --composer-${k}: ${v};`).join("\n");
}

// CSS 变量生成；`isDark` 同时影响全局语义色与 composer 令牌（由 main 随系统主题切换）
export function generateCSSVariables(theme: typeof imTheme, isDark = false) {
  const colors = isDark ? { ...theme.colors, ...theme.dark.colors } : theme.colors;

  return `
    :root {
      /* 主色调 */
      --primary: ${colors.primary};
      --primary-hover: ${colors.primaryHover};
      --primary-active: ${colors.primaryActive};

      /* 语义色 */
      --success: ${colors.success};
      --warning: ${colors.warning};
      --error: ${colors.error};
      --info: ${colors.info};

      /* 特殊角色色 */
      --robot: ${colors.robot};
      --important: ${colors.important};
      --pinned: ${colors.pinned};

      /* 背景色 */
      --bg-primary: ${colors.bg.primary};
      --bg-secondary: ${colors.bg.secondary};
      --bg-tertiary: ${colors.bg.tertiary};
      --bg-hover: ${colors.bg.hover};
      --bg-selected: ${colors.bg.selected};

      /* 文字色 */
      --text-primary: ${colors.text.primary};
      --text-secondary: ${colors.text.secondary};
      --text-tertiary: ${colors.text.tertiary};
      --text-link: ${colors.text.link};

      /* 边框色 */
      --border-primary: ${colors.border.primary};
      --border-secondary: ${colors.border.secondary};
      --border-selected: ${colors.border.selected};

      /* 消息气泡色 */
      --bubble-self: ${colors.bubble.self};
      --bubble-other: ${colors.bubble.other};
      --bubble-robot: ${colors.bubble.robot};

      /* 与 shared-im-ui 令牌对齐 */
      --im-bubble-received: ${colors.bubble.other};
      --im-bubble-sent: ${colors.bubble.self};
      --im-bubble-text: ${colors.text.primary};
      --im-bubble-received-text: ${colors.text.primary};
      --im-bubble-sent-text: #FFFFFF;
      --im-bubble-time: ${isDark ? "rgba(255,255,255,0.48)" : "rgba(17,19,24,0.46)"};
      --im-bubble-shadow: ${isDark ? "0 4px 14px rgba(0, 0, 0, 0.14)" : "0 1px 2px rgba(17, 19, 24, 0.06)"};
      --im-bubble-min-width: 38px;
      --im-bubble-padding-y: 7px;
      --im-bubble-padding-x: 12px;
      --im-bubble-attachment-padding: 8px;
      --im-bubble-link: ${isDark ? "#C4B5FD" : "#6D28D9"};
      --im-bubble-sent-link: #F5F0FF;
      --im-bubble-raised: ${isDark ? "#202A36" : "#F7F8FB"};
      --im-bubble-raised-hover: ${isDark ? "#253140" : "#F2F5FA"};
      --im-bubble-code-bg: ${isDark ? "rgba(255, 255, 255, 0.10)" : "rgba(17, 19, 24, 0.06)"};
      --im-bubble-code-border: ${isDark ? "rgba(255, 255, 255, 0.10)" : "rgba(17, 19, 24, 0.08)"};
      --im-bubble-code-text: ${colors.text.primary};
      --im-bubble-quote-bg: ${isDark ? "rgba(139, 92, 246, 0.18)" : "rgba(124, 58, 237, 0.08)"};
      --im-bubble-quote-border: ${isDark ? "rgba(196, 181, 253, 0.48)" : "rgba(124, 58, 237, 0.38)"};
      --im-bubble-quote-text: ${isDark ? "rgba(255, 255, 255, 0.68)" : "rgba(17, 19, 24, 0.66)"};
      --im-bubble-quote-sender: ${isDark ? "#C4B5FD" : "#6D28D9"};
      --im-bubble-on-sent-subtle: rgba(255, 255, 255, 0.14);
      --im-bubble-on-sent-strong: rgba(255, 255, 255, 0.22);
      --im-bubble-on-sent-border: rgba(255, 255, 255, 0.24);
      --im-bubble-on-sent-muted: rgba(255, 255, 255, 0.72);
      --im-bubble-on-sent-soft-text: rgba(255, 255, 255, 0.90);
      --im-reaction-bg: ${isDark ? "rgba(255, 255, 255, 0.07)" : "rgba(17, 19, 24, 0.04)"};
      --im-reaction-border: ${isDark ? "rgba(255, 255, 255, 0.09)" : "rgba(17, 19, 24, 0.06)"};
      --im-reaction-hover: ${isDark ? "rgba(255, 255, 255, 0.11)" : "rgba(17, 19, 24, 0.08)"};
      --im-reaction-active-bg: ${isDark ? "rgba(139, 92, 246, 0.20)" : "rgba(124, 58, 237, 0.12)"};
      --im-reaction-active-border: ${isDark ? "rgba(196, 181, 253, 0.38)" : "rgba(124, 58, 237, 0.30)"};
      --im-reaction-users: ${isDark ? "rgba(255, 255, 255, 0.66)" : "#5F6775"};
      --im-reaction-count: ${isDark ? "rgba(255, 255, 255, 0.48)" : "#8B919D"};
      --im-file-icon-bg: ${isDark ? "rgba(139, 92, 246, 0.18)" : "rgba(124, 58, 237, 0.10)"};
      --im-file-icon-border: ${isDark ? "rgba(196, 181, 253, 0.28)" : "rgba(124, 58, 237, 0.18)"};
      --im-file-icon-color: ${isDark ? "#C4B5FD" : colors.primary};
      --im-menu-bg: ${colors.bg.primary};
      --im-menu-border: ${colors.border.primary};
      --im-menu-text: ${colors.text.primary};
      --im-menu-text-muted: ${colors.text.secondary};
      --im-menu-icon: ${colors.text.secondary};
      --im-menu-hover: ${colors.bg.hover};
      --im-menu-active: ${colors.bg.selected};
      --im-menu-divider: ${colors.border.secondary};
      --im-menu-shadow: ${isDark ? "0 12px 32px rgba(0, 0, 0, 0.42)" : "0 12px 32px rgba(17, 19, 24, 0.14)"};
      --im-menu-radius: 10px;
      --im-control-bg: ${colors.bg.primary};
      --im-control-bg-hover: ${colors.bg.hover};
      --im-control-border: ${colors.border.primary};
      --im-control-focus-shadow: 0 0 0 3px ${isDark ? "rgba(139, 92, 246, 0.26)" : "rgba(124, 58, 237, 0.16)"};
      --im-modal-bg: ${colors.bg.primary};
      --im-popover-bg: ${colors.bg.primary};
      --im-bg-app: ${colors.bg.secondary};
      --im-bg-surface: ${colors.bg.primary};
      --im-bg-surface-alt: ${colors.bg.tertiary};
      --im-bg-input: ${colors.bg.primary};
      --im-bg-hover: ${colors.bg.hover};
      --im-bg-selected: ${colors.bg.selected};
      --im-bg-card: ${colors.bg.tertiary};
      --im-text-primary: ${colors.text.primary};
      --im-text-secondary: ${colors.text.secondary};
      --im-text-tertiary: ${colors.text.tertiary};
      --im-border: ${colors.border.primary};
      --im-border-subtle: ${colors.border.secondary};
      --im-divider: ${colors.border.secondary};
      --im-primary: ${colors.primary};
      --im-primary-hover: ${colors.primaryHover};
      --im-primary-pressed: ${colors.primaryActive};
      --im-primary-soft: ${isDark ? "rgba(124, 58, 237, 0.24)" : "#F1EAFF"};
      --im-danger: ${colors.error};
      --im-warning: ${colors.warning};
      --im-success: ${colors.success};
      --im-info: ${colors.info};
      --im-conv-title: ${colors.text.primary};
      --im-conv-preview: ${colors.text.secondary};
      --im-conv-meta: ${colors.text.secondary};
      --im-conv-item-hover: ${colors.bg.hover};
      --im-conv-item-active: ${colors.bg.selected};
      --im-conv-item-active-border: ${colors.info};
      --im-conv-unread-bg: ${colors.primary};
      --im-chat-hdr-bg: ${colors.bg.primary};
      --im-chat-hdr-border: ${colors.border.primary};
      --im-chat-hdr-title: ${colors.text.primary};
      --im-chat-hdr-meta: ${colors.text.secondary};
      --im-chat-hdr-typing: ${colors.info};
      --im-chat-window-bg: ${isDark ? "#101822" : "#F7F8FA"};
      --im-chat-window-empty-bg: ${colors.bg.primary};
      --im-rail-bg: ${isDark ? "#111318" : "#171A21"};
      --im-rail-border: rgba(255, 255, 255, 0.08);
      --im-rail-icon: rgba(255, 255, 255, 0.72);
      --im-rail-icon-hover: #FFFFFF;
      --im-rail-active-bg: rgba(124, 58, 237, ${isDark ? "0.30" : "0.14"});
      --im-rail-active: ${isDark ? "#C4B5FD" : "#7C3AED"};
      --wechat-background: var(--im-chat-window-bg);
      --wechat-divider: var(--im-divider);
      --wechat-text-primary: var(--im-text-primary);
      --wechat-text-secondary: var(--im-text-secondary);
      --wechat-text-tertiary: var(--im-text-tertiary);
      --wechat-primary: var(--im-primary);
      --wechat-bubble-sent: var(--im-bubble-sent);
      --wechat-bubble-received: var(--im-bubble-received);

      /* 间距 */
      --spacing-xs: ${theme.sizes.spacing.xs};
      --spacing-sm: ${theme.sizes.spacing.sm};
      --spacing-md: ${theme.sizes.spacing.md};
      --spacing-lg: ${theme.sizes.spacing.lg};
      --spacing-xl: ${theme.sizes.spacing.xl};

      /* 圆角 */
      --radius-xs: ${theme.sizes.radius.xs};
      --radius-sm: ${theme.sizes.radius.sm};
      --radius-md: ${theme.sizes.radius.md};
      --radius-lg: ${theme.sizes.radius.lg};

      /* 字体 */
      --font-xs: ${theme.sizes.fontSize.xs};
      --font-sm: ${theme.sizes.fontSize.sm};
      --font-md: ${theme.sizes.fontSize.md};
      --font-lg: ${theme.sizes.fontSize.lg};
      --font-xl: ${theme.sizes.fontSize.xl};
      --font-2xl: ${theme.sizes.fontSize["2xl"]};

      /* 布局 */
      --layout-left: ${theme.sizes.layout.leftPanel};
      --layout-right: ${theme.sizes.layout.rightPanel};
      --layout-header: ${theme.sizes.layout.headerHeight};
      --layout-session: ${theme.sizes.layout.sessionItemHeight};
      --layout-avatar: ${theme.sizes.layout.avatarSize};

      /* 阴影 */
      --shadow-sm: ${theme.shadows.sm};
      --shadow-md: ${theme.shadows.md};
      --shadow-lg: ${theme.shadows.lg};

      /* 动画 */
      --transition-fast: ${theme.transitions.fast};
      --transition-normal: ${theme.transitions.normal};

      /* 聊天输入框 EnhancedComposer */
${composerVariablesBlock(theme, isDark)}
    }
  `;
}

export function createNaiveThemeOverrides(isDark = false): GlobalThemeOverrides {
  const colors = isDark ? { ...imTheme.colors, ...imTheme.dark.colors } : imTheme.colors;
  const popoverShadow = isDark
    ? "0 12px 32px rgba(0, 0, 0, 0.42)"
    : "0 12px 32px rgba(17, 19, 24, 0.14)";
  const focusShadow = isDark
    ? "0 0 0 3px rgba(139, 92, 246, 0.26)"
    : "0 0 0 3px rgba(124, 58, 237, 0.16)";

  return {
    common: {
      fontFamily:
        '-apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", "PingFang SC", "Microsoft YaHei", "Noto Sans CJK SC", Inter, "Segoe UI", Arial, sans-serif',
      fontWeight: "400",
      fontWeightStrong: "600",
      primaryColor: colors.primary,
      primaryColorHover: colors.primaryHover,
      primaryColorPressed: colors.primaryActive,
      primaryColorSuppl: colors.primaryHover,
      infoColor: colors.info,
      infoColorHover: "#1F5AF0",
      infoColorPressed: "#164AD8",
      infoColorSuppl: "#1F5AF0",
      successColor: colors.success,
      successColorHover: "#16A34A",
      successColorPressed: "#15803D",
      successColorSuppl: "#16A34A",
      warningColor: colors.warning,
      warningColorHover: "#D97706",
      warningColorPressed: "#B45309",
      warningColorSuppl: "#D97706",
      errorColor: colors.error,
      errorColorHover: "#DC2626",
      errorColorPressed: "#B91C1C",
      errorColorSuppl: "#DC2626",
      bodyColor: colors.bg.secondary,
      cardColor: colors.bg.primary,
      modalColor: colors.bg.primary,
      popoverColor: colors.bg.primary,
      inputColor: colors.bg.primary,
      tableColor: colors.bg.primary,
      hoverColor: colors.bg.hover,
      pressedColor: colors.bg.selected,
      dividerColor: colors.border.secondary,
      borderColor: colors.border.primary,
      textColorBase: isDark ? "#FFFFFF" : "#111318",
      textColor1: colors.text.primary,
      textColor2: colors.text.secondary,
      textColor3: colors.text.tertiary,
      placeholderColor: colors.text.tertiary,
      iconColor: colors.text.secondary,
      iconColorHover: colors.text.primary,
      borderRadius: "8px",
      borderRadiusSmall: "6px",
      fontSize: "14px",
      fontSizeSmall: "13px",
      fontSizeMedium: "14px",
      fontSizeLarge: "15px",
      heightSmall: "32px",
      heightMedium: "38px",
      heightLarge: "44px",
      boxShadow1: imTheme.shadows.sm,
      boxShadow2: imTheme.shadows.md,
      boxShadow3: imTheme.shadows.lg,
      scrollbarColor: isDark ? "rgba(255,255,255,0.22)" : "rgba(107,114,128,0.28)",
      scrollbarColorHover: isDark ? "rgba(255,255,255,0.34)" : "rgba(107,114,128,0.42)",
    },
    Button: {
      borderRadiusTiny: "6px",
      borderRadiusSmall: "8px",
      borderRadiusMedium: "9px",
      borderRadiusLarge: "10px",
      textColorText: colors.text.secondary,
      textColorTextHover: colors.primary,
      textColorTextPressed: colors.primaryActive,
      colorPrimary: colors.primary,
      colorHoverPrimary: colors.primaryHover,
      colorPressedPrimary: colors.primaryActive,
      colorFocusPrimary: colors.primary,
      textColorPrimary: "#FFFFFF",
      textColorHoverPrimary: "#FFFFFF",
      textColorPressedPrimary: "#FFFFFF",
      borderPrimary: `1px solid ${colors.primary}`,
      borderHoverPrimary: `1px solid ${colors.primaryHover}`,
      borderPressedPrimary: `1px solid ${colors.primaryActive}`,
      borderFocusPrimary: `1px solid ${colors.primary}`,
      rippleColorPrimary: colors.primary,
    },
    Input: {
      borderRadius: "8px",
      color: colors.bg.primary,
      colorFocus: colors.bg.primary,
      border: `1px solid ${colors.border.primary}`,
      borderHover: `1px solid ${isDark ? colors.border.selected : imTheme.colors.border.hover}`,
      borderFocus: `1px solid ${colors.primary}`,
      boxShadowFocus: focusShadow,
      caretColor: colors.primary,
      textColor: colors.text.primary,
      placeholderColor: colors.text.tertiary,
      iconColor: colors.text.secondary,
      iconColorHover: colors.primary,
    },
    Dropdown: {
      borderRadius: "10px",
      color: colors.bg.primary,
      dividerColor: colors.border.secondary,
      optionTextColor: colors.text.primary,
      optionTextColorHover: colors.text.primary,
      optionTextColorActive: colors.primary,
      optionTextColorChildActive: colors.primary,
      optionColorHover: colors.bg.hover,
      optionColorActive: colors.bg.selected,
      prefixColor: colors.text.secondary,
      suffixColor: colors.text.secondary,
      padding: "6px",
      optionHeightMedium: "36px",
      fontSizeMedium: "14px",
      peers: {
        Popover: {
          color: colors.bg.primary,
          borderRadius: "10px",
          boxShadow: popoverShadow,
          textColor: colors.text.primary,
        },
      },
    },
    Popover: {
      color: colors.bg.primary,
      textColor: colors.text.primary,
      borderRadius: "10px",
      boxShadow: popoverShadow,
      padding: "8px 10px",
    },
    Tooltip: {
      color: isDark ? "rgba(255,255,255,0.94)" : "#171A21",
      textColor: isDark ? "#111318" : "#FFFFFF",
      borderRadius: "8px",
      padding: "6px 9px",
    },
    Modal: {
      color: colors.bg.primary,
      textColor: colors.text.primary,
      boxShadow: imTheme.shadows.lg,
    },
    Drawer: {
      color: colors.bg.primary,
      textColor: colors.text.primary,
      borderColor: colors.border.secondary,
      titleTextColor: colors.text.primary,
      closeIconColor: colors.text.secondary,
      closeIconColorHover: colors.text.primary,
    },
    Dialog: {
      color: colors.bg.primary,
      textColor: colors.text.secondary,
      titleTextColor: colors.text.primary,
      borderRadius: "12px",
      boxShadow: imTheme.shadows.lg,
    },
    Message: {
      color: colors.bg.primary,
      textColor: colors.text.primary,
      boxShadow: popoverShadow,
      borderRadius: "10px",
    },
    Empty: {
      textColor: colors.text.secondary,
      iconColor: colors.text.tertiary,
      extraTextColor: colors.text.tertiary,
    },
    Badge: {
      color: colors.error,
      textColor: "#FFFFFF",
    },
    Tag: {
      borderRadius: "8px",
    },
  };
}
