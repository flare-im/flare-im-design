import { createApp, defineComponent, h, ref } from "vue";
// primitives + IM component + provider (components entry)
import { FlareButton, FlareConversationList, FlareUiProvider } from "@flare-im/vue-ui/components";
// hooks + platform adapter factory (composables entry)
import { createWebPlatformAdapter, useFlarePlatformProvider, useLongPress } from "@flare-im/vue-ui/composables";
// types incl. PlatformAdapter contract (contracts entry)
import type { FlareConversationRowModel, FlareNavigationGroup, FlarePlatformAdapter } from "@flare-im/vue-ui/contracts";
// theme + i18n + root entry
import { imTheme } from "@flare-im/vue-ui/theme";
import { useFlareI18n } from "@flare-im/vue-ui/i18n";
import { FlareIcon } from "@flare-im/vue-ui";
// tokens
import { flareDesignTokens } from "@flare-im/tokens";
import "@flare-im/tokens/tokens.css";
import "@flare-im/vue-ui/style.css";

const adapter: FlarePlatformAdapter = createWebPlatformAdapter();
const navigation: FlareNavigationGroup[] = [{ id: "main", items: [{ id: "chats", label: "Chats", icon: "chats" }] }];
const rows: FlareConversationRowModel[] = [
  { id: "c1", displayName: "Consumer Alice", lastMessagePreview: "hello from tarball", unreadCount: 2 },
  { id: "c2", displayName: "Consumer Bob", lastMessagePreview: "second row" },
];

const Inner = defineComponent({
  setup() {
    useFlarePlatformProvider({ adapter });
    const { t } = useFlareI18n();
    const selected = ref("");
    const pressTarget = ref<HTMLElement | null>(null);
    useLongPress(pressTarget, { enabled: true, onLongPress: () => { selected.value = "long"; } });
    return () => h("main", { id: "smoke", "data-nav": navigation[0].items.length, "data-token-keys": Object.keys(flareDesignTokens).length, "data-theme-keys": Object.keys(imTheme).length, "data-i18n": typeof t },
      [
        h(FlareButton, { label: "Consumer ready", onClick: () => { selected.value = "button"; } }),
        h(FlareIcon, { name: "send" }),
        h("div", { style: "height:400px" }, [h(FlareConversationList, { items: rows, activeId: selected.value, onSelect: (id: string) => { selected.value = id; } })]),
        h("output", { id: "selected", ref: pressTarget }, selected.value),
      ]);
  },
});
createApp({ render: () => h(FlareUiProvider, { themeMode: "light", locale: "en-US" }, { default: () => h(Inner) }) }).mount("#app");
