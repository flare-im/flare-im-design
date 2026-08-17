import path from "node:path";
import { fileURLToPath } from "node:url";

import vue from "@vitejs/plugin-vue";
import { defineConfig } from "vitest/config";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "../..");
// 走**已声明的依赖**（devDep/peerDep `@flare-im/sdk`），不是手写兄弟仓路径。
// 原来写的 `../flare-core-typescript-sdk/src` 是本包还在 client-sdk 仓里时的相对
// 位置；抽成独立仓后那个路径根本不存在，独立 clone 一跑 vitest 就崩。
// 用 resolve 的好处是本地（node_modules 里是 symlink）与 npm 安装（真实包）都成立。
// 用 node_modules 解析而非 import.meta.resolve：包的 exports 不暴露
// package.json，resolve 会直接抛 ERR_PACKAGE_PATH_NOT_EXPORTED。
const typeScriptSdkRoot = path.join(
  __dirname,
  "node_modules/@flare-im/sdk/src",
);
const vueImUiRoot = path.resolve(__dirname, "src");

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: [
      {
        find: "@flare-im/sdk/web",
        replacement: path.join(typeScriptSdkRoot, "adapters/web/index.ts"),
      },
      {
        find: /^@flare-im\/sdk\/(.+)$/,
        replacement: path.join(typeScriptSdkRoot, "$1"),
      },
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
      // 更具体的子路径必须排在 `/composables` **前面**：字符串 find 是前缀匹配，
      // 否则 `/composables/sdk` 会先命中 `/composables` 并被拼成
      // `composables/index.ts/sdk`（表现为模块解析失败）。
      {
        find: "@flare-im/vue-ui/composables/sdk",
        replacement: path.join(vueImUiRoot, "composables/sdk.ts"),
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
        find: "@flare-im/vue-ui/sdk-lab",
        replacement: path.join(vueImUiRoot, "app/components/FlareSdkLabPanel.vue"),
      },
      {
        find: "@flare-im/vue-ui/app/style.css",
        replacement: path.join(vueImUiRoot, "app/styles/index.css"),
      },
      {
        find: /^@flare-im\/vue-ui\/app\/components\/(.+)$/,
        replacement: path.join(vueImUiRoot, "app/components/$1"),
      },
      {
        find: "@flare-im/vue-ui/app",
        replacement: path.join(vueImUiRoot, "app/index.ts"),
      },
      {
        find: "@flare-im/vue-ui",
        replacement: path.join(vueImUiRoot, "index.ts"),
      },
      {
        find: "@flare-im/sdk",
        replacement: path.join(typeScriptSdkRoot, "index.ts"),
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
    // 覆盖 src 全域，不要收窄回某个子目录。
    //
    // 曾经只 include `src/app/shared/testing/**`，于是放在被测代码旁边的测试
    // **一个都不会跑**，且 `vitest run` 照样绿——没有任何信号说它被漏了。
    // 组件层（src/utils、src/components…）的契约门禁必须在这个窗口内才有意义。
    include: ["src/**/*.test.ts"],
  },
});
