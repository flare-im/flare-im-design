# Optimal Component Library Architecture Report

本报告记录 Flare IM Design 在 `2.0.0-rc.1` 开发阶段完成的 breaking cleanup。目标是得到当前正确、长期可维护的组件库结构，不提供旧目录、旧导入或旧 token 的兼容层。

## 1. Before tree

重构前的 tracked 顶层结构如下。四个平台包、站点、脚本、设计源和临时原型都直接占用 root，Swift manifest 也错误地位于仓库根目录。

```text
flare-im-design/
├── .codegraph/
├── .github/
├── android-im-ui/
├── assets/
├── design-assets/
├── docs/
├── flutter-im-ui/
├── ios-im-ui/
├── prototypes/
├── scripts/
├── site/
├── spec/
├── tokens/
├── vue-im-ui/
├── .gitignore
├── CHANGELOG.md
├── CHANGELOG.zh-CN.md
├── LICENSE
├── Package.swift
├── README.md
├── README.zh-CN.md
└── jitpack.yml
```

主要问题：平台包没有共同 ownership 边界；`site`、`scripts`、`prototypes` 职责含混；root `Package.swift` 只描述 iOS 包；产品页面、SDK facade、诊断 UI、历史审查截图与组件库发布内容混杂。

## 2. Final tree

```text
flare-im-design/
├── .github/
├── assets/
│   ├── design-source/
│   └── emoji-sticker/
├── docs/
├── examples/
│   ├── gallery/
│   ├── vue/
│   ├── flutter/
│   ├── compose/
│   └── swiftui/
├── packages/
│   ├── vue-im-ui/
│   ├── flutter-im-ui/
│   ├── android-im-ui/
│   └── ios-im-ui/
├── spec/
│   └── scenarios/
├── tests/
│   ├── consumers/
│   │   ├── vue/
│   │   ├── flutter/
│   │   ├── android/
│   │   └── swift/
│   └── visual/
│       ├── vue/
│       ├── compose/
│       └── ios/
├── tokens/
├── tooling/
├── website/
├── .gitignore
├── CHANGELOG.md
├── CHANGELOG.zh-CN.md
├── COMPATIBILITY.md
├── CONTRIBUTING.md
├── LICENSE
├── PUBLIC_API.md
├── README.md
├── README.zh-CN.md
├── jitpack.yml
├── package-lock.json
└── package.json
```

最终为 11 个职责明确的 tracked 顶层目录、4 个真实平台包、4 个独立消费者和 4 端视觉 runner。root 不再允许 `.build/`、`.codegraph/`、旧平台目录或临时产物。

## 3. Removed directories

- `android-im-ui/`、`flutter-im-ui/`、`ios-im-ui/`、`vue-im-ui/`：源码迁入 `packages/*-im-ui/` 后删除旧 root 路径，没有副本或 symlink。
- `design-assets/`：唯一设计源迁入 `assets/design-source/app.pen`。
- `site/`：迁入并收敛为 `website/`。
- `scripts/`：长期有效脚本按 validation、generation、docs、visual、release 职责迁入 `tooling/`；一次性脚本删除。
- `prototypes/composer-studio/`、`prototypes/voice-studio/`：静态实验不再作为第二套组件实现保留。
- `flutter-im-ui/example/`：与统一 examples 重复，改由 `examples/flutter/` 承担。
- `docs/ui-review-20260909/`、日期化 `docs/releases/*`：旧审查截图、中间 JSON 和 RC 临时报告删除。
- `.codegraph/` 与 root `.build/`：无仓库职责的缓存占位和 Swift 旧根包产物删除，并从 scope allowlist 移除。
- Vue package 内仅服务 auth、SDK diagnostics 和产品 workbench 的页面、样式及状态桥接目录被删除；组件库通用布局与组合 pattern 保留。

## 4. Removed files

- root `Package.swift`；Swift manifest、source、tests 已在 `packages/ios-im-ui/` 自包含。
- `.github/CONTRIBUTING.md` 和 `.github/GOVERNANCE.md`；有效贡献约定统一到 root `CONTRIBUTING.md`，未维护的重复治理文档删除。
- `FlareAuthScreen.vue`、`FlareDiagnosticsConsole.vue`、`FlareWorkbenchShell.vue` 及 auth/diagnostics/workbench product CSS。
- `useFlareCoreClient.ts`、`useFlareSessionBridge.ts`、`useFlareWorkbenchUi.ts`、`composables/sdk.ts` 等产品 SDK orchestration。
- `messageState.ts` 及 numeric message status 兼容逻辑，替换为 `MessageLifecycle` 与 `MessageStatusState`。
- SDK error formatter、login cold-start、initial-history repair、archive/search race 等产品流程测试。
- `docs/DESIGN.md`、`docs/DISTRIBUTION-DESIGN.md`、`docs/IM-DISTRIBUTION.md`、`docs/KIT-POLISH-DESIGN.md`、旧验收与 rollout 文档；有效内容已重写进当前 architecture、release、testing、theming 文档。
- 旧 UI review PNG、browser-check JSON、一次性 release JSON/Markdown 和重复 baseline 输出。
- 所有验证过程产生的 `.build`、`build`、`.dart_tool`、`.gradle`、`.kotlin`、VitePress dist/cache、Playwright result、临时 Xcode project 和临时 `local.properties`。

物理迁移产生的大量旧路径删除不代表源码丢失；保留的组件源码、测试与资源均在新 package 路径继续维护。

## 5. Removed compatibility layers

- 旧 root platform paths 与任何 path alias、facade、forwarding manifest 全部为 0。
- Vue package exports 只保留 9 个显式发布入口，没有 compatibility wildcard 或内部目录穿透。
- CSS `--im-*`、`--wechat-*`、self/other bubble aliases 与对应 Dart/Kotlin/Swift legacy aliases 已删除。
- 旧 fixed Violet/purple message fallback 与 `brandPurple` 语义已删除。
- numeric message state 已从 active components、website demos、examples 和 fixtures 中移除。
- SDK-bound message/action models 改为 host-neutral contracts；package 不再 import product SDK。
- deprecated component names、旧根 `Package.swift` forwarding 和旧 consumer paths 不保留。
- `check-legacy-paths.mjs`、`check-legacy-im-tokens.mjs`、package export gate 和 package boundary gate 持续防止回归。

## 6. Root files kept and exact reason

| File | Exact repository-wide responsibility |
|---|---|
| `.gitignore` | 四个平台及 Node 文档工具的统一生成物策略。 |
| `README.md`, `README.zh-CN.md` | 仓库级双语入口、package map 与统一验证命令。 |
| `CHANGELOG.md`, `CHANGELOG.zh-CN.md` | 跨包 breaking release 历史。 |
| `COMPATIBILITY.md` | 当前 RC 的平台、runtime 与 breaking compatibility policy，不提供兼容实现。 |
| `CONTRIBUTING.md` | 跨 Vue/Flutter/Compose/SwiftUI 的贡献流程与质量门禁。 |
| `LICENSE` | 所有发布包与文档的仓库许可证。 |
| `PUBLIC_API.md` | 四个平台公共 API、导出稳定性与内部边界的统一政策。 |
| `package.json` | monorepo workspace、生成链、28 项统一质量门禁、consumer 与 website orchestration。它没有 runtime dependencies。结论：`ROOT_PACKAGE_JSON_REQUIRED`。 |
| `package-lock.json` | Node workspace、生成器、Vue package 与 website 的可复现工具链。 |
| `jitpack.yml` | JitPack 的 root discovery protocol；只委托 `packages/android-im-ui` 构建，因外部协议要求保留在 root。 |

## 7. Root files removed

- `Package.swift`：只服务单个 Swift package，不属于 repo-wide manifest。已迁移到 `packages/ios-im-ui/Package.swift`，root 不保留 wrapper。
- `.codegraph/.gitignore`：仅为空缓存目录占位，不属于组件库源码、规范或工具。

没有删除 repo-wide license、readme、changelog、public API 或构建 orchestration 文件。

## 8. Final packages

| Path | Published identity | Ownership | Validation |
|---|---|---|---|
| `packages/vue-im-ui` | `@flare-im/vue-ui@2.0.0-rc.1` | Vue 3 components、contracts、theme provider、i18n、utilities | 245 tests、typecheck、189 SFC compile、pack、browser download |
| `packages/flutter-im-ui` | `flare_im_ui 2.0.0-rc.1` | Flutter widgets、semantic tokens、assets、goldens | analyze、340 tests、publish dry-run、consumer bundle |
| `packages/android-im-ui` | `com.flare.im:im-ui-compose:2.0.0-rc.1` | Jetpack Compose components、tokens、unit/instrumentation tests | test、lint、AAR、10 device tests、consumer APK |
| `packages/ios-im-ui` | SwiftPM product `FlareIMUI` | SwiftUI components、tokens、resources、tests | resolve、build、164 tests、consumer build、simulator example build |

`tokens/` 是仓库级跨平台 source-of-truth package，不复制成第五个平台包。General UI 与 IM UI 目前是同一发布物内的真实逻辑层，没有制造 8 个空或高度耦合的理论 package。

## 9. General/IM boundaries

依赖方向固定为：

```text
foundation -> general-ui -> im-ui -> flare-product
```

- `foundation`：tokens、theme resolution、platform-neutral state/contracts。
- `general-ui`：General、Layout、Navigation、Form、Feedback、Overlay 与通用 Patterns。
- `im-ui`：Conversation、Message、Composer、Media、Contacts、Call、Profile、Moments。
- `flare-product`：不在本仓库实现；认证、SDK 生命周期、数据持久化、路由和业务编排由 host app 负责。
- IM UI 可以依赖 General UI；General UI 不得 import IM 或产品 SDK。
- `spec/component-layers.json` 对 139 个组件逐项分层，四个平台 ownership scan 与 Vue/Flutter source import scan 已通过。

## 10. Theme architecture

```text
tokens/tokens.json + tokens/themes.json
                  |
                  v
            tokens/build.mjs
                  |
      +-----------+-----------+-----------+
      |           |           |           |
     CSS         Dart       Kotlin       Swift
      |           |           |           |
   semantic/component tokens on all four platforms
                  |
                  v
 Conversation -> Message -> Status/Reaction -> Composer/Focus
```

- `tokens/themes.json` 定义 required semantic paths、Light/Dark defaults 和六个品牌映射。
- 生成结果包含 `tokens/dist/tokens.{css,ts,js,d.ts}`、Flutter `flare_tokens.dart`、Compose `FlareTokens.kt`、SwiftUI `FlareTokens.swift`。
- 当前生成规模：141 个 light CSS vars、62 个 dark overrides、57 个 size tokens、每个平台 56 个 colors x 6 brands x 2 modes。
- component 只消费 semantic/component token；raw palette 仅允许 theme/token explorer 使用。
- `check-theme-contract.mjs` 校验 6 x 2、四端 generated target、共享 scenario，以及 ConversationRow、MessageBubble、MessageStatus、Reaction、ComposerSendButton、CallDock 等敏感消费者。

## 11. Six built-in themes

| Theme | Light outgoing / read | Dark outgoing / read |
|---|---|---|
| Violet | `#6D28D9` / `#6D28D9` | `#5B21B6` / `#C4B5FD` |
| Ocean | `#1D4ED8` / `#1D4ED8` | `#1E40AF` / `#93C5FD` |
| Forest | `#15803D` / `#15803D` | `#166534` / `#86EFAC` |
| Sunset | `#C2410C` / `#C2410C` | `#9A3412` / `#FDBA74` |
| Rose | `#BE123C` / `#BE123C` | `#9F1239` / `#FDA4AF` |
| Graphite | `#475569` / `#475569` | `#475569` / `#CBD5E1` |

每个 mode 还单独定义 outgoing foreground/border、selected surface/border、focus ring、reply border、reaction selected 与 read-on-outgoing；不是把所有 message 值机械绑定到一个 global primary。

## 12. MessageBubble theme mapping

- Incoming 使用中性 semantic background/foreground/border，Light 为白色体系，Dark 为深色 surface。
- Outgoing 分别使用六主题自己的 message background、白色 foreground 和独立 border；Violet 不再泄漏到 Ocean/Forest/Sunset/Rose/Graphite。
- Selected 使用 `message.selected.background/border`，不直接引用品牌色常量。
- Failed 使用共享 danger semantics：Light `#FEF2F2/#B91C1C/#FCA5A5`，Dark `#3F1D24/#FCA5A5/#991B1B`。
- Meta、reply、reaction、link 和 status-on-outgoing 都有独立语义，保证时间、双勾和 reaction 在深浅 bubble 上可读。
- Vue、Flutter、Compose、SwiftUI 的 Bubble 与 Status 视觉契约均由同一 source 生成并受 theme gate 保护。

## 13. MessageStatus theme mapping

| State | Semantic behavior |
|---|---|
| `pending` | neutral/subtle token；保留等待 geometry。 |
| `sending` / `retrying` | neutral animated state，并尊重 reduced motion。 |
| `sent` | subtle neutral token，单勾 geometry 不变。 |
| `delivered` | secondary neutral token，双勾 geometry 不变。 |
| `read` | 当前 theme 的 `message.status.read`；位于 outgoing bubble 时使用 `readOnOutgoing`。 |
| `failed` | semantic danger，与品牌主题解耦。 |

旧 numeric 状态已删除。当前 contract 使用 `MessageLifecycle` 与 `MessageStatusState`，Swift/Flutter/Compose 使用等价 enum。视觉更新只改变正确的主题语义颜色，不改变 Sent/Delivered/Read 的 geometry。

## 14. Custom theme contract

- Web 使用 `FlareCustomTheme { name, light, dark }`，通过 `createFlareCustomTheme` 校验，并由 `resolveFlareTheme`、`flareThemeVars`、`applyFlareTheme` 或 `FlareThemeProvider` 应用。
- Light 和 Dark 最低必须覆盖 primary、surface、text、border、focus、message outgoing、message read 与 danger 对应语义；推荐从最接近的 built-in theme 深拷贝后覆盖。
- Flutter 可复制 built-in `FlareColors` 后通过 `FlareTheme(colors: ...)` 注入。
- Compose 通过 `FlareThemeProvider(colors = ...)` 注入 `FlareColors`。
- SwiftUI 通过 `FlareThemeColors` 和 environment/theme modifier 注入。
- 自定义主题不能修改 generated token 文件；生成物由 `tokens/build.mjs` 唯一维护。

## 15. Website result

- `website/` 是唯一 VitePress 文档与 live demo host；旧 `site/` 和产品官网/SDK diagnostics 路由已删除。
- 首页直接展示可交互 IM workspace，而不是营销 hero；六主题切换会同步改变 selection、outgoing bubble、read status、reaction、composer send 和 focus。
- Theming、tokens、patterns、platforms、accessibility、migration、release 与 API guides 均提供中英文入口。
- Playwright 固定 `Asia/Shanghai` 与测试时钟，消除 `Date.now()` 导致的视觉基线漂移。
- VitePress build 与 16 项 Playwright visual/IA/accessibility tests 通过；移动端页面 overflow gate 通过。

## 16. Component Catalog

- 139 个 stable components，15 个真实分类：General、Layout、Navigation、Form、Feedback、Overlay、Conversation、Message、Composer、Media、Contacts、Call、Profile、Patterns、Moments。
- 要求的 14 个核心分类全部存在；Moments 因拥有 8 个真实组件而保留为独立 domain，不被强塞进其他分类。
- 每个 stable entry 提供 Status、Platforms、Since、Demo、Usage、API、States、A11y；278 个中英文组件页全部可发现且已规范化。
- Vue 139/139；Flutter 138/139，仅 `ConfigProvider` 为 Web-specific；Compose 与 SwiftUI 137/139，仅 `ConfigProvider` 和 `DesktopWorkbench` 为明确平台差异。
- 对所有已实现 surface，missing props、missing events、extra events 和 no-surface 均为 0。
- Catalog 页面支持 category filter、搜索和 mobile table 行为；139 个 basics、26 个 core entries 与 complex state contract 均通过 coverage gate。

## 17. Examples

- `examples/gallery/`：共享 gallery manifest，不再复制平台 UI 实现。
- `examples/vue/`：只通过 `@flare-im/vue-ui` 和 `@flare-im/tokens` 公共入口消费。
- `examples/flutter/`：独立 Flutter Web app，覆盖组件与六主题选择。
- `examples/compose/`：独立 Android app，覆盖组件、主题与 Command Palette；`assembleDebug` 通过。
- `examples/swiftui/`：XcodeGen spec + Swift source，覆盖组件、六主题、Light/Dark 与 Command Palette；iOS Simulator build 通过。
- 重复的 package-local gallery、旧 workbench demo 与静态 prototype 已删除。

## 18. Tests

| Layer | Result |
|---|---|
| Vue unit/component | 36 files, 245 tests passed |
| Flutter unit/widget/golden | 340 tests passed |
| Compose JVM | `./gradlew test` passed |
| Compose device | Pixel 9 API 35, 10/10 connected tests passed |
| Swift package | 164 tests passed |
| Website | 16 Playwright tests passed |
| Consumers | Vue tarball、Flutter path package、Compose Maven local、SwiftPM path package all passed |
| Unified gates | 28/28 design-system gates passed |

重复 migration fixtures、compatibility-only tests 和 product SDK workflow tests 已删除；shared scenarios 现在同时驱动 gallery、interaction contract、docs 与 visual metadata。

## 19. Builds

- Vue：`npm test`、`npm run typecheck`、`npm run build`、`npm run pack`、`npm run test:browser-download` 全部通过。
- Flutter：`flutter analyze`、340 tests、example web build、consumer bundle、`dart pub publish --dry-run` 0 warnings。
- Android：unit test、lint、`assembleRelease`、AAR、Maven local consumer、example/consumer debug APK、connected Android tests 通过。
- Swift：package resolve、`swift build`、164 tests、Swift consumer build、XcodeGen iOS Simulator app build 通过。
- Website：VitePress production build 通过。
- Spec/tokens：139-component spec、signature drift、generated drift、6 x 2 theme generation 全部通过。
- Production npm dependencies：`npm audit --omit=dev` 为 0 vulnerabilities。

## 20. Visual regression

- Vue：12 个 committed baselines，包括 RC Light/Dark/Large Text、六个 Light themes，以及 Violet/Ocean/Graphite Dark representatives。
- Flutter：`core_components.png` 与 `message_status.png` golden；新 semantic primary 与 theme-aware read color 经人工对照后更新并复跑通过。
- SwiftUI：`swiftui-message-meta.png` 与 `swiftui-large-text.png`；只接受 read 双勾随 Violet semantic color 改变，geometry 与大字号布局不变。
- Compose：active instrumentation runner 与设备测试实际执行；10/10 在 Pixel 9 API 35 通过。
- 25 个 shared fixtures、4 个 active platform runners、9 个 theme-specific baselines 由 root visual gate 校验。
- Token contract 对完整 6 themes x 2 modes 做静态语义验证；视觉矩阵用代表性暗色场景控制 baseline 数量，避免 6 x 2 x 139 爆炸。

## 21. Remaining P2/P3

P0：0。P1：0。所有本轮 completion conditions 已满足。

P2：

- 可将 Forest/Sunset/Rose Dark 加入截图基线。当前三者已有 6 x 2 token contract 和跨端生成校验，但没有单独 committed dark screenshot。
- 若 Compose Desktop 或 SwiftUI macOS 将来成为正式交付目标，再实现对应 `DesktopWorkbench`；当前它们是显式平台差异，不是 signature drift。Flutter PC 已有对应 workbench surface。

P3：

- full `npm audit` 仍报告 5 个 dev-only advisories：Vitest 修复要求跨主版本，VitePress 1.6.4 的 Vite/esbuild 链暂无无破坏修复；发布运行时依赖审计为 0。
- 本机 Android SDK 的 NDK `27.0.12077973` 缺少 `source.properties`，且 AGP/Gradle 输出 Gradle 9 compatibility 提示；组件源码已无 Kotlin Material deprecation warning。
- Flutter Web consumer 会显示缺少可选 CupertinoIcons font 的工具提示，但 build、analyze 与 package consumer 均通过，组件源码未引用该字体。

20 维最终审计均值为 9.8/10：Repository simplicity 10、Package structure 10、Root cleanliness 10、Component library purity 10、Theme architecture 10、Theme switching 10、MessageBubble theming 10、Cross-platform theming 9.8、Token clarity 10、Spec clarity 10、Website quality 9.7、Discoverability 10、Examples 9.7、API clarity 9.8、Maintainability 9.8、Developer experience 9.7、Accessibility 9.7、Visual consistency 9.8、Anti-AI restraint 9.8、Build/release clarity 9.8。
