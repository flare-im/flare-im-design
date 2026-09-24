<script setup lang="ts">
import { ref, computed, getCurrentInstance } from "vue";
import { NIcon } from "naive-ui";
import { EllipsisHorizontal, HeartOutline, LocationOutline } from "../../shared/icon-glyphs";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareImageGrid from "../messages/FlareImageGrid.vue";
import FlareCommentThread from "./FlareCommentThread.vue";
import FlareMomentActionPopover from "./FlareMomentActionPopover.vue";
import type { FlareMoment, FlareMomentComment } from "../../shared/contracts";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = defineProps<{ moment: FlareMoment; canDelete?: boolean; canReport?: boolean }>();
const emit = defineEmits<{
  (e: "like"): void;
  (e: "comment"): void;
  (e: "delete"): void;
  (e: "report"): void;
  (e: "openImage", index: number): void;
  (e: "selectAuthor", id: string): void;
  (e: "selectLiker", id: string): void;
  (e: "selectComment", comment: FlareMomentComment): void;
}>();

const menuOpen = ref(false);
const likes = computed(() => props.moment.likes ?? []);
const comments = computed(() => props.moment.comments ?? []);
const hasSocial = computed(() => likes.value.length > 0 || comments.value.length > 0);
const { t } = useFlareI18n();
const instance = getCurrentInstance();
// People and comments are controls only when the host does something with them.
const handles = (listener: "onSelectAuthor" | "onSelectLiker" | "onSelectComment"): boolean => Boolean(instance?.vnode.props?.[listener]);
function threadListeners(): Record<string, (...args: never[]) => void> {
  const listeners: Record<string, (...args: never[]) => void> = {};
  if (handles("onSelectComment")) listeners.select = (comment: FlareMomentComment) => emit("selectComment", comment);
  if (handles("onSelectAuthor")) listeners.selectAuthor = (id: string) => emit("selectAuthor", id);
  return listeners;
}

function onLike(): void {
  menuOpen.value = false;
  emit("like");
}
function onComment(): void {
  menuOpen.value = false;
  emit("comment");
}
function onDelete(): void {
  menuOpen.value = false;
  emit("delete");
}
function onReport(): void {
  menuOpen.value = false;
  emit("report");
}
</script>

<template>
  <article class="flare-moment">
    <!-- The avatar repeats the name button, so it stays out of the Tab sequence and away from screen readers. -->
    <button
      v-if="handles('onSelectAuthor')"
      type="button"
      class="flare-moment__avatar"
      tabindex="-1"
      aria-hidden="true"
      @click="emit('selectAuthor', moment.author.id)"
    >
      <FlareAvatar :user-id="moment.author.id" :display-name="moment.author.name" :avatar-url="moment.author.avatarUrl" :size="42" />
    </button>
    <div v-else class="flare-moment__avatar">
      <FlareAvatar :user-id="moment.author.id" :display-name="moment.author.name" :avatar-url="moment.author.avatarUrl" :size="42" />
    </div>

    <div class="flare-moment__body">
      <button v-if="handles('onSelectAuthor')" type="button" class="flare-moment__name is-interactive" @click="emit('selectAuthor', moment.author.id)">{{ moment.author.name }}</button>
      <div v-else class="flare-moment__name">{{ moment.author.name }}</div>
      <p v-if="moment.text" class="flare-moment__text">{{ moment.text }}</p>

      <div v-if="moment.images && moment.images.length" class="flare-moment__media">
        <FlareImageGrid :images="moment.images" @open="(i) => emit('openImage', i)" />
      </div>

      <div v-if="moment.location" class="flare-moment__location">
        <n-icon aria-hidden="true" :size="13" :component="LocationOutline" />{{ moment.location }}
      </div>

      <div class="flare-moment__meta">
        <span class="flare-moment__time">{{ moment.time }}</span>
        <div class="flare-moment__actions">
          <transition name="flare-moment-pop">
            <FlareMomentActionPopover
              v-if="menuOpen"
              class="flare-moment__pop"
              :liked="moment.likedBySelf"
              :can-delete="canDelete"
              :can-report="canReport"
              @like="onLike"
              @comment="onComment"
              @delete="onDelete"
              @report="onReport"
            />
          </transition>
          <button
            type="button"
            class="flare-moment__more"
            :class="{ 'is-open': menuOpen }"
            :aria-label="t('moment.more')"
            :title="t('moment.more')"
            @click="menuOpen = !menuOpen"
          >
            <n-icon aria-hidden="true" :size="16" :component="EllipsisHorizontal" />
          </button>
        </div>
      </div>

      <div v-if="hasSocial" class="flare-moment__social">
        <div v-if="likes.length" class="flare-moment__likes">
          <n-icon aria-hidden="true" :size="14" :component="HeartOutline" class="flare-moment__likes-ico" />
          <span class="flare-moment__likers" role="group" :aria-label="t('moment.likedBy')">
            <template v-for="(l, i) in likes" :key="l.id"
              ><button v-if="handles('onSelectLiker')" type="button" class="flare-moment__liker is-interactive" @click="emit('selectLiker', l.id)">{{ l.name }}</button
              ><span v-else class="flare-moment__liker">{{ l.name }}</span
              ><span v-if="i < likes.length - 1">, </span></template>
          </span>
        </div>
        <div v-if="likes.length && comments.length" class="flare-moment__hairline" />
        <FlareCommentThread v-if="comments.length" :comments="comments" v-on="threadListeners()" />
      </div>
    </div>
  </article>
</template>

<style scoped>
.flare-moment {
  display: flex;
  gap: 12px;
  padding: 16px;
  border-radius: var(--flare-size-radius-2xl);
  background: var(--flare-color-bg-elevated);
  box-shadow: var(--flare-shadow-card);
}
.flare-moment__avatar { align-self: flex-start; border: none; background: none; padding: 0; flex: 0 0 auto; line-height: 0; }
button.flare-moment__avatar { cursor: pointer; }
.flare-moment__body { flex: 1; min-width: 0; }
.flare-moment__name {
  display: block;
  padding: 0;
  border: 0;
  background: none;
  font: inherit;
  font-size: 15px;
  font-weight: 600;
  text-align: start;
  color: var(--flare-color-primary-text);
  width: fit-content;
}
.flare-moment__name.is-interactive { cursor: pointer; }
.flare-moment__name:focus-visible,
.flare-moment__liker:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; border-radius: 2px; }
.flare-moment__text {
  margin: 4px 0 0;
  font-size: 15px;
  line-height: 1.55;
  color: var(--flare-color-text-primary);
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}
.flare-moment__media { margin-top: var(--flare-size-spacing-2sm); }
.flare-moment__location {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  margin-top: 8px;
  font-size: 12px;
  color: var(--flare-color-primary-text);
}
.flare-moment__meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: var(--flare-size-spacing-2sm);
}
.flare-moment__time { font-size: 12px; color: var(--flare-color-text-tertiary); }
/*
 * The popover hangs off this 30px wrapper, which is the whole width it has to offer. An absolutely
 * positioned box with `width: auto` is shrink-to-fit — `min(max(min-content, available),
 * max-content)` — so 30px is what *available* means here, and the popover has to carry its own
 * width in `min-content`. It once did not, and came out as a 30px column of folded-over glyphs
 * (FR-164); the two declarations that cost it its `min-content` are gone, and named in that file.
 */
.flare-moment__actions { position: relative; display: flex; align-items: center; }
.flare-moment__more {
  width: 30px;
  height: 24px;
  border: none;
  border-radius: 6px;
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-secondary);
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  transition: background 0.15s ease, color 0.15s ease;
}
.flare-moment__more.is-open,
.flare-moment__more:hover { background: var(--flare-color-bg-selected); color: var(--flare-color-primary-text); }
/* 36px = the 30px ··· button the popover slides out of, plus a 6px gap. */
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
/* 互动区与正文之间要有分界，但一条线就够 —— 改前这里是白卡里再套一张灰色圆角卡，
   同一条动态被切成两块表面，点赞和评论看着比正文还像个独立的东西。
   卡片已经是这条动态的容器了，里面不需要第二个容器。 */
.flare-moment__social {
  margin-top: var(--flare-size-spacing-md);
  padding-top: var(--flare-size-spacing-sm);
  border-top: 1px solid var(--flare-color-border-secondary);
}
.flare-moment__likes {
  display: flex;
  align-items: baseline;
  gap: 6px;
  font-size: 13px;
  line-height: 1.5;
}
.flare-moment__likes-ico { color: var(--flare-color-error-text); position: relative; top: 2px; flex: 0 0 auto; }
.flare-moment__likers { color: var(--flare-color-primary-text); }
.flare-moment__liker { padding: 0; border: 0; background: none; font: inherit; color: inherit; }
.flare-moment__liker.is-interactive { cursor: pointer; }
.flare-moment__liker.is-interactive:hover { text-decoration: underline; }
.flare-moment__hairline {
  height: 1px;
  margin: 7px 0;
  background: color-mix(in srgb, var(--flare-color-text-tertiary) 22%, transparent);
}
</style>
