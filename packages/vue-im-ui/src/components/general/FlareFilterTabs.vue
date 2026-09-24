<script lang="ts">
import type { Component } from "vue";

export interface FlareFilterTabOption {
  value: string;
  label: string;
  badge?: number;
  /** Optional leading icon (any Vue component, e.g. a `@vicons` glyph). */
  icon?: Component;
}
</script>

<script setup lang="ts">
import { computed, type CSSProperties } from "vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

// Replaces per-app filter rows. Grid mode keeps every option visible in a
// fixed-width pane instead of introducing horizontal scrolling.
const props = withDefaults(defineProps<{
  options: FlareFilterTabOption[];
  layout?: "scroll" | "wrap" | "grid";
  columns?: number;
  ariaLabel?: string;
  /**
   * `filled`(默认)每个选项各是一颗带底色的药丸 —— 适合浮在内容上的筛选条。
   * `quiet` 只有文字和一道下划线:一条常驻在列表顶上的筛选,摆成一排带底色的药丸时,
   * 会和它上面的搜索框叠成两排同色圆角,一屏里最先看见的是三块灰底而不是列表本身。
   *
   * 与 FlareSearchBar 的 `appearance` 是同一套词(filled / quiet):问的是同一个问题 ——
   * 这个控件自己画不画一块面。所以两边必须用同一个词,不能一边叫 chip 一边叫 filled。
   */
  appearance?: "filled" | "quiet";
  /**
   * `md`(默认)是独立成段的一行筛选。
   * `sm` 是**辅助条件**的紧凑胶囊:搜索页那种「输入框下面跟一排类型」的位置 ——
   * 默认尺寸在那里一颗 48 高、两排就吃掉近百像素,读起来像一排大按钮而不是筛选条件。
   * 视觉box 收到 30,触达区由 ::after 撑到触达目标(48,与 FlareButton 同一套做法);这一排自己是滚动容器,
   * 所以容器要给 ::after 留出高度(见样式),否则撑出去的部分会被它自己裁掉。
   */
  size?: "md" | "sm";
}>(), { layout: "scroll", columns: 4, ariaLabel: undefined, appearance: "filled", size: "md" });
const { t } = useFlareI18nOptional();
const active = defineModel<string>({ default: "" });
const emit = defineEmits<{ (e: "change", value: string): void }>();

const layoutStyle = computed<CSSProperties>(() => ({
  "--flare-filter-columns": String(Math.max(1, Math.floor(props.columns))),
} as CSSProperties));

function select(value: string): void {
  active.value = value;
  emit("change", value);
}
</script>

<template>
  <div
    class="flare-filter-tabs"
    :class="[`flare-filter-tabs--${layout}`, `flare-filter-tabs--${appearance}`, `flare-filter-tabs--size-${size}`]"
    :style="layoutStyle"
    role="tablist"
    :aria-label="ariaLabel ?? t('common.filters')"
  >
    <button
      v-for="option in options"
      :key="option.value"
      type="button"
      role="tab"
      class="flare-filter-tab"
      :class="{ 'flare-filter-tab--active': active === option.value }"
      :aria-selected="active === option.value"
      @click="select(option.value)"
    >
      <component :is="option.icon" v-if="option.icon" class="flare-filter-tab__icon" />
      {{ option.label }}
      <span v-if="option.badge" class="flare-filter-tab__badge">{{ option.badge }}</span>
    </button>
  </div>
</template>

<style scoped>
.flare-filter-tabs {
  display: flex;
  align-items: center;
  gap: 6px;
  overflow-x: auto;
  padding: 2px;
  scrollbar-width: none;
}
.flare-filter-tabs::-webkit-scrollbar {
  display: none;
}

.flare-filter-tabs--wrap {
  flex-wrap: wrap;
  overflow-x: hidden;
}

.flare-filter-tabs--grid {
  display: grid;
  grid-template-columns: repeat(var(--flare-filter-columns), minmax(0, 1fr));
  gap: 4px;
  overflow: hidden;
  padding: 3px;
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-secondary);
}

.flare-filter-tab {
  flex: none;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px var(--flare-size-spacing-2md);
  font: inherit;
  font-size: 13px;
  font-weight: 500;
  line-height: 1.2;
  color: var(--flare-color-text-secondary);
  background: var(--flare-color-bg-secondary);
  border: 1px solid transparent;
  border-radius: 999px;
  cursor: pointer;
  white-space: nowrap;
  transition:
    color 0.15s ease,
    background 0.15s ease;
}

.flare-filter-tab:hover {
  color: var(--flare-color-text-primary);
}

.flare-filter-tab--active {
  color: var(--flare-color-primary-text);
  background: color-mix(in srgb, var(--flare-color-primary) 12%, transparent);
  border-color: color-mix(in srgb, var(--flare-color-primary) 26%, transparent);
  font-weight: 600;
}

.flare-filter-tab__icon {
  display: inline-flex;
  width: 15px;
  height: 15px;
  flex: none;
}
.flare-filter-tab__icon :deep(svg) {
  width: 100%;
  height: 100%;
}

.flare-filter-tab__badge {
  min-width: 16px;
  height: 16px;
  padding: 0 5px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 600;
  color: #fff;
  background: var(--flare-color-primary);
  border-radius: 999px;
}

.flare-filter-tab:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: -2px;
}

.flare-filter-tabs--grid .flare-filter-tab {
  width: 100%;
  min-width: 0;
  justify-content: center;
  padding-inline: 6px;
  overflow: hidden;
  border-radius: calc(var(--flare-size-radius-md) - 2px);
  background: transparent;
  text-overflow: ellipsis;
}

.flare-filter-tabs--grid .flare-filter-tab--active {
  border-color: transparent;
  background: var(--flare-color-bg-primary);
  box-shadow: var(--flare-shadow-sm);
}

@media (pointer: coarse) {
  .flare-filter-tab {
    min-height: var(--flare-size-layout-touch-target);
  }
}

/* ── sm:辅助条件用的紧凑胶囊 ────────────────────────────────────────────────
   视觉 30 高、12px 字、10px 内距,一排放得下更多条件,结果也能早一百多像素出现。
   触达区不缩:::after 把命中区撑到触达区大小,和 FlareButton 同一套 —— 所以这里要
   显式写 min-height 压过上面那条 (pointer: coarse) 的 44 地板,否则盒子又被顶回去。 */
.flare-filter-tabs--size-sm .flare-filter-tab {
  position: relative;
  min-height: 30px;
  padding: 0 var(--flare-size-spacing-sm);
  font-size: var(--flare-size-font-size-sm);
  font-weight: 500;
  line-height: 30px;
}
.flare-filter-tabs--size-sm .flare-filter-tab::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: max(100%, var(--flare-size-layout-touch-target));
  height: max(100%, var(--flare-size-layout-touch-target));
}
/* 这一排自己就是滚动容器(overflow-x:auto 让 overflow-y 也算成 auto),标签画到盒外的东西会被它裁掉:
   ::after 上下各撑出去的 8px 上面被裁、下面变成 6px 的纵向滚动 —— 实际触达只有 36,还能上下拖。
   所以把触达区要的高度给容器本身,再用负外距收回来:48 的内距盒装得下 48 的 ::after,版面仍只占 36。
   grid 形态自己画着一块带边框的面,不能这么撑。 */
.flare-filter-tabs--size-sm:not(.flare-filter-tabs--grid) {
  padding-block: var(--flare-size-spacing-sm);
  margin-block: calc(2px - var(--flare-size-spacing-sm));
}
@media (pointer: coarse) {
  .flare-filter-tabs--size-sm .flare-filter-tab { min-height: 30px; }
}
.flare-filter-tabs--size-sm .flare-filter-tab--active { font-weight: 600; }
.flare-filter-tabs--size-sm .flare-filter-tab__badge { min-width: 14px; height: 14px; padding: 0 4px; font-size: var(--flare-size-font-size-2xs); }

/* ── quiet:文字 + 下划线 ─────────────────────────────────────────────────────
   常驻在列表顶上的那条筛选。不画药丸,所以它不会和上面的搜索框叠成两排灰圆角;
   选中用颜色 + 字重 + 一道下划线三重表达,不只靠颜色。 */
.flare-filter-tabs--quiet {
  gap: 0;
  padding: 0;
  border-block-end: 1px solid var(--flare-color-border-secondary);
}
.flare-filter-tabs--quiet .flare-filter-tab {
  position: relative;
  /* 左右 8px = 列表行自己的槽宽:第一个标签的文字、搜索里的文字、下面行的头像共用一条左边缘。 */
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-sm);
  border: 0;
  border-radius: 0;
  background: transparent;
}
.flare-filter-tabs--quiet .flare-filter-tab--active {
  color: var(--flare-color-primary-text);
  background: transparent;
}
.flare-filter-tabs--quiet .flare-filter-tab--active::after {
  position: absolute;
  inset-inline: var(--flare-size-spacing-sm);
  inset-block-end: 0;
  height: 2px;
  border-radius: 1px;
  background: var(--flare-color-primary);
  content: "";
}
/* 计数在这里是补充说明,不是角标:红底白字会把「未读 3」变成三个警报中最响的一个。 */
.flare-filter-tabs--quiet .flare-filter-tab__badge {
  min-width: 0;
  height: auto;
  padding: 0;
  color: inherit;
  background: transparent;
  font-weight: 400;
  opacity: 0.7;
}
@media (prefers-reduced-motion: no-preference) {
  .flare-filter-tabs--quiet .flare-filter-tab--active::after {
    transition: background 0.15s ease;
  }
}
</style>
