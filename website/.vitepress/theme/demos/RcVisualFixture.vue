<script setup lang="ts">
import ButtonDemo from "./ButtonDemo.vue";
import CommandPaletteDemo from "./CommandPaletteDemo.vue";
import CommentThreadDemo from "./CommentThreadDemo.vue";
import ComposerDemo from "./ComposerDemo.vue";
import ChatWorkspaceDemo from "./ChatWorkspaceDemo.vue";
import ConversationHeaderDemo from "./ConversationHeaderDemo.vue";
import DemoStage from "./DemoStage.vue";
import ConversationRowDemo from "./ConversationRowDemo.vue";
import InputDemo from "./InputDemo.vue";
import MessageBubbleDemo from "./MessageBubbleDemo.vue";
import MessageStatusDemo from "./MessageStatusDemo.vue";
import { FlareConversationHeader, FlareDesktopAppShell } from "@flare-im/vue-ui/components";

const navigation = [
  { id: "main", items: [
    { id: "conversations", label: "Chats", icon: "comment", badge: { kind: "count", count: 4 } },
    { id: "contacts", label: "Contacts", icon: "people" },
    { id: "settings", label: "Settings", icon: "settings" },
  ] },
];
</script>

<template>
  <main id="rc-visual-fixture" data-vr-ready="true" aria-label="RC visual regression fixture">
    <section aria-label="General controls"><ButtonDemo /><InputDemo /></section>
    <section aria-label="Conversation and message"><ConversationRowDemo /><MessageStatusDemo /><MessageBubbleDemo /></section>
    <section aria-label="Conversation headers">
      <DemoStage>
        <FlareConversationHeader
          :identity="{ id: 'ivy', title: 'Ivy Chen', kind: 'direct', presence: 'online' }"
          :capabilities="{ availableActionIds: ['search', 'share', 'details'] }"
          @action="() => undefined"
        />
      </DemoStage>
      <ConversationHeaderDemo />
    </section>
    <section aria-label="Composer and thread"><ComposerDemo /><CommentThreadDemo /></section>
    <section class="fixture-workspace" aria-label="Conversation workspace"><ChatWorkspaceDemo /></section>
    <section aria-label="Command surface"><CommandPaletteDemo /></section>
    <section aria-label="Desktop app shell" class="fixture-shell">
      <FlareDesktopAppShell :navigation="navigation" active-navigation-id="conversations" responsive-mode="desktop" pane-mode="triplePane" detail-mode="inline" :primary-width="232" :detail-width="200" has-detail label="Desktop app shell">
        <template #primary><div class="fixture-pane">Conversations</div></template>
        <div class="fixture-pane">Message workspace</div>
        <template #detail><div class="fixture-pane">Details</div></template>
      </FlareDesktopAppShell>
    </section>
  </main>
</template>

<style scoped>
#rc-visual-fixture { width: 1120px; padding: 24px; background: var(--flare-color-bg-primary); color: var(--flare-color-text-primary); }
/* Direct children only: kit roots (FlareDesktopAppShell renders a <section>) inherit this scope id. */
#rc-visual-fixture > section { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 20px; padding: 20px 0; border-bottom: 1px solid var(--flare-color-border-primary); }
#rc-visual-fixture > section:last-child { display: block; border-bottom: 0; }
#rc-visual-fixture > .fixture-workspace { display: block; }
#rc-visual-fixture.is-large-text > section { grid-template-columns: minmax(0, 1fr); }
.fixture-shell { height: 360px; }
.fixture-pane { min-height: 160px; padding: 16px; background: var(--flare-color-bg-secondary); border-inline-end: 1px solid var(--flare-color-border-primary); }
.fixture-nav { min-width: 72px; }
@media (prefers-reduced-motion: reduce) { *, *::before, *::after { animation: none !important; transition: none !important; } }
</style>
