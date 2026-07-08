# Install & reference

Each platform package is published independently and can be referenced three ways — a **package manager**, a **Git dependency**, or a **downloaded source archive**. Below, per platform.

> [!TIP]
> Components are pure presentation: props in, callbacks out. IM behavior and data come from the core's observable views (see [Getting started](/en/guide/getting-started)).

## Download source archives

No registry needed — download the archive for your platform and reference it locally:

| Platform | Package | Download |
|---|---|---|
| Vue | `flare-core-vue-im-ui` | [flare-core-vue-im-ui-0.1.0.tgz](/downloads/flare-core-vue-im-ui-0.1.0.tgz) |
| Flutter | `flare_im_ui` | [flare_im_ui-flutter-0.1.0.tar.gz](/downloads/flare_im_ui-flutter-0.1.0.tar.gz) |
| iOS | `FlareIMUI` | [FlareIMUI-ios-0.1.0.tar.gz](/downloads/FlareIMUI-ios-0.1.0.tar.gz) |
| Android | `com.flare.im:im-ui-compose` | [flare-im-ui-compose-android-0.1.0.tar.gz](/downloads/flare-im-ui-compose-android-0.1.0.tar.gz) |

## Vue

::: code-group

```bash [npm registry]
npm i flare-core-vue-im-ui
```

```bash [downloaded archive]
# after downloading the .tgz above
npm i ./flare-core-vue-im-ui-0.1.0.tgz
```

```bash [local source]
npm i /path/to/flare-im-design/vue-im-ui
```

:::

```vue
<script setup>
import { MessageBubble, FlareConversationList } from "flare-core-vue-im-ui";
import "flare-core-vue-im-ui/style.css";
</script>
```

> Depends on `flare-im-design-tokens` (design tokens) and an optional peer `flare-core-typescript-sdk` (data). When installing from a registry, make sure those two resolve (published or locally linked).

## Flutter

::: code-group

```yaml [Git dependency]
# pubspec.yaml
dependencies:
  flare_im_ui:
    git:
      url: https://github.com/flare-im/flare-im-design.git
      path: flutter-im-ui
```

```yaml [path dependency]
dependencies:
  flare_im_ui:
    path: ../flare-im-design/flutter-im-ui
```

```yaml [downloaded archive]
# extract the tar.gz, then point at the folder
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

```swift [SPM · local / archive]
// extract the tar.gz or point at a local folder
dependencies: [ .package(path: "../FlareIMUI") ]
```

:::

```swift
import FlareIMUI

MessageBubbleView(message: msg, currentUserId: "me")
```

> In Xcode: File → Add Package Dependencies… paste the Git URL, or Add Local… and pick the extracted folder.

## Android

::: code-group

```kotlin [Maven coordinates]
// settings.gradle.kts — repositories { mavenCentral(); /* or your private Maven */ }
// build.gradle.kts
dependencies {
  implementation("com.flare.im:im-ui-compose:0.1.0")
}
```

```kotlin [composite build / source]
// settings.gradle.kts
includeBuild("../flare-im-design/android-im-ui")
// build.gradle.kts
dependencies { implementation("com.flare.im:im-ui-compose") }
```

```kotlin [downloaded archive]
// extract the tar.gz and include it as a module
include(":im-ui-compose")
project(":im-ui-compose").projectDir = file("./android-im-ui")
```

:::

```kotlin
import com.flare.im.ui.MessageBubble

MessageBubble(message = msg, currentUserId = "me")
```

## Publishing (maintainers)

These commands push to a public repo/registry and **require your own credentials** — run them locally:

::: code-group

```bash [Vue → npm]
cd vue-im-ui && npm publish   # publishConfig.access=public is already set
```

```bash [Flutter → pub.dev / Git]
# pub.dev: drop `publish_to: none` from pubspec, then `dart pub publish`
# or just Git: push to GitHub and consumers use a git dependency (no publish)
git push && git tag v0.1.0 && git push --tags
```

```bash [iOS → SPM]
# SPM needs no registry: push a tag, consumers use .package(url:from:)
git push && git tag 0.1.0 && git push --tags
```

```bash [Android → Maven]
cd android-im-ui && ./gradlew publish   # first set publishing.repositories (target Maven + credentials) in build.gradle.kts
```

:::

> The source archives are produced by `site/scripts/pack-downloads.sh`; re-run it after cutting a new version to refresh the download links.
