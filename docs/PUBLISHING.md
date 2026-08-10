# 发布到 npm — runbook

三个包（已 `npm pack --dry-run` 验证可发布）：

| 包 | 目录 | 大小 | 说明 |
|---|---|---|---|
| `@flare-im/tokens` | `flare-im-design/tokens` | 3.8 kB | L3 tokens（CSS/JS/TS/d.ts） |
| `@flare-im/ui-spec` | `flare-im-design/spec` | 6.5 kB | L2 组件契约（JSON + validator） |
| `@flare-im/vue-ui` | `flare-im-design/vue-im-ui` | 237 kB | L1 Vue 组件库（源码发布，171 文件） |

## 注意：发布前必须你来做（我做不了的部分）
- **npm 登录**：`npm login`（当前 `npm whoami` = 未登录 / ENEEDAUTH）。**输入凭证/token 只能你来**——我不碰认证。
- **确认包名可用 / 是否加 scope**：三个名字都是**无 scope**，可能已被占用或你想用 `@your-org/`。
  先查：`npm view @flare-im/tokens version`（报 404 = 可用）。
  若改 scope：改各 `package.json` 的 `name` 为 `@org/xxx`，并把 `@flare-im/vue-ui` 依赖里的
  `@flare-im/tokens` 一并改名；`publishConfig.access` 已设 `public`（scope 包公开发布需要）。

## 发布顺序（有依赖：Vue 包依赖 tokens）
```bash
# 1) tokens（先，Vue 包 deps 里是 @flare-im/tokens@^0.1.0）
cd flare-im-design/tokens && npm run build && npm publish

# 2) spec（独立）
cd ../spec && npm publish

# 3) Vue 组件库（依赖已发布的 tokens）
cd ../vue-im-ui && npm publish
```

## 发布后消费方怎么用
```bash
npm i @flare-im/vue-ui vue naive-ui vue-router
```
```ts
import "@flare-im/vue-ui/style.css";
import { MessageBubble, FlareConversationList } from "@flare-im/vue-ui";
```

## 注意
- **Vue 包发的是 Vue SFC 源码**（exports 指向 `src/`）：Vite 开箱即用；其他打包器需配 Vue SFC 编译 node_modules。
  （后续可加 `vite` lib build 出 `dist` 预编译版——注意包内有 48 处 `@flare-im/vue-ui/*` 自引用子路径，
  lib build 需配 subpath alias；源码发布则天然正确。）
- **贴纸/表情图片(67MB)已排除**（`files` 里 `!src/assets/**/*.webp` 等），只留 manifest.json；图片由产品侧自备，运行时按 URL 加载。
- **本地开发**：Vue 包 `@flare-im/tokens` 依赖写的是 `^0.1.0`，本地靠 `node_modules/@flare-im/tokens` 符号链接解析（已建）；**发布 tokens 后**其他机器 `npm i` 才能拉到。
- **版本**：改动后 `npm version patch|minor` 再发；三包独立版本。
- 每个包 `package.json` 已就绪：`license` MIT、`files`、`exports`、`publishConfig.access=public`、`prepublishOnly`(tokens 会重建)。
