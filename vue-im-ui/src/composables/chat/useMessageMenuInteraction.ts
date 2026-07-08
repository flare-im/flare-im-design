import { computed, onMounted, onUnmounted, ref } from "vue";
import { useViewport, type ViewportMode } from "../../composables/useViewport";

export type MessageMenuPresentation = "dropdown" | "bottomSheet";

/** 各端消息菜单交互契约（对齐 shared-im-ui，按触达方式区分） */
export type MessageMenuInteractionProfile = {
  mode: ViewportMode;
  /** PC：气泡上方悬停工具条（反应 / 快捷回复 / 更多） */
  showHoverToolbar: boolean;
  /** 平板 / 手机：不显示「⋯」，仅长按（平板接鼠标可右键） */
  showBubbleMoreButton: boolean;
  /** PC（含 iPad 接鼠标）：右键打开下拉菜单 */
  enableContextMenu: boolean;
  /** 触摸端：长按打开菜单 */
  enableLongPress: boolean;
  longPressMs: number;
  /** 菜单载体：PC/平板用下拉；手机用底部操作表 */
  menuPresentation: MessageMenuPresentation;
};

function readFinePointer(): boolean {
  if (typeof window === "undefined" || !window.matchMedia) return false;
  return window.matchMedia("(pointer: fine)").matches;
}

export function useMessageMenuInteraction(): {
  profile: import("vue").ComputedRef<MessageMenuInteractionProfile>;
} {
  const { mode, isDesktop, isMobile, isTablet } = useViewport();
  const finePointer = ref(readFinePointer());

  onMounted(() => {
    if (typeof window === "undefined" || !window.matchMedia) return;
    const mq = window.matchMedia("(pointer: fine)");
    const sync = () => {
      finePointer.value = mq.matches;
    };
    sync();
    mq.addEventListener("change", sync);
    onUnmounted(() => mq.removeEventListener("change", sync));
  });

  const profile = computed<MessageMenuInteractionProfile>(() => {
    if (isDesktop.value) {
      return {
        mode: "desktop",
        showHoverToolbar: true,
        showBubbleMoreButton: false,
        enableContextMenu: true,
        enableLongPress: false,
        longPressMs: 500,
        menuPresentation: "dropdown",
      };
    }

    if (isTablet.value) {
      return {
        mode: "tablet",
        showHoverToolbar: false,
        showBubbleMoreButton: false,
        enableContextMenu: finePointer.value,
        enableLongPress: true,
        longPressMs: 450,
        menuPresentation: "dropdown",
      };
    }

    return {
      mode: "mobile",
      showHoverToolbar: false,
      showBubbleMoreButton: true,
      enableContextMenu: false,
      enableLongPress: true,
      longPressMs: 520,
      menuPresentation: "bottomSheet",
    };
  });

  return { profile };
}
