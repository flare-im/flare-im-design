import { createApp, h } from "vue";
import { FlareButton } from "@flare-im/vue-ui";
createApp({ render: () => h(FlareButton, { label: "B" }) }).mount("#app");
