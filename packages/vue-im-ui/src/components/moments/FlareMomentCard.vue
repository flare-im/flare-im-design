<script setup lang="ts">
import { ref, computed, getCurrentInstance, type Component } from "vue";
import { NIcon } from "naive-ui";
import { EllipsisHorizontal, HeartOutline, HeartDislikeOutline, LocationOutline } from "../../shared/icon-glyphs";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareImageGrid from "../messages/FlareImageGrid.vue";
import FlareCommentThread from "./FlareCommentThread.vue";
import FlareActionMenu from "../general/FlareActionMenu.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import type { FlareActionItem } from '../../shared/contracts/action-menu';
import type { FlareMoment, FlareMomentComment } from "../../shared/contracts";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(defineProps<{ moment: FlareMoment; canDelete?: boolean; canComment?: boolean; canLike?: boolean; canReport?: boolean; appearance?: 'card' | 'feed' | 'detail'; focusCommentId?: string }>(), { appearance: 'card', canComment: undefined, canLike: undefined });
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
const expanded = ref(false);
const longText = computed(() => (props.moment.text?.length ?? 0) > 280 || (props.moment.text?.split('\n').length ?? 0) > 6);
const likes = computed(() => props.moment.likes ?? []);
const comments = computed(() => props.moment.comments ?? []);
const hasSocial = computed(() => likes.value.length > 0 || comments.value.length > 0);
const { t } = useFlareI18n();
const instance = getCurrentInstance();
// People and comments are controls only when the host does something with them. Like and comment follow the same
// rule: a host turns a feature off by not taking its intent, and the card then does not offer it.
const handles = (listener: "onSelectAuthor" | "onSelectLiker" | "onSelectComment" | "onLike" | "onComment"): boolean =>
  Boolean(instance?.vnode.props?.[listener]) &&
  (!(listener === "onComment" || listener === "onSelectComment") || props.canComment !== false) &&
  (listener !== "onLike" || props.canLike !== false);
// Read from the vnode at render time (like `handles` above), so a host that binds a listener later gets the action.
const hasActions = (): boolean => handles("onLike") || handles("onComment") || Boolean(props.canDelete) || Boolean(props.canReport);
function threadListeners(): Record<string, (...args: never[]) => void> {
  const listeners: Record<string, (...args: never[]) => void> = {};
  if (handles("onSelectComment")) listeners.select = (comment: FlareMomentComment) => emit("selectComment", comment);
  if (handles("onSelectAuthor")) listeners.selectAuthor = (id: string) => emit("selectAuthor", id);
  return listeners;
}

function menuItems(): FlareActionItem<string | Component>[] {
  return [
    { id: 'like', label: t(props.moment.likedBySelf ? 'moment.unlike' : 'moment.like'), icon: props.moment.likedBySelf ? HeartDislikeOutline : HeartOutline, visible: handles('onLike') },
    { id: 'comment', label: t('moment.comment'), icon: 'comment', visible: handles('onComment') },
    { id: 'delete', label: t('moment.delete'), icon: 'delete', visible: Boolean(props.canDelete), danger: true, group: 'manage' },
    { id: 'report', label: t('moment.report'), icon: 'report', visible: !props.canDelete && Boolean(props.canReport), group: 'manage' },
  ];
}
function selectAction(id: string): void {
  if (id === 'like') emit('like');
  else if (id === 'comment') emit('comment');
  else if (id === 'delete') emit('delete');
  else if (id === 'report') emit('report');
}
</script>

<template>
  <article class="flare-moment" :class="`flare-moment--${appearance}`">
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
      <header class="flare-moment__heading">
        <button v-if="handles('onSelectAuthor')" type="button" class="flare-moment__name is-interactive" @click="emit('selectAuthor', moment.author.id)">{{ moment.author.name }}</button>
        <div v-else class="flare-moment__name">{{ moment.author.name }}</div>
        <span v-if="moment.time" class="flare-moment__time">{{ moment.time }}</span>
        <div v-if="hasActions()" class="flare-moment__actions">
          <FlareActionMenu v-model:open="menuOpen" :items="menuItems()" :label="t('moment.more')" placement="left" orientation="horizontal" @select="selectAction">
            <FlareIconButton
              class="flare-moment__more"
              :icon="EllipsisHorizontal"
              size="sm"
              shape="square"
              variant="plain"
              :ariaLabel="t('moment.more')"
              :title="t('moment.more')"
            />
          </FlareActionMenu>
        </div>
      </header>
      <p v-if="moment.text" class="flare-moment__text" :class="{ 'is-clamped': appearance !== 'detail' && longText && !expanded }">{{ moment.text }}</p>
      <button v-if="longText && appearance !== 'detail'" type="button" class="flare-moment__expand" :aria-expanded="expanded" @click="expanded = !expanded">{{ t(expanded ? 'pluginView.collapse' : 'pluginView.expand') }}</button>

      <div v-if="moment.images && moment.images.length" class="flare-moment__media">
        <FlareImageGrid :images="moment.images" @open="(i) => emit('openImage', i)" />
      </div>

      <div v-if="moment.location" class="flare-moment__location">
        <n-icon aria-hidden="true" size="var(--flare-size-icon-size-sm)" :component="LocationOutline" />{{ moment.location }}
      </div>

      <div v-if="hasSocial || appearance === 'detail'" class="flare-moment__social">
        <div v-if="likes.length" class="flare-moment__likes">
          <n-icon aria-hidden="true" size="var(--flare-size-icon-size-sm)" :component="HeartOutline" class="flare-moment__likes-ico" />
          <span class="flare-moment__likers" role="group" :aria-label="t('moment.likedBy')">
            <template v-for="(l, i) in likes" :key="l.id"
              ><button v-if="handles('onSelectLiker')" type="button" class="flare-moment__liker is-interactive" @click="emit('selectLiker', l.id)">{{ l.name }}</button
              ><span v-else class="flare-moment__liker">{{ l.name }}</span
              ><span v-if="i < likes.length - 1">, </span></template>
          </span>
        </div>
        <h3 v-if="appearance === 'detail'" class="flare-moment__comments-heading">{{ t('moment.commentsTitle') }} <span>{{ comments.length }}</span></h3>
        <p v-if="appearance === 'detail' && !comments.length" class="flare-moment__comments-empty">{{ t('moment.noComments') }}</p>
        <FlareCommentThread v-if="comments.length" :appearance="appearance === 'detail' ? 'detail' : 'inline'" :key="handles('onSelectComment') ? 'interactive' : 'static'" :comments="comments" :focus-comment-id="focusCommentId" v-on="threadListeners()" />
      </div>
    </div>
  </article>
</template>

<style scoped>
.flare-moment {
  display: flex;
  min-width: 0;
  gap: 12px;
  padding: 16px;
  border-radius: var(--flare-size-radius-2xl);
  background: var(--flare-color-bg-elevated);
  box-shadow: var(--flare-shadow-card);
}
.flare-moment__avatar { align-self: flex-start; border: none; background: none; padding: 0; flex: 0 0 auto; line-height: 0; }
.flare-moment--detail { display: block; border-radius: 0; box-shadow: none; position: relative; }
.flare-moment--detail .flare-moment__avatar { position: absolute; inset-inline-start: var(--flare-size-spacing-lg); top: var(--flare-size-spacing-lg); }
.flare-moment--detail .flare-moment__heading { min-height: 42px; padding-inline-start: calc(42px + var(--flare-size-spacing-md)); }
.flare-moment--detail .flare-moment__text { margin-top: var(--flare-size-spacing-sm); }
.flare-moment__comments-heading { display: flex; align-items: baseline; gap: var(--flare-size-spacing-xs); margin: var(--flare-size-spacing-sm) 0 0; font-size: var(--flare-size-font-size-md); font-weight: var(--flare-size-font-weight-semibold); }
.flare-moment__comments-heading span, .flare-moment__comments-empty { color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-sm); font-weight: var(--flare-size-font-weight-regular); }
.flare-moment__comments-empty { margin: var(--flare-size-spacing-sm) 0; }
.flare-moment--feed { border-radius: 0; box-shadow: none; border-bottom: 1px solid var(--flare-color-border-secondary); }
.flare-moment__text.is-clamped { display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 6; overflow: hidden; }
.flare-moment__expand { min-height: var(--flare-size-layout-touch-target); border: 0; padding: 0; background: transparent; color: var(--flare-color-primary-text); font: inherit; cursor: pointer; }
.flare-moment__expand:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
button.flare-moment__avatar { cursor: pointer; }
.flare-moment__body { flex: 1; min-width: 0; }
.flare-moment__heading { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); min-height: var(--flare-size-layout-control-height-sm); }
.flare-moment__name {
  display: block;
  min-width: 0;
  margin-inline-end: auto;
  padding: 0;
  border: 0;
  background: none;
  font: inherit;
  font-size: var(--flare-size-font-size-lg);
  font-weight: var(--flare-size-font-weight-semibold);
  text-align: start;
  color: var(--flare-color-text-primary);
  overflow-wrap: anywhere;
}
.flare-moment__name.is-interactive { cursor: pointer; }
.flare-moment__name.is-interactive:hover { text-decoration: underline; }
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
.flare-moment__time { flex: 0 1 auto; min-width: 0; max-width: 45%; overflow-wrap: anywhere; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary); }
.flare-moment__actions { display: flex; align-items: center; flex: none; }
/* 互动区与正文之间要有分界，但一条线就够 —— 改前这里是白卡里再套一张灰色圆角卡，
   同一条动态被切成两块表面，点赞和评论看着比正文还像个独立的东西。
   卡片已经是这条动态的容器了，里面不需要第二个容器。 */
.flare-moment__social {
  display: grid;
  gap: var(--flare-size-spacing-xs);
  margin-top: var(--flare-size-spacing-2xs);
  padding-top: var(--flare-size-spacing-xs);
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
</style>
