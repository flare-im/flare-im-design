# Android / iOS 手动引入指南（1.0.5）

Android 与 iOS **不走公共仓库**（Maven Central / CocoaPods Trunk），产物直接放在
GitHub。本文是这两端的引入方式。

Web（npm）与 Flutter（pub.dev）走各自的公共仓库，见 [RELEASE-1.0.5.md](./RELEASE-1.0.5.md)。

> 仓库 `flare-im/flare-im-design` 目前是 **private**。下面所有方式都要求使用方的
> GitHub 账号有本仓读权限（SPM 走 SSH/凭据、AAR 下载走登录态）。若要对外开放，
> 需先把仓库转为 public 或改用带 token 的分发。

---

## iOS —— FlareIMUI

要求 iOS 16+ / Swift 5.9+。**无任何第三方依赖**，引入后不需要再加别的包。

### 方式 A：Swift Package Manager（推荐）

Xcode → File → Add Package Dependencies，填仓库地址，版本规则选 "Up to Next Major" 填 `1.0.5`。

或在 `Package.swift` 里写：

```swift
dependencies: [
    .package(url: "https://github.com/flare-im/flare-im-design.git", from: "1.0.5"),
],
targets: [
    .target(name: "YourApp", dependencies: [
        .product(name: "FlareIMUI", package: "flare-im-design"),
    ])
]
```

版本由 **git tag** 决定，仓库里没有版本号字段。`from: "1.0.5"` 能解析的前提是
`1.0.5` 这个 tag 已推到远端。

### 方式 B：本地路径（不联网 / 要改源码时）

```bash
git clone https://github.com/flare-im/flare-im-design.git
```

Xcode → File → Add Package Dependencies → Add Local...，选克隆下来的**仓库根目录**
（不是 `ios-im-ui/`，根目录的 `Package.swift` 才是对外清单）。

### 方式 C：git submodule（要跟随上游更新时）

```bash
git submodule add https://github.com/flare-im/flare-im-design.git Vendor/flare-im-design
```

然后在自己的 `Package.swift` 用 `.package(path: "Vendor/flare-im-design")`。

### 使用

```swift
import FlareIMUI
```

表情/贴纸资源（`Resources/emoji-sticker`）已打进包内，通过 SPM 的 resource bundle
自动加载，不需要额外拷贝。

---

## Android —— im-ui-compose

要求 **minSdk 26**、**compileSdk 35**、**JDK 17**、Kotlin **2.2.20**、Compose BOM
**2024.12.01**。命名空间 `com.flare.im.ui`。

Kotlin 版本必须与 Compose compiler 插件匹配——使用方的 Kotlin 若低于 2.2.20，
Compose 编译产物会不兼容。

### 方式 A：源码依赖（推荐）

比 AAR 好在**依赖会自动传递**，不用手抄下面那一串。

```bash
git submodule add https://github.com/flare-im/flare-im-design.git vendor/flare-im-design
```

`settings.gradle.kts`：

```kotlin
include(":im-ui-compose")
project(":im-ui-compose").projectDir = file("vendor/flare-im-design/android-im-ui")
```

`app/build.gradle.kts`：

```kotlin
implementation(project(":im-ui-compose"))
```

### 方式 B：AAR 手动引入

从 GitHub Releases 下载 `im-ui-compose-1.0.5.aar`（67.8 MB，体积来自内置的表情贴纸
资源），放进 `app/libs/`：

```kotlin
implementation(files("libs/im-ui-compose-1.0.5.aar"))
```

⚠️ **AAR 不携带依赖信息**（没有 POM）。只写上面这一行，编译能过但**运行时必崩**
`NoClassDefFoundError`。必须把下面 8 个依赖一并加到自己的 `build.gradle.kts`：

```kotlin
val composeBom = platform("androidx.compose:compose-bom:2024.12.01")
implementation(composeBom)
implementation("androidx.compose.ui:ui")
implementation("androidx.compose.ui:ui-tooling-preview")
implementation("androidx.compose.foundation:foundation")
implementation("androidx.compose.material3:material3")
implementation("androidx.compose.material:material-icons-extended")
implementation("io.coil-kt:coil-compose:2.7.0")
implementation("io.coil-kt:coil-gif:2.7.0")
```

版本必须与上面一致——库就是按这套编的，换版本可能出 Compose runtime 不匹配。

### 使用

```kotlin
import com.flare.im.ui.*
```

---

## 关于 67.8 MB

Android AAR 和 iOS 包体积都主要来自 `assets/emoji-sticker`（约 67 MB 的 webp 表情
贴纸）。这是五端共用同一份资源的既定设计，不是打包缺陷。

真机安装包不会是这个体积——Android 的 R8/资源压缩、iOS 的 App Thinning 都会按实际
引用裁剪。若确实需要瘦身，方向是把表情包改成按需下载，那是独立的方案，不在本次范围。

---

## 版本对应

| 端 | 标识 | 1.0.5 从哪来 |
|---|---|---|
| iOS | `FlareIMUI` | git tag `1.0.5` |
| Android | `com.flare.im:im-ui-compose` | `android-im-ui/build.gradle.kts` 的 `version` |

两端要一起升。改 Android 版本号时别忘了补 tag，否则 iOS 停在旧版而没人察觉。
