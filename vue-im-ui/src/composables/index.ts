export {
  useFlareAdaptive,
  useFlareAdaptiveSafe,
  useFlareAdaptiveProvider,
  type FlareAdaptiveContext,
} from "./useAdaptiveMode";
export {
  useViewport,
  useViewportProvider,
  BREAKPOINT_DESKTOP_PX,
  BREAKPOINT_TABLET_PX,
  type ViewportContext,
  type ViewportMode,
} from "./useViewport";
export { useLongPress } from "./useLongPress";
export {
  useMessageMenuInteraction,
  type MessageMenuInteractionProfile,
  type MessageMenuPresentation,
} from "./chat/useMessageMenuInteraction";
export {
  provideFlareWorkbenchUi,
  useFlareWorkbenchUi,
  type FlareWorkbenchModalRefs,
  type FlareWorkbenchUiContext,
} from "./useFlareWorkbenchUi";
export {
  useFlareMediaProvider,
  useFlareMediaResolver,
  useResolvedMediaUrl,
  type FlareMediaResolverContext,
} from "./useMediaResolver";
export {
  useFlareNotificationProvider,
  useFlareNotificationResolver,
  type FlareNotificationPayload,
  type FlareNotificationResolver,
} from "./useNotificationRenderer";
// useFlareCoreClient / useFlareSessionBridge **故意不在这里转出**。
//
// 它们对 `@flare-im/sdk` 有运行时依赖，而这个 barrel 会被 `src/index.ts`
// 的 `export * from "./composables"` 带进主入口 —— 挂在这里等于让每个
// `from "@flare-im/vue-ui"` 的消费方都必须装 SDK，而 package.json 声明它
// 是 optional peer。不装 SDK 的消费方（flare-social 各端）会构建失败。
//
// 需要它们请走 `@flare-im/vue-ui/composables/sdk`（见 ./sdk.ts）。
