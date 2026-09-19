# Native Capability Matrix（2.0.0-rc.1）

每格只允许 PASS_RUNTIME / PASS_TEST / PASS_BUILD / SIMULATED / UNSUPPORTED / FAIL（见 2.0-release-criteria.md）。本轮所有原生操作最高只到 PASS_TEST / PASS_BUILD：没有真机 / 模拟器上的选择器往返证据，因此版本仍停在 rc（rc.2 条件见 gap-analysis §6）。2026-09-13：iOS / Android 示例的宿主适配器补齐，五个宿主全部经适配器调用原生能力。

## 契约层（Layer 5）

| 项 | Vue | Flutter | Compose | iOS |
|---|---|---|---|---|
| 能力记录 `PlatformCapabilities` | PASS_TEST | PASS_TEST | PASS_TEST | PASS_TEST |
| 适配器接口 + 默认 UNSUPPORTED | PASS_TEST | PASS_TEST | PASS_TEST | PASS_TEST |
| 错误归一化（5 码） | PASS_TEST（DOMException 名 + code + 文案启发） | PASS_TEST（PlatformException / TimeoutException / MissingPluginException） | PASS_TEST（TimeoutCancellation / Cancellation / Security / ActivityNotFound） | PASS_TEST（CancellationError / NSCocoa / NSURL 码） |
| 超时 → TIMEOUT | PASS_TEST | PASS_TEST | PASS_TEST | PASS_TEST |
| 18 向量（3 操作 × 6 结果） | PASS_TEST（真实 DOM input / navigator.share） | PASS_TEST（脚本适配器） | PASS_TEST（脚本适配器） | PASS_TEST（脚本适配器） |
| 提供者 / 注入 | PASS_TEST | PASS_TEST（widget 测试） | PASS_BUILD | PASS_BUILD |
| 平台探测（pointer/hover/…） | PASS_TEST（媒体查询） | PASS_TEST（macOS / Android 向量） | PASS_TEST（phone / tablet+mouse） | PASS_TEST（phone / iPad+trackpad） |

## 宿主实现

| 操作 | Web（flare-core-web-app） | Tauri | Flutter app | iOS app | Android app |
|---|---|---|---|---|---|
| pickFiles | PASS_TEST（kit web 适配器）+ PASS_BUILD（typecheck + vitest 50） | PASS_BUILD（typecheck；dialog 插件 null → CANCELLED） | PASS_TEST（`fileTypeFor` 映射 + 无插件 → UNSUPPORTED）+ PASS_BUILD（analyze 0 / 81 tests） | PASS_TEST（`iosContentTypes` accept 映射 + 取消即 CANCELLED，swift test 59）+ PASS_BUILD（iPhone 17 模拟器 BUILD SUCCEEDED；`UIDocumentPickerViewController(asCopy:)`） | PASS_TEST（空选择即 CANCELLED、单选只留第一个，20 单测）+ PASS_BUILD（compileDebugKotlin；`OpenMultipleDocuments`） |
| pickImages | 同上 | PASS_BUILD | PASS_TEST + PASS_BUILD | PASS_TEST + PASS_BUILD（PHPicker；`video: true` 时图片+视频，按返回类型分 createImage / createVideo） | PASS_TEST + PASS_BUILD（`PickMultipleVisualMedia`） |
| share | PASS_TEST（有 `navigator.share` 时 supported，否则 fallback） | UNSUPPORTED | UNSUPPORTED | UNSUPPORTED | UNSUPPORTED |
| onNativeBack | PASS_TEST（Round 5：kit `createWebPlatformAdapter({ historyBack: true })`，`nativeBack.test.ts`；web 参考应用开启并在夹具手机视口验证） | UNSUPPORTED | UNSUPPORTED（接口已在） | UNSUPPORTED | UNSUPPORTED（接口已在） |
| safeAreaInsets | PASS_TEST（`--flare-safe-area-*`） | UNSUPPORTED | PASS_BUILD（MediaQuery padding） | PASS_BUILD（宿主读 key window 的 `safeAreaInsets`） | PASS_BUILD（默认 0，宿主覆写） |
| 打开外部链接（气泡里的文本链接 / 链接卡片，Round 5） | PASS_TEST（kit 内部走 `safeExternalUrl` + 新标签，`browserDownload.test.ts`） | 同 Web（同一套 Vue kit） | UNSUPPORTED（没有 URL 启动器：锁文件冻结，不引入 `url_launcher`；宿主接 `onOpenLink` 才有动作） | PASS_TEST（宿主不接时 kit 用 `openURL` 打开 `safeExternalURL` 认可的 http/https，`TextLinkAndInlineEmojiTests`） | PASS_TEST（宿主不接时 kit 用 `LocalUriHandler`，同一道安全门，`MediaDefaultsTest`） |

## 证据

- kit：vitest 452（含 `shared/platform/contract.test.ts` 22）、flutter 464（含 `platform_contract_test.dart` 23）、compose 152（含 `FlarePlatformTest` 4）、swift 189（含 `PlatformContractTests` 4）、`node tooling/check-platform-contract.mjs`（4 平台 × 18 向量、sniffLint 0）。
- 示例：web `npm run typecheck` + `npm test`（50）、tauri `npm run typecheck` + `npm test`（5，含适配器接线断言）、flutter app `flutter analyze` 0 + `flutter test` 81（含 `app_platform_adapter_test.dart` 3）、ios app `swift test` 59（含 `IosPlatformAdapterTests` 6）+ 模拟器 `xcodebuild` BUILD SUCCEEDED、android app `make test` 20（含 `AndroidPlatformAdapterTest` 4）+ `make compile`。
- 宿主侧只测得到能力声明与结果归一（能力级别、accept→内容类型、空选择→CANCELLED、单选截断）：选择器本身要系统 UI 参与，JVM / macOS 单测里没有 UIKit 与 Activity。
- 未覆盖：真机 / 模拟器上的选择器往返（用户真正点一次相册）、share / nativeBack 的任何宿主实现。
