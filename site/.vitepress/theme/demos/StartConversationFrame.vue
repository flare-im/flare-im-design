<script setup>
// "Start conversation" is two separate components chosen by the host per platform:
// desktop → FlareStartConversationDialog (centered modal); mobile → a bottom sheet
// (FlareStartConversationSheet). The frame picks by viewport, mirroring the shell.
import { ref, onMounted, onBeforeUnmount } from "vue";
import FlareStartConversationDialog from "@flare-im/vue-ui/components/shell/FlareStartConversationDialog.vue";
import FlareStartConversationSheet from "@flare-im/vue-ui/components/shell/FlareStartConversationSheet.vue";

const isDesktop = ref(true);
let mq = null;
function onChange(e) { isDesktop.value = e.matches; }
onMounted(() => {
  mq = window.matchMedia("(min-width: 900px)");
  isDesktop.value = mq.matches;
  mq.addEventListener("change", onChange);
});
onBeforeUnmount(() => mq?.removeEventListener("change", onChange));
</script>

<template>
  <div class="sc-frame">
    <FlareStartConversationDialog v-if="isDesktop" :open="true" />
    <div v-else class="sc-frame__sheet">
      <FlareStartConversationSheet />
    </div>
  </div>
</template>

<style scoped>
.sc-frame {
  height: 100dvh;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  background: var(--flare-color-bg-secondary, #f5f6f8);
}
.sc-frame__sheet {
  background: var(--flare-color-bg-primary, #fff);
  border-top-left-radius: 18px;
  border-top-right-radius: 18px;
  box-shadow: 0 -8px 28px rgba(21, 18, 32, 0.12);
  padding-bottom: 8px;
}
</style>
