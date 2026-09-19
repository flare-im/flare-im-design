import { createApp, h } from "vue";
import { FlareButton } from "@flare-im/vue-ui";
import "@flare-im/vue-ui/style.css";

createApp({ render: () => h(FlareButton, { label: "Consumer ready" }) }).mount("#app");
