# 安装与引用

四端组件包各自独立发布，可通过**包管理器**、**Git 依赖**或**下载源码包**三种方式引用。下面按平台给出。

> [!TIP]
> 组件是纯展示：props 进、事件出，不绑定任何 SDK——接你现有的 IM 后端即可；想要开箱即用的收发与多端同步，可选接 Flare core（见[快速开始](/guide/getting-started)）。

## 下载源码包

无需任何仓库，直接下载对应平台的源码包，本地引用即可：

| 平台 | 包 | 下载 |
|---|---|---|
| Vue | `@flare-im/vue-ui` | [@flare-im/vue-ui-0.1.0.tgz](/downloads/@flare-im/vue-ui-0.1.0.tgz) |
| Flutter | `flare_im_ui` | [flare_im_ui-flutter-0.1.0.tar.gz](/downloads/flare_im_ui-flutter-0.1.0.tar.gz) |
| iOS | `FlareIMUI` | [FlareIMUI-ios-0.1.0.tar.gz](/downloads/FlareIMUI-ios-0.1.0.tar.gz) |
| Android | `com.flare.im:im-ui-compose` | [flare-im-ui-compose-android-0.1.0.tar.gz](/downloads/flare-im-ui-compose-android-0.1.0.tar.gz) |

## Vue

::: code-group

```bash [npm 仓库]
npm i @flare-im/vue-ui
```

```bash [下载的源码包]
# 下载上面的 .tgz 后
npm i ./@flare-im/vue-ui-0.1.0.tgz
```

```bash [本地源码]
npm i /path/to/flare-im-design/vue-im-ui
```

:::

```vue
<script setup>
import { MessageBubble, FlareConversationList } from "@flare-im/vue-ui";
import "@flare-im/vue-ui/style.css";
</script>
```

> 依赖 `@flare-im/tokens`（设计 Tokens）与可选 peer `@flare-im/sdk`（喂数据）；用仓库安装时需保证这两者可解析（已发布或本地 link）。

## Flutter

::: code-group

```yaml [Git 依赖]
# pubspec.yaml
dependencies:
  flare_im_ui:
    git:
      url: https://github.com/flare-im/flare-im-design.git
      path: flutter-im-ui
```

```yaml [路径依赖]
dependencies:
  flare_im_ui:
    path: ../flare-im-design/flutter-im-ui
```

```yaml [下载的源码包]
# 解压 tar.gz 后指向解压目录
dependencies:
  flare_im_ui:
    path: ./flare_im_ui
```

:::

```dart
import 'package:flare_im_ui/flare_im_ui.dart';

FlareMessageBubble(message: msg, currentUserId: 'me');
```

## iOS

::: code-group

```swift [SPM · Git]
// Package.swift
dependencies: [
  .package(url: "https://github.com/flare-im/flare-im-design.git", from: "0.1.0"),
]
// target: .product(name: "FlareIMUI", package: "flare-im-design")
```

```swift [SPM · 本地/下载]
// 解压 tar.gz 或指向本地目录
dependencies: [ .package(path: "../FlareIMUI") ]
```

:::

```swift
import FlareIMUI

MessageBubbleView(message: msg, currentUserId: "me")
```

> Xcode 图形界面：File → Add Package Dependencies… 粘贴 Git URL，或 Add Local… 选择解压目录。

## Android

::: code-group

```kotlin [Maven 坐标]
// settings.gradle.kts —— repositories { mavenCentral(); /* 或你的私有 Maven */ }
// build.gradle.kts
dependencies {
  implementation("com.flare.im:im-ui-compose:0.1.0")
}
```

```kotlin [复合构建 / 源码]
// settings.gradle.kts
includeBuild("../flare-im-design/android-im-ui")
// build.gradle.kts
dependencies { implementation("com.flare.im:im-ui-compose") }
```

```kotlin [下载的源码包]
// 解压 tar.gz 后作为模块引入
include(":im-ui-compose")
project(":im-ui-compose").projectDir = file("./android-im-ui")
```

:::

```kotlin
import com.flare.im.ui.MessageBubble

MessageBubble(message = msg, currentUserId = "me")
```

## 发布（维护者）

以下命令会推送到公开仓库/registry，**需要你自己的凭据**，请在本地执行：

::: code-group

```bash [Vue → npm]
cd vue-im-ui && npm publish   # package.json 已设 publishConfig.access=public
```

```bash [Flutter → pub.dev / Git]
# pub.dev：先把 pubspec 的 publish_to:none 去掉，再 dart pub publish
# 或直接 Git：推送到 github 后消费方用 git 依赖（无需发布）
git push && git tag v0.1.0 && git push --tags
```

```bash [iOS → SPM]
# SPM 无需 registry：推送 tag，消费方用 .package(url:from:)
git push && git tag 0.1.0 && git push --tags
```

```bash [Android → Maven]
cd android-im-ui && ./gradlew publish   # 先在 build.gradle.kts 的 publishing.repositories 配置目标 Maven 与凭据
```

:::

> 下载源码包由 `site/scripts/pack-downloads.sh` 生成；发新版本后重跑该脚本以刷新下载链接。
