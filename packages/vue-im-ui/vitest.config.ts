import path from "node:path";
import { fileURLToPath } from "node:url";

import vue from "@vitejs/plugin-vue";
import { defineConfig } from "vitest/config";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "../..");
const vueImUiRoot = path.resolve(__dirname, "src");

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: [
      {
        find: "@flare-im/vue-ui/style.css",
        replacement: path.join(vueImUiRoot, "design-system/styles/index.css"),
      },
      {
        find: "@flare-im/vue-ui/theme",
        replacement: path.join(vueImUiRoot, "design-system/theme/index.ts"),
      },
      {
        find: "@flare-im/vue-ui/i18n",
        replacement: path.join(vueImUiRoot, "shared/i18n/index.ts"),
      },
      {
        find: "@flare-im/vue-ui/components",
        replacement: path.join(vueImUiRoot, "components/index.ts"),
      },
      {
        find: "@flare-im/vue-ui/utils",
        replacement: path.join(vueImUiRoot, "utils/index.ts"),
      },
      {
        find: "@flare-im/vue-ui/composables",
        replacement: path.join(vueImUiRoot, "composables/index.ts"),
      },
      {
        find: "@flare-im/vue-ui/contracts",
        replacement: path.join(vueImUiRoot, "shared/contracts/index.ts"),
      },
      {
        find: "@flare-im/vue-ui",
        replacement: path.join(vueImUiRoot, "index.ts"),
      },
    ],
  },
  server: {
    fs: {
      allow: [repoRoot],
    },
  },
  test: {
    environment: "node",
    // Keep component and utility tests in the same discovery window.
    include: ["src/**/*.test.ts"],
  },
});
