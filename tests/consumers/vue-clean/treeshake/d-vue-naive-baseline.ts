import { createApp, h } from "vue";
import { NIcon } from "naive-ui";
createApp({ render: () => h(NIcon, null, { default: () => "D" }) }).mount("#app");
