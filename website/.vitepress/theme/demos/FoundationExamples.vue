<script setup>
import { ref } from "vue";
import {
  FlareButton,
  FlareUiProvider,
  FlareConversationRow,
  FlareIcon,
  FlareInput,
  FlareSelect,
} from "@flare-im/vue-ui/components";

defineProps({ kind: { type: String, required: true } });
const input = ref("");
const selection = ref("all");
const options = [
  { value: "all", label: "All conversations" },
  { value: "unread", label: "Unread" },
];
const conversation = {
  id: "design-system",
  displayName: "Design System",
  lastMessagePreview: "Review the mobile composer defaults",
  timestamp: Date.now(),
  unreadCount: 3,
};
const colors = [
  ["Primary", "--flare-color-primary"],
  ["Surface", "--flare-color-bg-primary"],
  ["Text", "--flare-color-text-primary"],
  ["Border", "--flare-color-border-primary"],
  ["Selected", "--flare-color-bg-selected"],
  ["Danger", "--flare-color-error"],
  ["Outgoing", "--flare-color-message-outgoing-background"],
  ["Read", "--flare-color-message-status-read"],
  ["Focus", "--flare-color-focus-ring"],
];
const typeRoles = ["display", "titleLarge", "titleMedium", "titleSmall", "bodyLarge", "bodyMedium", "bodySmall", "labelLarge", "labelMedium", "labelSmall", "caption"];
const spacings = ["xs", "sm", "md", "lg", "xl", "2xl"];
const radii = ["xs", "sm", "md", "lg", "xl", "full"];
</script>

<template>
  <div class="foundation-example" :data-kind="kind">
    <div v-if="kind === 'colors'" class="foundation-example__swatches">
      <div v-for="[label, token] in colors" :key="token"><i :style="{ background: 'var(' + token + ')' }" /><strong>{{ label }}</strong><code>{{ token }}</code></div>
    </div>
    <div v-else-if="kind === 'typography'" class="foundation-example__type">
      <p v-for="role in typeRoles" :key="role" :data-role="role"><code>{{ role }}</code><span>Conversation clarity before decoration</span></p>
    </div>
    <div v-else-if="kind === 'spacing'" class="foundation-example__scale">
      <div v-for="space in spacings" :key="space"><code>{{ space }}</code><i :style="{ width: 'var(--flare-size-spacing-' + space + ')' }" /></div>
    </div>
    <div v-else-if="kind === 'radius'" class="foundation-example__radius">
      <div v-for="radius in radii" :key="radius"><i :style="{ borderRadius: 'var(--flare-size-radius-' + radius + ')' }" /><code>{{ radius }}</code></div>
    </div>
    <div v-else-if="kind === 'elevation'" class="foundation-example__elevation">
      <div><span>Content surface</span><code>flat</code></div><div class="is-overlay"><span>Popover / dialog</span><code>elevated</code></div>
    </div>
    <div v-else-if="kind === 'icons'" class="foundation-example__icons">
      <span><FlareIcon name="search" :size="16" /><code>sm</code></span>
      <span><FlareIcon name="comment" :size="20" /><code>md</code></span>
      <span><FlareIcon name="person" :size="24" /><code>lg</code></span>
    </div>
    <div v-else-if="kind === 'motion'" class="foundation-example__motion"><i /><span>State change preserves position and never shifts layout.</span></div>
    <div v-else-if="kind === 'breakpoints'" class="foundation-example__breakpoints">
      <div><code>mobile</code><span>single pane</span></div><div><code>tablet</code><span>dual pane</span></div><div><code>desktop</code><span>multi-pane</span></div>
    </div>
    <ClientOnly v-else-if="kind === 'density'">
      <FlareUiProvider locale="en-US">
        <div class="foundation-example__density">
          <section v-for="level in ['comfortable', 'default', 'compact']" :key="level" :data-density="level">
            <h3>{{ level }}</h3>
            <FlareButton :size="level === 'comfortable' ? 'lg' : level === 'compact' ? 'sm' : 'md'">New message</FlareButton>
            <FlareInput v-model="input" placeholder="Search" />
            <FlareSelect v-model="selection" :size="level === 'comfortable' ? 'lg' : level === 'compact' ? 'sm' : 'md'" :options="options" />
            <FlareConversationRow :item="conversation" />
          </section>
        </div>
      </FlareUiProvider>
    </ClientOnly>
  </div>
</template>

<style scoped>
.foundation-example { margin: 14px 0 24px; color: var(--vp-c-text-1); }
.foundation-example__swatches { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); border-top: 1px solid var(--vp-c-divider); }
.foundation-example__swatches > div { display: grid; grid-template-columns: 36px 1fr; gap: 2px 10px; padding: 12px 10px 12px 0; border-bottom: 1px solid var(--vp-c-divider); }
.foundation-example__swatches i { grid-row: 1 / 3; width: 36px; height: 36px; border: 1px solid var(--vp-c-divider); border-radius: var(--flare-size-radius-sm); }
.foundation-example__swatches strong { font-size: 13px; }
.foundation-example__swatches code { overflow-wrap: anywhere; color: var(--vp-c-text-3); font-size: 10px; }
.foundation-example__type p { display: grid; grid-template-columns: 110px 1fr; align-items: baseline; gap: 16px; margin: 0; padding: 8px 0; border-bottom: 1px solid var(--vp-c-divider); }
.foundation-example__type p[data-role="display"] span { font-size: 24px; font-weight: 700; }
.foundation-example__type p[data-role^="title"] span { font-size: 18px; font-weight: 650; }
.foundation-example__type p[data-role^="body"] span { font-size: 14px; }
.foundation-example__type p[data-role^="label"] span { font-size: 13px; font-weight: 600; }
.foundation-example__type p[data-role="caption"] span { color: var(--vp-c-text-3); font-size: 11px; }
.foundation-example__scale > div { display: grid; grid-template-columns: 56px 1fr; align-items: center; gap: 12px; min-height: 34px; }
.foundation-example__scale i { display: block; height: 12px; background: var(--flare-color-primary); }
.foundation-example__radius,
.foundation-example__icons,
.foundation-example__breakpoints { display: flex; flex-wrap: wrap; gap: 18px; }
.foundation-example__radius > div,
.foundation-example__icons span { display: grid; justify-items: center; gap: 7px; }
.foundation-example__radius i { width: 56px; height: 42px; border: 1px solid var(--flare-color-border-selected); background: var(--flare-color-bg-selected); }
.foundation-example__elevation { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; padding: 24px; background: var(--vp-c-bg-alt); }
.foundation-example__elevation > div { display: grid; gap: 8px; min-height: 100px; padding: 16px; border: 1px solid var(--vp-c-divider); background: var(--vp-c-bg); }
.foundation-example__elevation .is-overlay { box-shadow: var(--flare-shadow-lg); }
.foundation-example__icons span { min-width: 60px; padding: 10px; }
.foundation-example__motion { display: flex; align-items: center; gap: 14px; padding: 16px 0; border-block: 1px solid var(--vp-c-divider); }
.foundation-example__motion i { width: 44px; height: 8px; background: var(--flare-color-primary); animation: functional-motion 1.8s ease-in-out infinite alternate; }
.foundation-example__breakpoints > div { display: grid; gap: 4px; flex: 1; min-width: 120px; padding-block: 12px; border-block: 1px solid var(--vp-c-divider); }
.foundation-example__density { display: grid; grid-template-columns: repeat(3, minmax(220px, 1fr)); gap: 1px; overflow-x: auto; background: var(--vp-c-divider); }
.foundation-example__density section { display: grid; align-content: start; gap: 12px; min-width: 220px; padding: 14px; background: var(--vp-c-bg); }
.foundation-example__density h3 { margin: 0; font-size: 13px; text-transform: capitalize; }
.foundation-example__density section[data-density="comfortable"] { gap: 16px; }
.foundation-example__density section[data-density="compact"] { gap: 8px; }
@keyframes functional-motion { to { transform: translateX(120px); } }
@media (prefers-reduced-motion: reduce) { .foundation-example__motion i { animation: none; } }
@media (max-width: 680px) { .foundation-example__elevation { grid-template-columns: 1fr; } }
</style>
