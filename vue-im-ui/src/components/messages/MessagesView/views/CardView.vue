<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { PersonOutline } from "@vicons/ionicons5";
import { NIcon } from "naive-ui";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readString } from "../../../../utils/contentData";

const props = defineProps<{ content: ContentElem; isSelf: boolean }>();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "card");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

const title = computed(() => readString(payload.value, "title") || readString(payload.value, "id") || "名片");
const subtitle = computed(() => readString(payload.value, "subtitle", "cardType", "card_type") || "联系人");
const avatar = computed(() => readString(payload.value, "avatar", "avatarUrl"));
const cardType = computed(() => readString(payload.value, "cardType", "card_type"));
const cardId = computed(() => readString(payload.value, "id"));
const avatarFailed = ref(false);

watch(avatar, () => {
  avatarFailed.value = false;
});

const showAvatar = computed(() => Boolean(avatar.value) && !avatarFailed.value);
const typeLabel = computed(() => {
  const t = cardType.value.toLowerCase();
  if (t === "user") return "个人名片";
  if (t === "group") return "群名片";
  return cardType.value || "名片";
});
const avatarInitial = computed(() => Array.from(title.value.trim() || "名")[0] ?? "名");
</script>

<template>
  <div class="im-rich-message-card im-rich-message-card--compact im-contact-card">
    <header class="im-rich-message-card__header">
      <span class="im-rich-message-card__avatar" aria-hidden="true">
        <img
          v-if="showAvatar"
          :src="avatar"
          :alt="title"
          loading="lazy"
          @error="avatarFailed = true"
        />
        <span v-else-if="avatarInitial">{{ avatarInitial }}</span>
        <n-icon v-else :component="PersonOutline" />
      </span>
      <div class="im-rich-message-card__main">
        <span class="im-rich-message-card__kicker">{{ typeLabel }}</span>
        <strong class="im-rich-message-card__title">{{ title }}</strong>
        <p class="im-rich-message-card__subtitle">{{ subtitle }}</p>
      </div>
    </header>
    <footer class="im-rich-message-card__footer">
      <span>名片</span>
      <span v-if="cardId">{{ cardId }}</span>
    </footer>
  </div>
</template>

<style scoped>
.im-rich-message-card__avatar > span {
  transform: translateY(-0.5px);
}
</style>
