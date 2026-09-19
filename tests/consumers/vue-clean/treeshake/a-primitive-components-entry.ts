import { createApp, h } from "vue";
import { FlareButton } from "@flare-im/vue-ui/components";
createApp({ render: () => h(FlareButton, { label: "A" }) }).mount("#app");
