# Android / iOS source installation

The native packages are self-contained under `packages/`. They can be consumed from a checkout or packaged as release artifacts without a platform manifest at repository root.

## iOS: FlareIMUI

Requirements: iOS 16 or macOS 13, Swift 5.9 or later. The package has no third-party dependency.

Add the package directory in Xcode with **File > Add Package Dependencies > Add Local**, selecting `packages/ios-im-ui`, or declare a local path:

```swift
dependencies: [
    .package(path: "../flare-im-design/packages/ios-im-ui"),
],
targets: [
    .target(name: "YourApp", dependencies: [
        .product(name: "FlareIMUI", package: "ios-im-ui"),
    ]),
]
```

Then import the library:

```swift
import FlareIMUI
```

The monorepo root intentionally has no `Package.swift`; a Git URL targeting the monorepo root is not a supported SwiftPM entry. A remote release must publish `packages/ios-im-ui` as a standalone source artifact or repository.

Emoji and sticker manifests ship in the package. To include the optional binary images in a source checkout, run:

```bash
./assets/emoji-sticker/fetch-assets.sh
./packages/ios-im-ui/sync-resources.sh
```

## Android: im-ui-compose

Requirements: minSdk 26, compileSdk 35, JDK 17, Kotlin 2.2.20, and Compose BOM 2024.12.01.

For a source dependency, include the package directly:

```kotlin
// settings.gradle.kts
include(":im-ui-compose")
project(":im-ui-compose").projectDir =
    file("vendor/flare-im-design/packages/android-im-ui")
```

```kotlin
// app/build.gradle.kts
implementation(project(":im-ui-compose"))
```

The package publishes Maven coordinates `com.flare.im:im-ui-compose:<version>`. Root `jitpack.yml` is retained because JitPack discovers its build configuration at repository root and then delegates to `packages/android-im-ui`.

For a manual AAR, add the AAR and its runtime dependencies because a bare AAR has no POM metadata:

```kotlin
implementation(files("libs/im-ui-compose-2.0.0-rc.1.aar"))

val composeBom = platform("androidx.compose:compose-bom:2024.12.01")
implementation(composeBom)
implementation("androidx.activity:activity-compose:1.9.3")
implementation("androidx.compose.ui:ui")
implementation("androidx.compose.ui:ui-tooling-preview")
implementation("androidx.compose.foundation:foundation")
implementation("androidx.compose.material3:material3")
implementation("androidx.compose.material:material-icons-extended")
implementation("io.coil-kt:coil-compose:2.7.0")
implementation("io.coil-kt:coil-gif:2.7.0")
```

Import the package with:

```kotlin
import com.flare.im.ui.*
```

## Release alignment

The workspace, Vue, tokens, spec, and Android manifests use the same release version. Swift source artifacts must be produced from that same commit. `node tooling/check-kit-distribution.mjs` validates the local ownership and version contract without relying on a registry or Git tags.
