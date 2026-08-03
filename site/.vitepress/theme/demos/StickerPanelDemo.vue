<script setup>
import FlareStickerPanel from "@flare-im/vue-ui/components/composer/FlareStickerPanel.vue";
import DemoStage from "./DemoStage.vue";
const mk = (emojis) => emojis.map((e, i) => ({ id: `${e}-${i}`, placeholder: e }));
const packs = [
  { key: "cat", label: "喵星人", coverEmoji: "🐱", stickers: mk("😺 😸 😹 😻 😼 😽 🙀 😿 😾 🐱 🐈 🐾".split(" ")) },
  { key: "party", label: "庆祝", coverEmoji: "🎉", stickers: mk("🎉 🎊 🥳 🎈 🎁 🍰 🎂 🧨 ✨ 🎇 🎆 🪅".split(" ")) },
  { key: "food", label: "美食", coverEmoji: "🍜", stickers: mk("🍜 🍕 🍔 🍟 🌮 🍣 🍩 🍪 🧁 🍦 🍺 ☕".split(" ")) },
];
const recents = mk("🎉 😻 🍜 🥳".split(" "));
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareStickerPanel :packs="packs" :recents="recents" @select="() => {}" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; justify-content: center; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
