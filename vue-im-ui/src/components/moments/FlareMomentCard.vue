<script setup lang="ts">
import { ref, computed } from "vue";
import { NIcon } from "naive-ui";
import { EllipsisHorizontal, HeartOutline, LocationOutline } from "@vicons/ionicons5";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareImageGrid from "../messages/FlareImageGrid.vue";
import FlareCommentThread from "./FlareCommentThread.vue";
import FlareMomentActionPopover from "./FlareMomentActionPopover.vue";
import type { FlareMoment, FlareMomentComment } from "../../shared/contracts";

const props = defineProps<{ moment: FlareMoment }>();
const emit = defineEmits<{
  (e: "like"): void;
  (e: "comment"): void;
  (e: "openImage", index: number): void;
  (e: "selectAuthor", id: string): void;
  (e: "selectLiker", id: string): void;
  (e: "selectComment", comment: FlareMomentComment): void;
}>();

const menuOpen = ref(false);
const likes = computed(() => props.moment.likes ?? []);
const comments = computed(() => props.moment.comments ?? []);
const hasSocial = computed(() => likes.value.length > 0 || comments.value.length > 0);

function onLike(): void {
  menuOpen.value = false;
  emit("like");
}
function onComment(): void {
  menuOpen.value = false;
  emit("comment");
}
</script>

<template>
  <article class="flare-moment">
    <button type="button" class="flare-moment__avatar" @click="emit('selectAuthor', moment.author.id)">
      <FlareAvatar :user-id="moment.author.id" :display-name="moment.author.name" :avatar-url="moment.author.avatarUrl" :size="42" />
    </button>

    <div class="flare-moment__body">
      <div class="flare-moment__name" @click="emit('selectAuthor', moment.author.id)">{{ moment.author.name }}</div>
      <p v-if="moment.text" class="flare-moment__text">{{ moment.text }}</p>

      <div v-if="moment.images && moment.images.length" class="flare-moment__media">
        <FlareImageGrid :images="moment.images" @open="(i) => emit('openImage', i)" />
      </div>

      <div v-if="moment.location" class="flare-moment__location">
        <n-icon :size="13" :component="LocationOutline" />{{ moment.location }}
      </div>

      <div class="flare-moment__meta">
        <span class="flare-moment__time">{{ moment.time }}</span>
        <div class="flare-moment__actions">
          <transition name="flare-moment-pop">
            <FlareMomentActionPopover
              v-if="menuOpen"
              class="flare-moment__pop"
              :liked="moment.likedBySelf"
              @like="onLike"
              @comment="onComment"
            />
          </transition>
          <button type="button" class="flare-moment__more" :class="{ 'is-open': menuOpen }" @click="menuOpen = !menuOpen">
            <n-icon :size="16" :component="EllipsisHorizontal" />
          </button>
        </div>
      </div>

      <div v-if="hasSocial" class="flare-moment__social">
        <div v-if="likes.length" class="flare-moment__likes">
          <n-icon :size="14" :component="HeartOutline" class="flare-moment__likes-ico" />
          <span class="flare-moment__likers">
            <template v-for="(l, i) in likes" :key="l.id"
              ><a class="flare-moment__liker" @click="emit('selectLiker', l.id)">{{ l.name }}</a
              ><span v-if="i < likes.length - 1">, </span></template>
          </span>
        </div>
        <div v-if="likes.length && comments.length" class="flare-moment__hairline" />
        <FlareCommentThread
          v-if="comments.length"
          :comments="comments"
          @select="(c) => emit('selectComment', c)"
          @select-author="(id) => emit('selectAuthor', id)"
        />
      </div>
    </div>
  </article>
</template>

<style scoped>
.flare-moment {
  display: flex;
  gap: 12px;
  padding: 16px;
  background: var(--flare-color-bg-primary, #fff);
}
.flare-moment__avatar { border: none; background: none; padding: 0; cursor: pointer; flex: 0 0 auto; line-height: 0; }
.flare-moment__body { flex: 1; min-width: 0; }
.flare-moment__name {
  font-size: 15px;
  font-weight: 600;
  color: var(--flare-color-primary, #7c3aed);
  cursor: pointer;
  width: fit-content;
}
.flare-moment__text {
  margin: 4px 0 0;
  font-size: 15px;
  line-height: 1.55;
  color: var(--flare-color-text-primary, #15131c);
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}
.flare-moment__media { margin-top: 10px; }
.flare-moment__location {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  margin-top: 8px;
  font-size: 12px;
  color: var(--flare-color-primary, #7c3aed);
  opacity: 0.8;
}
.flare-moment__meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 10px;
}
.flare-moment__time { font-size: 12px; color: var(--flare-color-text-tertiary, #a7a2b4); }
.flare-moment__actions { position: relative; display: flex; align-items: center; }
.flare-moment__more {
  width: 30px;
  height: 24px;
  border: none;
  border-radius: 6px;
  background: var(--flare-color-bg-secondary, #f6f5fb);
  color: var(--flare-color-text-secondary, #6b6780);
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  transition: background 0.15s ease, color 0.15s ease;
}
.flare-moment__more.is-open,
.flare-moment__more:hover { background: var(--flare-color-bg-selected, #f1eaff); color: var(--flare-color-primary, #7c3aed); }
.flare-moment__pop {
  position: absolute;
  right: 36px;
  top: 50%;
  transform: translateY(-50%);
  z-index: 3;
}
.flare-moment-pop-enter-active,
.flare-moment-pop-leave-active { transition: opacity 0.15s ease, transform 0.15s ease; }
.flare-moment-pop-enter-from,
.flare-moment-pop-leave-to { opacity: 0; transform: translateY(-50%) translateX(6px); }
.flare-moment__social {
  margin-top: 10px;
  padding: 8px 12px;
  border-radius: var(--flare-size-radius-lg, 10px);
  background: var(--flare-color-bg-secondary, #f6f5fb);
}
.flare-moment__likes {
  display: flex;
  align-items: baseline;
  gap: 6px;
  font-size: 13px;
  line-height: 1.5;
}
.flare-moment__likes-ico { color: var(--flare-color-error, #ef4444); position: relative; top: 2px; flex: 0 0 auto; }
.flare-moment__likers { color: var(--flare-color-primary, #7c3aed); }
.flare-moment__liker { cursor: pointer; }
.flare-moment__liker:hover { text-decoration: underline; }
.flare-moment__hairline {
  height: 1px;
  margin: 7px 0;
  background: color-mix(in srgb, var(--flare-color-text-tertiary, #a7a2b4) 22%, transparent);
}
</style>
