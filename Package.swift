// swift-tools-version:5.9
import PackageDescription

// 仓库根清单 —— 存在的唯一理由是让 SPM 能通过 git URL 消费本包。
//
// SPM 只在仓库根目录找 Package.swift，而本仓是多端 monorepo，iOS 包在
// ios-im-ui/ 下。没有这个文件，`.package(url: "...flare-im-design.git", from: "1.0.5")`
// 会直接报 "does not contain a Package.swift"。
//
// ⚠️ 与 ios-im-ui/Package.swift 是同一份 target 的两个清单：前者供仓库外消费，
// 后者供在 ios-im-ui/ 目录内直接 `swift build` / `swift test`。改动 target 结构
// （新增 target、改资源声明、调平台版本）时两个文件必须同步，否则「本地能编、
// 外部引入编不过」。target 结构稳定，日常开发不会碰到。
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
            path: "ios-im-ui/Sources/FlareIMUI",
            resources: [.copy("Resources/emoji-sticker")]
        ),
    ]
)
