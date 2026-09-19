# Install & reference

The four platform packages ship independently with one version (currently **2.0.0-rc.1**). Each platform gets a **package manager** path and a **Git / source** path; every component is pure presentation — props in, events out — with no SDK lock-in.

> [!TIP]
> Components do not bind a backend. See [Getting started](/en/guide/getting-started) and [Standalone](/en/guide/standalone) for data mapping and side-effect wiring.

| Platform | Package | Channel | Minimum |
|---|---|---|---|
| Vue | `@flare-im/vue-ui` | npm | Vue 3.5+, Vite (or any toolchain that compiles `.vue`) |
| Flutter | `flare_im_ui` | git tag / path (pub.dev has 1.0.5; use git until 2.0.0-rc.1 is published) | Flutter 3.10+ |
| iOS | `FlareIMUI` | SwiftPM (local path / standalone package artifact) | iOS 16+, Swift 5.9+ |
| Android | `com.flare.im:im-ui-compose` | JitPack / source module / AAR | minSdk 26, compileSdk 35, JDK 17, Kotlin 2.2.20, Compose BOM 2024.12.01 |

## Vue

```bash
npm i @flare-im/vue-ui naive-ui vue
```

`naive-ui` and `vue` are **peer dependencies** the host must install. The package ships as source (`.vue` + `.ts`), so the host build must compile `.vue` (Vite + `@vitejs/plugin-vue`, or webpack + vue-loader).

```vue
<script setup>
import { FlareMessageBubble, FlareConversationList } from "@flare-im/vue-ui";
import "@flare-im/vue-ui/style.css";
</script>
```

::: code-group

```bash [Local source]
npm i /path/to/flare-im-design/packages/vue-im-ui
```

```bash [Subpath imports]
# 9 explicit entries: components / theme / i18n / contracts / composables …
import { FlareButton } from "@flare-im/vue-ui/components";
import "@flare-im/vue-ui/style.css";
```

:::

## Flutter

::: code-group

```yaml [Git tag (recommended)]
# pubspec.yaml
dependencies:
  flare_im_ui:
    git:
      url: https://github.com/flare-im/flare-im-design.git
      path: packages/flutter-im-ui
      ref: "2.0.0-rc.1"
```

```yaml [Path]
dependencies:
  flare_im_ui:
    path: ../flare-im-design/packages/flutter-im-ui
```

```yaml [pub.dev]
# pub.dev currently has 1.0.5; switch once 2.0.0-rc.1 is published
dependencies:
  flare_im_ui: ^1.0.5
```

:::

```dart
import 'package:flare_im_ui/flare_im_ui.dart';

FlareMessageBubble(message: msg, currentUserId: 'me');
```

## iOS

```swift [SPM · local]
// Xcode → File → Add Package Dependencies → Add Local…
// Select packages/ios-im-ui
dependencies: [ .package(path: "../flare-im-design/packages/ios-im-ui") ]
// target: .product(name: "FlareIMUI", package: "ios-im-ui")
```

```swift
import FlareIMUI

MessageBubbleView(message: msg, currentUserId: "me")
```

> The emoji/sticker **contract** loads automatically; the **webp images are not in git**. To include images, run `./assets/emoji-sticker/fetch-assets.sh && ./packages/ios-im-ui/sync-resources.sh` in the checkout. See the [manual install guide](https://github.com/flare-im/flare-im-design/blob/main/docs/MANUAL-INSTALL-ANDROID-IOS.md).

## Android

::: code-group

```kotlin [JitPack (recommended)]
// settings.gradle.kts
dependencyResolutionManagement {
  repositories { google(); mavenCentral(); maven { url = uri("https://jitpack.io") } }
}
// build.gradle.kts — JitPack versions by git tag and addresses the GitHub repository
dependencies {
  implementation("com.github.flare-im:flare-im-design:2.0.0-rc.1")
}
```

```kotlin [Source module]
// settings.gradle.kts (git submodule at vendor/flare-im-design)
include(":im-ui-compose")
project(":im-ui-compose").projectDir = file("vendor/flare-im-design/packages/android-im-ui")
// build.gradle.kts
dependencies { implementation(project(":im-ui-compose")) }
```

```kotlin [AAR]
// Download im-ui-compose-2.0.0-rc.1.aar from GitHub Releases into app/libs/.
// A bare AAR has no POM, so transitive dependencies do not come along: Compose BOM
// 2024.12.01 ui / ui-tooling-preview / foundation / material3 / material-icons-extended,
// plus coil-compose 2.7.0 / coil-gif 2.7.0 — miss one and you get NoClassDefFoundError at runtime.
```

:::

```kotlin
import com.flare.im.ui.MessageBubble

MessageBubble(message = msg, currentUserId = "me")
```

## Publishing (maintainers)

All four platforms release together: `node tooling/check-kit-distribution.mjs` asserts that npm, the Android `version`, the git tag and the SPM manifests agree.

::: code-group

```bash [Vue → npm]
cd packages/vue-im-ui && npm publish
```

```bash [Flutter → pub.dev]
cd packages/flutter-im-ui && dart pub publish --dry-run   # pubspec must not contain git dependencies
```

```bash [iOS · Android → git tag]
git tag 2.0.0-rc.1 && git push --tags   # SPM and JitPack both resolve this tag
```

:::
