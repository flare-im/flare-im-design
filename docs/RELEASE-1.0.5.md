# flare-im-design 1.0.5 发版说明

## 为什么跳过 1.0.4

1.0.4 已发出（Flutter 上了 pub.dev，iOS/Android 上了 GitHub），但各端 README 里的
**引入说明写的还是 monorepo 本地路径**，指向仓库其他目录的相对链接在发布产物里也全是
死链。pub.dev 的已发布版本不可修改，只能靠新版本覆盖，因此有了 1.0.5。

1.0.4 保留在 pub.dev 上作为历史，不撤回。

## 各端引入方式

| 平台 | 包名 | 引入方式 |
|---|---|---|
| Web / Vue | `flare-core-vue-im-ui` | `npm i flare-core-vue-im-ui` |
| Web / tokens | `flare-im-design-tokens` | `npm i flare-im-design-tokens` |
| Web / 客户端 SDK | `flare-core-typescript-sdk` | `npm i flare-core-typescript-sdk` |
| Flutter | `flare_im_ui` | `flutter pub add flare_im_ui` |
| Android | `com.flare.im:im-ui-compose` | GitHub Release 的 AAR，或源码依赖 |
| iOS | `FlareIMUI` | SPM 指向仓库，`from: "1.0.5"` |

**Android/iOS 不走 Maven Central / CocoaPods**，产物放 GitHub，详见
[MANUAL-INSTALL-ANDROID-IOS.md](./MANUAL-INSTALL-ANDROID-IOS.md)。

iOS 的 SPM 没有版本字段，版本由 **git tag** 决定——发版必须打 `1.0.5` tag，否则
`from: "1.0.5"` 解析不到。

## 本轮改动

- 五端版本 `1.0.4` → `1.0.5`；`flare-core-typescript-sdk` 由 `0.2.0` 一并对齐到 `1.0.5`。
- 各端 README 的 Install 段改为真实的发布引入方式（此前是 monorepo 本地路径）。
- README 内 `../spec`、`../tokens`、`../vue-im-ui` 等相对链接改为 GitHub 绝对地址
  ——发布产物只含自己那个子目录，相对链接必然 404。
- `tokens/README.md` 的 "Flare IM UI Kit" 链接此前指向裸 `https://github.com/`，已修正。
- `vue-im-ui/README.md` 此前**完全没有 Install 段**，已补。
- 解除 `flare-core-typescript-sdk` 的 `private: true`，补 `description`。

## 依赖关系（决定发布顺序）

`flare-core-vue-im-ui` 有 10 处**运行时值导入**指向 `flare-core-typescript-sdk`
（`ConversationType`、`MessageContentType`、`uploadMediaInput` 等，不只是类型）。
该 SDK 不上 npm，vue-im-ui 发出去也是坏的。因此 npm 三个包的顺序是：

`flare-core-typescript-sdk` → `flare-im-design-tokens` → `flare-core-vue-im-ui`

（后者依赖 tokens `^1.0.5`。）

## 发布纪律

**只从 `main` 分支发布。** 发布前确认 `git branch --show-current` 是 main 且工作区干净。

## 未决

- **许可证**：`flare-im-core-client-sdk` 全仓没有 LICENSE 文件，README 也无许可声明。
  公开发布而不声明许可，法律默认为「保留所有权利」，使用者无权使用。需要确认后补。
- **仓库地址**：`github.com/flare-im/flare-im-core-client-sdk` 在 GitHub 上不存在，
  该 SDK 的 `package.json` 因此没有 `repository` 字段。
- **`flare-core-vue-im-ui` 的 smoke.test.ts** 里有一处硬编码相对路径
  （`../../../../../flare-core-typescript-sdk/src/adapter/codec/wireCodec.ts`），
  只在 monorepo 内成立。它是测试文件，已被 `files` 的 `!src/**/*.test.ts` 排除出发布
  产物，不影响使用方，但留着容易误导。
