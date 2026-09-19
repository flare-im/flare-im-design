// Migration smoke (docs/release/migration/2.0-rc-to-2.0.md), type-checked against the
// packed tarball. Each replacement the guide tells a host to use must import from the
// entry the guide names; each removed symbol must be gone. Not bundled — vue-tsc only.
import {
  FlareAppLayout,
  FlareButton,
  FlareComposerActionPanel,
  FlareComposerMediaPreview,
  FlareComposerReplyStrip,
  FlareComposerSendButton,
  FlareConversationHeader,
  FlareConversationListContainer,
  FlareDatePill,
  FlareDesktopAppShell,
  FlareEmojiStickerPicker,
  FlareFormField,
  FlareInput,
  FlareMarkdownPreview,
  FlareMentionPicker,
  FlareMessageContentView,
  FlareMobileAppShell,
  FlareScrollToLatest,
  FlareSelect,
  FlareStartConversationDialog,
  FlareTextarea,
  FlareWorkspaceFrame,
  type FlareComposerMediaPreviewItem,
} from "@flare-im/vue-ui/components";
import {
  createWebVoiceRecorderAdapter,
  provideFlareVoiceRecorder,
  useFileDrop,
  useMarkdownShortcuts,
  useVoiceRecorder,
  type FlareVoiceRecorderAdapter,
} from "@flare-im/vue-ui/composables";
import {
  FLARE_BREAKPOINT_DESKTOP_MIN,
  FLARE_BREAKPOINT_IPAD_MAX,
  FLARE_BREAKPOINT_TABLET_MIN,
  FLARE_SAFE_URL_PROTOCOLS,
  isSafeExternalUrl,
  paneEmptyActionVisible,
  safeExternalUrl,
  type FlareToastVariant,
} from "@flare-im/vue-ui/contracts";
import type { FlareToastVariant as RootToastVariant } from "@flare-im/vue-ui";
// §1 / §1b / public-api-2.0.md §2: removed without aliases.
// @ts-expect-error FlareTimeStamp was merged into FlareDatePill (D3)
import { FlareTimeStamp } from "@flare-im/vue-ui/components";
// @ts-expect-error FlarePrimaryButton was merged into FlareButton size="lg" block (D5)
import { FlarePrimaryButton } from "@flare-im/vue-ui/components";
// @ts-expect-error FlareAppShell was split into FlareMobileAppShell / FlareDesktopAppShell (D12)
import { FlareAppShell } from "@flare-im/vue-ui/components";
// @ts-expect-error FlareDesktopWorkbench became FlareDesktopAppShell (N1)
import { FlareDesktopWorkbench } from "@flare-im/vue-ui/components";
// @ts-expect-error FlareAdaptiveWorkbench was retired into FlareAppLayout (D18)
import { FlareAdaptiveWorkbench } from "@flare-im/vue-ui/components";
// @ts-expect-error FlareChatHeader became FlareConversationHeader (D6)
import { FlareChatHeader } from "@flare-im/vue-ui/components";
// @ts-expect-error FlareStartConversationSheet became FlareStartConversationDialog (D7)
import { FlareStartConversationSheet } from "@flare-im/vue-ui/components";
// @ts-expect-error FlareComposerEmojiStickerPanel became FlareEmojiStickerPicker (D14)
import { FlareComposerEmojiStickerPanel } from "@flare-im/vue-ui/components";
// @ts-expect-error FlareContactsWorkspace became FlareWorkspaceFrame (D10)
import { FlareContactsWorkspace } from "@flare-im/vue-ui/components";
// @ts-expect-error FlareToastVariant is no longer re-exported from ./components (§4c)
import type { FlareToastVariant as ComponentsToastVariant } from "@flare-im/vue-ui/components";

type Props<T> = T extends abstract new (...args: never[]) => { $props: infer P } ? P : never;

// Documented props must exist under the documented names.
const button: Props<typeof FlareButton> = { size: "lg", block: true, label: "Send" };
const desktop: Props<typeof FlareDesktopAppShell> = { navigation: [], activeNavigationId: "chats", paneMode: "triplePane", detailMode: "inline", primaryWidth: 320, detailWidth: 360 };
const input: Props<typeof FlareInput> = { id: "name", ariaLabel: "Name", ariaDescribedby: "hint", autocomplete: "name", name: "name", invalid: false, size: "lg" };
const select: Props<typeof FlareSelect> = { id: "role", ariaDescribedby: "hint", options: [] };
const textarea: Props<typeof FlareTextarea> = { id: "bio", name: "bio", ariaLabel: "Bio", ariaDescribedby: "hint", invalid: false };

const toast: FlareToastVariant = "success";
const rootToast: RootToastVariant = toast;
const url: string | null = safeExternalUrl("example.com");
const breakpoints = [FLARE_BREAKPOINT_TABLET_MIN, FLARE_BREAKPOINT_DESKTOP_MIN, FLARE_BREAKPOINT_IPAD_MAX] as const;

export const migrationSmoke = {
  components: [FlareAppLayout, FlareComposerActionPanel, FlareComposerMediaPreview, FlareComposerReplyStrip, FlareComposerSendButton,
    FlareConversationHeader, FlareConversationListContainer, FlareDatePill, FlareEmojiStickerPicker, FlareFormField, FlareMarkdownPreview,
    FlareMentionPicker, FlareMessageContentView, FlareMobileAppShell, FlareScrollToLatest, FlareStartConversationDialog, FlareWorkspaceFrame],
  composables: [createWebVoiceRecorderAdapter, provideFlareVoiceRecorder, useFileDrop, useMarkdownShortcuts, useVoiceRecorder],
  removed: [FlareTimeStamp, FlarePrimaryButton, FlareAppShell, FlareDesktopWorkbench, FlareAdaptiveWorkbench, FlareChatHeader, FlareStartConversationSheet, FlareComposerEmojiStickerPanel, FlareContactsWorkspace],
  props: [button, desktop, input, select, textarea],
  values: { rootToast, url, breakpoints, protocols: FLARE_SAFE_URL_PROTOCOLS, isSafe: isSafeExternalUrl, paneEmptyActionVisible },
};
export type MigrationSmokeTypes = [FlareComposerMediaPreviewItem, FlareVoiceRecorderAdapter, ComponentsToastVariant];
