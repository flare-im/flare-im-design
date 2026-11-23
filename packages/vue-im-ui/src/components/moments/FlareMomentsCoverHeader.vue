<script setup lang="ts">
import { getCurrentInstance } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

defineProps<{
  userId: string;
  name: string;
  coverUrl?: string;
  avatarUrl?: string;
  signature?: string;
  /** Compact panel inset from the feed edges. */
  appearance?: "default" | "inset";
}>();
const emit = defineEmits<{
  (e: "editCover"): void;
  (e: "avatar"): void;
}>();
const { t } = useFlareI18n();
const instance = getCurrentInstance();
// Changing the cover and opening the avatar are controls only when the host handles them.
const handles = (listener: "onEditCover" | "onAvatar"): boolean => Boolean(instance?.vnode.props?.[listener]);
</script>

<template>
  <header class="flare-moments-cover" :class="{ 'flare-moments-cover--empty': !coverUrl, 'flare-moments-cover--inset': appearance === 'inset' }">
    <component
      v-if="coverUrl"
      :is="handles('onEditCover') ? 'button' : 'div'"
      :type="handles('onEditCover') ? 'button' : undefined"
      class="flare-moments-cover__photo"
      :class="{ 'is-interactive': handles('onEditCover') }"
      :style="{ backgroundImage: `url(${coverUrl})` }"
      :aria-label="handles('onEditCover') ? t('moment.editCover') : undefined"
      @click="handles('onEditCover') && emit('editCover')"
    />

    <div class="flare-moments-cover__id">
      <!-- Without a photo the change-cover affordance has no photo to sit on top of, so it
           takes its place at the end of the identity row instead of floating over a blank band. -->
      <button v-if="handles('onAvatar')" type="button" class="flare-moments-cover__avatar" @click="emit('avatar')">
        <FlareAvatar :user-id="userId" :display-name="name" :avatar-url="avatarUrl" :size="coverUrl ? 56 : 48" />
      </button>
      <div v-else class="flare-moments-cover__avatar">
        <FlareAvatar :user-id="userId" :display-name="name" :avatar-url="avatarUrl" :size="coverUrl ? 56 : 48" />
      </div>
      <div class="flare-moments-cover__text">
        <div class="flare-moments-cover__name">{{ name }}</div>
        <div v-if="signature" class="flare-moments-cover__sig">{{ signature }}</div>
      </div>
      <button
        v-if="!coverUrl && handles('onEditCover')"
        type="button"
        class="flare-moments-cover__hint"
        @click="emit('editCover')"
      >{{ t("moment.editCover") }}</button>
    </div>
  </header>
</template>

<style scoped>
.flare-moments-cover { position: relative; padding-bottom: 20px; }
.flare-moments-cover__photo {
  display: block;
  width: 100%;
  height: 240px;
  border: none;
  padding: 0;
  background-color: var(--flare-color-bg-tertiary);
  background-size: cover;
  background-position: center;
  position: relative;
}
/* Bottom scrim so the name + avatar stay legible over any cover image. */
.flare-moments-cover__photo::after {
  content: "";
  position: absolute;
  inset: 0;
  background: linear-gradient(to bottom, transparent 45%, rgba(15, 12, 25, 0.42));
  pointer-events: none;
}
.flare-moments-cover__hint {
  display: inline-flex;
  align-items: center;
  flex: none;
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm);
  border-radius: var(--flare-size-radius-md);
  background: transparent;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
  transition: background var(--flare-transition-fast);
  border: 0;
  cursor: pointer;
  white-space: nowrap;
  position: relative;
}
.flare-moments-cover__hint::after { content: ''; position: absolute; inset: 50% auto auto 50%; transform: translate(-50%, -50%); width: max(100%, var(--flare-size-layout-touch-target)); height: max(100%, var(--flare-size-layout-touch-target)); }
.flare-moments-cover__hint:focus-visible,
.flare-moments-cover__avatar:focus-visible,
.flare-moments-cover__photo:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-moments-cover__hint:hover { background: var(--flare-color-bg-hover); }
/* Name + avatar sit OVER the cover's lower scrim (white text stays legible on
   any cover), with the avatar overhanging the cover's bottom edge. */
.flare-moments-cover__id {
  display: flex;
  align-items: flex-end;
  justify-content: flex-end;
  gap: var(--flare-size-spacing-2md);
  padding: 0 16px;
  margin-top: -62px;
  position: relative;
  z-index: 1;
}
.flare-moments-cover__text {
  order: 1;
  text-align: right;
  padding-bottom: 20px;
  min-width: 0;
}
.flare-moments-cover__name {
  font-size: 18px;
  font-weight: 700;
  color: #fff;
  text-shadow: 0 1px 6px rgba(0, 0, 0, 0.45);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-moments-cover__sig {
  margin-top: 5px;
  font-size: 12.5px;
  color: rgba(255, 255, 255, 0.88);
  text-shadow: 0 1px 4px rgba(0, 0, 0, 0.4);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-moments-cover__photo.is-interactive,
button.flare-moments-cover__avatar { cursor: pointer; }
.flare-moments-cover__avatar {
  order: 2;
  flex: 0 0 auto;
  border: none;
  border-radius: var(--flare-size-radius-full);
  padding: 0;
  background: none;
  overflow: hidden;
  box-shadow: 0 0 0 2px var(--flare-color-bg-primary);
  line-height: 0;
}
/* Without a cover photo the header stays quiet: a short neutral band instead of a brand gradient,
   and the name reads in the normal text colours because there is no image to lift it off. */
/* No cover photo: the header is a compact identity row read left to right, sized by its
   content and sitting on the tertiary surface. It used to keep the photo geometry — a 140px
   band with the name right-aligned and pulled up onto where the scrim would be — but right
   alignment, the overlap and the overhang only mean something with a photo under them. With
   no photo they left ~110px of empty band above a name glued to its bottom-right corner. */
.flare-moments-cover--empty { padding-bottom: 0; background: var(--flare-color-bg-primary); border-bottom: 1px solid var(--flare-color-border-secondary); }
.flare-moments-cover--empty .flare-moments-cover__photo { display: none; }
.flare-moments-cover--empty .flare-moments-cover__id {
  flex-direction: row;
  align-items: center;
  justify-content: flex-start;
  gap: var(--flare-size-spacing-md);
  margin-top: 0;
  padding: var(--flare-size-spacing-lg);
}
/* The avatar leads the row; the name follows it. */
.flare-moments-cover--empty .flare-moments-cover__avatar,
.flare-moments-cover--empty button.flare-moments-cover__avatar { order: 0; outline: none; }
.flare-moments-cover--empty button.flare-moments-cover__avatar:focus-visible { outline: 2px solid var(--flare-color-border-selected); }
.flare-moments-cover--empty .flare-moments-cover__text {
  order: 1;
  flex: 1;
  text-align: left;
  padding-bottom: 0;
}
.flare-moments-cover--empty .flare-moments-cover__hint {
  order: 2;
}
.flare-moments-cover--empty .flare-moments-cover__name { color: var(--flare-color-text-primary); text-shadow: none; font-size: var(--flare-size-font-size-lg); }
.flare-moments-cover--empty .flare-moments-cover__sig { color: var(--flare-color-text-secondary); text-shadow: none; }
.flare-moments-cover--inset {
  margin: 0 var(--flare-size-spacing-lg) var(--flare-size-spacing-md);
}
.flare-moments-cover--inset .flare-moments-cover__photo {
  border-radius: var(--flare-size-radius-xl);
  overflow: hidden;
}
.flare-moments-cover--inset.flare-moments-cover--empty {
  border: 1px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-xl);
  background: var(--flare-color-bg-primary);
}
.flare-moments-cover--inset.flare-moments-cover--empty .flare-moments-cover__hint {
  background: var(--flare-color-bg-primary);
  color: var(--flare-color-text-link);
}
.flare-moments-cover--inset.flare-moments-cover--empty .flare-moments-cover__hint:hover {
  background: var(--flare-color-bg-hover);
}
</style>
