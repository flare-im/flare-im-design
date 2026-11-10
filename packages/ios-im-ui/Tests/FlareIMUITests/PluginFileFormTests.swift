import XCTest
@testable import FlareIMUI

final class PluginFileFormTests: XCTestCase {
    private let policy = PluginFileInput(accept: ["image/png", "application/pdf"], maxBytes: 5_242_880,
        upload: .init(prepareOperation: "proof.prepare", completeOperation: "proof.complete", purpose: "rechargeProof"))
    private var kind: PluginInput {
        .init(id: "kind", kind: .select, label: "Type", defaultValue: "alipay",
            choices: [.init(value: "alipay", label: "Ali"), .init(value: "wechat", label: "WeChat"), .init(value: "bankCard", label: "Bank")])
    }
    private var file: PluginInput {
        .init(id: "code", kind: .file, label: "Code", required: true, file: policy,
              showWhen: .init(field: "kind", anyOf: ["alipay", "wechat"]))
    }

    func testSpecificMimeAndBoundedPolicyDecode() throws {
        let source = #"{"id":"proof","kind":"file","label":"Proof","file":{"accept":["application/pdf"],"maxBytes":5242880,"upload":{"prepareOperation":"p","completeOperation":"c","purpose":"rechargeProof"}}}"#
        XCTAssertEqual(try JSONDecoder().decode(PluginInput.self, from: Data(source.utf8)).file?.accept, ["application/pdf"])
        XCTAssertThrowsError(try JSONDecoder().decode(PluginInput.self, from: Data(source.replacingOccurrences(of: "5242880", with: "5242881").utf8)))
    }

    func testFileValueContainsOnlyDurableId() {
        XCTAssertEqual(PluginFileValue.read(["fileId": "f1"])?.fileId, "f1")
        XCTAssertNil(PluginFileValue.read("https://signed.example/secret"))
        XCTAssertNil(PluginFileValue.read(["fileId": "f1", "url": "secret"]))
        XCTAssertNil(PluginFileValue.read(["fileId": " "]))
    }

    func testConditionalControllerClearsEvenStillVisibleFileAndDoesNotReseedDefaults() {
        let text = PluginInput(id: "name", kind: .text, label: "Name", required: true, defaultValue: "Initial",
            showWhen: .init(field: "kind", anyOf: ["alipay", "wechat"]))
        let inputs = [kind, text, file]
        var state = PluginFormState(inputs: inputs, values: ["code": ["fileId": "existing"]], scope: "s")
        XCTAssertEqual(state.draft["name"], "Initial")
        let events = state.set("kind", "wechat")
        XCTAssertEqual(events.map(\.action), [.invalidate])
        XCTAssertNil(state.draft["name"])
        XCTAssertNil(state.draft["code"])
        XCTAssertNil(state.submit(inputs))
        state.set("kind", "bankCard")
        XCTAssertEqual(state.submit(inputs), ["kind": "bankCard"])
        state.set("kind", "alipay")
        XCTAssertNil(state.draft["name"], "defaults are initialization only")
        XCTAssertNil(state.submit(inputs))
    }

    func testHiddenFieldsAreNeitherCheckedNorSubmitted() {
        let inputs = [kind, file]
        let draft: [String: PluginJSONValue] = ["kind": "bankCard", "code": ["fileId": "stale"]]
        XCTAssertTrue(PluginFormRules.check(inputs, draft).isEmpty)
        XCTAssertEqual(PluginFormRules.values(inputs, draft), ["kind": "bankCard"])
        XCTAssertFalse(PluginFormRules.visible(file, in: [file, kind], draft: ["kind": "alipay"]))
    }

    func testUploadStateRequiresExactScopeAndGeneration() {
        let inputs = [kind, file]
        var state = PluginFormState(inputs: inputs, values: nil, scope: "scope")
        let choose = state.fileAction(.choose, input: file)
        XCTAssertEqual(choose.generation, 1)
        XCTAssertTrue(state.filePending)
        state.acceptFiles(["code": .init(scope: "other", generation: 1, phase: .uploaded, value: .init(fileId: "wrong"))])
        XCTAssertNil(state.draft["code"])
        let cancel = state.fileAction(.cancel, input: file)
        XCTAssertEqual(cancel.generation, 2)
        state.acceptFiles(["code": .init(scope: "scope", generation: 1, phase: .uploaded, value: .init(fileId: "late"))])
        XCTAssertNil(state.draft["code"])
        let replace = state.fileAction(.replace, input: file)
        XCTAssertEqual(replace.generation, 3)
        state.acceptFiles(["code": .init(scope: "scope", generation: 3, phase: .failed)])
        XCTAssertNil(state.submit(inputs), "failed optional transfers cannot silently disappear")
        XCTAssertEqual(state.fileAction(.retry, input: file).generation, 3)
        state.acceptFiles(["code": .init(scope: "scope", generation: 3, phase: .uploaded, value: .init(fileId: "right"))])
        XCTAssertEqual(state.submit(inputs), ["kind": "alipay", "code": ["fileId": "right"]])
    }

    func testEachFormMountHasADistinctScope() {
        XCTAssertNotEqual(PluginFormState(inputs: [file], values: nil).scope, PluginFormState(inputs: [file], values: nil).scope)
    }
}
