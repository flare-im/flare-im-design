import XCTest
@testable import FlareIMUI

final class AdaptiveGridTests: XCTestCase {
    func testContentWidthAndLargeTextChoosePredictableColumns() {
        for width in [0.0, 280, 319] {
            XCTAssertEqual(FlareAdaptiveGrid.columnCount(width: width), 1)
        }
        for width in [320.0, 390, 599] {
            XCTAssertEqual(FlareAdaptiveGrid.columnCount(width: width), 2)
        }
        for width in [600.0, 880, 1440] {
            XCTAssertEqual(FlareAdaptiveGrid.columnCount(width: width), 3)
            XCTAssertEqual(FlareAdaptiveGrid.columnCount(width: width, singleColumn: true), 1)
        }
    }
}

#if os(macOS)
import AppKit
import SwiftUI

private final class GridImageLifecycle {
    var starts = [0, 0, 0]
    var finished = Set<Int>()
    var disappears = 0
}

@MainActor
private final class GridPresentation: ObservableObject {
    @Published var width: CGFloat = 390
    @Published var singleColumn = false
}

private struct AsyncGridImage: View {
    let index: Int
    let lifecycle: GridImageLifecycle
    @State private var loaded = false

    var body: some View {
        VStack {
            Text("Photo")
            ZStack {
                if loaded { Color.green.frame(idealWidth: 512, idealHeight: 320) }
                else { ProgressView() }
            }
            .frame(maxWidth: .infinity).aspectRatio(1.6, contentMode: .fit)
        }
        .task {
            lifecycle.starts[index] += 1
            await Task.yield()
            guard !Task.isCancelled else { return }
            loaded = true
            lifecycle.finished.insert(index)
        }
        .onDisappear { lifecycle.disappears += 1; loaded = false }
    }
}

private struct HostedAdaptiveGrid: View {
    @ObservedObject var presentation: GridPresentation
    let lifecycle: GridImageLifecycle

    var body: some View {
        ScrollView {
            FlareAdaptiveGrid(singleColumn: presentation.singleColumn) {
                ForEach(0..<3) { index in AsyncGridImage(index: index, lifecycle: lifecycle) }
            }
        }.frame(width: presentation.width, height: 700)
    }
}

extension AdaptiveGridTests {
    /// No displayed window or generated input: exercise SwiftUI mounting and
    /// asynchronous intrinsic-size changes without touching another app.
    @MainActor
    func testAsyncImagesRemainMountedWhenTheyLoadAndTheGridReflows() {
        _ = NSApplication.shared
        let presentation = GridPresentation()
        let lifecycle = GridImageLifecycle()
        let host = NSHostingView(rootView: HostedAdaptiveGrid(presentation: presentation, lifecycle: lifecycle))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
                              styleMask: [], backing: .buffered, defer: false)
        window.contentView = host
        defer { window.contentView = nil }
        host.layoutSubtreeIfNeeded()
        let deadline = Date().addingTimeInterval(2)
        while lifecycle.finished.count < 3 && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }
        XCTAssertEqual(lifecycle.finished, Set(0..<3))

        for width: CGFloat in [880, 280, 390] {
            presentation.width = width
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.03))
        }
        presentation.singleColumn = true
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.03))
        XCTAssertEqual(lifecycle.starts, [1, 1, 1], "reflow must not restart asynchronous children")
        XCTAssertEqual(lifecycle.disappears, 0, "loaded content must remain mounted on the visible page")
    }
}
#endif
