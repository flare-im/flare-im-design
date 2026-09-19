<script setup lang="ts">
import { computed } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readString } from "../../../../utils/contentData";
import { useFlareI18n } from "../../../../shared/i18n/useFlareI18n";
import FlareContactMessage from "../../standalone/FlareContactMessage.vue";

// Timeline adapter: contact/group card payload → the contract body.
const props = defineProps<{ content: ContentElem; isSelf: boolean }>();
const { t } = useFlareI18n();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "card");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

// A card names a person, never their account id: without a name it says what kind of card it is,
// and without a subtitle it shows none (the id is internal).
const name = computed(() => readString(payload.value, "title") || t("composer.card"));
const avatar = computed(() => readString(payload.value, "avatar", "avatarUrl"));
const subtitle = computed(() => readString(payload.value, "subtitle"));
</script>

<template>
  <div class="im-contact-card" role="group" :aria-label="[name, subtitle].filter(Boolean).join(', ')">
    <FlareContactMessage :name="name" :avatar-url="avatar" :subtitle="subtitle" />
  </div>
</template>

<style scoped>
.im-contact-card { display: inline-block; max-width: 100%; }
</style>
