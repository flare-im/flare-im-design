import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";
import { fileURLToPath, URL } from "node:url";

const r = (p: string) => fileURLToPath(new URL(p, import.meta.url));

// In a real project you'd just `npm i flare-core-vue-im-ui naive-ui vue` and
// import from the package. Here we alias to the workspace source so the example
// runs without publishing. Only the SDK-free subpaths are used.
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: [
      { find: "flare-core-vue-im-ui/components", replacement: r("../../src/components/index.ts") },
      { find: "flare-core-vue-im-ui/i18n", replacement: r("../../src/shared/i18n/index.ts") },
      { find: "flare-core-vue-im-ui/style.css", replacement: r("../../src/design-system/styles/index.css") },
      { find: /^flare-im-design-tokens\/theme$/, replacement: r("../../../tokens/theme.js") },
      { find: /^flare-im-design-tokens\/tokens\.css$/, replacement: r("../../../tokens/dist/tokens.css") },
      { find: /^flare-im-design-tokens$/, replacement: r("../../../tokens/dist/tokens.js") },
    ],
  },
  server: { port: 5180 },
});
