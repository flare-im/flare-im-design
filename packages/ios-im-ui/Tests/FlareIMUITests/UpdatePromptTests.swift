import Foundation
import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The shared update table (`spec/update-prompt-vectors.json`): what the host read in, what the prompt, the bar and the
/// version panel show out. The Vue, Flutter and Compose kits run the same file.
final class UpdatePromptTests: XCTestCase {
    private struct Progress: Decodable { let received: Int64; let total: Int64? }
    private struct Input: Decodable {
        let form: String
        let mandatory: Bool?
        let state: String?
        let progress: Progress?
        let errorCode: String?
        let retryable: Bool?
        let sizeBytes: Int64?
        let canContinueReadOnly: Bool?
        let reason: String?
    }
    private struct Bar: Decodable { let value: Double?; let percent: Int? }
    private struct Expect: Decodable {
        let phase: String
        let forced: Bool
        let dismissible: Bool
        let live: String
        let title: String
        let message: String?
        let actions: [String]
        let notes: Bool
        let progress: Bar?
    }
    private struct Case: Decodable { let name: String; let input: Input; let expect: Expect }
    private struct Failure: Decodable { let errorCode: String?; let message: String }
    private struct VersionRow: Decodable { let version: String?; let shown: Bool }
    private struct BarRow: Decodable { let value: Double?; let indeterminate: Bool; let shown: Double?; let percent: Int? }
    private struct PanelRow: Decodable { let updateState: String?; let row: String; let action: String?; let detail: String? }
    private struct Channel: Decodable { let channel: String?; let text: String? }
    private struct Table: Decodable {
        let failures: [Failure]
        let versions: [VersionRow]
        let progressBar: [BarRow]
        let versionPanel: [PanelRow]
        let channels: [Channel]
        let cases: [Case]
    }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        return try JSONDecoder().decode(
            Table.self, from: Data(contentsOf: root.appendingPathComponent("spec/update-prompt-vectors.json")))
    }

    func testPromptRules() throws {
        for vector in try table().cases {
            let input = vector.input
            let model = flareUpdatePrompt(
                form: try XCTUnwrap(FlareUpdatePromptForm(rawValue: input.form)),
                mandatory: input.mandatory ?? false,
                state: input.state,
                progress: input.progress.map { FlareUpdateProgress(received: $0.received, total: $0.total) },
                errorCode: input.errorCode,
                retryable: input.retryable ?? true,
                sizeBytes: input.sizeBytes,
                canContinueReadOnly: input.canContinueReadOnly ?? false,
                reason: input.reason)
            let want = vector.expect
            XCTAssertEqual(model.phase.rawValue, want.phase, vector.name)
            XCTAssertEqual(model.forced, want.forced, vector.name)
            XCTAssertEqual(model.dismissible, want.dismissible, vector.name)
            XCTAssertEqual(model.live.rawValue, want.live, vector.name)
            XCTAssertEqual(model.title.rawValue, want.title, vector.name)
            XCTAssertEqual(model.message?.rawValue, want.message, vector.name)
            XCTAssertEqual(model.actions.map(\.rawValue), want.actions, vector.name)
            XCTAssertEqual(model.notes, want.notes, vector.name)
            XCTAssertEqual(model.progress?.value, want.progress?.value, vector.name)
            XCTAssertEqual(model.progress?.percent, want.progress?.percent, vector.name)
            XCTAssertEqual(model.progress == nil, want.progress == nil, vector.name)
        }
    }

    func testFailures() throws {
        for vector in try table().failures {
            XCTAssertEqual(flareUpdateFailure(vector.errorCode).rawValue, vector.message)
        }
    }

    func testVersionLine() throws {
        for vector in try table().versions {
            XCTAssertEqual(flareUpdateVersionShown(vector.version), vector.shown)
        }
    }

    func testPromptDrawsNoVersionLineBeforeAManifestArrived() throws {
        let view = UpdatePromptView(form: .modal, state: "required", onUpdate: {}, onLater: {})
        XCTAssertFalse(view.dismissible)
        XCTAssertNoThrow(try view.inspect().find(text: "需要更新"))
        XCTAssertThrowsError(try view.inspect().find(text: "稍后"))
        // The message says 当前版本; the version line starts with the word.
        XCTAssertThrowsError(try view.inspect().find(ViewType.Text.self, where: { try $0.string().hasPrefix("版本") }))
    }

    func testProgressBarValues() throws {
        for vector in try table().progressBar {
            let shown = flareProgressBarValue(vector.value, indeterminate: vector.indeterminate)
            XCTAssertEqual(shown.value, vector.shown)
            XCTAssertEqual(shown.percent, vector.percent)
        }
        XCTAssertEqual(flareProgressBarValue(Double.nan), FlareProgressBarValue.none)
        XCTAssertEqual(flareProgressBarValue(Double.infinity), FlareProgressBarValue.none)
    }

    func testVersionPanelRules() throws {
        for vector in try table().versionPanel {
            let model = flareVersionPanel(vector.updateState)
            XCTAssertEqual(model.row.rawValue, vector.row)
            XCTAssertEqual(model.action?.rawValue, vector.action)
            XCTAssertEqual(model.detail?.rawValue, vector.detail)
        }
    }

    func testChannels() throws {
        for vector in try table().channels {
            XCTAssertEqual(flareVersionChannelText(vector.channel)?.rawValue, vector.text)
        }
    }

    func testWords() {
        let zh = FlareStrings()
        let en = FlareStrings.english
        XCTAssertEqual(FlareUpdatePromptAction.update.label(zh), "立即更新")
        XCTAssertEqual(FlareUpdatePromptAction.update.label(en), "Update now")
        XCTAssertEqual(FlareUpdatePromptAction.fallback.label(zh), "前往官网下载")
        XCTAssertEqual(FlareUpdatePromptAction.fallback.label(zh, fallbackTarget: .store), "前往应用商店")
        XCTAssertEqual(FlareUpdatePromptMessage.metered.label(zh, size: "50.0 MB"), "当前是计费网络，这次下载约 50.0 MB")
        XCTAssertEqual(FlareUpdatePromptMessage.reason.label(zh, reason: "这个版本已撤回，请更新。"), "这个版本已撤回，请更新。")
        XCTAssertEqual(flareVersionChannelLabel("beta", strings: zh), "测试版")
        XCTAssertEqual(flareVersionChannelLabel("nightly", strings: zh), "nightly")
    }

    func testPromptDrawsAnActionOnlyWhenTheHostHandlesIt() throws {
        let view = UpdatePromptView(form: .sheet, version: "2.4.0", state: "available", onUpdate: {})
        XCTAssertNoThrow(try view.inspect().find(text: "立即更新"))
        XCTAssertThrowsError(try view.inspect().find(text: "稍后"))
        XCTAssertThrowsError(try view.inspect().find(text: "跳过此版本"))
    }

    func testForcedPromptHasNoLaterAndKeepsReadOnly() throws {
        let view = UpdatePromptView(form: .modal, version: "2.4.0", mandatory: true, state: "required",
                                    canContinueReadOnly: true, onUpdate: {}, onLater: {}, onSkip: {},
                                    onContinueReadOnly: {})
        XCTAssertFalse(view.dismissible)
        XCTAssertThrowsError(try view.inspect().find(text: "稍后"))
        XCTAssertNoThrow(try view.inspect().find(text: "继续浏览"))
    }

    func testForcedOfferSaysTheReasonInPlaceOfTheFixedWords() throws {
        let view = UpdatePromptView(form: .modal, reason: "这个版本已撤回，请更新。", state: "required", onUpdate: {})
        XCTAssertNoThrow(try view.inspect().find(text: "这个版本已撤回，请更新。"))
        XCTAssertThrowsError(try view.inspect().find(text: "当前版本已停止支持，更新后才能继续使用。"))
    }

    func testBlankReasonKeepsTheFixedWords() throws {
        let view = UpdatePromptView(form: .modal, reason: "   ", state: "required", onUpdate: {})
        XCTAssertNoThrow(try view.inspect().find(text: "当前版本已停止支持，更新后才能继续使用。"))
    }

    func testFailureKeepsItsOwnWordsOverTheReason() throws {
        let view = UpdatePromptView(form: .modal, reason: "这个版本已撤回，请更新。", mandatory: true, state: "failed",
                                    errorCode: "update.downloadFailed", onRetry: {})
        XCTAssertThrowsError(try view.inspect().find(text: "这个版本已撤回，请更新。"))
    }

    func testPromptOffersLaterOnlyWhileTheHostCanTakeIt() {
        var later = 0
        let view = UpdatePromptView(form: .modal, version: "2.4.0", state: "available", onLater: { later += 1 })
        XCTAssertTrue(view.dismissible)
        view.requestLater()
        XCTAssertEqual(later, 1)
        XCTAssertFalse(UpdatePromptView(form: .modal, version: "2.4.0", state: "available").dismissible)
    }

    func testPromptShowsTheDownloadWithItsNumber() throws {
        let view = UpdatePromptView(form: .modal, version: "2.4.0", sizeBytes: 52_428_800, state: "downloading",
                                    progress: FlareUpdateProgress(received: 26_214_400, total: 52_428_800))
        XCTAssertNoThrow(try view.inspect().find(text: "版本 2.4.0 · 50.0 MB"))
        XCTAssertNoThrow(try view.inspect().find(text: "50% · 25.0 MB / 50.0 MB"))
    }

    func testPromptDrawsNoFallbackWithoutAnAddress() throws {
        let view = UpdatePromptView(form: .modal, version: "2.4.0", state: "failed",
                                    errorCode: "update.downloadFailed", onLater: {}, onRetry: {})
        XCTAssertNoThrow(try view.inspect().find(text: "重试"))
        XCTAssertThrowsError(try view.inspect().find(text: "前往官网下载"))
    }

    #if os(macOS)
    /// A forced update is often the first status there is: the layer opens from nothing, in a form the prompt of the
    /// render before did not have. Reading that prompt's form, it took itself for closed and showed nothing.
    @MainActor
    func testTheFirstStatusOpensItsLayerInEveryForm() {
        final class Source: ObservableObject {
            @Published var form: FlareUpdatePromptForm?
        }
        struct Host: View {
            @ObservedObject var source: Source
            var body: some View {
                Color.clear.flareUpdatePrompt(
                    isPresented: Binding(get: { source.form != nil }, set: { _ in }),
                    prompt: UpdatePromptView(form: source.form ?? .sheet, version: "2.4.0", state: "required"))
            }
        }
        for form in [FlareUpdatePromptForm.sheet, .modal, .fullscreen] {
            let source = Source()
            let size = CGSize(width: 390, height: 844)
            let host = NSHostingView(rootView: Host(source: source)
                .flareFeedbackHost(FlareFeedback(announce: { _ in }))
                .frame(width: size.width, height: size.height))
            let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .titled,
                                  backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            defer { window.close() }
            window.contentView = host
            window.orderFront(nil)
            RunLoop.main.run(until: Date().addingTimeInterval(0.2))
            XCTAssertNil(window.attachedSheet)
            source.form = form
            RunLoop.main.run(until: Date().addingTimeInterval(0.6))
            XCTAssertNotNil(window.attachedSheet, "\(form)")
        }
    }
    #endif

    func testVersionPanelListsItsRows() throws {
        let view = VersionPanelView(version: "2.3.2", build: 20302, channel: "stable")
        XCTAssertNoThrow(try view.inspect().find(text: "2.3.2"))
        XCTAssertNoThrow(try view.inspect().find(text: "20302"))
        XCTAssertNoThrow(try view.inspect().find(text: "正式版"))
        XCTAssertNoThrow(try view.inspect().find(text: "检查更新"))
    }
}
