import { defineAsyncComponent } from "vue";
import DefaultTheme from "vitepress/theme";
import "./custom.css";
import "../../../tokens/dist/tokens.css";
import "@flare-im/vue-ui/style.css";

// Demo filenames are their public Markdown component names. Keep presentation
// next to the page that uses it and load it only when that page is visited.
const modules = import.meta.glob([
  "./demos/*.vue",
  "./demos/messages/demos/*.vue",
]);
const demos = Object.fromEntries(
  Object.entries(modules).map(([path, loader]) => {
    const name = path.split("/").pop()!.replace(/\.vue$/, "");
    return [name, defineAsyncComponent(loader as () => Promise<any>)];
  }),
);

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    for (const [name, component] of Object.entries(demos)) app.component(name, component);
  },
  setup() {
    if (typeof document === "undefined") return;
    const sync = () => {
      document.documentElement.dataset.flareTheme =
        document.documentElement.classList.contains("dark") ? "dark" : "light";
    };
    sync();
    new MutationObserver(sync).observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["class"],
    });
  },
};
