# flare-im-design 1.0.4 发版说明

状态（2026-07-31）：

| 端 | 渠道 | 状态 |
|---|---|---|
| Flutter | pub.dev | ✅ 已发布 `flare_im_ui` 1.0.4 |
| iOS | GitHub tag `1.0.4` | ✅ 已推送，外部工程 SPM 拉取实测通过 |
| Android | GitHub Release 附 AAR | ✅ `im-ui-compose-1.0.4.aar`（71.1 MB） |
| tokens | npm | ⏳ 待发布（2FA 拦截） |
| vue-im-ui | npm | ⏳ 待发布（依赖 tokens，须后发） |

**Android/iOS 不走 Maven Central / CocoaPods**，改为 GitHub 分发，引入方式见
[MANUAL-INSTALL-ANDROID-IOS.md](./MANUAL-INSTALL-ANDROID-IOS.md)。

## 各端引入方式

发布后，业务方按各平台惯例引入（不再使用本地路径）：

| 平台 | 包名 | 引入方式 |
|---|---|---|
| Web / Vue | `flare-core-vue-im-ui` | `npm i flare-core-vue-im-ui@1.0.4` |
| Web / tokens | `flare-im-design-tokens` | `npm i flare-im-design-tokens@1.0.4` |
| Flutter | `flare_im_ui` | `flutter pub add flare_im_ui:^1.0.4` |
| Android | `com.flare.im:im-ui-compose` | `implementation("com.flare.im:im-ui-compose:1.0.4")` |
| iOS | `FlareIMUI` | SPM 指向仓库 `.package(url: ..., from: "1.0.4")` |

iOS 的 SPM 没有版本字段，版本由 **git tag** 决定——发版时必须打 `1.0.4` tag，否则
`from: "1.0.4"` 解析不到。

## 本轮完成

- 五端版本统一 `0.1.0` → `1.0.4`（iOS 由 git tag 承载）。
- 补齐发布必需文件：根 `LICENSE`（此前缺失，而 npm 包已声明 MIT）+ 五端各自的
  `LICENSE` 与 `CHANGELOG.md`（pub.dev 强制要求，缺失即拒绝发布）。
- `flutter-im-ui` 补 `repository` 字段。
- **修正一处会导致装不上的版本区间**：`vue-im-ui` 依赖 `flare-im-design-tokens: ^0.1.0`，
  而 tokens 已升至 1.0.4，`^0.1.0` 不匹配 1.x。已改为 `^1.0.4`。

## 校验结果

| 平台 | 校验方式 | 结果 |
|---|---|---|
| tokens | `npm pack --dry-run` | 通过（10 文件 / 8.4 kB） |
| vue-im-ui | `npm pack --dry-run` | 通过（278 文件 / 1.5 MB） |
| Flutter | `flutter pub publish --dry-run` | 通过（仅剩「工作区未提交」，提交后消失） |
| Android | `publishToMavenLocal` | 通过，产出 `im-ui-compose-1.0.4.aar` |
| iOS | `swift build` | 通过 |

Android AAR 达 67.8 MB，因表情贴纸资源（`assets/emoji-sticker`，67 MB）经 symlink
打入。这是跨端共用同一份资源的既定设计，非缺陷；若要瘦身需另做资源按需下载方案。

## 保留 file: 引用的两处（正确，勿改）

- `site/package.json` 用 `file:../vue-im-ui` 与 `file:../tokens`：文档站不发布
  （已标 `private: true`），引用同仓源码是正确做法。
- `vue-im-ui` 的 `flare-core-typescript-sdk` 是 **devDependency**，仅供本地类型检查；
  `npm publish` 不打包 devDependencies，不影响发布产物。

## 发布顺序

`tokens` → `vue-im-ui`（依赖 tokens）→ Flutter / Android / iOS（三者互不依赖，任意顺序）。

iOS 记得打 git tag：`git tag 1.0.4 && git push origin 1.0.4`。
