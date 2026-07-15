<script setup>
import FlareEmojiPicker from "flare-core-vue-im-ui/components/composer/FlareEmojiPicker.vue";
import DemoStage from "./DemoStage.vue";
const categories = [
  { key: "smileys", label: "笑脸", symbol: "😀", emojis: "😀 😁 😂 🤣 😊 😇 🙂 😉 😍 😘 😜 🤪 😎 🤩 🥳 😏 😌 😔 😴 🤤 😪 😷 🤒 🤕 🤢 🤮 🥴 😵 🤯 🤠".split(" ") },
  { key: "gestures", label: "手势", symbol: "👍", emojis: "👍 👎 👊 ✊ 🤛 🤜 👏 🙌 👐 🤲 🙏 ✌️ 🤞 🤟 🤘 👌 🤏 ✋ 🖐️ 🖖 👋 💪".split(" ") },
  { key: "hearts", label: "爱心", symbol: "❤️", emojis: "❤️ 🧡 💛 💚 💙 💜 🖤 🤍 🤎 💔 ❣️ 💕 💞 💓 💗 💖 💘 💝".split(" ") },
  { key: "animals", label: "动物", symbol: "🐶", emojis: "🐶 🐱 🐭 🐹 🐰 🦊 🐻 🐼 🐨 🐯 🦁 🐮 🐷 🐸 🐵 🐔 🐧 🐦 🦄 🐝".split(" ") },
];
const recents = "😂 👍 ❤️ 🎉 🙏 🔥".split(" ");
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareEmojiPicker :categories="categories" :recents="recents" skin-tones @select="() => {}" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; justify-content: center; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
