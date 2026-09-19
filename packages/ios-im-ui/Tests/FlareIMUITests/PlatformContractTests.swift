import XCTest
import SwiftUI
@testable import FlareIMUI

// Contract tests for Layer 5 (spec/platform-contract.json vectors). A scripted
// adapter plays each native outcome; the assertions are on the contract's
// normalization and result shape, not on any real picker — the capability
// matrix records this as PASS_TEST, never PASS_RUNTIME.
final class PlatformContractTests: XCTestCase {
    private enum Outcome: String, CaseIterable { case success, cancelled, unsupported, denied, timeout, failed }

    private struct Scripted: FlarePlatformAdapter {
        let outcome: Outcome
        var capabilities: FlarePlatformCapabilities {
            FlarePlatformCapabilities(filePicker: .supported, imagePicker: .supported, share: .supported)
        }
        private func play<T: Sendable>(_ value: T) async throws -> FlarePlatformResult<T> {
            switch outcome {
            case .success: return .success(value)
            // PhotosPicker / fileImporter report a dismissed picker as nil / .failure(userCancelled); the host maps it.
            case .cancelled: return .failure(FlarePlatformError(.cancelled, message: "picker dismissed"))
            case .unsupported: throw NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError)
            case .denied: throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError)
            case .timeout:
                while true { try await Task.sleep(nanoseconds: 5_000_000) }
            case .failed: throw NSError(domain: "FlareImApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "native surface crashed"])
            }
        }
        func pickFiles(_ options: FlarePickFilesOptions) async -> FlarePlatformResult<[FlarePickedFile]> {
            (try? await play([FlarePickedFile(name: "spec.pdf", size: 4, mimeType: "application/pdf", path: "/tmp/spec.pdf")])) ?? .failure(FlarePlatformError(.failed))
        }
        func pickImages(_ options: FlarePickImagesOptions) async -> FlarePlatformResult<[FlarePickedFile]> {
            (try? await play([FlarePickedFile(name: "shot.png", mimeType: "image/png", path: "/tmp/shot.png")])) ?? .failure(FlarePlatformError(.failed))
        }
        func share(_ payload: FlareSharePayload) async -> FlarePlatformResult<Void> {
            (try? await play(())) ?? .failure(FlarePlatformError(.failed))
        }
        // The throwing path is what hosts wrap with callFlarePlatform; expose it for the vectors.
        func raw(_ operation: String) async throws -> FlarePlatformResult<Int> {
            switch operation {
            case "pickFiles": return try await play(1)
            case "pickImages": return try await play(2)
            default: return try await play(3)
            }
        }
    }

    private func run(_ operation: String, _ outcome: Outcome) async -> FlarePlatformResult<Int> {
        let adapter = Scripted(outcome: outcome)
        return await callFlarePlatform(timeoutMilliseconds: 40) { try await adapter.raw(operation) }
    }

    // Vector ids: pickFiles.success pickFiles.cancelled pickFiles.unsupported
    // pickFiles.denied pickFiles.timeout pickFiles.failed pickImages.success
    // pickImages.cancelled pickImages.unsupported pickImages.denied
    // pickImages.timeout pickImages.failed share.success share.cancelled
    // share.unsupported share.denied share.timeout share.failed
    func testEveryOperationOutcomeVectorNormalizes() async {
        let expected: [Outcome: FlarePlatformErrorCode] = [
            .cancelled: .cancelled, .unsupported: .unsupported, .denied: .permissionDenied, .timeout: .timeout, .failed: .failed,
        ]
        for operation in ["pickFiles", "pickImages", "share"] {
            let ok = await run(operation, .success)
            XCTAssertTrue(ok.isOk, "\(operation).success")
            for (outcome, code) in expected {
                let id = "\(operation).\(outcome.rawValue)"
                let result = await run(operation, outcome)
                XCTAssertFalse(result.isOk, id)
                XCTAssertEqual(result.code, code, id)
                XCTAssertNotNil(result.errorOrNil?.message, "\(id) keeps a message")
            }
        }
        let files = await Scripted(outcome: .success).pickFiles(FlarePickFilesOptions())
        XCTAssertEqual(files.valueOrNil?.first?.name, "spec.pdf")
    }

    func testErrorModelMapsFoundationErrors() {
        XCTAssertEqual(normalizeFlarePlatformError(CancellationError()).code, .cancelled)
        XCTAssertEqual(normalizeFlarePlatformError(NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)).code, .cancelled)
        XCTAssertEqual(normalizeFlarePlatformError(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)).code, .timeout)
        XCTAssertEqual(normalizeFlarePlatformError(NSError(domain: NSCocoaErrorDomain, code: NSFileWriteNoPermissionError)).code, .permissionDenied)
        XCTAssertEqual(normalizeFlarePlatformError(NSError(domain: "x", code: 9, userInfo: [NSLocalizedDescriptionKey: "Photos access denied"])).code, .permissionDenied)
        XCTAssertEqual(normalizeFlarePlatformError(NSError(domain: "x", code: 9, userInfo: [NSLocalizedDescriptionKey: "boom"])).code, .failed)
        XCTAssertEqual(normalizeFlarePlatformError(NSError(domain: "x", code: 9, userInfo: [NSLocalizedDescriptionKey: "request timed out"])).code, .timeout)
        let passthrough = FlarePlatformError(.timeout, message: "kept")
        XCTAssertEqual(normalizeFlarePlatformError(passthrough), passthrough)
    }

    func testUnsupportedAdapterAnswersUnsupportedEverywhere() async {
        let adapter = FlareUnsupportedPlatformAdapter()
        let files = await adapter.pickFiles(FlarePickFilesOptions())
        XCTAssertEqual(files.code, .unsupported)
        let images = await adapter.pickImages(FlarePickImagesOptions())
        XCTAssertEqual(images.code, .unsupported)
        let shared = await adapter.share(FlareSharePayload())
        XCTAssertEqual(shared.code, .unsupported)
        XCTAssertNil(adapter.onNativeBack { true })
        XCTAssertEqual(adapter.capabilities.filePicker, .unsupported)
        XCTAssertTrue(adapter.capabilities.safeArea)
        XCTAssertEqual(adapter.kind, .ios)
    }

    func testIOSCapabilitiesFollowFormFactorAndPointer() {
        let phone = FlarePlatformCapabilities.ios(width: 390)
        XCTAssertEqual(phone.pointer, .coarse)
        XCTAssertTrue(phone.bottomSheet)
        XCTAssertFalse(phone.hover)
        let padWithTrackpad = FlarePlatformCapabilities.ios(width: 1024, hasPointer: true)
        XCTAssertEqual(padWithTrackpad.pointer, .mixed)
        XCTAssertFalse(padWithTrackpad.bottomSheet)
        XCTAssertTrue(padWithTrackpad.contextMenu)
        _ = EmptyView().flarePlatform(Scripted(outcome: .success))
    }
}
