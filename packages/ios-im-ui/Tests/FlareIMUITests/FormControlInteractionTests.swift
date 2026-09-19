import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

final class FormControlInteractionTests: XCTestCase {
    @MainActor
    func testSwitchUsesButtonActionAndRespectsDisabledState() throws {
        var checked = false
        let binding = Binding(get: { checked }, set: { checked = $0 })
        let button = try SwitchView(isOn: binding).inspect().find(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(try button.labelView().flexFrame().minHeight, 44)
        try button.tap()
        XCTAssertTrue(checked)
        let disabled = try SwitchView(isOn: binding, disabled: true).inspect().find(ViewType.Button.self)
        XCTAssertTrue(disabled.isDisabled())
        XCTAssertThrowsError(try disabled.tap())
        XCTAssertTrue(checked)
    }

    @MainActor
    func testCheckboxUsesButtonActionAndRespectsDisabledState() throws {
        var checked = false
        let binding = Binding(get: { checked }, set: { checked = $0 })
        let button = try CheckboxView(isOn: binding, label: "Read receipts").inspect().find(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(try button.labelView().flexFrame().minHeight, 44)
        XCTAssertEqual(try button.find(text: "Read receipts").string(), "Read receipts")
        try button.tap()
        XCTAssertTrue(checked)
        let disabled = try CheckboxView(isOn: binding, disabled: true).inspect().find(ViewType.Button.self)
        XCTAssertTrue(disabled.isDisabled())
        XCTAssertThrowsError(try disabled.tap())
    }

    @MainActor
    func testRadioSelectionAndDisabledOptions() throws {
        var selected = "first"
        let binding = Binding(get: { selected }, set: { selected = $0 })
        let controls = try RadioGroupView(options: [
            .init(value: "first", label: "First"),
            .init(value: "second", label: "Second"),
            .init(value: "disabled", label: "Disabled", disabled: true),
        ], selection: binding, vertical: true).inspect().findAll(ViewType.Button.self)
        XCTAssertEqual(controls.count, 3)
        for control in controls {
            XCTAssertGreaterThanOrEqual(try control.labelView().flexFrame().minHeight, 44)
        }
        try XCTUnwrap(controls.dropFirst().first).tap()
        XCTAssertEqual(selected, "second")
        let disabled = try XCTUnwrap(controls.last)
        XCTAssertTrue(disabled.isDisabled())
        XCTAssertThrowsError(try disabled.tap())
        XCTAssertEqual(selected, "second")
    }
}
