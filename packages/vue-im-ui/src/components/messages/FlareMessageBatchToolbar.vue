<script setup lang="ts">
import { computed, getCurrentInstance, ref } from "vue";
import { NIcon } from "naive-ui";
import { flareIcons } from "../../shared/icons";
import {
  messageBatchActions,
  messageBatchActionsAvailable,
  type MessageBatchAction,
  type MessageBatchCapabilities,
} from "../../shared/contracts/message-batch";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { useFlareContextualLayer } from "../../shared/useContextualLayer";
import { useFlareScrollEdges } from "../../shared/useScrollEdges";

// Multi-select batch bar for the timeline. Same contract as FlareConversationBatchToolbar (FR-034):
// the host declares what it can do over the selection, the toolbar reports one action with the ids.
// Selecting all and clearing the selection stay their own events: they change the selection, not the world.
//
// 工具条挂着 = 多选这层活着,所以退出它的三条路径都由它自己拥有:Escape、平台返回、kit 返回控件
// 的第一下(会话页头 / FlareScreen 先问上下文层)。宿主只接 @exit。从前 Escape 与返回是 web app
// 里的三件套胶水,tauri 一件都没有 —— 同一个组件两个宿主两种行为,正是「胶水其实是 kit 缺口」。
// 规则见 shared/useContextualLayer.ts;`active` 挂在宿主是否监听 @exit 上(与页头的 onBack 同一
// 技法):没人听的工具条既不吞键也不认领返回。
const props = withDefaults(
  defineProps<{
    selectedIds: string[];
    total: number;
    capabilities: MessageBatchCapabilities;
    busy?: boolean;
    floating?: boolean;
  }>(),
  { busy: false, floating: false },
);
const emit = defineEmits<{
  action: [value: { action: MessageBatchAction; ids: string[] }];
  selectAll: [];
  clearSelection: [];
  exit: [];
}>();

const { t } = useFlareI18n();
const instance = getCurrentInstance();
const root = ref<HTMLElement | null>(null);
const actions = ref<HTMLElement | null>(null);
const count = computed(() => props.selectedIds.length);
const available = computed(() => messageBatchActionsAvailable(props.selectedIds, props.capabilities, props.busy));
const visibleActions = computed(() => messageBatchActions.filter((action) => props.capabilities?.[action] === true));
const icons: Record<MessageBatchAction, keyof typeof flareIcons> = {
  forwardEach: "forward",
  forwardMerged: "merge-forward",
  pin: "pin",
  pinSelf: "pin-self",
  delete: "delete",
};

useFlareContextualLayer({
  active: () => Boolean(instance?.vnode.props?.onExit),
  root,
  dismissible: () => !props.busy,
  onDismiss: () => emit("exit"),
});
// 浮动形态下键会横向滚:末端还有键藏在钉住的退出键后面时,才画那条渐隐。
const edges = useFlareScrollEdges(actions, () => props.floating);
</script>

<template>
  <div
    ref="root"
    class="flare-batch-toolbar"
    :class="{ 'flare-batch-toolbar--floating': floating }"
    role="toolbar"
    :aria-label="t('batch.title')"
  >
    <div class="flare-batch-toolbar__meta" aria-live="polite" aria-atomic="true">
      <strong>{{ count }}</strong>
      <span>/ {{ total }} · {{ t("batch.selected") }}</span>
    </div>
    <div ref="actions" class="flare-batch-toolbar__actions" :data-scroll-end="edges.end.value ? 'true' : undefined">
      <button
        type="button"
        class="flare-batch-btn"
        :aria-label="t('batch.selectAll')"
        :title="t('batch.selectAll')"
        :disabled="busy || total === 0"
        @click="emit('selectAll')"
      >
        <n-icon aria-hidden="true" :size="16" :component="flareIcons.check" />
        <span>{{ t("batch.selectAll") }}</span>
      </button>
      <button
        type="button"
        class="flare-batch-btn flare-batch-btn--text"
        :aria-label="t('batch.clear')"
        :title="t('batch.clear')"
        :disabled="busy || count === 0"
        @click="emit('clearSelection')"
      >
        <span>{{ t("batch.clear") }}</span>
      </button>
      <button
        v-for="action in visibleActions"
        :key="action"
        type="button"
        class="flare-batch-btn"
        :class="{ 'flare-batch-btn--danger': action === 'delete' }"
        :aria-label="t(`batch.${action}`)"
        :title="t(`batch.${action}`)"
        :disabled="!available.includes(action)"
        @click="emit('action', { action, ids: [...selectedIds] })"
      >
        <n-icon aria-hidden="true" :size="16" :component="flareIcons[icons[action]]" />
        <span>{{ t(`batch.${action}`) }}</span>
      </button>
      <!-- 退出键是这一流里的最后一个(三端原生也是),在浮动的滚动条里由它的包裹层钉在末端。 -->
      <span class="flare-batch-toolbar__exit">
        <button
          type="button"
          class="flare-batch-btn flare-batch-btn--icon"
          :disabled="busy"
          :aria-label="t('batch.exit')"
          aria-keyshortcuts="Escape"
          @click="emit('exit')"
        >
          <n-icon aria-hidden="true" :size="18" :component="flareIcons.close" />
        </button>
      </span>
    </div>
  </div>
</template>

<style scoped>
/* 一套 DOM、两种呈现,由 `floating` 决定而不是由宽度决定。
   非浮动(挂在输入框位置、列表上方)在任何宽度都像三端原生一样换行:计数留在左边,键在它右侧
   折行收尾。改前 ≤599px 把它变成一条隐藏滚动条的横向滚动带,退出键排在最后 —— 手机上刚进多选
   就被滚出视野,而且没有任何提示这条带子会滚。 */
.flare-batch-toolbar {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-2md);
  flex-wrap: nowrap;
  padding: var(--flare-size-spacing-2sm) var(--flare-size-spacing-2md);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary);
  box-shadow: var(--flare-shadow-md);
}
.flare-batch-toolbar--floating {
  position: absolute;
  right: 16px;
  bottom: var(--flare-size-spacing-2md);
  left: 16px;
  z-index: 6;
  min-height: 52px;
  box-sizing: border-box;
}
.flare-batch-toolbar__meta {
  display: inline-flex;
  align-items: baseline;
  flex: none;
  gap: 5px;
  font-size: 13px;
  color: var(--flare-color-text-secondary);
}
.flare-batch-toolbar__meta strong {
  font-size: 16px;
  color: var(--flare-color-primary-text);
  font-variant-numeric: tabular-nums;
}
.flare-batch-toolbar__actions {
  display: flex;
  flex: 1 1 auto;
  min-width: 0;
  align-items: center;
  justify-content: flex-end;
  flex-wrap: wrap;
  gap: 6px;
  row-gap: var(--flare-size-spacing-xs);
}
.flare-batch-toolbar__exit {
  display: inline-flex;
  align-items: center;
  flex: none;
}
/* 浮在时间线上的那一种不能长第二行(第二行会盖住消息),键横向滚动,退出键钉在滚动口末端。
   溢出必须落在末端才滚得到:flex-end 会把多出来的键推出起始边,而滚动口从不越过起始边 ——
   所以这里用 flex-start + 第一个键的 auto 边距:放得下时键仍靠右,放不下时 auto 归零、末端可滚。 */
.flare-batch-toolbar--floating .flare-batch-toolbar__actions {
  flex-wrap: nowrap;
  justify-content: flex-start;
  overflow-x: auto;
  overscroll-behavior-inline: contain;
  scrollbar-width: none;
  /* overflow-x: auto 让 overflow-y 也成了 auto,键的 2px+2px 焦点环会被竖向裁掉:给环留出一圈。 */
  padding: var(--flare-size-spacing-xs);
  margin: calc(-1 * var(--flare-size-spacing-xs));
  /* Tab / focus() 滚进来的键停在钉住的退出键之前,而不是钻到它的地面下面:
     滚动口内边距 + 粗指针下退出键最宽 44 + 键前的 6px 间隙 + 焦点环 4。 */
  scroll-padding-inline-end: calc(
    var(--flare-size-spacing-xs) + var(--flare-size-layout-touch-target-min) + var(--flare-size-spacing-2xs) + var(--flare-size-spacing-xs)
  );
}
.flare-batch-toolbar--floating .flare-batch-toolbar__actions::-webkit-scrollbar {
  display: none;
}
.flare-batch-toolbar--floating .flare-batch-toolbar__actions > :first-child {
  margin-inline-start: auto;
}
.flare-batch-toolbar--floating .flare-batch-toolbar__exit {
  position: sticky;
  inset-inline-end: 0;
  z-index: 1;
  align-self: stretch;
  /* 不透明地面:从底下滑过的键不会从药丸的圆角缝里露出来。它前面那 6px 间隙留着不盖:
     滚到底时最后一个键就贴在这道缝前面,它 4px 的焦点环得有地方画。 */
  background: var(--flare-color-bg-primary);
}
/* 末端还有键藏着时的提示:一条落在地面之外、压在滑过的键上的渐隐。只在真有东西被藏住时画,
   否则它会把最后一个键蒙掉一角。 */
.flare-batch-toolbar--floating .flare-batch-toolbar__exit::before {
  content: "";
  position: absolute;
  inset-block: 0;
  inset-inline-end: 100%;
  width: var(--flare-size-spacing-xl);
  pointer-events: none;
  background: linear-gradient(to right, transparent, var(--flare-color-bg-primary));
  opacity: 0;
  transition: opacity var(--flare-transition-fast);
}
.flare-batch-toolbar--floating .flare-batch-toolbar__actions[data-scroll-end="true"] > .flare-batch-toolbar__exit::before {
  opacity: 1;
}
.flare-batch-btn {
  flex: none;
  white-space: nowrap;
  display: inline-flex;
  align-items: center;
  gap: 5px;
  height: 32px;
  padding: 0 var(--flare-size-spacing-2sm);
  border: none;
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
  font-size: 13px;
  cursor: pointer;
  transition: filter var(--flare-transition-fast), transform var(--flare-transition-fast);
}
.flare-batch-btn:hover:not(:disabled) {
  filter: brightness(0.97);
}
.flare-batch-btn:active:not(:disabled) {
  transform: scale(0.97);
}
.flare-batch-btn:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
}
.flare-batch-btn:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}
.flare-batch-btn--danger {
  color: var(--flare-color-error-text);
}
.flare-batch-btn--icon {
  padding: 0 8px;
}
/* The host decides where this mounts, so there is no container it is guaranteed to sit inside,
   and a named container query that matches nothing applies nothing. It is sized against the
   window on purpose (100vw / 100dvh below), so the window is what it asks. */
@media (max-width: 599px) {
  .flare-batch-toolbar--floating {
    right: var(--flare-size-spacing-2sm);
    left: var(--flare-size-spacing-2sm);
    gap: 8px;
    padding: 8px var(--flare-size-spacing-2sm);
  }
}
@media (prefers-reduced-motion: reduce) {
  .flare-batch-btn {
    transition: none;
  }
  .flare-batch-btn:active:not(:disabled) {
    transform: none;
  }
  .flare-batch-toolbar--floating .flare-batch-toolbar__exit::before {
    transition: none;
  }
}
</style>
