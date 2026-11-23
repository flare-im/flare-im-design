import { flareDesignTokens } from "@flare-im/tokens";

const component = flareDesignTokens.sizes.component;
/** The call avatar tokens in px: FlareAvatar takes a number, so they are read from the generated tokens, not written. */
export const flareCallAvatar = {
  stage: parseFloat(component.callAvatarSize),
  tile: parseFloat(component.callTileAvatar),
  dock: parseFloat(component.callDockAvatarSize),
  banner: parseFloat(component.callIncomingBannerAvatar),
} as const;
