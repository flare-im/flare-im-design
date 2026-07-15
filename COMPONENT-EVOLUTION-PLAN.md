# 组件设计全面进化 —— 设计立意与计划

## 立意（frontend-design）
**「考究的紫」** —— 一个签名动作贯穿全库:
- **中性色带微紫底**:现有纯冷灰(#F5F6F8/#6B7280/#E7E9EE…)偏通用 AI 味;整体色相微微偏向品牌紫(~262°、极低饱和),白色卡面保留纯白。全库因此显得"为这套紫而设计",而非通用灰。
- **柔和的分层景深**:单层阴影 → 双层(环境光 + 直接光),更高级。
- **更慷慨的圆角**:圆角尺度整体上调 + 补 `2xl`/`full`,贴近飞书/Telegram 现代 IM。
- **有生命的动效**:通用 `ease` → 精修 ease-out 曲线(0.22,1,0.36,1),补一个轻微回弹 `spring`。
- **统一的焦点环** token(a11y + 打磨感)。
其余保持克制:品牌紫 #7C3AED、语义色、排版尺度、间距节奏不动。

## 关键事实（架构）
- **tokens.json 是唯一真源**:`im-theme.ts` 的 `imTheme = flareDesignTokens`(生成物);`generateCSSVariables` 发 `--primary/--bg-*/--text-*/--radius-*` 均来自它;`apply-flare-theme` 把 `--im-*` 桥到这些;`tokens.css` 发 `--flare-*`。改 tokens.json + `node build.mjs` → 全平台(css/ts/dart/swift/kotlin)一致进化。
- 阴影/动效只发到 CSS(web);颜色/尺寸发全平台。
- 只能浏览器验证 Vue;原生靠同源生成保持一致。

## Status: DONE（token 单源进化落全平台 + 签名点睛，明暗浏览器验证）
Current focus: —

## Steps
- [x] 审计现状（站点 + tokens + 主题架构）→ 确认单一真源（`imTheme = flareDesignTokens`）
- [x] 进化 `tokens/tokens.json`:中性色微紫底(light+dark)、圆角上调(lg8→10/xl12→14/xs2→3/sm4→6/md6→8)+补 2xl18/full999、双层阴影、动效 `cubic-bezier(0.22,1,0.36,1)`+新增 spring、加 focusRing(明暗)。
- [x] `node build.mjs` → dist/tokens.{css,ts,js} + 原生四端 token 文件（31 色×2 主题、29 尺寸；Swift/Kotlin/Dart 均含 focusRing/radius2xl/radiusFull）。
- [x] 浏览器验证:三链路(flare/im/short)全更新；聊天窗明色(微紫底/白气泡软阴影)+暗色(紫黑 #131019/#1B1922、暗紫气泡)均协调。
- [x] 签名点睛:`--im-brand-gradient`(桥接层定义) → 发送键品牌渐变 + hover 抬升/active 按压 + 双层品牌投影；`--im-focus-ring` 就位。实测发送键 bg=linear-gradient(135deg,#7C3AED→#5B21B6)。
- [x] vue-tsc 净 + 14/14 测试；原生 kit 无手动构造 FlareColors → 加字段安全。

## 教训 / 事实
- **单一真源确认**:`im-theme.ts` `export const imTheme = flareDesignTokens`（生成物）；改 tokens.json + `node build.mjs` → `--flare-*`(tokens.css) / `--im-*`(apply-flare-theme 桥) / 短名 `--primary/--bg-*/--radius-*`(generateCSSVariables) 三条链全流过。阴影/动效仅 web；颜色/尺寸落全平台。
- **文档站双主题坑**:VitePress 外观开关(`.dark`/`data-flare-theme`) 与 kit `FlareUiProvider`(localStorage `flare-web-theme-mode` → applyFlareTheme 设 `data-theme`) 是两套；只切一个会造成 `--flare-*` 暗 / `--im-*` 亮 的混合态。验证时两个都要设一致（`vitepress-theme-appearance` + `flare-web-theme-mode`）。
- 生成器加法安全：新增颜色 key(含 rgba)/radius key 都能落 css/dart/swift/kotlin；dark 缺省回退 light。

## Notes
- 生成器加法安全:新增颜色 key(含 rgba)、新增 radius key 都能落 css/dart/swift/kotlin。
- dark 缺省回退 light 值(darkColors = {...light, ...dark})。
- 谨慎:radii/中性色改全平台但只能验 Vue → 改动保持 subtle、可感知不突兀。
