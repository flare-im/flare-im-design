import XCTest
@testable import FlareIMUI

/// DoD 20 — the vector table of spec/form-keyboard-contract.json. The four
/// platforms run the same ids; tooling/check-form-keyboard.mjs fails when one of
/// them stops exercising a vector.
final class FormBehaviorTests: XCTestCase {
    private struct Vector {
        let id: String
        let key: String
        let intent: FlareFormKeyboardIntent
        var shift = false
        var composing = false
        var popupOpen = false
        var submitOnEnter = false
    }

    private let vectors: [Vector] = [
        Vector(id: "enter.submits", key: "Enter", intent: .submit, submitOnEnter: true),
        Vector(id: "enter.withoutSubmitMode", key: "Enter", intent: .none),
        Vector(id: "enter.composing", key: "Enter", intent: .none, composing: true, submitOnEnter: true),
        Vector(id: "tab.forward", key: "Tab", intent: .tabForward),
        Vector(id: "tab.backward", key: "Tab", intent: .tabBackward, shift: true),
        Vector(id: "tab.composing", key: "Tab", intent: .none, composing: true),
        Vector(id: "escape.closesPopup", key: "Escape", intent: .closePopup, popupOpen: true),
        Vector(id: "escape.withoutPopup", key: "Escape", intent: .none),
        Vector(id: "escape.composing", key: "Escape", intent: .none, composing: true, popupOpen: true),
        Vector(id: "arrowDown.nextOption", key: "ArrowDown", intent: .nextOption, popupOpen: true),
        Vector(id: "arrowUp.previousOption", key: "ArrowUp", intent: .previousOption, popupOpen: true),
        Vector(id: "arrowDown.composing", key: "ArrowDown", intent: .none, composing: true, popupOpen: true),
        Vector(id: "arrowDown.withoutPopup", key: "ArrowDown", intent: .none),
        Vector(id: "home.firstOption", key: "Home", intent: .firstOption, popupOpen: true),
        Vector(id: "end.lastOption", key: "End", intent: .lastOption, popupOpen: true),
        Vector(id: "pageDown.pageForward", key: "PageDown", intent: .pageForward, popupOpen: true),
        Vector(id: "pageUp.pageBackward", key: "PageUp", intent: .pageBackward, popupOpen: true),
        Vector(id: "unknownKey", key: "F13", intent: .none, popupOpen: true),
    ]

    func testEveryVectorResolvesToItsIntent() {
        for v in vectors {
            XCTAssertEqual(
                resolveFormKeyboardIntent(v.key, shift: v.shift, composing: v.composing, popupOpen: v.popupOpen, submitOnEnter: v.submitOnEnter),
                v.intent,
                v.id
            )
        }
    }

    func testTheImeGetsEveryKeyWhileACompositionIsOpen() {
        // The guard is unconditional on purpose: a composing Tab must not move
        // focus out from under a half-typed word, and Escape belongs to the IME.
        for key in ["Enter", "Tab", "Escape", "ArrowDown", "ArrowUp", "Home", "End", "PageDown", "PageUp"] {
            XCTAssertEqual(
                resolveFormKeyboardIntent(key, shift: true, composing: true, popupOpen: true, submitOnEnter: true),
                .none,
                key
            )
        }
    }

    func testTheKeyNameIsCaseInsensitive() {
        XCTAssertEqual(resolveFormKeyboardIntent("enter", submitOnEnter: true), .submit)
        XCTAssertEqual(resolveFormKeyboardIntent("ARROWDOWN", popupOpen: true), .nextOption)
    }
}
