// swift-tools-version: 5.9

import PackageDescription

// The iOS side of flare_plugin_bundle_host: the SwiftUI kit's web bundle host in a Flutter platform view.
//
// `FlareIMUI` is a symbolic link to flare-im-design/packages/ios-im-ui. Flutter reaches this package through its own
// links (`ios/Flutter/ephemeral/Packages/.packages/...`), so a relative path to the kit would resolve from there; a link
// inside the package resolves from where the package really is. The kit declares iOS 16, so this package does too: an
// app adds it only once its own deployment target is iOS 16 (D-17 keeps iOS 15 devices on the declarative variant).
let package = Package(
    name: "flare_plugin_bundle_host_ios",
    platforms: [
        .iOS("16.0"),
    ],
    products: [
        .library(name: "flare-plugin-bundle-host-ios", targets: ["flare_plugin_bundle_host_ios"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(name: "FlareIMUI", path: "FlareIMUI"),
    ],
    targets: [
        .target(
            name: "flare_plugin_bundle_host_ios",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "FlareIMUI", package: "FlareIMUI"),
            ]
        ),
    ]
)
