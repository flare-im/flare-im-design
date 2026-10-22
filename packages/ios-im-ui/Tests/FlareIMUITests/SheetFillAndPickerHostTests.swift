import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The bottom sheet's fill mode and the content's own-header declaration, and what LocationPickerView takes from its
/// host: `sending`, the permission step before each locate and the map size in device pixels
/// (`spec/location-vectors.json` previewSize).
final class SheetFillAndPickerHostTests: XCTestCase {
    private let s = FlareStrings()
    private let here = FlareLocationCoordinate(latitude: 30.2741, longitude: 120.1551)

    // MARK: Sheet fill

    func testTheTitleGivesWayOnlyToAFilledSheetWhoseContentBringsItsHeader() {
        XCTAssertTrue(BottomSheetView<EmptyView>.drawsTitle(title: "位置", titleHidden: false, fill: false, ownHeader: false))
        XCTAssertTrue(BottomSheetView<EmptyView>.drawsTitle(title: "位置", titleHidden: false, fill: false, ownHeader: true),
                      "without fill the declaration changes nothing")
        XCTAssertTrue(BottomSheetView<EmptyView>.drawsTitle(title: "位置", titleHidden: false, fill: true, ownHeader: false))
        XCTAssertFalse(BottomSheetView<EmptyView>.drawsTitle(title: "位置", titleHidden: false, fill: true, ownHeader: true))
        XCTAssertFalse(BottomSheetView<EmptyView>.drawsTitle(title: "位置", titleHidden: true, fill: false, ownHeader: false))
        XCTAssertFalse(BottomSheetView<EmptyView>.drawsTitle(title: nil, titleHidden: false, fill: true, ownHeader: false))
    }

    func testAFilledSheetTakesItsWholeCap() {
        XCTAssertEqual(FlareBottomSheetFrame<EmptyView>.fillDetents(cap: 540), [.height(540)])
        XCTAssertEqual(FlareBottomSheetFrame<EmptyView>.fillDetents(cap: nil), [.large], "no host to measure: large")
    }

    @MainActor
    func testTheFrameStillDrawsTheTitleBeforeAnyDeclaration() throws {
        let sheet = BottomSheetView(title: "位置", maxHeight: 400, fill: true) { Text("body") }
        XCTAssertNoThrow(try sheet.inspect().find(text: "位置"))
        XCTAssertNoThrow(try sheet.inspect().find(text: "body"))
    }

    #if os(macOS)
    private final class Seen { var height: CGFloat = 0; var owns: Bool? }

    private struct HeightProbe: View {
        let seen: Seen
        var body: some View {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { seen.height = proxy.size.height }
                    .onChange(of: proxy.size.height) { seen.height = $0 }
            }
        }
    }

    /// Reads the declaration a view makes, as a sheet reads it.
    private struct OwnHeaderProbe<Content: View>: View {
        let seen: Seen
        let content: Content
        var body: some View {
            content.onPreferenceChange(FlareSheetOwnHeaderKey.self) { seen.owns = $0 }
        }
    }

    @MainActor
    private func render<V: View>(_ view: V, size: CGSize = CGSize(width: 390, height: 800)) -> NSWindow {
        _ = NSApplication.shared
        let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height, alignment: .top))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        host.setFrameSize(size)
        host.layoutSubtreeIfNeeded()
        window.orderFront(nil)
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        host.layoutSubtreeIfNeeded()
        return window
    }

    @MainActor
    func testFillHandsTheContentTheCapAndAnOwnHeaderTakesTheTitlesPlace() {
        let declared = Seen(), titled = Seen()
        let a = render(BottomSheetView(title: "位置", maxHeight: 400, fill: true) {
            HeightProbe(seen: declared).flareSheetOwnHeader()
        })
        let b = render(BottomSheetView(title: "位置", maxHeight: 400, fill: true) { HeightProbe(seen: titled) })
        defer { a.close(); b.close() }
        XCTAssertEqual(declared.height, 400, accuracy: 0.5, "own header: the content fills the whole cap")
        XCTAssertGreaterThan(titled.height, 300, "the content fills what the title leaves")
        XCTAssertLessThan(titled.height, 400, "the caption still takes its row")
    }

    @MainActor
    func testTheKitPickersDeclareTheirOwnHeader() {
        let location = Seen(), contacts = Seen(), plain = Seen()
        let windows = [
            render(OwnHeaderProbe(seen: location, content: LocationPickerView())),
            render(OwnHeaderProbe(seen: contacts, content: ContactPickerView(groups: [
                FlareContactPickerGroup(id: FlareContactPickerGroup.friends, entries: [
                    FlareContactPickerEntry(userId: "u1", name: "Ann")]),
            ]))),
            render(OwnHeaderProbe(seen: plain, content: Text("x").flareSheetOwnHeader(false))),
        ]
        defer { windows.forEach { $0.close() } }
        XCTAssertEqual(location.owns, true)
        XCTAssertEqual(contacts.owns, true)
        XCTAssertNotEqual(plain.owns, true)
    }
    #endif

    // MARK: Location picker: sending

    @MainActor
    private func picker(sending: Bool, onSend: ((FlareLocationPlace) -> Void)? = nil) -> LocationPickerView {
        var model = FlareLocationPickerModel()
        model.located(here)
        return LocationPickerView(initialLocation: nil, zoom: 16, locateTimeoutMs: 5000, requestCurrentLocation: nil,
                                  reverseGeocode: nil, searchNearby: nil, previewUrl: nil, onSend: onSend,
                                  onCancel: nil, model: model, sending: sending)
    }

    @MainActor
    func testSendingSpinsTheSendKeyAndTakesNoSecondTap() throws {
        var sent = 0
        let idle = try picker(sending: false, onSend: { _ in sent += 1 }).inspect()
        let key = try idle.find(ViewType.Button.self, where: { (try? $0.labelView().find(text: self.s.locationSend)) != nil })
        XCTAssertFalse(key.isDisabled())
        XCTAssertThrowsError(try key.labelView().find(ViewType.ProgressView.self))
        try key.tap()
        XCTAssertEqual(sent, 1)

        let busy = try picker(sending: true, onSend: { _ in sent += 1 }).inspect()
        let spinning = try busy.find(ViewType.Button.self, where: { (try? $0.labelView().find(text: self.s.locationSend)) != nil })
        XCTAssertTrue(spinning.isDisabled(), "a second tap sends nothing")
        XCTAssertNoThrow(try spinning.labelView().find(ViewType.ProgressView.self), "the key spins")
        XCTAssertThrowsError(try spinning.tap())
        XCTAssertEqual(sent, 1)

        var model = FlareLocationPickerModel()
        model.located(here)
        XCTAssertTrue(model.statuses(sending: true).contains(.sending))
        XCTAssertFalse(model.statuses(sending: false).contains(.sending))
        XCTAssertTrue(FlareLocationPickerStatus.allCases.contains(.sending))
    }

    // MARK: Location picker: permission

    private final class Calls: @unchecked Sendable {
        private let lock = NSLock()
        private var count = 0
        func hit() { lock.lock(); count += 1; lock.unlock() }
        var value: Int { lock.lock(); defer { lock.unlock() }; return count }
    }

    func testThePermissionStepComesFirstAndIsNotTimed() async {
        let calls = Calls()
        let point = here
        let request: @Sendable () async throws -> FlareLocationCoordinate = { calls.hit(); return point }

        let refused = await LocationPickerView.position(ensurePermission: { false }, requestCurrentLocation: request,
                                                        timeoutMs: 5000)
        XCTAssertNil(refused, "false is denied")
        XCTAssertEqual(calls.value, 0, "without permission the position is never asked for")

        struct Denied: Error {}
        let failed = await LocationPickerView.position(ensurePermission: { throw Denied() },
                                                       requestCurrentLocation: request, timeoutMs: 5000)
        XCTAssertNil(failed, "a throw is denied")
        XCTAssertEqual(calls.value, 0)

        // The prompt is up longer than the timeout: its wait does not count.
        let slowPrompt = await LocationPickerView.position(ensurePermission: {
            try? await Task.sleep(nanoseconds: 300_000_000)
            return true
        }, requestCurrentLocation: request, timeoutMs: 100)
        XCTAssertEqual(slowPrompt, here)
        XCTAssertEqual(calls.value, 1)

        let withoutStep = await LocationPickerView.position(ensurePermission: nil, requestCurrentLocation: request,
                                                            timeoutMs: 5000)
        XCTAssertEqual(withoutStep, here, "no permission step: the position is asked for at once")

        let slowFix = await LocationPickerView.position(ensurePermission: { true }, requestCurrentLocation: {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            return point
        }, timeoutMs: 50)
        XCTAssertNil(slowFix, "the timeout still runs once permission is granted")
    }

    // MARK: Location picker: map size

    private struct PreviewSize: Decodable {
        struct Size: Decodable { let width: Double; let height: Double; let scale: Double? }
        let id: String
        let input: Size
        let output: Size
    }

    func testThePreviewSizeIsDevicePixelsAsTheTableSays() throws {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        struct Table: Decodable { let previewSize: [PreviewSize] }
        let table = try JSONDecoder().decode(
            Table.self, from: Data(contentsOf: root.appendingPathComponent("spec/location-vectors.json")))
        XCTAssertGreaterThanOrEqual(table.previewSize.count, 7)
        for row in table.previewSize {
            let pixels = FlareLocationFormat.previewPixels(width: row.input.width, height: row.input.height,
                                                           scale: row.input.scale ?? 1)
            XCTAssertEqual(pixels.width, Int(row.output.width), row.id)
            XCTAssertEqual(pixels.height, Int(row.output.height), row.id)
        }
    }
}
