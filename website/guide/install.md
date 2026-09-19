# 安装与引用

四端组件包各自独立发布，版本锁步（当前 **2.0.0-rc.1**）。每个平台给出**包管理器**、**Git / 源码**两条路径；四端组件都是纯展示——props 进、事件出——不绑定任何 SDK。

> [!TIP]
> 组件不绑定后端。数据映射与副作用接线见[快速开始](/guide/getting-started)与[独立使用](/guide/standalone)。

| 平台 | 包 | 渠道 | 最低要求 |
|---|---|---|---|
| Vue | `@flare-im/vue-ui` | npm | Vue 3.5+、Vite（或任何能编译 `.vue` 的构建链） |
| Flutter | `flare_im_ui` | git tag / 路径（pub.dev 上为 1.0.5，2.0.0-rc.1 发布前请走 git） | Flutter 3.10+ |
| iOS | `FlareIMUI` | SwiftPM（本地路径 / 独立 package 产物） | iOS 16+、Swift 5.9+ |
| Android | `com.flare.im:im-ui-compose` | JitPack / 源码模块 / AAR | minSdk 26、compileSdk 35、JDK 17、Kotlin 2.2.20、Compose BOM 2024.12.01 |

## Vue

```bash
npm i @flare-im/vue-ui naive-ui vue
```

`naive-ui` 与 `vue` 是 **peer 依赖**，必须由宿主安装。包以源码（`.vue` + `.ts`）形式发布，宿主构建需要能处理 `.vue`（Vite + `@vitejs/plugin-vue`，或 webpack + vue-loader）。

```vue
<script setup>
import { FlareMessageBubble, FlareConversationList } from "@flare-im/vue-ui";
import "@flare-im/vue-ui/style.css";
</script>
```

::: code-group

```bash [本地源码]
npm i /path/to/flare-im-design/packages/vue-im-ui
```

```bash [按需引入]
# 9 个明确入口：components / theme / i18n / contracts / composables …
import { FlareButton } from "@flare-im/vue-ui/components";
import "@flare-im/vue-ui/style.css";
```

:::

## Flutter

::: code-group

```yaml [Git tag（推荐）]
# pubspec.yaml
dependencies:
  flare_im_ui:
    git:
      url: https://github.com/flare-im/flare-im-design.git
      path: packages/flutter-im-ui
      ref: "2.0.0-rc.1"
```

```yaml [路径依赖]
dependencies:
  flare_im_ui:
    path: ../flare-im-design/packages/flutter-im-ui
```

```yaml [pub.dev]
# pub.dev 当前为 1.0.5；2.0.0-rc.1 发布后可改用
dependencies:
  flare_im_ui: ^1.0.5
```

:::

```dart
import 'package:flare_im_ui/flare_im_ui.dart';

FlareMessageBubble(message: msg, currentUserId: 'me');
```

## iOS

```swift [SPM · 本地]
// Xcode → File → Add Package Dependencies → Add Local…
// 选择 packages/ios-im-ui
dependencies: [ .package(path: "../flare-im-design/packages/ios-im-ui") ]
// target: .product(name: "FlareIMUI", package: "ios-im-ui")
```

```swift
import FlareIMUI

MessageBubbleView(message: msg, currentUserId: "me")
```

> 表情/贴纸的**契约**随包自动加载，**webp 图片不在 git 里**。需要图片时在检出目录执行 `./assets/emoji-sticker/fetch-assets.sh && ./packages/ios-im-ui/sync-resources.sh`。详见[手动引入指南](https://github.com/flare-im/flare-im-design/blob/main/docs/MANUAL-INSTALL-ANDROID-IOS.md)。

## Android

::: code-group

```kotlin [JitPack（推荐）]
// settings.gradle.kts
dependencyResolutionManagement {
  repositories { google(); mavenCentral(); maven { url = uri("https://jitpack.io") } }
}
// build.gradle.kts —— JitPack 用 git tag 作版本，坐标是 GitHub 仓库
dependencies {
  implementation("com.github.flare-im:flare-im-design:2.0.0-rc.1")
}
```

```kotlin [源码模块]
// settings.gradle.kts（git submodule 到 vendor/flare-im-design）
include(":im-ui-compose")
project(":im-ui-compose").projectDir = file("vendor/flare-im-design/packages/android-im-ui")
// build.gradle.kts
dependencies { implementation(project(":im-ui-compose")) }
```

```kotlin [AAR]
// 从 GitHub Releases 下载 im-ui-compose-2.0.0-rc.1.aar 放进 app/libs/。
// 裸 AAR 没有 POM，传递依赖不会自动带上：Compose BOM 2024.12.01 的 ui /
// ui-tooling-preview / foundation / material3 / material-icons-extended，
// 以及 coil-compose 2.7.0 / coil-gif 2.7.0 —— 缺一个就是运行时 NoClassDefFoundError。
```

:::

```kotlin
import com.flare.im.ui.MessageBubble

MessageBubble(message = msg, currentUserId = "me")
```

## 发布（维护者）

四端同版本一起发：`node tooling/check-kit-distribution.mjs` 会校验 npm、Android `version`、git tag 与 SPM 清单一致。

::: code-group

```bash [Vue → npm]
cd packages/vue-im-ui && npm publish
```

```bash [Flutter → pub.dev]
cd packages/flutter-im-ui && dart pub publish --dry-run   # pubspec 不能含 git 依赖
```

```bash [iOS · Android → git tag]
git tag 2.0.0-rc.1 && git push --tags   # SPM 与 JitPack 都从这个 tag 取
```

:::
