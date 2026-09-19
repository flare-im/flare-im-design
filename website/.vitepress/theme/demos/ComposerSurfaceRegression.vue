<script setup lang="ts">
import { nextTick, onMounted, ref } from "vue";
import { FlareComposer } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const focused = ref<{ focusInput: () => void } | null>(null);
const draft = ref("");
const richMode = ref(false);
// The expanded preset shows its voice shortcut only when a recording has somewhere to go.
function keepVoice(): void {}
const multiline = ref("A compact first line\nA second line grows the same surface\nA third line keeps actions aligned below.");
const uploadItems = [
  { id: "upload-1", name: "design-review.png", progress: 0.62, state: "uploading" as const },
  { id: "upload-2", name: "prototype.mov", progress: 0.48, state: "failed" as const },
];

onMounted(() => {
  void nextTick(() => focused.value?.focusInput());
});
</script>

<template>
  <DemoStage>
    <section id="composer-surface-regression" data-vr-ready="true" aria-label="Composer surface regression">
    <article data-composer-state="default">
      <h2>Default</h2>
      <FlareComposer v-model="draft" :rich-mode="richMode" toolbar-presentation="expanded" @send-voice="keepVoice" target-name="Ivy Chen" @toggle-rich-mode="richMode = $event" />
    </article>
    <article data-composer-state="focused">
      <h2>Focused</h2>
      <FlareComposer ref="focused" toolbar-presentation="expanded" @send-voice="keepVoice" target-name="Ivy Chen" />
    </article>
    <article data-composer-state="multiline">
      <h2>Multi-line</h2>
      <FlareComposer v-model="multiline" toolbar-presentation="expanded" @send-voice="keepVoice" target-name="Ivy Chen" />
    </article>
    <article data-composer-state="reply">
      <h2>Reply</h2>
      <FlareComposer toolbar-presentation="expanded" @send-voice="keepVoice" target-name="Ivy Chen" reply-sender="Ivy Chen" reply-preview="Review the mobile state too." />
    </article>
    <article data-composer-state="upload">
      <h2>Upload</h2>
      <FlareComposer toolbar-presentation="expanded" @send-voice="keepVoice" target-name="Ivy Chen" :upload-items="uploadItems" />
    </article>
    <article data-composer-state="disabled">
      <h2>Disabled</h2>
      <FlareComposer toolbar-presentation="expanded" @send-voice="keepVoice" target-name="Ivy Chen" disabled status-hint="This conversation is unavailable." />
    </article>
    <article data-composer-state="readonly">
      <h2>Read only</h2>
      <FlareComposer toolbar-presentation="expanded" @send-voice="keepVoice" target-name="Ivy Chen" read-only status-hint="You can read messages but cannot send." />
    </article>
    </section>
  </DemoStage>
</template>

<style scoped>
#composer-surface-regression {
  display: grid;
  /* One column, so each composer really is desktop-wide. In two columns each one was about 520px
     and only looked like a desktop composer because the rules asked the window (FR-153); now that a
     composer reads its own box, a "desktop" snapshot has to be taken of a desktop-width composer. */
  grid-template-columns: minmax(0, 1fr);
  /* Each state must own its height: a stretched row would make one state's
     snapshot change whenever its neighbour grows. */
  align-items: start;
  gap: 20px;
  width: min(1120px, 100%);
  padding: 24px;
  color: var(--flare-color-text-primary);
  background: var(--flare-color-bg-secondary);
}

article {
  min-width: 0;
}

h2 {
  margin: 0 0 8px;
  color: var(--flare-color-text-secondary);
  font-size: 13px;
  font-weight: 600;
}

@media (max-width: 760px) {
  #composer-surface-regression {
    grid-template-columns: minmax(0, 1fr);
    gap: 16px;
    padding: 12px;
  }
}
</style>
