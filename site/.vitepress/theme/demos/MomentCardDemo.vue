<script setup>
import { reactive } from "vue";
import FlareMomentCard from "flare-core-vue-im-ui/components/moments/FlareMomentCard.vue";
import DemoStage from "./DemoStage.vue";
const sw = (a, b) => "data:image/svg+xml;utf8," + encodeURIComponent(
  `<svg xmlns='http://www.w3.org/2000/svg' width='120' height='120'><defs><linearGradient id='g' x1='0' y1='0' x2='1' y2='1'><stop offset='0' stop-color='${a}'/><stop offset='1' stop-color='${b}'/></linearGradient></defs><rect width='120' height='120' fill='url(%23g)'/></svg>`.replace(/#/g, "%23"));
const imgs = [["#a78bfa", "#7c3aed"], ["#fca5a5", "#ef4444"], ["#93c5fd", "#2563eb"], ["#6ee7b7", "#059669"], ["#fcd34d", "#d97706"]].map(([a, b]) => ({ url: sw(a, b) }));
const state = reactive({
  feed: [
    {
      id: "1", author: { id: "ivy", name: "Ivy Chen" }, time: "2 小时前", location: "上海 · 徐汇",
      text: "周末去看了场展,色彩和留白都很讲究。分享几张 📷",
      images: imgs,
      likedBySelf: false,
      likes: [{ id: "leo", name: "Leo Wang" }, { id: "mia", name: "Mia Zhou" }, { id: "ada", name: "Ada Li" }],
      comments: [
        { id: "c1", author: { id: "leo", name: "Leo Wang" }, text: "第三张构图绝了！" },
        { id: "c2", author: { id: "ivy", name: "Ivy Chen" }, replyToName: "Leo Wang", text: "哈哈那张我也最喜欢" },
      ],
    },
    {
      id: "2", author: { id: "sam", name: "Sam Gao" }, time: "昨天",
      text: "四端奇偶终于全绿，收工 🎉",
      likedBySelf: true,
      likes: [{ id: "ivy", name: "Ivy Chen" }],
      comments: [],
    },
  ],
});
function toggleLike(m) {
  m.likedBySelf = !m.likedBySelf;
  const meIdx = m.likes.findIndex((l) => l.id === "me");
  if (m.likedBySelf && meIdx < 0) m.likes.push({ id: "me", name: "你" });
  else if (!m.likedBySelf && meIdx >= 0) m.likes.splice(meIdx, 1);
}
</script>
<template>
  <DemoStage>
    <div class="feed">
      <FlareMomentCard
        v-for="m in state.feed" :key="m.id" :moment="m"
        @like="toggleLike(m)" @comment="() => {}" @open-image="() => {}"
      />
    </div>
  </DemoStage>
</template>
<style scoped>
.feed { max-width: 420px; margin: 0 auto; border-radius: 14px; overflow: hidden; background: var(--flare-color-bg-secondary); }
.feed > * + * { border-top: 8px solid var(--flare-color-bg-secondary); }
</style>
