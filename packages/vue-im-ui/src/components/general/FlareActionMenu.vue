<script setup lang="ts">
/**
 * A small menu of actions — the "new", "more" and context menus of an IM app. On
 * pointer devices it is anchored to its trigger (or to a point, for a context menu);
 * on phones it is a bottom sheet titled with `label`. One item model and one grouping
 * rule on four platforms (spec ActionMenu), drawing the shared `FlareActionItem`.
 * Selecting an action closes the menu, returns focus to the trigger, then reports its id.
 *
 * The trigger is the default slot's first element: it gets the click that toggles the
 * menu and `aria-haspopup` / `aria-expanded` / `aria-controls`.
 */
import { Comment, Fragment, cloneVNode, computed, onMounted, ref, useId, useSlots, watch, type Component, type VNode } from "vue";
import { NPopover } from "naive-ui";
import FlareBottomSheet from "./FlareBottomSheet.vue";
import FlareActionMenuList from "./FlareActionMenuList.vue";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";
import type { FlareActionItem, FlareActionMenuPresentation } from "../../shared/contracts/action-menu";

defineOptions({ inheritAttrs: false });

const props = withDefaults(
  defineProps<{
    /** Actions in display order; an icon is a kit glyph name or a glyph component. */
    items: FlareActionItem<string | Component>[];
    /** The menu's accessible name; also the sheet title on phones. */
    label: string;
    /** Controlled open state; leave it unset and the trigger opens and closes the menu. */
    open?: boolean;
    /** Anchor at a viewport point instead of the trigger (a context menu). */
    x?: number;
    y?: number;
    placement?: "bottom-start" | "bottom-end" | "top-start" | "top-end" | "right-start" | "left-start";
    presentation?: FlareActionMenuPresentation;
    /** `click`: the trigger toggles the menu. `manual`: the slot is only the anchor and `open` decides. */
    trigger?: "click" | "manual";
  }>(),
  { open: undefined, x: undefined, y: undefined, placement: "bottom-end", presentation: "auto", trigger: "click" },
);
const emit = defineEmits<{
  (e: "select", id: string): void;
  (e: "update:open", open: boolean): void;
}>();

const slots = useSlots();
const platform = useFlarePlatformSafe();
const menuId = `flare-action-menu-${useId()}`;
const innerOpen = ref(false);
const hasVisibleItems = computed(() => props.items.some((item) => item.visible !== false));
const isOpen = computed(() => (props.open ?? innerOpen.value) && hasVisibleItems.value);
const resolvedPresentation = computed<"anchored" | "sheet">(() => {
  if (props.presentation !== "auto") return props.presentation;
  return platform.capabilities.value.bottomSheet ? "sheet" : "anchored";
});
const reduceMotion = ref(false);
onMounted(() => {
  reduceMotion.value = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches ?? false;
});

let returnFocusTo: HTMLElement | null = null;

function triggerElement(): HTMLElement | null {
  if (typeof document === "undefined") return null;
  return document.querySelector<HTMLElement>(`[data-action-menu-trigger="${menuId}"]`);
}

function setOpen(next: boolean): void {
  if (props.open === undefined) innerOpen.value = next;
  emit("update:open", next);
}

// Immediate: a menu mounted already open (a message menu mounts on first use) still records
// where focus returns.
watch(isOpen, (open) => {
  if (!open) {
    returnFocusTo = null;
    return;
  }
  if (!returnFocusTo && typeof document !== "undefined") {
    const active = document.activeElement;
    returnFocusTo = active instanceof HTMLElement && active !== document.body ? active : triggerElement();
  }
}, { immediate: true });

function onTriggerClick(): void {
  if (!hasVisibleItems.value) return;
  if (isOpen.value) {
    close(true);
    return;
  }
  returnFocusTo = triggerElement();
  setOpen(true);
}

function close(restoreFocus: boolean): void {
  if (!isOpen.value) return;
  const target = returnFocusTo;
  setOpen(false);
  if (restoreFocus && target?.isConnected) target.focus({ preventScroll: true });
}

function onSelect(id: string): void {
  close(true);
  emit("select", id);
}

function onClickOutside(event: MouseEvent): void {
  // A click on the trigger toggles the menu itself; treating it as "outside" would reopen it.
  const target = event.target;
  if (target instanceof Element && target.closest(`[data-action-menu-trigger="${menuId}"]`)) return;
  close(false);
}

/**
 * The trigger: the default slot's first element, marked and (for `click`) wired. It is
 * rendered as that element itself, never wrapped, so the anchored menu measures the real
 * trigger box.
 */
function triggerVNode(): VNode | null {
  const node = (slots.default?.() ?? []).find((child) => child.type !== Comment && child.type !== Fragment && typeof child.type !== "symbol");
  if (!node) return null;
  return props.trigger === "click"
    ? cloneVNode(node, {
        "data-action-menu-trigger": menuId,
        "aria-haspopup": "menu",
        "aria-expanded": isOpen.value,
        "aria-controls": isOpen.value ? menuId : undefined,
        onClick: onTriggerClick,
      })
    : cloneVNode(node, { "data-action-menu-trigger": menuId });
}
</script>

<template>
  <NPopover
    v-if="resolvedPresentation === 'anchored'"
    :show="isOpen"
    trigger="manual"
    raw
    :show-arrow="false"
    :placement="placement"
    :x="x"
    :y="y"
    :animated="!reduceMotion"
    class="flare-action-menu-popover"
    @clickoutside="onClickOutside"
  >
    <template v-if="$slots.default" #trigger>
      <component :is="triggerVNode()" />
    </template>
    <FlareActionMenuList
      :menu-id="menuId"
      :items="items"
      :label="label"
      presentation="anchored"
      @select="onSelect"
      @escape="close(true)"
      @tab="close(false)"
    />
  </NPopover>
  <template v-else>
    <component :is="triggerVNode()" v-if="$slots.default" />
    <FlareBottomSheet :open="isOpen" presentation="sheet" :title="label" @close="close(true)">
      <FlareActionMenuList
        v-if="isOpen"
        :menu-id="menuId"
        :items="items"
        :label="label"
        presentation="sheet"
        @select="onSelect"
        @escape="close(true)"
        @tab="close(false)"
      />
    </FlareBottomSheet>
  </template>
</template>
