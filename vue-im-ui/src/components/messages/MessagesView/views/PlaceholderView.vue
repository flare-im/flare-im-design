<script setup lang="ts">
import { computed } from "vue";
import { DocumentTextOutline } from "../../../../shared/icon-glyphs";
import { NIcon } from "naive-ui";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readString } from "../../../../utils/contentData";
import { getContentDecodedPreview } from "../../../../utils/messagePreview";
import { useFlareI18n } from "../../../../shared/i18n/useFlareI18n";

const props = defineProps<{ content: ContentElem; isSelf: boolean }>();

const { t } = useFlareI18n();

// Burn-after-read / hard-delete tombstones are universal IM placeholders; the
// reason string carries the intent (locale-agnostic tokens + zh 阅后/焚).
const BURN_REASON_TOKENS = ["burn", "hard_delete", "hard_deleted", "阅后", "焚"];

const nested = computed(() => pickNestedPayload(props.content, "placeholder"));

const preview = computed(() => {
  const reason = readString(nested.value, "reason").trim().toLowerCase();
  if (reason && BURN_REASON_TOKENS.some((token) => reason.includes(token))) {
    return t("placeholder.burned");
  }
  const fallback = readString(nested.value, "fallbackText", "text");
  if (fallback) return fallback;
  return getContentDecodedPreview(props.content) || t("placeholder.fallback");
});
</script>

<template>
  <div class="im-placeholder">
    <n-icon :component="DocumentTextOutline" />
    <span>{{ preview }}</span>
  </div>
</template>

<style scoped>
.im-placeholder {
  display: flex;
  align-items: center;
  gap: 8px;
  color: var(--im-text-secondary);
  font-size: 13px;
}
</style>
