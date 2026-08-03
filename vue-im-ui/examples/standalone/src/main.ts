import { createApp } from "vue";
// The one stylesheet — base tokens + component styles. Override --flare-color-*
// anywhere to re-theme (see the Theming guide).
import "@flare-im/vue-ui/style.css";
import App from "./App.vue";

createApp(App).mount("#app");
