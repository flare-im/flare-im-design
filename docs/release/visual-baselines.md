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

## 2. 重建的动作

新增用例要在 `tests/visual/manifest.json` 的对应 `baselineFiles` / `platforms` 里加一行。门禁盯的就是这一步：**一张没有人在清单里写过的 PNG，就是一次没有人审过的重建**；反过来，清单里有名字却没有文件，说明这条用例的基线丢了，下一次跑会重新写一张、然后跟它自己比。

```bash
# Vue（Playwright）
npx --prefix website playwright test --update-snapshots --grep-invert "@a11y|@perf"

# Flutter
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

Vue 基线放在 `tests/visual/vue/baselines/<platform>/`。截图是一次渲染，macOS 与 Linux 的文字栅格化不一样，共用一套的结果是 CI 拿 Linux 的输出去比 macOS 的像素，**凡是带字的用例都会红**。

当前仓库里只有 `darwin/` 一套（54 张）。这意味着：

> **CI 的视觉任务跑在 ubuntu 上，目前没有对应的 Linux 基线。** 第一次跑会因为缺基线而失败，这是应该的——它在说"这个平台的视觉回归从来没有被验过"，而不是假装通过。要打开它，需要在 CI 环境里跑一次 `--update-snapshots` 并把 `linux/` 那套提交进来，同时在清单里登记。本机（darwin/arm64）生成的 Linux 基线不算数：容器架构不同，栅格化仍有差别。

## 4. 四端覆盖

| 平台 | 渲染器 | 基线数 | 每次验证跑得到吗 |
|---|---|---|---|
| Vue | Playwright / Chromium（darwin） | 54 | 是 |
| Flutter | `flutter test --update-goldens` | 2 | 是 |
| iOS | `UPDATE_GOLDENS=1 swift test`（macOS 宿主渲染） | 2 | 是 |
| Compose | instrumented，固定 Pixel_9_API_35 / 420dpi | 3 | **否**——要连模拟器，离线单测与 CI 都跑不到 |

Compose 有基线（明暗两套加 200% 大字号），但它是 instrumented 测试：只有在那台固定 AVD 上才能生成与比对。缺口不是"没有基线"，而是**没有任何东西会自动重新比对它们**。

## 6. 应用级视觉：Golden App（Round 5 新增）

组件基线证明组件契约，应用基线证明整体组合。第五轮给 golden app（`flare-social-web-app`）加了一层：

- 位置：**应用仓库**里 `tests/app-visual/baselines/<platform>/`（12 张：收件箱、群聊、暗色群聊、搜索、群成员、设置、图片预览、空态、错误态、平板、手机、手机暗色）。跑在测试专用的内存夹具核心上，不连后端、不登录。
- 命令：`npx playwright test -c tests/app-visual/playwright.config.ts application-visual.spec.ts`，更新用 `--update-snapshots`。
- 确定性：macOS 上以经典滚动条启动 Chromium（`tests/app-visual/support-bin/chromium-classic-scrollbars.sh`，与网站同一手法），`animations: "disabled"`，时钟固定，`reducedMotion: "reduce"`。
- 容差用**像素个数**（`maxDiffPixels: 120`），不用比例。整窗截图上百万像素，0.2% 的比例容差等于两千多像素——一整句文案改掉都可能照样绿。第五轮就撞上过：把空态文案换成「会话列表没有加载出来」后，比例容差下用例仍然通过。
- 平台分开存，理由同第 3 节；`linux/` 一套同样要在 CI 镜像上生成，本机不算数。

## 5. 没覆盖的

- **Linux 基线**（见第 3 节）——CI 的视觉回归要等这套基线补上才真正生效。
- **Compose 的自动比对**——它的基线只在固定 AVD 上才跑得动，本轮的四端验证扫不到它。要进 CI 需要模拟器 runner，或者改用 Paparazzi / Roborazzi 这类离线截图框架（是一次依赖与构建链的变更，不在 RC 范围）。
- **真机 / 模拟器**上的原生渲染：Flutter 与 iOS 的基线都是宿主机离线渲染，不等于设备上的观感。
- **动效**：所有截图都关掉了动画（`animations: "disabled"`），过渡过程没有基线。
