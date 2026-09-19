// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FlareSwiftConsumerSmoke",
    platforms: [.macOS(.v13)],
    dependencies: [.package(path: "../../../packages/ios-im-ui")],
    targets: [
        .executableTarget(
            name: "FlareSwiftConsumerSmoke",
            dependencies: [.product(name: "FlareIMUI", package: "ios-im-ui")]
        )
    ]
)
