<script setup lang="ts">
import { computed, ref, useId, type Component } from "vue";
import { NIcon } from "naive-ui";
import {
  CodeSlashOutline, CodeWorkingOutline, ImageOutline, LinkOutline, ListOutline,
  ReaderOutline, RemoveOutline, ReorderThreeOutline,
} from "../../shared/icon-glyphs";
import { flareIcons } from "../../shared/icons";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { useFlareScrollEdges } from "../../shared/useScrollEdges";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";
import type { FlareActionItem } from "../../shared/contracts/action-menu";
import type { MarkdownShortcutKey } from "../../composables/composer/useMarkdownShortcuts";
import type { RichHeadingLevel, RichMarkdownFormatState } from "./ComposerRichMarkdownInput.vue";
import FlareActionMenu from "../general/FlareActionMenu.vue";

type FormatAction = { key: MarkdownShortcutKey; title: string; icon?: Component; glyph?: string };
type HeadingOption = { level: RichHeadingLevel | null; id: string; label: string; description: string };

// Rich-text toolbar of the composer: one compact text-style picker plus the
// inline / block / insert groups. It only reports intents; the composer applies
// them to whichever editor is active.
//
// 文本样式(正文 / 标题 1–6)不再是一个裸的 <select>:它的弹层由浏览器画,桌面 Chrome 在手机
// 仿真里是一张贴在视口左缘、被裁掉一半的列表,真机上又是另一种轮子。现在按指针分两种呈现:
//  - 指针精细(桌面):kit 自己的锚定菜单,向上开在触发器上方,与 kit 里别的菜单一个样子;
//  - 指针粗糙(手机):触发器就地展开成一行级别键(飞书的做法),不开任何浮层 —— 底部面板会把焦点
//    拿走,软键盘收起再弹,而这一行的每一颗键都在 pointerdown 上 preventDefault,编辑器从未失焦,
//    活选区一直在,和 B / I / U 走的是同一条路。
const props = defineProps<{ state: RichMarkdownFormatState; disabled?: boolean }>();
const emit = defineEmits<{ (event: "apply", key: MarkdownShortcutKey): void; (event: "heading", level: RichHeadingLevel | null): void }>();
const { t } = useFlareI18n();
const platform = useFlarePlatformSafe();
// 键的尺寸与拾取器的形态出自同一个信号(平台能力里的指针种类),而不是一个走 CSS 媒体查询、
// 一个走能力:触屏笔记本 / 接了触控板的 iPad 报 'mixed',宿主也可以覆写 —— 两条轴要么一起粗、
// 要么一起细,不能出现「44 的键 + 弹层菜单」或「32 的键 + 内联行」这种拼装。
const pointerKind = computed(() => platform.capabilities.value.pointer);
const coarsePointer = computed(() => pointerKind.value === "coarse");

const groups = computed<ReadonlyArray<ReadonlyArray<FormatAction>>>(() => [
  [
    { key: "bold", glyph: "B", title: t("composer.formatBold") },
    { key: "strike", glyph: "S", title: t("composer.formatStrike") },
    { key: "italic", glyph: "I", title: t("composer.formatItalic") },
    { key: "underline", glyph: "U", title: t("composer.formatUnderline") },
  ],
  [
    { key: "ordered", icon: ReorderThreeOutline, title: t("composer.formatOrdered") },
    { key: "bullet", icon: ListOutline, title: t("composer.formatBullet") },
    { key: "quote", icon: ReaderOutline, title: t("composer.formatQuote") },
  ],
  [
    { key: "link", icon: LinkOutline, title: t("composer.formatLink") },
    { key: "image", icon: ImageOutline, title: t("composer.formatImage") },
    { key: "code", icon: CodeSlashOutline, title: t("composer.formatCode") },
    { key: "codeBlock", icon: CodeWorkingOutline, title: t("composer.formatCodeBlock") },
    { key: "divider", icon: RemoveOutline, title: t("composer.formatDivider") },
  ],
]);
const headingOptions = computed<ReadonlyArray<HeadingOption>>(() => [
  { level: null, id: "paragraph", label: "P", description: t("composer.paragraph") },
  ...([1, 2, 3, 4, 5, 6] as RichHeadingLevel[]).map((level) => ({ level, id: `heading-${level}`, label: `H${level}`, description: t("composer.heading", { level }) })),
]);
const activeHeading = computed(() => headingOptions.value.find((option) => option.level === props.state.headingLevel) ?? headingOptions.value[0]);
// 桌面菜单里每一项是一句完整的名字(正文 / 标题 2),当前那一项打勾;短记号只留在触发器上。
const headingItems = computed<FlareActionItem<string>[]>(() =>
  headingOptions.value.map((option) => ({ id: option.id, label: option.description, pressed: option.level === props.state.headingLevel })),
);
function pickHeading(option: HeadingOption | undefined): void {
  if (props.disabled || !option) return;
  emit("heading", option.level);
}
function onHeadingSelect(id: string): void {
  pickHeading(headingOptions.value.find((entry) => entry.id === id));
}

// 手机:级别行就地展开,占掉三个格式组的位置;再点触发器或 Escape 收起,不改值。
const levelsOpen = ref(false);
const levelsId = useId();
function toggleLevels(): void {
  if (props.disabled) return;
  levelsOpen.value = !levelsOpen.value;
}
function pickLevel(option: HeadingOption): void {
  pickHeading(option);
  levelsOpen.value = false;
}

function isActive(key: MarkdownShortcutKey): boolean {
  return key === "bold" || key === "strike" || key === "italic" || key === "underline" || key === "code"
    ? props.state.inline[key]
    : false;
}
// pointerdown applies the format before the editor loses focus; the following click is then a no-op.
const pointerActive = ref(false);
function fromPointer(action: () => void): void {
  if (props.disabled) return;
  pointerActive.value = true;
  action();
}
function fromClick(action: () => void): void {
  if (pointerActive.value) { pointerActive.value = false; return; }
  if (!props.disabled) action();
}
// 窄的一屏放不下十二个键,这一排横向滚;末端真有键藏着时才画渐隐(与多选工具条同一机制)。
// 起始侧不画:滚过去之后被裁掉一截的键本身就是提示。
const scroller = ref<HTMLElement | null>(null);
const edges = useFlareScrollEdges(scroller, () => true);
</script>

<template>
  <div
    class="composer-format-strip"
    role="group"
    :aria-label="t('composer.formatToolbar')"
    :data-pointer="pointerKind"
    :data-scroll-end="edges.end.value ? 'true' : undefined"
    @mousedown.stop
  >
    <div ref="scroller" class="composer-format-strip__scroller">
      <div class="composer-format-group composer-format-group--heading" role="group" :aria-label="t('composer.headingLevel')">
        <template v-if="coarsePointer">
          <button
            type="button"
            class="composer-heading-select"
            :class="{ 'is-active': state.headingLevel !== null }"
            :aria-label="t('composer.headingLevel')"
            :aria-expanded="levelsOpen"
            :aria-controls="levelsOpen ? levelsId : undefined"
            :title="activeHeading.description"
            :disabled="disabled"
            @pointerdown.prevent.stop="fromPointer(toggleLevels)"
            @click.prevent.stop="fromClick(toggleLevels)"
            @keydown.enter.prevent.stop="toggleLevels"
            @keydown.space.prevent.stop="toggleLevels"
          >
            <span class="composer-heading-select__value">{{ activeHeading.label }}</span>
            <n-icon aria-hidden="true" :size="14" :component="levelsOpen ? flareIcons['chevron-up'] : flareIcons['chevron-down']" />
          </button>
        </template>
        <FlareActionMenu v-else :items="headingItems" :label="t('composer.headingLevel')" presentation="anchored" placement="top-start" @select="onHeadingSelect">
          <button
            type="button"
            class="composer-heading-select"
            :class="{ 'is-active': state.headingLevel !== null }"
            :aria-label="t('composer.headingLevel')"
            :title="activeHeading.description"
            :disabled="disabled"
            @pointerdown.prevent
          >
            <span class="composer-heading-select__value">{{ activeHeading.label }}</span>
            <n-icon aria-hidden="true" :size="14" :component="flareIcons['chevron-down']" />
          </button>
        </FlareActionMenu>
      </div>
      <div
        v-if="coarsePointer && levelsOpen"
        :id="levelsId"
        class="composer-format-group composer-format-group--levels"
        role="radiogroup"
        :aria-label="t('composer.headingLevel')"
        @keydown.esc.prevent.stop="levelsOpen = false"
      >
        <button
          v-for="option in headingOptions"
          :key="option.id"
          type="button"
          class="composer-format-button composer-format-button--level"
          :class="{ 'is-active': option.level === state.headingLevel }"
          role="radio"
          :aria-checked="option.level === state.headingLevel"
          :aria-label="option.description"
          :title="option.description"
          :disabled="disabled"
          @pointerdown.prevent.stop="fromPointer(() => pickLevel(option))"
          @click.prevent.stop="fromClick(() => pickLevel(option))"
          @keydown.enter.prevent.stop="pickLevel(option)"
          @keydown.space.prevent.stop="pickLevel(option)"
        >
          <span class="composer-format-glyph" aria-hidden="true">{{ option.label }}</span>
        </button>
      </div>
      <div
        v-for="(group, groupIndex) in groups"
        v-show="!(coarsePointer && levelsOpen)"
        :key="`format-group-${groupIndex}`"
        class="composer-format-group"
        role="group"
      >
        <button
          v-for="action in group"
          :key="action.key"
          type="button"
          class="composer-format-button"
          :class="[`composer-format-button--${action.key}`, { 'is-active': isActive(action.key) }]"
          :title="action.title"
          :aria-label="action.title"
          :aria-pressed="isActive(action.key)"
          :disabled="disabled"
          @pointerdown.prevent.stop="fromPointer(() => emit('apply', action.key))"
          @click.prevent.stop="fromClick(() => emit('apply', action.key))"
          @keydown.enter.prevent.stop="emit('apply', action.key)"
          @keydown.space.prevent.stop="emit('apply', action.key)"
        >
          <n-icon aria-hidden="true" v-if="action.icon" :size="14" :component="action.icon" />
          <span v-else class="composer-format-glyph" :class="`composer-format-glyph--${action.key}`" aria-hidden="true">{{ action.glyph }}</span>
        </button>
      </div>
    </div>
    <span class="composer-format-strip__fade" aria-hidden="true" />
  </div>
</template>

<style scoped>
/* 这一排是输入框那块面的顶边,不是另一块面:透明底、没有自己的边和阴影,高度只够放下键。
   键的画像与触达区分开(与 FlareIconButton 同一套做法):粗指针下键画 36、命中 44,
   否则 accessibility.css 的 44 地板会把整排撑成一条比输入框还高的带子。 */
.composer-format-strip {
  position: relative;
  /* 粗指针下键的命中区比条高 8px,下沿伸进输入行的顶部内距里:这一层要画在输入行之上,那 4px 才真归键。 */
  z-index: 1;
  grid-column: 1 / -1;
  min-width: 0;
  width: 100%;
  border: 0;
  border-radius: 0;
  background: transparent;
  box-shadow: none;
}
.composer-format-strip__scroller {
  display: flex;
  flex-wrap: nowrap;
  align-items: center;
  gap: var(--flare-size-spacing-3xs);
  /* 上下各留 4px 再用负外距收回:overflow-x: auto 会让 overflow-y 也成 auto,把键的 2px+2px 焦点环
     竖向裁掉;粗指针下键盒 36、命中区 44,多出的上下各 4px 也正好落在这一圈里,不被滚动口裁掉。
     根不再 overflow: hidden,否则这一圈又被根裁回去。 */
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-2sm);
  margin-block: calc(-1 * var(--flare-size-spacing-xs));
  overflow-x: auto;
  overflow-y: hidden;
  overscroll-behavior-inline: contain;
  scrollbar-width: none;
  /* Tab / focus() 滚进来的键停在渐隐之外,而不是停在它底下。 */
  scroll-padding-inline-end: var(--flare-size-spacing-xl);
}
.composer-format-strip__scroller::-webkit-scrollbar { display: none; }
/* 末端的渐隐:只在那一头真有键被藏住时才画,否则会把边上的键蒙掉一角。压在滑过的键上,不吃点击。
   底色是 composer 带的面,不是 bg-primary:宿主覆写了带色时渐隐才不会露馅。 */
.composer-format-strip__fade {
  position: absolute;
  inset-block: 0;
  inset-inline-end: 0;
  width: var(--flare-size-spacing-xl);
  background: linear-gradient(to left, var(--flare-component-composer-bar-bg), transparent);
  pointer-events: none;
  opacity: 0;
  transition: opacity var(--flare-transition-fast);
}
.composer-format-strip[data-scroll-end="true"] > .composer-format-strip__fade { opacity: 1; }
.composer-format-group { display: flex; align-items: center; flex: 0 0 auto; gap: var(--flare-size-spacing-3xs); padding: 0 var(--flare-size-spacing-xs); border: 0; }
/* 组与组之间一条竖线。手机上这一排横向滚,最后一组(插入类)的起始竖线会恰好裁在滚动口右缘,
   露出半截像一条多余的边 —— 所以触屏上最后一组不画线、只留白;前面各组之间照画。 */
.composer-format-group + .composer-format-group { border-inline-start: 1px solid var(--flare-color-border-secondary); }
.composer-format-strip[data-pointer="coarse"] .composer-format-group:last-child { border-inline-start: 0; margin-inline-start: var(--flare-size-spacing-xs); }
.composer-format-button,
.composer-heading-select {
  position: relative;
  flex: none;
  height: var(--flare-size-layout-control-height-sm);
  min-height: var(--flare-size-layout-control-height-sm);
  border: 0;
  border-radius: var(--flare-size-radius-sm);
  color: var(--flare-color-text-secondary);
  background: transparent;
  box-shadow: none;
  cursor: pointer;
}
.composer-format-button { display: grid; place-items: center; width: var(--flare-size-layout-control-height-sm); min-width: var(--flare-size-layout-control-height-sm); padding: 0; font-weight: var(--flare-size-font-weight-bold); font-size: var(--flare-size-font-size-lg); }
.composer-heading-select { display: inline-flex; align-items: center; gap: var(--flare-size-spacing-3xs); min-width: 48px; padding: 0 var(--flare-size-spacing-xs) 0 var(--flare-size-spacing-2xs); font-size: var(--flare-size-font-size-sm); font-weight: var(--flare-size-font-weight-semibold); }
.composer-heading-select__value { min-width: 18px; text-align: center; }
/* 字形键:粗体 / 删除线 / 斜体 / 下划线各自长成它代表的样子。斜体用同一族字体,不为一个键另立字体。 */
.composer-format-glyph { display: inline-grid; place-items: center; width: 18px; height: 18px; line-height: 1; pointer-events: none; }
.composer-format-button--level .composer-format-glyph { width: auto; padding-inline: var(--flare-size-spacing-3xs); font-size: var(--flare-size-font-size-sm); }
.composer-format-glyph--strike { text-decoration: line-through; text-decoration-thickness: 2px; }
.composer-format-glyph--italic { font-style: italic; }
.composer-format-glyph--underline { text-decoration: underline; text-underline-offset: 3px; text-decoration-thickness: 2px; }
/* 已开启的格式 / 选中的级别:品牌文字色落在 selected 面上 —— 这是状态(aria-pressed / aria-checked),
   不是悬停装饰;文字色用 primary-text 而不是品牌填充色(填充色当文字色在浅色下只有 2.66:1)。
   当前的文本样式触发器(H2 一类)只换颜色:它是一个「现在是什么」的读数,不是按下去的键。 */
.composer-format-button.is-active { color: var(--flare-color-primary-text); background: var(--flare-color-bg-selected); }
.composer-heading-select.is-active,
.composer-heading-select[aria-expanded="true"] { color: var(--flare-color-primary-text); }
/* 悬停只给真有悬停的指针:触屏上 :hover 会在点过之后留在键上,像一块洗不掉的底色。 */
@media (hover: hover) {
  .composer-format-button:hover,
  .composer-heading-select:hover { color: var(--flare-color-primary-text); background: var(--flare-color-bg-hover); }
}
.composer-format-button:disabled,
.composer-heading-select:disabled { opacity: var(--flare-opacity-disabled, 0.5); cursor: default; }
.composer-format-button:focus-visible,
.composer-heading-select:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
/* 粗指针:键画 36(条就 36 高,用户要的是比输入框矮一截的一行),手指要的 44 由不可见的伪元素撑出来;
   min-* 显式写上,accessibility.css 的 44 地板才不会把盒子顶回 44。 */
.composer-format-strip[data-pointer="coarse"] .composer-format-button { width: 36px; min-width: 36px; height: 36px; min-height: 36px; }
.composer-format-strip[data-pointer="coarse"] .composer-heading-select { height: 36px; min-height: 36px; }
.composer-format-strip[data-pointer="coarse"] .composer-format-button::after,
.composer-format-strip[data-pointer="coarse"] .composer-heading-select::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: max(100%, var(--flare-size-layout-touch-target-min));
  height: max(100%, var(--flare-size-layout-touch-target-min));
}
@media (prefers-reduced-motion: reduce) {
  .composer-format-strip__fade { transition: none; }
}
</style>
