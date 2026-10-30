# Visual Baselines（2.0.0-rc.1 · P0-12 DoD 23）

真源：`tests/visual/manifest.json`。门禁 `node tooling/check-visual-regression.mjs`（release-check 的 `visual-regression`）。

截图基线最大的风险不是没有基线，而是**重建基线太顺手**：一条真实回归改了几百个像素，跑一次 `--update-snapshots` 就变成"通过"了。所以这份文档的重点是重建基线时那一步人工判断，以及让它留下痕迹。

## 1. EXPECTED 还是 REGRESSION

快照对不上时，先回答一个问题：**这次差异是不是我这次改动应该造成的？**

| 判据 | EXPECTED | REGRESSION |
|---|---|---|
| 差异位置 | 落在本次改动的组件 / token 上 | 出现在没碰过的地方 |
| 差异性质 | 只有颜色、间距、字重等本次有意调整的属性 | 版式移位、元素消失、裁切、重叠 |
| 差异范围 | 与改动影响面吻合 | 一条小改动动了几十张图 |
| 能否说清 | 能用一句话说明为什么该这样 | 说不清，或者要靠"大概是渲染差异" |

**任何一条答不上来就按 REGRESSION 处理**——先查代码，不要先重建基线。

必须逐张看图，不能只看像素数。三张图都在 `website/test-results/` 下：`*-expected.png`、`*-actual.png`、`*-diff.png`。diff 图里红色是变化区域；确认红色只落在预期范围内。

本轮的三次重建都走了这个流程，可以照着看：

- **complete-app 参考应用**：diff 显示会话行时间从 `02:27 PM` 变成 `14:27`，外发气泡右移约 15px。位置对得上（时间戳 + 气泡宽度），性质却不对——我没改过时间格式。查下去发现是 `FlareUiProvider` 把宿主设的 en-US 重置成了 zh-CN。**按 REGRESSION 处理，修代码，基线未动。**
- **Flutter `message_status.png`**：diff 只有状态文字与图标的颜色，版式逐像素未动，正是 P0-7 收深 token 的直接结果。**EXPECTED，重建。**
- **iOS `swiftui-message-meta.png`**：同上，灰阶与错误红变深。**EXPECTED，重建。**

2026-10 那次重建（CI 视觉任务自 9 月下旬起一直红）也逐张走了这个流程：

- **Vue darwin 50 张**，全部 EXPECTED，每组都能指到提交：
  - 输入区扁平化（ba305b0）；
  - 会话行 token 化（ba305b0）；
  - 搜索框去聚焦发光，附件预览改由 FlareModal / 底部面板绘制（ba305b0、a5a9989）；
  - 回执只剩五态、气泡面色加内联元信息、920 阅读列（f4b0477、2440ff1、ba305b0）。
  - 期间改掉的是夹具与陈旧断言，不是基线：
    - 「没有更多消息了」提示停留 2.4 秒，截图会不会拍到它取决于机器负载，所以截图前先把时钟快进；
    - ReadReceiptSheet 的 demo 加载即抛错。
  - 真回归修在 Kit 里：窄屏输入行 46、已读名单表头内缩、SchemaForm 步进键无名。
- **iOS 2 张**：b0cee27 的回执五态、实心失败图标、内联元信息。同时快照固定按 2x 渲染（见第 3 节）。
- **Flutter**：没有重建，只是按平台分目录。

## 2. 重建的动作

新增用例要在 `tests/visual/manifest.json` 的对应 `baselineFiles` / `platforms` 里加一行。门禁盯的就是这一步：**一张没有人在清单里写过的 PNG，就是一次没有人审过的重建**；反过来，清单里有名字却没有文件，说明这条用例的基线丢了，下一次跑会重新写一张、然后跟它自己比。

```bash
# Vue（Playwright）
npx --prefix website playwright test --update-snapshots --grep-invert "@a11y|@perf"

# Flutter（只写本机系统那一套：baselines/macos/ 或 baselines/linux/）
flutter test --no-pub --update-goldens -C packages/flutter-im-ui

# iOS
UPDATE_GOLDENS=1 swift test --package-path packages/ios-im-ui

# Compose（需要固定的 Pixel_9_API_35 AVD，离线单测跑不到）
cd packages/android-im-ui && ./gradlew connectedDebugAndroidTest \
  -Pandroid.testInstrumentationRunnerArguments.class=com.flare.im.ui.RcScreenshotHarnessTest \
  -Pandroid.testInstrumentationRunnerArguments.compareBaselines=true

# 清单同步（改完再跑门禁）
node tooling/check-visual-regression.mjs
```

## 3. 基线按平台分开存

截图是一次渲染。macOS 与 Linux 的文字栅格化不一样，共用一套基线，结果就是 CI 拿 Linux 的输出去比 macOS 的像素，**凡是带字的用例都会红**。Flutter 的测试引擎在两个系统上画曲线和边缘也差约 1%。所以基线按平台分目录存：

- Vue：`tests/visual/vue/baselines/<platform>/`，即 `darwin/` 与 `linux/`；
- Flutter：`packages/flutter-im-ui/test/goldens/baselines/<Platform.operatingSystem>/`，即 `macos/` 与 `linux/`。CI 固定 Flutter 版本（与本机同为 3.44.1），否则引擎一升级，Linux 那套就会在基线底下移位。

**Linux 那套只在 CI 镜像上生成**，本机（darwin/arm64）生成的不算数：容器架构不同，栅格化仍有差别。流程如下：

1. 先让 darwin 那套在本机按第 1 节审过，并且全绿。
2. 在 GitHub Actions 里对目标分支手动触发 CI，勾选 `baselines`：`gh workflow run CI --ref dev -f baselines=true`。这次运行不做比对，网站任务用 `--update-snapshots=all` 重画，Flutter 任务用 `--update-goldens test/goldens` 重画。
3. 下载产物 `website-visual`（`tests/visual/vue/baselines/linux/`）与 `flutter-goldens`（`test/goldens/baselines/linux/`），与同名的 darwin / macos 基线逐张对照：版式、元素、颜色必须一致，差异只能是栅格化本身。
4. 提交，并在清单的 `platforms.linux` 里登记。

平时的 CI 失败也会上传 `website-visual` 与 `flutter-goldens`（actual / diff 图，以及 Flutter 的 failures 目录），审图不必在本机复现。

**iOS 快照**由宿主窗口的缓存位图画出。它原来跟随显示器的缩放：笔记本屏是 2x，外接屏与 CI runner 是 1x，于是同一张图在两台机器上尺寸不同。现在固定按 2x 画（`VisualSnapshotTests.snapshotScale`），与显示器无关。

另有两项宿主设置也会改像素，快照里一并固定：

- 「减弱动态效果」为关。runner 默认开着，开着时发送中的转圈会画成时钟。
- 排版语言为 en-US。`·` 这类东亚宽度不定的标点按系统偏好语言取字形：zh-Hans 系统取 CJK 字体里较宽的点，en-US 系统取拉丁字体里较窄的点。按 en-US 排版时两种系统画得一样；按 zh-Hans 排版拉不回 en-US 系统上的宽点。

CI 另外固定 Xcode 26.4，让 SDK 不随镜像升级而变。

## 4. 四端覆盖

| 平台 | 渲染器 | 基线数 | 每次验证跑得到吗 |
|---|---|---|---|
| Vue | Playwright / Chromium（darwin、linux 各一套） | 54 × 2 | 是 |
| Flutter | `flutter test --update-goldens`（macos、linux 各一套） | 2 × 2 | 是 |
| iOS | `UPDATE_GOLDENS=1 swift test`（macOS 宿主渲染，固定 2x） | 2 | 是 |
| Compose | instrumented，固定 Pixel_9_API_35 / 420dpi | 3 | **否**——CI 的模拟器任务跑交互回归，但不开 `compareBaselines` |

Compose 有基线（明暗两套加 200% 大字号），但它是 instrumented 测试：只有在那台固定 AVD 上才能生成与比对。缺口不是"没有基线"，而是**没有任何东西会自动重新比对它们**。

## 6. 应用级视觉：Golden App（Round 5 新增）

组件基线证明组件契约，应用基线证明整体组合。第五轮给 golden app（`flare-social-web-app`）加了一层：

- 位置：**应用仓库**里 `tests/app-visual/baselines/<platform>/`（12 张：收件箱、群聊、暗色群聊、搜索、群成员、设置、图片预览、空态、错误态、平板、手机、手机暗色）。跑在测试专用的内存夹具核心上，不连后端、不登录。
- 命令：`npx playwright test -c tests/app-visual/playwright.config.ts application-visual.spec.ts`，更新用 `--update-snapshots`。
- 确定性：macOS 上以经典滚动条启动 Chromium（`tests/app-visual/support-bin/chromium-classic-scrollbars.sh`，与网站同一手法），`animations: "disabled"`，时钟固定，`reducedMotion: "reduce"`。
- 容差用**像素个数**（`maxDiffPixels: 120`），不用比例。整窗截图上百万像素，0.2% 的比例容差等于两千多像素——一整句文案改掉都可能照样绿。第五轮就撞上过：把空态文案换成「会话列表没有加载出来」后，比例容差下用例仍然通过。
- 平台分开存，理由同第 3 节；`linux/` 一套同样要在 CI 镜像上生成，本机不算数。

## 5. 没覆盖的

- **Compose 的自动比对**——它的基线只在固定 AVD 上才跑得动，本轮的四端验证扫不到它。要进 CI 需要模拟器 runner，或者改用 Paparazzi / Roborazzi 这类离线截图框架（是一次依赖与构建链的变更，不在 RC 范围）。
- **真机 / 模拟器**上的原生渲染：Flutter 与 iOS 的基线都是宿主机离线渲染，不等于设备上的观感。
- **动效**：所有截图都关掉了动画（`animations: "disabled"`），过渡过程没有基线。
- ~~浮层三件套（2026-09-28）待重建的基线~~（2026-10 结案）：
  - `surface-integrity` 两处陈旧断言改为现行契约后，`attachment-surface-*` 按第 1 节审图重建：1280 宽由 FlareModal 绘制，390 宽是底部面板。
  - `sheet-surface-*` 比对通过，未重建。
  - Compose RC 截图里若有面板，遮罩已由窗口 dim 改为 `colors.scrim`；下次在固定 AVD 上比对时，同样按 EXPECTED 审图。
