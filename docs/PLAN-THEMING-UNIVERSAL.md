# 通用性 + 自定义样式 + 美化（Vue 主题层）

## Goal
让任意 IM 项目**一行导入 + 少量 CSS 变量覆盖即可整体换肤**（含深色），无需魔改组件源、无需 SDK。默认外观不变（美化以默认主题质感为主）。中英主题指南 + 实测覆盖 `--primary` 全局生效。

## 现状诊断（已查清）
三层 token，但品牌色被**硬编码复制了 3 份**、级联断裂：
- L3 静态 `tokens/dist/tokens.css`（`flare-im-design-tokens/tokens.css`）：`--flare-color-primary: #7C3AED` 等，**仅浅色**（无 dark 变体）。
- 基础语义（`im-theme.ts` JS 注入）：`--primary: <hex>` —— 直接拷贝 token JSON 的 hex，**不** `var(--flare-color-primary)`；dark 由 provider 重注入浅/深值，所以基础 `--primary` 家族是**能随深色翻转的正确覆盖点**。
- 组件扩展（`apply-flare-theme.ts` JS 注入）：`--im-brand-primary: #7C3AED` / `--im-gradient-start: #7c3aed` 等**硬编码 hex**，不引用 `--primary`。
- 组件里多为 `var(--im-brand-primary,#7c3aed)` / `var(--im-primary,#7c3aed)` / `var(--im-bubble-sent,#7c3aed)`（三种名字同色）。
→ 覆盖 `--primary` 现在**不会**级联到 `--im-*`，换肤要手动改十几个变量。

## Constraints & decisions
- 覆盖点 = 基础 `--primary`/`--primary-hover`/`--primary-active`/`--bg-*`/`--text-*`/`--border-*`/`--error`/`--success` 家族（provider 按主题翻转，dark 正确）。
- 修 `apply-flare-theme.ts`：把品牌色 `--im-*` 扩展 token 由硬编码 hex → `var(--primary…)`/`var(--bg-selected)` 等（默认值不变，纯级联接线）。
- 默认外观零变化（fallback 保留）；只增加"覆盖 1~几个变量即全局生效"的能力。
- 不动生成物 `tokens/dist/*`（GENERATED）。不引入编译期依赖。flare-im-spec：跨端行为归 core，本项是 Web/Vue 表现层的主题接线，属 L1 平台适配。
- 先证后修：preview 里覆盖 `--primary` 截图对比 → 修 → 再截图确认全局翻转。

## Status: DONE ✅（级联接通 + 纯 CSS 文档 + 实测换肤，dark-safe）

## Steps
- [x] 实测确认级联断裂 ✅：静态消费方 `--flare-color-primary` 有定义但 `--primary`/`--im-*` 皆空，组件靠字面量 `#7c3aed`，覆盖 `--flare-color-*` 无效。
- [x] **组件级 fallback 接线 ✅**：脚本把 `var(--im-x, #hex)` → `var(--im-x, var(--flare-color-Y, #hex))`（hex→canonical 映射），vue-im-ui 组件 **289 处 / 36 文件** + site demo 同步。默认渲染逐字节不变，覆盖 canonical 即级联。vue-tsc 净。
- [x] **JS 扩展层品牌 token 接线 ✅**：`apply-flare-theme.ts` 把 `--im-brand-primary`/`--im-gradient-start/end`/`--im-brand-primary-soft`/`--im-message-outgoing`/`--im-presence-online` 由硬编码 hex → `var(--flare-color-*)`；**dark-safe**（查 tokens.json：dark 仅覆盖 bubble.self → 唯 `--im-message-outgoing` 做 `isDark?JS值:flare-var` 双分支，其余 primary/success/info 无 dark 差异直接接）。让 `deriveFlareTheme`/provider 路径也整体生效。
- [x] **复测 ✅**：preview 覆盖 `--flare-color-*`（teal）→ 未读徽标/pin/选中行翻转；ThemePlayground 点 Forest → 整个 IM 预览紫→绿（气泡/在线态），语义橙草稿保留。
- [x] **主题指南（中英）✅**：新增"引入即用（纯 CSS · 任何项目）"——一行 `import style.css` + `:root{ --flare-color-* }` 覆盖 + 局部作用域示例 + **权威可覆盖变量表**，链到 tokens 页。
- [x] **验证 ✅**：vue-tsc / vitepress build 净、preview 换肤实测、无溢出、控制台净。

## Notes
- 后续可选：把 npm 包 files/exports 收敛到组件库（去 demo app）——"方便引入"的另一半，另起一轮。
