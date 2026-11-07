import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

final class AuthShellTests: XCTestCase {
    @MainActor
    func testOptionalTaskCopyAndBackActionShareTheForm() throws {
        var backs = 0
        let shell = FlareAuthShell(product: "Flare IM", title: "Create account", subtitle: "Keep in touch",
                                   eyebrow: "YOUR CONVERSATION SPACE", footer: "Your messages live here.",
                                   backLabel: "Back to sign in", onBack: { backs += 1 }) {
            Text("Account fields")
        }
        let view = try shell.inspect()
        XCTAssertNoThrow(try view.find(text: "Create account"))
        XCTAssertNoThrow(try view.find(text: "YOUR CONVERSATION SPACE"))
        XCTAssertNoThrow(try view.find(text: "Your messages live here."))
        XCTAssertNoThrow(try view.find(text: "Account fields"))
        try view.find(ViewType.Button.self).tap()
        XCTAssertEqual(backs, 1)
    }

    #if os(macOS)
    private final class Measurement { var frame: CGRect = .zero }

    private struct FieldProbe: View {
        let measurement: Measurement
        var body: some View {
            VStack(spacing: FlareSizes.spacingLg) {
                FormFieldView(label: "账号", required: true) {
                    InputView(text: .constant(""), placeholder: "请输入账号")
                }
                FormFieldView(label: "密码", required: true) {
                    InputView(text: .constant(""), placeholder: "请输入密码", secure: true, revealable: true)
                }
                ButtonView(label: "登录", size: .lg, disabled: true, block: true) {}
            }
            .frame(maxWidth: .infinity)
            .background(GeometryReader { proxy in
                Color.clear.onAppear { measurement.frame = proxy.frame(in: .named("auth-test")) }
            })
        }
    }

    @MainActor
    private func render(width: CGFloat, height: CGFloat, dark: Bool = false,
                        largeText: Bool = false, measurement: Measurement) -> NSWindow {
        _ = NSApplication.shared
        let shell = FlareAuthShell(
            product: "Flare IM", title: "欢迎回来", subtitle: "登录，继续你的对话。",
            tagline: "即时沟通 · 多端连接", headline: "让沟通，\n自然发生。",
            description: "消息、文件与群组，在你的设备间轻松衔接。",
            eyebrow: "你的沟通空间", footer: "你的消息、联系人和群组，都在这里。"
        ) { FieldProbe(measurement: measurement) }
            .environment(\.colorScheme, dark ? .dark : .light)
            .environment(\.dynamicTypeSize, largeText ? .accessibility3 : .large)
            .coordinateSpace(name: "auth-test")
        let size = CGSize(width: width, height: height)
        let host = NSHostingView(rootView: shell.frame(width: width, height: height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        host.setFrameSize(size)
        window.orderFront(nil)
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        host.layoutSubtreeIfNeeded()
        if let destination = ProcessInfo.processInfo.environment["FLARE_AUTH_SNAPSHOT_DIR"],
           let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) {
            host.cacheDisplay(in: host.bounds, to: bitmap)
            let name = "swift-auth-\(Int(width))-\(Int(height))-\(dark ? "dark" : "light").png"
            try? bitmap.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: destination).appendingPathComponent(name))
        }
        return window
    }

    @MainActor
    func testDesktopFormKeepsAReadableWidthBesideTheBrandPanel() {
        let measurement = Measurement()
        let window = render(width: 1440, height: 900, measurement: measurement)
        defer { window.close() }
        XCTAssertGreaterThan(measurement.frame.width, 350)
        XCTAssertLessThanOrEqual(measurement.frame.width, FlareSizes.authFormMaxWidth + 0.5)
        XCTAssertGreaterThan(measurement.frame.minX, 1440 * 0.44)
        XCTAssertGreaterThan(measurement.frame.minY, 100)
        XCTAssertLessThan(measurement.frame.maxY, 900)
    }

    @MainActor
    func testPhoneStartsNearTheSafeTopAndDoesNotOverflowHorizontally() {
        let measurement = Measurement()
        let window = render(width: 320, height: 640, measurement: measurement)
        defer { window.close() }
        XCTAssertGreaterThan(measurement.frame.width, 200)
        XCTAssertLessThanOrEqual(measurement.frame.maxX, 320)
        XCTAssertGreaterThanOrEqual(measurement.frame.minX, FlareSizes.spacing2xl)
        XCTAssertLessThan(measurement.frame.minY, 360)
    }

    @MainActor
    func testDarkShortPhoneWithAccessibleTextKeepsTheFormInsideItsWidth() {
        let measurement = Measurement()
        let window = render(width: 390, height: 360, dark: true, largeText: true, measurement: measurement)
        defer { window.close() }
        XCTAssertGreaterThan(measurement.frame.width, 200)
        XCTAssertGreaterThanOrEqual(measurement.frame.minX, 0)
        XCTAssertLessThanOrEqual(measurement.frame.maxX, 390)
    }
    #endif
}
