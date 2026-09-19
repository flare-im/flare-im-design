import { createApp, h } from "vue";
import * as all from "@flare-im/vue-ui/components";
const names = Object.keys(all);
createApp({ render: () => h("pre", names.join(",")) }).mount("#app");
(globalThis as any).__all = all;
