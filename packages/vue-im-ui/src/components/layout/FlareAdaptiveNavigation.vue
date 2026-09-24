<script setup lang="ts">
import { computed, nextTick, ref } from "vue";
import {
  resolveNavigationPresentation,
  type FlareApplicationResponsiveMode,
  type FlareNavigationGroup,
  type FlareNavigationIdentity,
  type FlareNavigationItem,
  type FlareNavigationPresentation,
} from "../../shared/contracts/application";
import FlareActionMenu from "../general/FlareActionMenu.vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareGlyph from "../general/FlareGlyph.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(defineProps<{
  groups: readonly FlareNavigationGroup[];
  activeId: string;
  responsiveMode: FlareApplicationResponsiveMode;
  presentation?: FlareNavigationPresentation;
  label?: string;
  /** 谁在用这个 app。给了就画在侧栏最上面;手机底栏不画(那里没有这个位置)。 */
  identity?: FlareNavigationIdentity;
  /**
   * 身份下面那一组高频动作(新建 / 搜索)。它们不是目的地:没有选中态,
   * 但和导航项一样通过 `navigate` 把 id 交回宿主,宿主按 id 路由。
   */
  actions?: readonly FlareNavigationItem[];
}>(), { label: "" });

const emit = defineEmits<{ (event: "navigate", id: string): void }>();

/** 侧栏才有身份/动作这一段:手机底栏是一行图标,塞不下也不该塞。 */
const showLeading = computed(
  () => resolvedPresentation.value !== "bottom" && (!!props.identity || visibleActions.value.length > 0),
);
const visibleActions = computed(() => (props.actions ?? []).filter((a) => a.visible !== false));
/** 每个带菜单的动作各自的开合;按 id 存,增删动作不会把开着的那个记错。 */
const openMenus = ref<Record<string, boolean>>({});
const { t } = useFlareI18nOptional();

/**
 * The kit's own default entries carry English labels in the data contract
 * (FLARE_DEFAULT_IM_NAVIGATION / FLARE_DEFAULT_CONTACT_NAVIGATION), so they are translated here,
 * at render time, the way ConversationHeader translates its default action labels: an item whose
 * label is still the default for its id reads from the strings table, and a host's own wording is
 * left alone. The three native kits build their defaults from the strings table instead, which
 * arrives at the same words.
 */
const DEFAULT_NAVIGATION_LABELS: Record<string, string> = {
  chats: "Chats",
  contacts: "Contacts",
  profile: "Profile",
  friends: "Friends",
  groups: "Groups",
  newFriends: "New Friends",
  favorites: "Favorites",
};

function itemLabel(item: FlareNavigationItem): string {
  return item.label === DEFAULT_NAVIGATION_LABELS[item.id] ? t(`navigation.${item.id}`) : item.label;
}
const visibleGroups = computed(() => props.groups.map((group) => ({
  ...group,
  items: group.items.filter((item) => item.visible !== false),
})).filter((group) => group.items.length));
const items = computed(() => visibleGroups.value.flatMap((group) => group.items));
const resolvedPresentation = computed(() => props.presentation ?? resolveNavigationPresentation(props.responsiveMode));
const buttons = ref<HTMLButtonElement[]>([]);

function badgeText(item: FlareNavigationItem): string {
  if (!item.badge) return "";
  if (item.badge.kind === "dot") return "";
  if (item.badge.kind === "mention") return item.badge.label ?? "@";
  const count = Math.max(0, item.badge.count ?? 0);
  return count > 99 ? "99+" : String(count);
}

function badgeLabel(item: FlareNavigationItem): string | undefined {
  if (!item.badge) return undefined;
  return item.badge.label || item.accessibilityLabel || itemLabel(item);
}

async function moveFocus(current: number, delta: number): Promise<void> {
  const candidates = items.value.map((item, index) => ({ item, index })).filter(({ item }) => !item.disabled);
  if (!candidates.length) return;
  const at = Math.max(0, candidates.findIndex(({ index }) => index === current));
  const next = candidates[(at + delta + candidates.length) % candidates.length].index;
  await nextTick();
  buttons.value[next]?.focus();
}

function onKeydown(event: KeyboardEvent, index: number): void {
  const vertical = resolvedPresentation.value !== "bottom";
  const previous = vertical ? event.key === "ArrowUp" : event.key === "ArrowLeft";
  const next = vertical ? event.key === "ArrowDown" : event.key === "ArrowRight";
  if (previous || next) {
    event.preventDefault();
    void moveFocus(index, previous ? -1 : 1);
  } else if (event.key === "Home" || event.key === "End") {
    event.preventDefault();
    const target = event.key === "Home" ? buttons.value.find((button) => !button.disabled) : [...buttons.value].reverse().find((button) => !button.disabled);
    target?.focus();
  }
}
</script>

<template>
  <nav class="flare-adaptive-navigation" :data-presentation="resolvedPresentation" :aria-label="label || undefined">
    <!-- 身份 → 新建 / 搜索 → 导航。手机底栏是一行图标,没有这个纵向位置,所以只在侧栏画。 -->
    <div v-if="showLeading" class="flare-adaptive-navigation__leading">
      <button
        v-if="identity"
        type="button"
        class="flare-adaptive-navigation__identity"
        :aria-label="identity.accessibilityLabel || identity.displayName"
        :title="identity.displayName"
        @click="emit('navigate', 'profile')"
      >
        <FlareAvatar :user-id="identity.userId" :display-name="identity.displayName" :src="identity.avatarUrl" :size="44" />
      </button>
      <template v-for="action in visibleActions" :key="action.id">
        <!-- 一组动作:菜单锚在这个按钮上。宿主拿不到这个按钮,锚不了,所以锚由侧栏自己做;
             选中的条目照样以 navigate 交回宿主。 -->
        <FlareActionMenu
          v-if="action.menu?.length"
          v-model:open="openMenus[action.id]"
          :items="[...action.menu]"
          :label="itemLabel(action)"
          placement="right-start"
          @select="emit('navigate', $event)"
        >
          <button
            type="button"
            class="flare-adaptive-navigation__item flare-adaptive-navigation__action"
            :class="{ 'is-open': openMenus[action.id] }"
            :disabled="action.disabled"
            :aria-label="action.accessibilityLabel || itemLabel(action)"
            :title="itemLabel(action)"
          >
            <span class="flare-adaptive-navigation__icon">
              <FlareGlyph :icon="action.icon || 'add'" :size="20" />
            </span>
          </button>
        </FlareActionMenu>
        <button
          v-else
          type="button"
          class="flare-adaptive-navigation__item flare-adaptive-navigation__action"
          :disabled="action.disabled"
          :aria-label="action.accessibilityLabel || itemLabel(action)"
          :title="itemLabel(action)"
          @click="emit('navigate', action.id)"
        >
          <span class="flare-adaptive-navigation__icon">
            <FlareGlyph :icon="action.icon || 'add'" :size="20" />
          </span>
        </button>
      </template>
    </div>
    <div
      v-for="(group, groupIndex) in visibleGroups"
      :key="group.id"
      class="flare-adaptive-navigation__group"
      :class="{ 'is-trailing': visibleGroups.length > 1 && groupIndex === visibleGroups.length - 1 }"
      role="group"
      :aria-label="group.label || undefined"
    >
      <span v-if="group.label && resolvedPresentation === 'expandedSidebar'" class="flare-adaptive-navigation__group-label">{{ group.label }}</span>
      <button
        v-for="item in group.items"
        :key="item.id"
        :ref="(element) => { if (element) buttons[items.indexOf(item)] = element as HTMLButtonElement }"
        type="button"
        class="flare-adaptive-navigation__item"
        :class="{ 'is-active': item.id === activeId }"
        :disabled="item.disabled"
        :aria-current="item.id === activeId ? 'page' : undefined"
        :aria-label="item.accessibilityLabel || itemLabel(item)"
        :title="resolvedPresentation === 'rail' ? itemLabel(item) : undefined"
        @click="emit('navigate', item.id)"
        @keydown="onKeydown($event, items.indexOf(item))"
      >
        <span class="flare-adaptive-navigation__icon">
          <FlareGlyph :icon="item.icon || 'comment'" :size="resolvedPresentation === 'rail' ? 24 : 20" />
          <span
            v-if="item.badge"
            class="flare-adaptive-navigation__badge"
            :data-kind="item.badge.kind"
            :aria-label="badgeLabel(item)"
          >{{ badgeText(item) }}</span>
        </span>
        <span class="flare-adaptive-navigation__label">{{ itemLabel(item) }}</span>
      </button>
    </div>
  </nav>
</template>

<style scoped>
.flare-adaptive-navigation {
  display: flex;
  gap: var(--flare-size-spacing-xs);
  height: 100%;
  box-sizing: border-box;
  color: var(--flare-color-text-secondary);
  background: var(--flare-color-bg-secondary);
}
.flare-adaptive-navigation:not([data-presentation="bottom"]) {
  flex-direction: column;
  width: var(--flare-size-layout-navigation-rail-width);
  padding: var(--flare-size-spacing-lg) var(--flare-size-spacing-xs) var(--flare-size-spacing-md);
  border-inline-end: 1px solid var(--flare-color-border-primary);
  /* 竖栏可以比它的内容矮(身份 + 动作 + 导航加起来不止一屏,外壳又是 overflow:hidden),
     那时底下的导航项会被直接裁掉 —— 看不见,也点不到。给它自己滚。 */
  overflow-y: auto;
  overscroll-behavior: contain;
  scrollbar-width: none;
}
.flare-adaptive-navigation:not([data-presentation="bottom"])::-webkit-scrollbar { width: 0; }
/* 身份那一段不参与压缩:要挤也是导航组去滚,不是头像被压扁。 */
.flare-adaptive-navigation__leading { flex: none; }
.flare-adaptive-navigation[data-presentation="rail"] { gap: var(--flare-size-spacing-md); background: var(--flare-color-bg-secondary); }
.flare-adaptive-navigation[data-presentation="sidebar"],
.flare-adaptive-navigation[data-presentation="expandedSidebar"] { width: var(--flare-size-layout-primary-pane-min-width); padding-inline: var(--flare-size-spacing-sm); }
.flare-adaptive-navigation[data-presentation="expandedSidebar"] { width: var(--flare-size-layout-primary-pane-default-width); }
.flare-adaptive-navigation[data-presentation="bottom"] {
  flex-direction: row;
  width: 100%;
  height: auto;
  padding: var(--flare-size-spacing-xs) max(var(--flare-size-spacing-xs), env(safe-area-inset-right)) max(var(--flare-size-spacing-xs), env(safe-area-inset-bottom)) max(var(--flare-size-spacing-xs), env(safe-area-inset-left));
  overflow-x: auto;
  border-top: 1px solid var(--flare-color-border-primary);
  background: var(--flare-color-bg-primary);
}
.flare-adaptive-navigation__group { display: flex; flex-direction: column; gap: var(--flare-size-spacing-xs); width: 100%; min-width: 0; }
.flare-adaptive-navigation[data-presentation="bottom"] .flare-adaptive-navigation__group { display: contents; }
.flare-adaptive-navigation[data-presentation="rail"] .flare-adaptive-navigation__group.is-trailing { margin-block-start: auto; }
.flare-adaptive-navigation__group-label { padding: var(--flare-size-spacing-md) var(--flare-size-spacing-sm) var(--flare-size-spacing-xs); color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-xs); font-weight: 600; }
.flare-adaptive-navigation__item {
  position: relative;
  display: flex;
  flex: none;
  align-items: center;
  justify-content: flex-start;
  gap: var(--flare-size-spacing-sm);
  min-width: var(--flare-size-layout-touch-target);
  min-height: var(--flare-size-layout-touch-target);
  padding: var(--flare-size-spacing-sm);
  border: 0;
  border-radius: var(--flare-size-radius-md);
  color: inherit;
  background: transparent;
  cursor: pointer;
  font: inherit;
  text-align: start;
}
.flare-adaptive-navigation[data-presentation="rail"] .flare-adaptive-navigation__item {
  align-self: center;
  flex-direction: column;
  justify-content: center;
  gap: var(--flare-size-spacing-xs);
  width: calc(var(--flare-size-layout-navigation-rail-width) - var(--flare-size-spacing-sm));
  height: 60px;
  padding: 0;
}
.flare-adaptive-navigation[data-presentation="bottom"] .flare-adaptive-navigation__item {
  flex: 1 1 var(--flare-size-layout-touch-target);
  min-width: var(--flare-size-layout-touch-target);
  flex-direction: column;
  gap: 2px;
  padding-block: var(--flare-size-spacing-xs);
  padding-inline: 2px;
}
/* 身份 → 新建 / 搜索 → 导航:桌面左栏顶部的一条固定纵向路径。
   这三样以前散在内容区的页头里,同一个入口在手机上和桌面上位置不同。 */
.flare-adaptive-navigation__leading {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  padding-block-end: var(--flare-size-spacing-md);
  border-block-end: 1px solid var(--flare-color-border-primary);
}
.flare-adaptive-navigation[data-presentation="sidebar"] .flare-adaptive-navigation__leading,
.flare-adaptive-navigation[data-presentation="expandedSidebar"] .flare-adaptive-navigation__leading {
  align-items: stretch;
}
.flare-adaptive-navigation__identity {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  border: 0;
  border-radius: var(--flare-size-radius-full);
  background: transparent;
  cursor: pointer;
}
.flare-adaptive-navigation__identity:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
}
/* 动作不是目的地:没有选中态,只有 hover / focus。 */
.flare-adaptive-navigation__action { flex: 0 0 auto; }
/* 也不带文字,所以不需要导航项那 60px 的两行高度 —— 收到触达区本身那么高就够,
   身份 → 新建 → 搜索 这一段才不会比它下面整组导航还占地方。 */
.flare-adaptive-navigation[data-presentation="rail"] .flare-adaptive-navigation__action {
  width: var(--flare-size-layout-touch-target);
  height: var(--flare-size-layout-touch-target);
}
/* 菜单开着的时候按钮要看得出是它开的（和会话列表里那个「+」同一套表达）。 */
.flare-adaptive-navigation__action.is-open { color: var(--flare-color-primary-text); background: var(--flare-color-bg-selected); }

.flare-adaptive-navigation__item:hover:not(:disabled) { background: var(--flare-color-bg-hover); }
/* 活跃态只由图标和文字的颜色表达。底部栏原来还在活跃项外面画一块 bg-selected 胶囊 ——
   一行四项里只有一项带底色,那块色块比它要标示的图标还显眼,而且 iOS 一直是只用颜色。
   侧边 rail / sidebar 保留底色:那里是列表式的选中行,与 FlareSettingsList 同一套语法。 */
.flare-adaptive-navigation__item.is-active { color: var(--flare-color-primary-text); background: var(--flare-color-bg-selected); }
.flare-adaptive-navigation[data-presentation="bottom"] .flare-adaptive-navigation__item.is-active { background: transparent; }
.flare-adaptive-navigation[data-presentation="bottom"] .flare-adaptive-navigation__item:hover:not(:disabled) { background: transparent; }
.flare-adaptive-navigation__item:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-adaptive-navigation__item:disabled { opacity: var(--flare-opacity-disabled); cursor: not-allowed; }
.flare-adaptive-navigation__icon { position: relative; display: inline-flex; align-items: center; justify-content: center; width: var(--flare-size-icon-size-lg); height: var(--flare-size-icon-size-lg); }
.flare-adaptive-navigation__badge { position: absolute; inset-block-start: -7px; inset-inline-end: -11px; min-width: var(--flare-size-icon-size-sm); height: var(--flare-size-icon-size-sm); padding-inline: var(--flare-size-spacing-xs); box-sizing: border-box; border-radius: var(--flare-size-radius-full); color: white; background: var(--flare-color-error); font-size: var(--flare-size-font-size-2xs); line-height: var(--flare-size-icon-size-sm); text-align: center; }
.flare-adaptive-navigation__badge[data-kind="dot"] { inset-block-start: -2px; inset-inline-end: calc(-1 * var(--flare-size-spacing-xs)); min-width: var(--flare-size-spacing-sm); width: var(--flare-size-spacing-sm); height: var(--flare-size-spacing-sm); padding: 0; }
.flare-adaptive-navigation__badge[data-kind="mention"] { background: var(--flare-color-important); }
.flare-adaptive-navigation__label { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: var(--flare-size-font-size-sm); }
.flare-adaptive-navigation[data-presentation="rail"] .flare-adaptive-navigation__label {
  display: block;
  max-width: 100%;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-sm);
  line-height: 1.2;
}
.flare-adaptive-navigation[data-presentation="rail"] .flare-adaptive-navigation__item.is-active .flare-adaptive-navigation__label {
  color: var(--flare-color-primary-text);
  font-weight: 600;
}
@media (prefers-reduced-motion: reduce) {
  .flare-adaptive-navigation__item { transition: none; }
}
</style>
