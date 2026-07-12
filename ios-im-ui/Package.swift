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
            // Emoji-pack + sticker resources. Resources/emoji-sticker is a symlink
            // to the cross-platform source at flare-im-design/assets/emoji-sticker,
            // so this package ships the same webp + manifest every platform uses.
            resources: [.copy("Resources/emoji-sticker")]
        ),
        .testTarget(name: "FlareIMUITests", dependencies: ["FlareIMUI"]),
    ]
)
