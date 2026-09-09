// swift-tools-version:5.9
import PackageDescription

// Flare IM UI Kit — iOS/SwiftUI component package (L1).
// One framework-neutral contract (flare-im-ui-spec), realised natively.
// Design tokens are generated from flare-im-design-tokens into
// Sources/FlareIMUI/Tokens/FlareTokens.swift (do not edit by hand).
//
// macOS is declared alongside iOS purely so the components can be built and
// smoke-tested on a Mac host (`swift build` / `swift test`) without a simulator;
// the components use cross-platform SwiftUI only.
let package = Package(
    name: "FlareIMUI",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "FlareIMUI", targets: ["FlareIMUI"]),
    ],
    targets: [
        .target(
            name: "FlareIMUI",
            // Emoji-pack + sticker resources. Resources/emoji-sticker is a mirror of
            // the cross-platform source at flare-im-design/assets/emoji-sticker
            // (SwiftPM does not follow symlinks). The text contracts of the mirror
            // are tracked so the directory always exists and Bundle.module is always
            // generated; the webp binaries are synced in by sync-resources.sh.
            resources: [.copy("Resources/emoji-sticker")]
        ),
        .testTarget(name: "FlareIMUITests", dependencies: ["FlareIMUI"]),
    ]
)
