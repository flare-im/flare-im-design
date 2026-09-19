<script setup>
import { ref } from "vue";
import { FlareButton, FlareComposerMediaPreview } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const open = ref(false);
const kind = ref("image");
const sending = ref(false);
const last = ref("");
const items = {
  image: [
    { id: "a", kind: "image", name: "design-review.png", previewUrl: "/flare-im-ui-assets/demo/photo-1.jpg", mimeType: "image/png", size: 248_000 },
    { id: "b", kind: "image", name: "hero.png", previewUrl: "/flare-im-ui-assets/demo/photo-2.jpg", mimeType: "image/png", size: 512_000 },
  ],
  file: [{ id: "f", kind: "file", name: "release-notes.pdf", mimeType: "application/pdf", size: 24_576 }],
};

function show(nextKind) {
  kind.value = nextKind;
  open.value = true;
}
function submit(description) {
  sending.value = true;
  setTimeout(() => {
    sending.value = false;
    open.value = false;
    last.value = description ? `已发送 · 说明「${description}」` : "已发送";
  }, 400);
}
</script>

<template>
  <DemoStage>
    <div class="cmp-demo">
      <div class="cmp-demo__row">
        <FlareButton variant="secondary" @click="show('image')">预览图片</FlareButton>
        <FlareButton variant="secondary" @click="show('file')">预览文件</FlareButton>
      </div>
      <p v-if="last" class="cmp-demo__last">{{ last }}</p>
      <FlareComposerMediaPreview v-model:show="open" :kind="kind" :items="items[kind]" :loading="sending" @cancel="open = false" @submit="submit" />
    </div>
  </DemoStage>
</template>

<style scoped>
.cmp-demo { display: grid; gap: 10px; }
.cmp-demo__row { display: flex; gap: 8px; }
.cmp-demo__last { margin: 0; font-size: 13px; color: var(--flare-color-text-secondary); }
</style>
