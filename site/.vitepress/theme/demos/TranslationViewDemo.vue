<script setup>
import FlareTranslationView from "@flare-im/vue-ui/components/messages/FlareTranslationView.vue";
import DemoStage from "./DemoStage.vue";
</script>
<template>
  <DemoStage>
    <div class="stack">
      <div class="bubble">
        Let's ship the four-platform parity before Friday's review.
        <FlareTranslationView
          translated="我们赶在周五评审前把四端奇偶做完吧。"
          original="Let's ship the four-platform parity before Friday's review."
          provider="DeepL"
        />
      </div>
      <div class="bubble">
        ¿Puedes revisar el pull request?
        <FlareTranslationView translated="正在翻译…" pending />
      </div>
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 14px; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.bubble {
  align-self: flex-start; max-width: 340px; padding: 10px 14px; border-radius: 14px 14px 14px 4px;
  background: var(--flare-color-bg-primary); color: var(--flare-color-text-primary);
  border: 1px solid var(--flare-color-border-primary); font-size: 14px; line-height: 1.5;
}
</style>
