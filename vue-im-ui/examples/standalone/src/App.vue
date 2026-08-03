<script setup lang="ts">
import { ref } from "vue";
import { NConfigProvider } from "naive-ui";
// One-time i18n provider (the library ships zh/en; default English here).
import { useFlareI18nProvider } from "@flare-im/vue-ui/i18n";
// Real components from the package — props in, events out. No Flare core.
import {
  FlareConversationList,
  FlareConversationRow,
  FlareTextMessage,
  FlareImageMessage,
  FlareComposerSendButton,
} from "@flare-im/vue-ui/components";
import { backend } from "./backend";

useFlareI18nProvider("en-US");

const draft = ref("");
function send(): void {
  const text = draft.value.trim();
  if (!text) return;
  backend.send(text); // your backend — the UI just emitted an event
  draft.value = "";
}
</script>

<template>
  <n-config-provider>
    <div class="im">
      <aside class="im__list">
        <header class="im__brand">
          Acme Chat <span>· standalone · no Flare core</span>
        </header>
        <FlareConversationList :items="backend.conversations" :active-id="backend.activeId">
          <template #item="{ item, active }">
            <FlareConversationRow :item="item" :active="active" @select="backend.select(item.id)" />
          </template>
        </FlareConversationList>
      </aside>

      <main class="im__chat">
        <header class="im__hdr">{{ backend.active?.displayName }}</header>
        <div class="im__thread">
          <div v-for="m in backend.messages" :key="m.id" class="im__row" :class="{ 'im__row--self': m.self }">
            <FlareImageMessage v-if="m.type === 'image'" :src="m.src" />
            <FlareTextMessage v-else :text="m.text ?? ''" :self="m.self" />
          </div>
        </div>
        <footer class="im__composer">
          <textarea
            v-model="draft"
            class="im__input"
            placeholder="Type a message…"
            rows="1"
            @keydown.enter.prevent="send"
          />
          <FlareComposerSendButton :active="!!draft.trim()" @send="send" />
        </footer>
      </main>
    </div>
  </n-config-provider>
</template>

<style scoped>
.im {
  display: grid;
  grid-template-columns: 320px 1fr;
  height: 100vh;
  background: var(--flare-color-bg-secondary, #f5f6f8);
  color: var(--flare-color-text-primary, #111318);
  font: 14px/1.5 -apple-system, "Segoe UI", "PingFang SC", sans-serif;
}
.im__list {
  display: flex;
  flex-direction: column;
  min-height: 0;
  border-right: 1px solid var(--flare-color-border-primary, #e7e9ee);
  background: var(--flare-color-bg-primary, #fff);
}
.im__brand {
  padding: 16px 16px 12px;
  font-weight: 700;
  font-size: 15px;
}
.im__brand span {
  color: var(--flare-color-text-tertiary, #a3a7ae);
  font-weight: 500;
  font-size: 12px;
}
.im__chat {
  display: flex;
  flex-direction: column;
  min-width: 0;
  min-height: 0;
}
.im__hdr {
  padding: 16px 20px;
  font-weight: 600;
  border-bottom: 1px solid var(--flare-color-border-primary, #e7e9ee);
  background: var(--flare-color-bg-primary, #fff);
}
.im__thread {
  flex: 1;
  min-height: 0;
  overflow: auto;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 20px;
  background:
    radial-gradient(var(--flare-color-border-secondary, #eef0f4) 1px, transparent 1px) 0 0 / 22px 22px;
}
.im__row {
  display: flex;
  justify-content: flex-start;
}
.im__row--self {
  justify-content: flex-end;
}
.im__composer {
  display: flex;
  align-items: flex-end;
  gap: 10px;
  padding: 12px 16px;
  border-top: 1px solid var(--flare-color-border-primary, #e7e9ee);
  background: var(--flare-color-bg-primary, #fff);
}
.im__input {
  flex: 1;
  resize: none;
  max-height: 120px;
  padding: 10px 12px;
  border: 1px solid var(--flare-color-border-primary, #e7e9ee);
  border-radius: 12px;
  font: inherit;
  outline: none;
  background: var(--flare-color-bg-secondary, #f5f6f8);
  color: inherit;
}
.im__input:focus {
  border-color: var(--flare-color-primary, #7c3aed);
}
</style>
