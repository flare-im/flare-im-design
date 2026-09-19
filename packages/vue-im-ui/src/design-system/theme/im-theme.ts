import type { GlobalThemeOverrides } from "naive-ui";
import { flareDesignTokens } from "@flare-im/tokens";
import {
  resolveFlareTheme,
  type FlareCustomTheme,
  type FlareThemeMode,
  type FlareThemeName,
} from "@flare-im/tokens/theme";

export const imTheme = flareDesignTokens;
export type FlareBrandTheme = FlareThemeName | FlareCustomTheme;

export function createNaiveThemeOverrides(
  mode: FlareThemeMode = "light",
  brand: FlareBrandTheme = "violet",
): GlobalThemeOverrides {
  const colors = resolveFlareTheme(brand, mode).colors as any;
  const dark = mode === "dark";
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
      successColor: colors.success,
      warningColor: colors.warning,
      errorColor: colors.error,
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
      textColorBase: colors.text.primary,
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
      heightMedium: "40px",
      heightLarge: "48px",
      boxShadow1: dark ? flareDesignTokens.dark.shadows.sm : flareDesignTokens.shadows.sm,
      boxShadow2: dark ? flareDesignTokens.dark.shadows.md : flareDesignTokens.shadows.md,
      boxShadow3: dark ? flareDesignTokens.dark.shadows.lg : flareDesignTokens.shadows.lg,
      scrollbarColor: dark ? "rgba(255,255,255,0.22)" : "rgba(107,114,128,0.28)",
      scrollbarColorHover: dark ? "rgba(255,255,255,0.34)" : "rgba(107,114,128,0.42)",
    },
  };
}
