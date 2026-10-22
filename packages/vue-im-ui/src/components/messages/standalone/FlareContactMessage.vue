<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import { avatarTint } from "../../../shared/avatar-tint";
import MsgIcon from "./MsgIcon.vue";
// A contact card: an avatar image when given, else a pastel initials chip, the name and a free secondary
// line (department, handle). With an `open` listener the card is a button that reports the person's
// `userId`, so the host opens their profile; without one it only displays.
const props = withDefaults(
  defineProps<{ name?: string; avatarUrl?: string; subtitle?: string; userId?: string }>(),
  { name: "contact", userId: "" },
);
const emit = defineEmits<{ (e: "open", userId: string): void }>();
const instance = getCurrentInstance();
const interactive = computed(() => Boolean(instance?.vnode.props?.onOpen));
// 同一个人到哪都一个颜色：调色板只有 shared/avatar-tint.ts 一份。
const av = computed(() => avatarTint(props.name));
const initials = computed(() => {
  const p = (props.name || "").trim().split(/\s+/);
  return ((p.length > 1 ? p[0][0] + p[1][0] : (p[0] || "?")[0]) || "?").toUpperCase();
});
</script>
<template>
  <component
    :is="interactive ? 'button' : 'div'"
    :type="interactive ? 'button' : undefined"
    class="fm-contact"
    :class="{ 'is-interactive': interactive }"
    @click="interactive && emit('open', userId)"
  >
    <img v-if="avatarUrl" class="av img" :src="avatarUrl" :alt="name" />
    <span v-else class="av" :style="{ background: av.bg, color: av.fg }">{{ initials }}</span>
    <span class="meta"><b>{{ name }}</b><small v-if="subtitle">{{ subtitle }}</small></span>
    <MsgIcon v-if="interactive" name="chevronRight" :size="16" class="chev" />
  </component>
</template>
<style scoped>
.fm-contact { display: inline-flex; align-items: center; gap: 12px; min-width: 240px; padding: 9px var(--flare-size-spacing-2md); border-radius: 16px 16px 16px 4px; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-secondary); box-shadow: var(--flare-component-bubble-shadow); font: inherit; color: inherit; text-align: start; }
.fm-contact.is-interactive { cursor: pointer; }
.fm-contact.is-interactive:hover { border-color: var(--flare-color-border-hover); }
.fm-contact.is-interactive:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.av { width: 44px; height: 44px; border-radius: 10px; flex: none; display: grid; place-items: center; font-weight: 600; font-size: 14px; }
.av.img { object-fit: cover; }
.meta { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.meta b { font-size: 15px; font-weight: 600; color: var(--flare-color-text-primary); }
.meta small { font-size: 11px; color: var(--flare-color-text-tertiary); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.chev { color: var(--flare-color-text-tertiary); }
</style>
