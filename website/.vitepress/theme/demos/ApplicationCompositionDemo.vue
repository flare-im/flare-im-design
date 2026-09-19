<script setup>
import { computed, inject, ref } from "vue";
import {
  FlareAdaptiveNavigation,
  FlareAppLayout,
  FlareConversationListContainer,
  FlareDesktopAppShell,
  FlareFriendListContainer,
  FlareIMAppKit,
  FlareMobileAppShell,
  FlareWorkspaceFrame,
} from "@flare-im/vue-ui";
import DemoStage from "./DemoStage.vue";
import { previewContextKey } from "./preview-context";

const props = defineProps({
  component: { type: String, required: true },
  previewState: { type: String, default: "ready" },
});
const preview = inject(previewContextKey, null);
const activeId = ref("conversations");
const navigation = [
  { id: "main", items: [
    { id: "conversations", label: "Chats", icon: "comment", badge: { kind: "count", count: 4 } },
    { id: "contacts", label: "Contacts", icon: "people" },
    { id: "search", label: "Search", icon: "search" },
    { id: "settings", label: "Settings", icon: "settings" },
  ] },
];
const configuration = {
  features: { enabled: ["conversations", "contacts", "groups", "search", "settings"] },
  capabilities: { enabled: ["message", "search", "details"] },
  navigation,
};
const workspaceComponents = { WorkspaceFrame: FlareWorkspaceFrame };
const responsiveMode = computed(() => {
  const value = preview?.viewport.value;
  if (value === "mobile" || value === "tablet" || value === "desktop") return value;
  return "wideDesktop";
});
const listState = computed(() => {
  const status = ["loading", "empty", "error", "offline"].includes(props.previewState) ? props.previewState : "ready";
  return { status, error: status === "offline" ? "Messages remain available while reconnecting." : status === "error" ? "Could not load this view." : "" };
});
const workspaceState = computed(() => ({
  content: listState.value,
  banner: props.previewState === "offline"
    ? { tone: "warning", message: "Offline. Drafts stay on this device.", actionLabel: "Retry" }
    : undefined,
}));
const isWorkspace = computed(() => Boolean(workspaceComponents[props.component]));
</script>

<template>
  <DemoStage>
    <div class="application-demo">
      <FlareAdaptiveNavigation
        v-if="component === 'AdaptiveNavigation'"
        :groups="navigation"
        :active-id="activeId"
        :responsive-mode="responsiveMode"
        label="Primary"
        @navigate="activeId = $event"
      />

      <FlareMobileAppShell
        v-else-if="component === 'MobileAppShell'"
        :navigation="navigation"
        :active-navigation-id="activeId"
        label="Mobile messaging shell"
        @navigate="activeId = $event"
      >
        <template #appBar><div class="application-demo__bar">Messages <button type="button">New</button></div></template>
        <div class="application-demo__content"><strong>Ivy Chen</strong><p>Review the component coverage before release.</p></div>
      </FlareMobileAppShell>

      <FlareDesktopAppShell
        v-else-if="component === 'DesktopAppShell'"
        :navigation="navigation"
        :active-navigation-id="activeId"
        :responsive-mode="responsiveMode === 'wideDesktop' ? 'wideDesktop' : 'desktop'"
        pane-mode="triplePane"
        detail-mode="inline"
        has-detail
        label="Desktop messaging shell"
        @navigate="activeId = $event"
      >
        <template #primary><div class="application-demo__pane"><strong>Messages</strong><p>Ivy Chen</p><p>Design review</p></div></template>
        <div class="application-demo__content"><strong>Design review</strong><p>Cross-platform component coverage is ready.</p></div>
        <template #detail><div class="application-demo__pane"><strong>Details</strong><p>4 members</p></div></template>
      </FlareDesktopAppShell>

      <FlareIMAppKit
        v-else-if="component === 'IMAppKit'"
        :configuration="configuration"
        :active-navigation-id="activeId"
        label="Flare IM app"
        @navigate="activeId = $event"
      >
        <template #appBar><div class="application-demo__bar">Flare</div></template>
        <template #destination="{ id }">
          <FlareAppLayout v-if="id === 'conversations'" pane-mode="triplePane" detail-mode="inline" has-detail label="Chats">
            <template #primary><div class="application-demo__pane"><strong>Conversations</strong><p>Ivy Chen · 3</p><p>Product team</p></div></template>
            <template #content><div class="application-demo__content"><strong>Product team</strong><p>The host owns data and navigation intents.</p></div></template>
            <template #detail><div class="application-demo__pane"><strong>Conversation info</strong><p>Muted notifications</p></div></template>
          </FlareAppLayout>
          <div v-else class="application-demo__content"><strong>{{ id }}</strong><p>Each destination keeps its state while another is active.</p></div>
        </template>
      </FlareIMAppKit>

      <component
        :is="component === 'FriendListContainer' ? FlareFriendListContainer : FlareConversationListContainer"
        v-else-if="component === 'ConversationListContainer' || component === 'FriendListContainer'"
        :state="listState"
        label="List state preview"
      >
        <template #header><div class="application-demo__bar">{{ component === "FriendListContainer" ? "Contacts" : "Messages" }}</div></template>
        <div class="application-demo__rows"><p><strong>Ivy Chen</strong><span>Design review at 10:00</span></p><p><strong>Product team</strong><span>4 unread messages</span></p></div>
      </component>

      <component
        :is="workspaceComponents[component]"
        v-else-if="isWorkspace"
        :state="workspaceState"
        has-detail
        :label="component"
      >
        <template #primary><div class="application-demo__pane"><strong>Contacts</strong><p>Recent</p><p>Favorites</p></div></template>
        <div class="application-demo__content"><strong>{{ component }}</strong><p>Contacts, groups, search, media, calls, settings and saved messages are all host content composed into this one frame.</p></div>
        <template #detail><div class="application-demo__pane"><strong>Details</strong><p>Shared context</p></div></template>
      </component>

      <FlareAppLayout
        v-else
        pane-mode="triplePane"
        detail-mode="inline"
        has-detail
        label="Application layout"
      >
        <template #navigation><FlareAdaptiveNavigation :groups="navigation" :active-id="activeId" :responsive-mode="responsiveMode" /></template>
        <template #primary><div class="application-demo__pane"><strong>Messages</strong><p>Ivy Chen</p></div></template>
        <template #content><div class="application-demo__content"><strong>Conversation</strong><p>Primary task area</p></div></template>
        <template #detail><div class="application-demo__pane"><strong>Details</strong><p>Context</p></div></template>
      </FlareAppLayout>
    </div>
  </DemoStage>
</template>

<style scoped>
.application-demo { width: 100%; height: 390px; min-width: 0; overflow: hidden; border: 1px solid var(--flare-color-border-primary); background: var(--flare-color-bg-primary); }
.application-demo__bar { display: flex; align-items: center; justify-content: space-between; min-height: 48px; padding: 0 14px; border-bottom: 1px solid var(--flare-color-border-primary); color: var(--flare-color-text-primary); font-weight: 650; }
.application-demo__bar button { min-height: var(--flare-size-layout-touch-target-min); border: 0; color: var(--flare-color-primary-text); background: transparent; font: inherit; }
.application-demo__pane,
.application-demo__content { height: 100%; padding: 18px; box-sizing: border-box; color: var(--flare-color-text-primary); }
.application-demo__pane { background: var(--flare-color-bg-secondary); }
.application-demo p { margin: 8px 0; color: var(--flare-color-text-secondary); font-size: 13px; }
.application-demo__rows { padding: 6px 14px; }
.application-demo__rows p { display: grid; gap: 3px; padding: 10px 0; border-bottom: 1px solid var(--flare-color-border-secondary); }
.application-demo__rows span { color: var(--flare-color-text-tertiary); }
.application-demo :deep(.flare-mobile-shell) { height: 390px; }
</style>
