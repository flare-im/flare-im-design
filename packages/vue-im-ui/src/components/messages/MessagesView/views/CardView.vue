<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import { asRecord, readString } from "../../../../utils/contentData";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { useFlareI18n } from "../../../../shared/i18n/useFlareI18n";
import FlareContactMessage from "../../standalone/FlareContactMessage.vue";

// Timeline adapter: contact/group card payload → the contract body. A person's card is a control
// while the host listens to `cardOpen`: it reports the card's user id so the host opens the profile.
const props = defineProps<{ content: ContentElem; isSelf: boolean }>();
const emit = defineEmits<{ (event: "cardOpen", userId: string): void }>();
const { t } = useFlareI18n();
const instance = getCurrentInstance();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "card");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

// A card names a person, never their account id: without a name it says what kind of card it is,
// and without a subtitle it shows none (the id is internal).
const name = computed(() => readString(payload.value, "title") || t("composer.card"));
const avatar = computed(() => readString(payload.value, "avatar", "avatarUrl"));
const subtitle = computed(() => readString(payload.value, "subtitle"));
// The card's `id` is a user id for a person's card (`cardType` "user", or a card that names no type).
const cardType = computed(() => readString(payload.value, "cardType") || readString(asRecord(payload.value.attributes), "cardType"));
const userId = computed(() =>
  readString(payload.value, "userId") || (!cardType.value || cardType.value === "user" ? readString(payload.value, "id") : ""),
);
const listeners = computed(() =>
  userId.value && instance?.vnode.props?.onCardOpen ? { open: (id: string) => emit("cardOpen", id) } : {},
);
</script>

<template>
  <div class="im-contact-card" role="group" :aria-label="[name, subtitle].filter(Boolean).join(', ')">
    <FlareContactMessage :name="name" :avatar-url="avatar" :subtitle="subtitle" :user-id="userId" v-on="listeners" />
  </div>
</template>

<style scoped>
.im-contact-card { display: inline-block; max-width: 100%; }
</style>
